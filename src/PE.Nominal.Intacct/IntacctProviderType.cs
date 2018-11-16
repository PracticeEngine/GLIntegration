using PE.Nominal.Provider;
using System;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Extensions.Options;
using System.Linq;
using System.Xml.Linq;
using Microsoft.Extensions.Caching.Memory;
using System.Web;
using Microsoft.AspNetCore.Hosting;
using System.IO;
using Intacct.SDK.Functions.Common;
using Intacct.SDK;
using Intacct.SDK.Functions.GeneralLedger;
using Intacct.SDK.Xml;
using Hangfire.Server;
using Hangfire.Console;

namespace PE.Nominal.Intacct
{
    public class IntacctProviderType : IntacctBaseService, IProviderType
    {
        private readonly IMemoryCache _cache;
        const string cacheTypesFormat = "intacct_cache_accttypes_{0}";
        const string cacheNameFormat = "intacct_cache_acctlist_{0}";

        public IntacctProviderType(IOptions<IntacctConfig> config, IMemoryCache cache, IHostingEnvironment env)
            :base(config.Value, env)
        {
            _cache = cache;
        }



        /// <summary>
        /// Caches Data about Account Lists for an Orgization
        /// </summary>
        /// <param name="Org"></param>
        /// <returns></returns>
        private async Task CacheAccountList(int Org)
        {
            // Items to build our lists
            var accountList = new Dictionary<string,GLAccount>();
            var accountTypeList = new Dictionary<string, GLType>();

            // Perform Priming Read
            ReadByQuery read = new ReadByQuery
            {
                ObjectName = "GLACCOUNT",
                PageSize = 1000
            };
            var client = GetClient(Org);
            var onlineResponse = await client.Execute(read);
            var xmlResult = onlineResponse.Results.First();
            xmlResult.EnsureStatusSuccess();

            // Process Results
            ExtractInfoFromXML(xmlResult.Data, xmlResult.ListType, accountList, accountTypeList);

            int receivedCount = xmlResult.Count;

            while(receivedCount < xmlResult.TotalCount)
            {
                // Read Additional Pages of Data
                ReadMore more = new ReadMore(xmlResult.ControlId)
                {
                    ResultId = xmlResult.ResultId
                };
                onlineResponse = await client.Execute(more);
                xmlResult = onlineResponse.Results.First();
                xmlResult.EnsureStatusSuccess();

                // Process Results
                ExtractInfoFromXML(xmlResult.Data, xmlResult.ListType, accountList, accountTypeList);

                // Increment the Counter
                receivedCount += xmlResult.Count;
            }

            // Save to Cache
            _cache.Set(String.Format(cacheTypesFormat, Org), accountTypeList.Values.OrderBy(glt => glt.AccountTypeCode).AsEnumerable(), new MemoryCacheEntryOptions
            {
                SlidingExpiration = TimeSpan.FromMinutes(Math.Max(1, _config.CacheMinutes))
            });
            _cache.Set(String.Format(cacheNameFormat, Org), accountList.Values.OrderBy(acct => acct.AccountTypeCode).ThenBy(acct => acct.AccountCode).AsEnumerable(), new MemoryCacheEntryOptions
            {
                SlidingExpiration = TimeSpan.FromMinutes(Math.Max(1, _config.CacheMinutes))
            });
        }

        /// <summary>
        /// Extracts AccountGroupHierarchy Data from XML and puts into Lists
        /// </summary>
        /// <param name="data"></param>
        /// <param name="accountList"></param>
        /// <param name="accountTypeList"></param>
        private void ExtractInfoFromXML(IEnumerable<XElement> details, string listType, Dictionary<string, GLAccount> accountList, Dictionary<string, GLType> accountTypeList)
        {
            foreach(var detail in details)
            {
                var typeCode = detail.Element("ACCOUNTTYPE");
                var typeDesc = detail.Element("ACCOUNTTYPE");
                var acctCode = detail.Element("ACCOUNTNO");
                var acctDesc = detail.Element("TITLE");

                // Ignore Data that is not valid
                if (typeCode == null || typeDesc == null || acctCode == null || acctDesc == null)
                    continue;

                // Add Type if not already added
                if (!accountTypeList.ContainsKey(typeCode.Value))
                {
                    accountTypeList.Add(typeCode.Value, new GLType
                    {
                        AccountTypeCode = typeCode.Value,
                        AccountTypeDesc = typeDesc.Value
                    });
                }
                // Add Account if not already added
                if (!accountList.ContainsKey(acctCode.Value))
                {
                    accountList.Add(acctCode.Value, new GLAccount
                    {
                        AccountTypeCode = typeCode.Value,
                        AccountTypeDesc = typeDesc.Value,
                        AccountCode = acctCode.Value,
                        AccountDesc = acctCode.Value + " - " + acctDesc.Value
                    });
                }
            }
        }

        public async Task<IEnumerable<GLAccount>> AccountsQuery(int Org, string AcctType)
        {
            string cacheName = String.Format(cacheNameFormat, Org);
            IEnumerable<GLAccount> cached;
            if (!_cache.TryGetValue<IEnumerable<GLAccount>>(cacheName, out cached))
            {
                await CacheAccountList(Org);
                cached = _cache.Get<IEnumerable<GLAccount>>(cacheName);
            }
            return cached.Where(acct => acct.AccountTypeCode == AcctType);
        }

        public async Task<IEnumerable<GLType>> AccountTypesQuery(int Org)
        {
            string cacheName = String.Format(cacheTypesFormat, Org);
            IEnumerable<GLType> cached;
            if (!_cache.TryGetValue<IEnumerable<GLType>>(cacheName, out cached))
            {
                await CacheAccountList(Org);
                cached = _cache.Get<IEnumerable<GLType>>(cacheName);
            }
            return cached;
        }

        public async Task PostJournalCmd(int Org, IEnumerable<JournalExtract> lines, string JournalSymbol, PerformContext performContext)
        {
            var orgConfig = GetOrgConfig(Org);
            var example = lines.First();
            var desc = "Practice Engine Journal: (Batch #" + example.NomBatch + ")";
            var comment = orgConfig.CreateAsDraft ? "Draft Journal Created from Practice Engine" : "Journal Created from Practice Engine";
            var client = GetClient(Org);
            await this.SendJournalCmd(client, Org, lines, example.NomDate, example.NomBatch.ToString(), JournalSymbol, desc, comment, orgConfig.CreateAsDraft);
        }


        /// <summary>
        /// Sends an Intacct Stats Journal
        /// </summary>
        /// <param name="Org"></param>
        /// <param name="lines"></param>
        /// <param name="JournalSymbol"></param>
        /// <returns></returns>
        public async Task PostStatHourJournalCmd(int Org, IEnumerable<IntacctStatHours> lines, string JournalSymbol, PerformContext performContext)
        {
            var orgConfig = GetOrgConfig(Org);
            var example = lines.First();
            var desc = "Practice Engine Stats Journal: (Batch #" + example.BatchID + ")";
            var comment = orgConfig.CreateAsDraft ? "Draft STAT Journal Created from Practice Engine" : "STAT Journal Created from Practice Engine";
            var client = GetClient(Org);
            await this.SendStatHoursJournalCmd(client, Org, lines, example.BatchDate, example.BatchID.ToString(), JournalSymbol, desc, comment, orgConfig.CreateAsDraft);

        }

        /// <summary>
        /// Sends a Journal to the Intacct GL System
        /// </summary>
        /// <param name="client"></param>
        /// <param name="Org"></param>
        /// <param name="lines"></param>
        /// <param name="PostingDate"></param>
        /// <param name="ReferenceNumber"></param>
        /// <param name="JournalSymbol"></param>
        /// <param name="Description"></param>
        /// <param name="HistoryComment"></param>
        /// <param name="AsDraft"></param>
        /// <returns></returns>
        private async Task SendJournalCmd(OnlineClient client, int Org, IEnumerable<JournalExtract> lines, DateTime PostingDate, string ReferenceNumber, string JournalSymbol, string Description, string HistoryComment, bool AsDraft)
        {
            JournalEntryCreate create = new JournalEntryCreate();
            create.JournalSymbol = JournalSymbol;
            create.ReferenceNumber = ReferenceNumber;
            create.PostingDate = PostingDate;
            create.Description = Description;
            create.HistoryComment = HistoryComment;
            if (AsDraft)
            {
                create.CustomFields.Add("STATE", "Draft");
            }
            foreach (var item in lines)
            {
                JournalEntryLineCreate line = new JournalEntryLineCreate
                {
                    GlAccountNumber = item.AccountCode,
                    TransactionAmount = decimal.Parse(item.NomAmount.ToString("F2")),
                    Memo = String.IsNullOrWhiteSpace(item.NomTransRef) ? item.NomNarrative : item.NomNarrative + " (" + item.NomTransRef + ")"
                };
                if (!String.IsNullOrWhiteSpace(item.IntacctCustomerID))
                {
                    line.CustomerId = item.IntacctCustomerID;
                }
                if (!String.IsNullOrWhiteSpace(item.IntacctEmployeeID))
                {
                    line.EmployeeId = item.IntacctEmployeeID;
                }
                if (!String.IsNullOrWhiteSpace(item.IntacctProjectID))
                {
                    line.ProjectId = item.IntacctProjectID;
                }
                if (!String.IsNullOrWhiteSpace(item.IntacctDepartment))
                {
                    line.DepartmentId = item.IntacctDepartment;
                }
                if (!String.IsNullOrWhiteSpace(item.IntacctLocation))
                {
                    line.LocationId = item.IntacctLocation;
                }

                var customFields = new Dictionary<string, dynamic>();

                if (!String.IsNullOrWhiteSpace(item.client_partner_id))
                {
                    customFields.Add("client_partner_id", item.client_partner_id);
                }

                if (!String.IsNullOrWhiteSpace(item.client_partner))
                {
                    customFields.Add("client_partner", item.client_partner);
                }

                if (!String.IsNullOrWhiteSpace(item.category_name_id))
                {
                    customFields.Add("category_name_id", item.category_name_id);
                }

                if (!String.IsNullOrWhiteSpace(item.category_name))
                {
                    customFields.Add("category_name", item.category_name);
                }

                if (!String.IsNullOrWhiteSpace(item.owner_name_id))
                {
                    customFields.Add("owner_name_id", item.owner_name_id);
                }

                if (!String.IsNullOrWhiteSpace(item.owner_name))
                {
                    customFields.Add("owner_name", item.owner_name);
                }

                if (!String.IsNullOrWhiteSpace(item.service_type_id))
                {
                    customFields.Add("service_type_id", item.service_type_id);
                }

                if (!String.IsNullOrWhiteSpace(item.service_type))
                {
                    customFields.Add("service_type", item.service_type);
                }

                if (customFields.Count() > 0)
                    line.CustomFields = customFields;

                create.Lines.Add(line);
            }
            OnlineResponse onlineResponse = await client.Execute(create);
            foreach (var result in onlineResponse.Results)
            {
                result.EnsureStatusSuccess();
            }
        }


        /// <summary>
        /// Sends a Hours Journal to the Intacct STATISTIC System
        /// </summary>
        /// <param name="client"></param>
        /// <param name="Org"></param>
        /// <param name="lines"></param>
        /// <param name="PostingDate"></param>
        /// <param name="ReferenceNumber"></param>
        /// <param name="JournalSymbol"></param>
        /// <param name="Description"></param>
        /// <param name="HistoryComment"></param>
        /// <param name="AsDraft"></param>
        /// <returns></returns>
        private async Task SendStatHoursJournalCmd(OnlineClient client, int Org, IEnumerable<IntacctStatHours> lines, DateTime PostingDate, string ReferenceNumber, string JournalSymbol, string Description, string HistoryComment, bool AsDraft)
        {
            StatisticalJournalEntryCreate create = new StatisticalJournalEntryCreate();
            create.JournalSymbol = JournalSymbol;
            create.ReferenceNumber = ReferenceNumber;
            create.PostingDate = PostingDate;
            create.Description = Description;
            create.HistoryComment = HistoryComment;
            if (AsDraft)
            {
                create.CustomFields.Add("STATE", "Draft");
            }
            foreach (var item in lines)
            {
                StatisticalJournalEntryLineCreate line = new StatisticalJournalEntryLineCreate
                {
                    
                    StatAccountNumber = item.Account,
                    Amount = decimal.Parse(item.Hours.ToString("F2")),
                    Memo = $"Part of Practice Engine Batch #{item.BatchID}"
                };
                if (!String.IsNullOrWhiteSpace(item.EmployeeID))
                {
                    line.EmployeeId = item.EmployeeID;
                }
                if (!String.IsNullOrWhiteSpace(item.ProjectID))
                {
                    line.ProjectId = item.ProjectID;
                }
                if (!String.IsNullOrWhiteSpace(item.IntacctCustomerID))
                {
                    line.CustomerId = item.IntacctCustomerID;
                }
                if (!String.IsNullOrWhiteSpace(item.IntacctDepartment))
                {
                    line.DepartmentId = item.IntacctDepartment;
                }
                if (!String.IsNullOrWhiteSpace(item.IntacctLocation))
                {
                    line.LocationId = item.IntacctLocation;
                }

                var customFields = new Dictionary<string, dynamic>();

                if (!String.IsNullOrWhiteSpace(item.client_partner_id))
                {
                    customFields.Add("client_partner_id", item.client_partner_id);
                }

                if (!String.IsNullOrWhiteSpace(item.client_partner))
                {
                    customFields.Add("client_partner", item.client_partner);
                }

                if (!String.IsNullOrWhiteSpace(item.category_name_id))
                {
                    customFields.Add("category_name_id", item.category_name_id);
                }

                if (!String.IsNullOrWhiteSpace(item.category_name))
                {
                    customFields.Add("category_name", item.category_name);
                }

                if (!String.IsNullOrWhiteSpace(item.owner_name_id))
                {
                    customFields.Add("owner_name_id", item.owner_name_id);
                }

                if (!String.IsNullOrWhiteSpace(item.owner_name))
                {
                    customFields.Add("owner_name", item.owner_name);
                }

                if (!String.IsNullOrWhiteSpace(item.service_type_id))
                {
                    customFields.Add("service_type_id", item.service_type_id);
                }

                if (!String.IsNullOrWhiteSpace(item.service_type))
                {
                    customFields.Add("service_type", item.service_type);
                }

                if (customFields.Count() > 0)
                    line.CustomFields = customFields;

                create.Lines.Add(line);
            }
            OnlineResponse onlineResponse = await client.Execute(create);
            foreach (var result in onlineResponse.Results)
            {
                result.EnsureStatusSuccess();
            }
        }


        /// <summary>
        /// Returns Configuration Details for Cashbook Posting
        /// </summary>
        /// <param name="org"></param>
        /// <returns></returns>
        private IntacctOrgConfig GetOrgCashConfig(int org)
        {
            var orgConfig = _config.CashbookConfigs.FirstOrDefault(c => c.Org == org);
            if (orgConfig == null)
                throw new Exception("No Intacct Cashbook Configuration found for Organization #" + org);

            return orgConfig;
        }

        /// <summary>
        /// Returns an Intacct Client Connected to the correct database for Cashbook Posting
        /// </summary>
        /// <param name="org"></param>
        /// <returns></returns>
        private OnlineClient GetCashClient(int org)
        {
            var orgConfig = GetOrgCashConfig(org);

            var intacctClient = new OnlineClient(new ClientConfig
            {
                SenderId = orgConfig.SenderID,
                SenderPassword = orgConfig.SenderPassword,
                CompanyId = orgConfig.CompanyID,
                UserId = orgConfig.UserID,
                UserPassword = orgConfig.UserPassword
            });

            return intacctClient;
        }


        public async Task CashJournalCmd(int Org, IEnumerable<JournalExtract> lines, string JournalSymbol, PerformContext performContext)
        {
            var orgConfig = GetOrgCashConfig(Org);
            var example = lines.First();
            var desc = "Practice Engine Cash Journal: (Batch #" + example.NomBatch + ")";
            var comment = orgConfig.CreateAsDraft ? "Draft Journal Created from Practice Engine" : "Journal Created from Practice Engine";
            var client = GetCashClient(Org);
            await this.SendJournalCmd(client, Org, lines, example.NomDate, example.NomBatch.ToString(), JournalSymbol, desc, comment, orgConfig.CreateAsDraft);
        }

    }
}

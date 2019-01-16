using Hangfire.Server;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using PE.Nominal.Intacct;
using PE.Nominal.Provider;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Xero.Api.Core;
using Xero.Api.Infrastructure.Authenticators;
using Xero.Api.Infrastructure.OAuth;

namespace PE.Nominal.XeroGL
{
    public class XeroProviderType : XeroBaseService, IProviderType
    {
        private readonly IMemoryCache _cache;
        const string cacheTypesFormat = "intacct_cache_accttypes_{0}";
        const string cacheNameFormat = "intacct_cache_acctlist_{0}";

        public XeroProviderType(IOptions<XeroConfig> config, IMemoryCache cache, IHostingEnvironment env)
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
            /*
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
            */
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
            throw new NotImplementedException();
            /*
            var orgConfig = GetOrgConfig(Org);
            var example = lines.First();
            var desc = "Practice Engine Journal: (Batch #" + example.NomBatch + ")";
            var comment = orgConfig.CreateAsDraft ? "Draft Journal Created from Practice Engine" : "Journal Created from Practice Engine";
            var client = GetClient(Org);
            await this.SendJournalCmd(client, Org, lines, example.NomDate, example.NomBatch.ToString(), JournalSymbol, desc, comment, orgConfig.CreateAsDraft);
            */
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
            throw new NotImplementedException();
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
        private async Task SendJournalCmd(IXeroCoreApi client, int Org, IEnumerable<JournalExtract> lines, DateTime PostingDate, string ReferenceNumber, string JournalSymbol, string Description, string HistoryComment, bool AsDraft)
        {
            throw new NotImplementedException();
            /*
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

                //if (!String.IsNullOrWhiteSpace(item.client_partner_id))
                //{
                //    customFields.Add("client_partner_id", item.client_partner_id);
                //}

                if (!String.IsNullOrWhiteSpace(item.client_partner))
                {
                    customFields.Add("GLDIMCLIENT_PARTNER", item.client_partner);
                }

                //if (!String.IsNullOrWhiteSpace(item.category_name_id))
                //{
                //    customFields.Add("category_name_id", item.category_name_id);
                //}

                if (!String.IsNullOrWhiteSpace(item.category_name))
                {
                    customFields.Add("GLDIMCATEGORY_NAME", item.category_name);
                }

                //if (!String.IsNullOrWhiteSpace(item.owner_name_id))
                //{
                //    customFields.Add("owner_name_id", item.owner_name_id);
                //}

                if (!String.IsNullOrWhiteSpace(item.owner_name))
                {
                    customFields.Add("GLDIMOWNER_NAME", item.owner_name);
                }

                //if (!String.IsNullOrWhiteSpace(item.service_type_id))
                //{
                //    customFields.Add("service_type_id", item.service_type_id);
                //}

                if (!String.IsNullOrWhiteSpace(item.service_type))
                {
                    customFields.Add("GLDIMSERVICE_TYPE", item.service_type);
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
            */
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
        private async Task SendStatHoursJournalCmd(IXeroCoreApi client, int Org, IEnumerable<IntacctStatHours> lines, DateTime PostingDate, string ReferenceNumber, string JournalSymbol, string Description, string HistoryComment, bool AsDraft)
        {
            throw new NotImplementedException();
            /*
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

                //if (!String.IsNullOrWhiteSpace(item.client_partner_id))
                //{
                //    customFields.Add("client_partner_id", item.client_partner_id);
                //}

                if (!String.IsNullOrWhiteSpace(item.client_partner))
                {
                    customFields.Add("GLDIMCLIENT_PARTNER", item.client_partner);
                }

                //if (!String.IsNullOrWhiteSpace(item.category_name_id))
                //{
                //    customFields.Add("category_name_id", item.category_name_id);
                //}

                if (!String.IsNullOrWhiteSpace(item.category_name))
                {
                    customFields.Add("GLDIMCATEGORY_NAME", item.category_name);
                }

                //if (!String.IsNullOrWhiteSpace(item.owner_name_id))
                //{
                //    customFields.Add("owner_name_id", item.owner_name_id);
                //}

                if (!String.IsNullOrWhiteSpace(item.owner_name))
                {
                    customFields.Add("GLDIMOWNER_NAME", item.owner_name);
                }

                //if (!String.IsNullOrWhiteSpace(item.service_type_id))
                //{
                //    customFields.Add("service_type_id", item.service_type_id);
                //}

                if (!String.IsNullOrWhiteSpace(item.service_type))
                {
                    customFields.Add("GLDIMSERVICE_TYPE", item.service_type);
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
            */
        }


        /// <summary>
        /// Returns Configuration Details for Cashbook Posting
        /// </summary>
        /// <param name="org"></param>
        /// <returns></returns>
        private XeroOrgConfig GetOrgCashConfig(int org)
        {
            var orgConfig = _config.CashbookConfigs.FirstOrDefault(c => c.Org == org);
            if (orgConfig == null)
                throw new Exception("No Xero Cashbook Configuration found for Organization #" + org);

            return orgConfig;
        }

        /// <summary>
        /// Returns an Xero Client Connected to the correct database for Cashbook Posting
        /// </summary>
        /// <param name="org"></param>
        /// <returns></returns>
        private IXeroCoreApi GetCashClient(int org)
        {
            var orgConfig = GetOrgCashConfig(org);

            var xeroClient = new XeroCoreApi(orgConfig.XeroURL, new PrivateAuthenticator(orgConfig.XeroCertPath),
                new Consumer(orgConfig.SenderID, orgConfig.SenderPassword));

            return xeroClient;
        }


        public async Task CashJournalCmd(int Org, IEnumerable<JournalExtract> lines, string JournalSymbol, PerformContext performContext)
        {
            throw new NotImplementedException();
            /*
            var orgConfig = GetOrgCashConfig(Org);
            var example = lines.First();
            var desc = "Practice Engine Cash Journal: (Batch #" + example.NomBatch + ")";
            var comment = orgConfig.CreateAsDraft ? "Draft Journal Created from Practice Engine" : "Journal Created from Practice Engine";
            var client = GetCashClient(Org);
            await this.SendJournalCmd(client, Org, lines, example.NomDate, example.NomBatch.ToString(), JournalSymbol, desc, comment, orgConfig.CreateAsDraft);
            */
        }

        public async Task PostMTDCmd(int Org, IEnumerable<MTDClient> clients, IEnumerable<MTDInvoice> invoices, IEnumerable<MTDInvoiceLine> lines, PerformContext performContext)
        {
            var orgConfig = GetOrgCashConfig(Org);

            var xeroClient = GetClient(Org);

            var xeroContacts = await xeroClient.Contacts.FindAsync();

            var newContacts = new List<Xero.Api.Core.Model.Contact>();
            var updatedContacts = new List<Xero.Api.Core.Model.Contact>();

            foreach (var client in clients)
            {
                var cont = xeroContacts.Where(c => c.ContactNumber == client.ClientCode || c.Id.ToString() == client.GLClientID);
                if (cont.Count() == 0)
                {
                    // New Contact in Xero
                    Xero.Api.Core.Model.Contact newcontact = new Xero.Api.Core.Model.Contact();
                    newcontact.ContactNumber = client.ClientCode;
                    newcontact.Name = client.ClientName;
                    newcontact.IsCustomer = true;
                    var address = new Xero.Api.Core.Model.Address();
                    address.AddressLine1 = client.Address;
                    address.City = client.TownCity;
                    address.Region = client.County;
                    address.Country = client.Country;
                    address.PostalCode = client.PostCode;
                    newcontact.Addresses = new List<Xero.Api.Core.Model.Address>();
                    newcontact.Addresses.Add(address);
                    newcontact.ContactStatus = Xero.Api.Core.Model.Status.ContactStatus.Active;

                    newContacts.Add(newcontact);
                }
                else
                {
                    // Update Contact in Xero
                    Xero.Api.Core.Model.Contact existingcontact = cont.First();
                    existingcontact.ContactNumber = client.ClientCode;
                    existingcontact.Name = client.ClientName;
                    existingcontact.IsCustomer = true;
                    var address = new Xero.Api.Core.Model.Address();
                    address.AddressLine1 = client.Address;
                    address.City = client.TownCity;
                    address.Region = client.County;
                    address.Country = client.Country;
                    address.PostalCode = client.PostCode;
                    existingcontact.Addresses = new List<Xero.Api.Core.Model.Address>();
                    existingcontact.Addresses.Add(address);
                    existingcontact.ContactStatus = Xero.Api.Core.Model.Status.ContactStatus.Active;

                    updatedContacts.Add(existingcontact);
                }
            }

            var createResponse = await xeroClient.Contacts.CreateAsync(newContacts);

            var updateResponse = await xeroClient.Contacts.UpdateAsync(updatedContacts);


        }
    }
}

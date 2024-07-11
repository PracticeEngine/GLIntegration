using Hangfire.Server;
using Intacct.SDK;
using Intacct.SDK.Functions.Common;
using Intacct.SDK.Functions.GeneralLedger;
using Intacct.SDK.Xml;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using PE.Nominal.Intacct;
using PE.Nominal.Provider;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace PE.Nominal.BusCent
{
    public class BusCentProviderType : BusCentBaseService, IProviderType
    {
        private readonly IMemoryCache _cache;
        const string cacheTypesFormat = "buscent_cache_accttypes_{0}";
        const string cacheNameFormat = "buscent_cache_acctlist_{0}";

        public BusCentProviderType(IOptions<BusCentConfig> config, IMemoryCache cache, IHostingEnvironment env)
            :base(config.Value, env)
        {
            _cache = cache;
        }



        /// <summary>
        /// Caches Data about Account Lists for an Organisation
        /// </summary>
        /// <param name="Org"></param>
        /// <returns></returns>
        private async Task CacheAccountList(int Org)
        {
            // Items to build our lists
            var accountList = new Dictionary<string, GLAccount>();
            var accountTypeList = new Dictionary<string, GLType>();

            var orgConfig = GetOrgConfig(Org);
            var client = await GetClient(Org);

            var companiesResponse = await client.GetAsync("companies");
            string companyContent = await companiesResponse.Content.ReadAsStringAsync();
            BusCentCompanies companies = JsonConvert.DeserializeObject<BusCentCompanies>(companyContent);
            var company = companies.value.Where(c => c.displayName.Trim() == orgConfig.CompanyName.Trim()).FirstOrDefault();
            if (company == null)
            {
                throw new Exception($"Company {orgConfig.CompanyName} not found in Business Central");
            }
            else
            {
                var accountsResponse = await client.GetAsync($"companies({company.id})/accounts");
                string accountContent = await accountsResponse.Content.ReadAsStringAsync();
                BusCentAccounts accounts = JsonConvert.DeserializeObject<BusCentAccounts>(accountContent);

                // Process Results
                ExtractInfoFromJson(accounts, accountList, accountTypeList);

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
        }

        /// <summary>
        /// Extracts AccountGroupHierarchy Data from Json and puts into Lists
        /// </summary>
        /// <param name="data"></param>
        /// <param name="accountList"></param>
        /// <param name="accountTypeList"></param>
        private void ExtractInfoFromJson(BusCentAccounts details, Dictionary<string, GLAccount> accountList, Dictionary<string, GLType> accountTypeList)
        {
            foreach(var detail in details.value)
            {
                if (detail.accountType.ToLower() == "posting")
                {
                    var typeCode = detail.category;
                    var typeDesc = detail.category;
                    var acctId = detail.id;
                    var acctCode = detail.number;
                    var acctDesc = detail.displayName;

                    // Ignore Data that is not valid
                    if (typeCode == null || typeDesc == null || acctCode == null || acctDesc == null)
                        continue;

                    // Add Type if not already added
                    if (!accountTypeList.ContainsKey(typeCode))
                    {
                        accountTypeList.Add(typeCode, new GLType
                        {
                            AccountTypeCode = typeCode,
                            AccountTypeDesc = typeDesc
                        });
                    }
                    // Add Account if not already added
                    if (!accountList.ContainsKey(acctId))
                    {
                        accountList.Add(acctId, new GLAccount
                        {
                            AccountTypeCode = typeCode,
                            AccountTypeDesc = typeDesc,
                            AccountCode = acctCode,
                            AccountDesc = acctCode + " - " + acctDesc,
                            AccountId = acctId
                        });
                    }
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

        public async Task<IEnumerable<GLAccount>> AllAccountsQuery(int Org)
        {
            string cacheName = String.Format(cacheNameFormat, Org);
            IEnumerable<GLAccount> cached;
            if (!_cache.TryGetValue<IEnumerable<GLAccount>>(cacheName, out cached))
            {
                await CacheAccountList(Org);
                cached = _cache.Get<IEnumerable<GLAccount>>(cacheName);
            }
            return cached;
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

        public async Task<IEnumerable<BusCentCompany>> CompaniesQuery(HttpClient client)
        {
            var companiesResponse = await client.GetAsync("companies");
            string companyContent = await companiesResponse.Content.ReadAsStringAsync();
            BusCentCompanies companies = JsonConvert.DeserializeObject<BusCentCompanies>(companyContent);
            return companies.value;
        }

        public async Task<IEnumerable<BCJournal>> JournalQuery(HttpClient client, string companyId)
        {
            var journalResponse = await client.GetAsync($"companies({companyId})/journals");
            string journalContent = await journalResponse.Content.ReadAsStringAsync();
            BusCentJournal journals = JsonConvert.DeserializeObject<BusCentJournal>(journalContent);
            return journals.value;
        }

        public async Task<IEnumerable<BCJournalLine>> JournalLineQuery(HttpClient client, string companyId, string journalId)
        {
            var journalResponse = await client.GetAsync($"companies({companyId})/journals({journalId})/journalLines");
            string journalContent = await journalResponse.Content.ReadAsStringAsync();
            BusCentJournalLines journals = JsonConvert.DeserializeObject<BusCentJournalLines>(journalContent);
            return journals.value;
        }

        public async Task<IEnumerable<BCDimension>> DimensionQuery(HttpClient client, string companyId)
        {
            var dimResponse = await client.GetAsync($"companies({companyId})/dimensions");
            string dimContent = await dimResponse.Content.ReadAsStringAsync();
            BusCentDimensions dims = JsonConvert.DeserializeObject<BusCentDimensions>(dimContent);
            return dims.value;
        }

        public async Task<IEnumerable<BCDimensionValue>> DimensionValueQuery(HttpClient client, string companyId)
        {
            var dimResponse = await client.GetAsync($"companies({companyId})/dimensionValues");
            string dimContent = await dimResponse.Content.ReadAsStringAsync();
            BusCentDimensionValues dims = JsonConvert.DeserializeObject<BusCentDimensionValues>(dimContent);
            return dims.value;
        }

        public async Task<BCJournal> CreateJournalQuery(HttpClient client, string companyId)
        {
            string createJournalBody = "{\"code\": \"PE\", \"displayName\": \"Practice Engine Journal\"}";
            var createJournalResponse = await client.PostAsync($"companies({companyId})/journals", new StringContent(createJournalBody, Encoding.UTF8, "application/json"));
            string createJournalContent = await createJournalResponse.Content.ReadAsStringAsync();
            var newJournal = JsonConvert.DeserializeObject<BCJournal>(createJournalContent);
            return newJournal;
        }

        public async Task<BCJournalLine> CreateJournalLineQuery(HttpClient client, string companyId, string journalId, JournalExtract item, int lineNumber, string documentNum, IEnumerable<GLAccount> accounts)
        {
            string lineid = Guid.NewGuid().ToString();
            var account = accounts.Where(a => a.AccountCode == item.AccountCode).FirstOrDefault();

            string createJournalLineBody = "{\"id\": \"" + lineid + "\", \"journalId\": \"" + journalId + "\", \"lineNumber\": " + lineNumber.ToString() + ", \"accountType\": \"G/L Account\", \"accountId\": \"" + account.AccountId + "\", \"accountNumber\": \"" + account.AccountCode + "\", \"postingDate\": \"" + item.NomDate.ToString("yyyy-MM-dd") + "\", \"amount\": " + item.NomAmount.ToString() + ", \"documentNumber\": \"" + documentNum + "\", \"externalDocumentNumber\": \"\", \"description\": \"" + item.NomNarrative + "\", \"comment\": \"" + item.NomTransRef + "\", \"taxCode\": \"" + item.BCTaxProdGroup + "\" }";
            var createJournalLineResponse = await client.PostAsync($"companies({companyId})/journals({journalId})/journalLines", new StringContent(createJournalLineBody, Encoding.UTF8, "application/json"));
            string createJournalLineContent = await createJournalLineResponse.Content.ReadAsStringAsync();
            var newLine = JsonConvert.DeserializeObject<BCJournalLine>(createJournalLineContent);
            return newLine;
        }

        public async Task CreateJournalLineDimensionQuery(HttpClient client, string companyId, JournalExtract item, BCJournalLine line, IEnumerable<BCDimension> dimensions, IEnumerable<BCDimensionValue> dimensionValues)
        {
            if (!string.IsNullOrEmpty(item.Dimension1Code))
            {
                var dim = dimensions.Where(d => d.code == item.Dimension1Code).FirstOrDefault();
                if (dim != null)
                {
                    var dimv = dimensionValues.Where(d => d.code == item.Dimension1Value).FirstOrDefault();
                    if (dimv != null)
                    {
                        string createDimBody = "{\"code\": \"" + dim.code + "\", \"valueCode\": \"" + dimv.code + "\" }";
                        var createDimResponse = await client.PostAsync($"companies({companyId})/journalLines({line.id})/dimensionSetLines", new StringContent(createDimBody, Encoding.UTF8, "application/json"));
                    }
                }
            }

            if (!string.IsNullOrEmpty(item.Dimension2Code))
            {
                var dim = dimensions.Where(d => d.code == item.Dimension2Code).FirstOrDefault();
                if (dim != null)
                {
                    var dimv = dimensionValues.Where(d => d.code == item.Dimension2Value).FirstOrDefault();
                    if (dimv != null)
                    {
                        string createDimBody = "{\"code\": \"" + dim.code + "\", \"valueCode\": \"" + dimv.code + "\" }";
                        var createDimResponse = await client.PostAsync($"companies({companyId})/journalLines({line.id})/dimensionSetLines", new StringContent(createDimBody, Encoding.UTF8, "application/json"));
                    }
                }
            }

            if (!string.IsNullOrEmpty(item.Dimension3Code))
            {
                var dim = dimensions.Where(d => d.code == item.Dimension3Code).FirstOrDefault();
                if (dim != null)
                {
                    var dimv = dimensionValues.Where(d => d.code == item.Dimension3Value).FirstOrDefault();
                    if (dimv != null)
                    {
                        string createDimBody = "{\"code\": \"" + dim.code + "\", \"valueCode\": \"" + dimv.code + "\" }";
                        var createDimResponse = await client.PostAsync($"companies({companyId})/journalLines({line.id})/dimensionSetLines", new StringContent(createDimBody, Encoding.UTF8, "application/json"));
                    }
                }
            }

            if (!string.IsNullOrEmpty(item.Dimension4Code))
            {
                var dim = dimensions.Where(d => d.code == item.Dimension4Code).FirstOrDefault();
                if (dim != null)
                {
                    var dimv = dimensionValues.Where(d => d.code == item.Dimension4Value).FirstOrDefault();
                    if (dimv != null)
                    {
                        string createDimBody = "{\"code\": \"" + dim.code + "\", \"valueCode\": \"" + dimv.code + "\" }";
                        var createDimResponse = await client.PostAsync($"companies({companyId})/journalLines({line.id})/dimensionSetLines", new StringContent(createDimBody, Encoding.UTF8, "application/json"));
                    }
                }
            }

            if (!string.IsNullOrEmpty(item.Dimension5Code))
            {
                var dim = dimensions.Where(d => d.code == item.Dimension5Code).FirstOrDefault();
                if (dim != null)
                {
                    var dimv = dimensionValues.Where(d => d.code == item.Dimension5Value).FirstOrDefault();
                    if (dimv != null)
                    {
                        string createDimBody = "{\"code\": \"" + dim.code + "\", \"valueCode\": \"" + dimv.code + "\" }";
                        var createDimResponse = await client.PostAsync($"companies({companyId})/journalLines({line.id})/dimensionSetLines", new StringContent(createDimBody, Encoding.UTF8, "application/json"));
                    }
                }
            }
        }

        public async Task PostJournalCmd(int Org, IEnumerable<JournalExtract> lines, string JournalSymbol, PerformContext performContext)
        {
            var orgConfig = GetOrgConfig(Org);
            var example = lines.First();
            var desc = "Practice Engine Journal: (Batch #" + example.NomBatch + ")";
            var comment = orgConfig.CreateAsDraft ? "Draft Journal Created from Practice Engine" : "Journal Created from Practice Engine";
            var client = await GetClient(Org);
            await this.SendJournalCmd(client, Org, lines, example.NomDate, example.NomBatch.ToString(), JournalSymbol, desc, comment, orgConfig.CreateAsDraft);
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
        private async Task SendJournalCmd(HttpClient client, int Org, IEnumerable<JournalExtract> lines, DateTime PostingDate, string ReferenceNumber, string JournalSymbol, string Description, string HistoryComment, bool AsDraft)
        {
            var orgConfig = GetOrgConfig(Org);
            IEnumerable<BusCentCompany> companies = await CompaniesQuery(client);
            var company = companies.Where(c => c.displayName.Trim() == orgConfig.CompanyName.Trim()).FirstOrDefault();
            string companyId = company.id;

            IEnumerable<GLAccount> accounts = await AllAccountsQuery(Org);
            IEnumerable<BCDimension> dimensions = await DimensionQuery(client, companyId);
            IEnumerable<BCDimensionValue> dimensionValues = await DimensionValueQuery(client, companyId);

            IEnumerable<BCJournal> journals = await JournalQuery(client, companyId);
            var journal = journals.Where(j => j.code.Trim() == "PE").FirstOrDefault();
            string journalId = "";

            if (journal == null)
            {
                BCJournal newJournal = await CreateJournalQuery(client, companyId);
                journalId = newJournal.id;
            }
            else
            {
                journalId = journal.id;
            }

            IEnumerable<BCJournalLine> jnlLines = await JournalLineQuery(client, companyId, journalId);

            int lineNumber = 0;
            string documentNum = "";

            var lastLine = jnlLines.OrderByDescending(j => j.lineNumber).FirstOrDefault();
            if (lastLine != null)
            {
                lineNumber = lastLine.lineNumber;
                documentNum = lastLine.documentNumber;
            }
            else
            {
                documentNum = "PE" + lines.First().NomBatch.ToString();
            }

            foreach (var accCode in lines.Select(l => l.AccountCode).Distinct())
            {
                var account = accounts.Where(a => a.AccountCode == accCode).FirstOrDefault();
                if (account == null || account.AccountCode != accCode)
                {
                    throw new Exception($"Company {orgConfig.CompanyName} does not have account {accCode} required for this transfer.");
                }
            }

            foreach (var dim1 in lines.Where(l => !string.IsNullOrEmpty(l.Dimension1Code) && !string.IsNullOrEmpty(l.Dimension1Value)).Select(l => new KeyValuePair<string, string>(l.Dimension1Code, l.Dimension1Value)).Distinct())
            {
                var dim = dimensions.Where(a => a.code == dim1.Key).FirstOrDefault();
                if (dim == null || dim.code != dim1.Key)
                {
                    throw new Exception($"Company {orgConfig.CompanyName} does not have a 1st dimension code of {dim1.Key} required for this transfer.");
                }
                else
                {
                    var dimv = dimensionValues.Where(d => d.code == dim1.Value).FirstOrDefault();
                    if (dimv == null || dimv.code != dim1.Value)
                    {
                        throw new Exception($"Company {orgConfig.CompanyName} does not have a dimension value of {dim1.Value} in dimension {dim1.Key} required for this transfer.");
                    }
                }
            }


            foreach (var dim2 in lines.Where(l => !string.IsNullOrEmpty(l.Dimension2Code) && !string.IsNullOrEmpty(l.Dimension2Value)).Select(l => new KeyValuePair<string, string>(l.Dimension2Code, l.Dimension2Value)).Distinct())
            {
                var dim = dimensions.Where(a => a.code == dim2.Key).FirstOrDefault();
                if (dim == null || dim.code != dim2.Key)
                {
                    throw new Exception($"Company {orgConfig.CompanyName} does not have a 2nd dimension code of {dim2.Key} required for this transfer.");
                }
                else
                {
                    var dimv = dimensionValues.Where(d => d.code == dim2.Value).FirstOrDefault();
                    if (dimv == null || dimv.code != dim2.Value)
                    {
                        throw new Exception($"Company {orgConfig.CompanyName} does not have a dimension value of {dim2.Value} in dimension {dim2.Key} required for this transfer.");
                    }
                }
            }

            foreach (var dim3 in lines.Where(l => !string.IsNullOrEmpty(l.Dimension3Code) && !string.IsNullOrEmpty(l.Dimension3Value)).Select(l => new KeyValuePair<string, string>(l.Dimension3Code, l.Dimension3Value)).Distinct())
            {
                var dim = dimensions.Where(a => a.code == dim3.Key).FirstOrDefault();
                if (dim == null || dim.code != dim3.Key)
                {
                    throw new Exception($"Company {orgConfig.CompanyName} does not have a 3st dimension code of {dim3.Key} required for this transfer.");
                }
                else
                {
                    var dimv = dimensionValues.Where(d => d.code == dim3.Value).FirstOrDefault();
                    if (dimv == null || dimv.code != dim3.Value)
                    {
                        throw new Exception($"Company {orgConfig.CompanyName} does not have a dimension value of {dim3.Value} in dimension {dim3.Key} required for this transfer.");
                    }
                }
            }

            foreach (var dim4 in lines.Where(l => !string.IsNullOrEmpty(l.Dimension4Code) && !string.IsNullOrEmpty(l.Dimension4Value)).Select(l => new KeyValuePair<string, string>(l.Dimension4Code, l.Dimension4Value)).Distinct())
            {
                var dim = dimensions.Where(a => a.code == dim4.Key).FirstOrDefault();
                if (dim == null || dim.code != dim4.Key)
                {
                    throw new Exception($"Company {orgConfig.CompanyName} does not have a 4st dimension code of {dim4.Key} required for this transfer.");
                }
                else
                {
                    var dimv = dimensionValues.Where(d => d.code == dim4.Value).FirstOrDefault();
                    if (dimv == null || dimv.code != dim4.Value)
                    {
                        throw new Exception($"Company {orgConfig.CompanyName} does not have a dimension value of {dim4.Value} in dimension {dim4.Key} required for this transfer.");
                    }
                }
            }

            foreach (var dim5 in lines.Where(l => !string.IsNullOrEmpty(l.Dimension5Code) && !string.IsNullOrEmpty(l.Dimension5Value)).Select(l => new KeyValuePair<string, string>(l.Dimension5Code, l.Dimension5Value)).Distinct())
            {
                var dim = dimensions.Where(a => a.code == dim5.Key).FirstOrDefault();
                if (dim == null || dim.code != dim5.Key)
                {
                    throw new Exception($"Company {orgConfig.CompanyName} does not have a 5st dimension code of {dim5.Key} required for this transfer.");
                }
                else
                {
                    var dimv = dimensionValues.Where(d => d.code == dim5.Value).FirstOrDefault();
                    if (dimv == null || dimv.code != dim5.Value)
                    {
                        throw new Exception($"Company {orgConfig.CompanyName} does not have a dimension value of {dim5.Value} in dimension {dim5.Key} required for this transfer.");
                    }
                }
            }

            foreach (var item in lines)
            {
                lineNumber = lineNumber + 10000;
                BCJournalLine newLine = await CreateJournalLineQuery(client, companyId, journalId, item, lineNumber, documentNum, accounts);

                await CreateJournalLineDimensionQuery(client, companyId, item, newLine, dimensions, dimensionValues);
            }
        }

        /// <summary>
        /// Returns Configuration Details for Cashbook Posting
        /// </summary>
        /// <param name="org"></param>
        /// <returns></returns>
        private BusCentOrgConfig GetOrgCashConfig(int org)
        {
            var orgConfig = _config.OrgConfigs.FirstOrDefault(c => c.Org == org);
            if (orgConfig == null)
                throw new Exception("No Business Central Cashbook Configuration found for Organisation #" + org);

            return orgConfig;
        }

        public async Task CashJournalCmd(int Org, IEnumerable<JournalExtract> lines, string JournalSymbol, PerformContext performContext)
        {
            var orgConfig = GetOrgCashConfig(Org);
            var example = lines.First();
            var desc = "Practice Engine Cash Journal: (Batch #" + example.NomBatch + ")";
            var comment = orgConfig.CreateAsDraft ? "Draft Journal Created from Practice Engine" : "Journal Created from Practice Engine";
            var client = await GetCashClient(Org);
            await this.SendJournalCmd(client, Org, lines, example.NomDate, example.NomBatch.ToString(), JournalSymbol, desc, comment, orgConfig.CreateAsDraft);
        }

        public async Task<IEnumerable<int>> PostMTDCmd(int Org, IEnumerable<MTDClient> clients, IEnumerable<MTDInvoice> invoices, PerformContext performContext)
        {
            throw new NotImplementedException();
        }
        public Task PostExpenseCmd(int Org, IEnumerable<ExpenseExtract> lines, PerformContext performContext)
        {
            throw new NotImplementedException();
        }

        public Task ImportDisbursementsCmd(int Org, PerformContext performContext, int StaffId)
        {
            throw new NotImplementedException();
        }

        public Task PostStatHourJournalCmd(int Org, IEnumerable<IntacctStatHours> lines, string JournalSymbol, PerformContext performContext)
        {
            throw new NotImplementedException();
        }
    }
}

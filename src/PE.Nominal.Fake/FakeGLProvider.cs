using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using PE.Nominal.Intacct;
using PE.Nominal.Provider;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace PE.Nominal.Fake
{
    /// <summary>
    /// A Fake GL Provider (useful for testing or demonstration purposes)
    /// </summary>
    public class FakeGLProvider : IProviderType
    {
        private readonly ILogger _logger;

        public FakeGLProvider(ILogger<FakeGLProvider> logger)
        {
            if (logger == null)
                throw new ArgumentNullException("A Logger must be provieded for the FakeGL Provider", nameof(logger));

            _logger = logger;
        }

        /// <summary>
        /// This is our Fake GL Chart of Accounts
        /// </summary>
        static IEnumerable<GLAccount> accounts = new [] {
            new GLAccount { AccountTypeCode = "1000", AccountTypeDesc = "1000 Assets", AccountCode = "1010", AccountDesc="1010 Cash Operating"},
            new GLAccount { AccountTypeCode = "1000", AccountTypeDesc = "1000 Assets", AccountCode = "1020", AccountDesc="1020 Debitors"},
            new GLAccount { AccountTypeCode = "1000", AccountTypeDesc = "1000 Assets", AccountCode = "1030", AccountDesc="1030 Cash Petty Cash"},
            new GLAccount { AccountTypeCode = "1200", AccountTypeDesc = "1200 Receivables", AccountCode = "1210", AccountDesc="1210 Trade Credit"},
            new GLAccount { AccountTypeCode = "1200", AccountTypeDesc = "1200 Receivables", AccountCode = "1230", AccountDesc="1230 Installment Receivables"},
            new GLAccount { AccountTypeCode = "1200", AccountTypeDesc = "1200 Receivables", AccountCode = "1290", AccountDesc="1290 Allowance for Uncollectable"},
            new GLAccount { AccountTypeCode = "1300", AccountTypeDesc = "1300 Inventories", AccountCode = "1310", AccountDesc="1310 Work in Progress"},
            new GLAccount { AccountTypeCode = "1300", AccountTypeDesc = "1300 Inventories", AccountCode = "1350", AccountDesc="1350 Finished Work"},
            new GLAccount { AccountTypeCode = "2100", AccountTypeDesc = "2100 Liabilities Payable", AccountCode = "2110", AccountDesc="2110 Accrued Accounts Payable"},
            new GLAccount { AccountTypeCode = "2100", AccountTypeDesc = "2100 Liabilities Payable", AccountCode = "2120", AccountDesc="2120 Bank Notes Payable"},
            new GLAccount { AccountTypeCode = "2200", AccountTypeDesc = "2200 Liabilities Compensation", AccountCode = "2210", AccountDesc="2210 Payroll"},
            new GLAccount { AccountTypeCode = "2200", AccountTypeDesc = "2200 Liabilities Compensation", AccountCode = "2220", AccountDesc="2220 Commissions"},
            new GLAccount { AccountTypeCode = "3000", AccountTypeDesc = "3000 Equity", AccountCode = "3010", AccountDesc="3010 Smith Equity"},
            new GLAccount { AccountTypeCode = "3000", AccountTypeDesc = "3000 Equity", AccountCode = "3020", AccountDesc="3010 Jones Equity"},
            new GLAccount { AccountTypeCode = "4000", AccountTypeDesc = "4000 Revenue", AccountCode = "4010", AccountDesc="4010 Revenue Tax Service"},
            new GLAccount { AccountTypeCode = "4000", AccountTypeDesc = "4000 Revenue", AccountCode = "4020", AccountDesc="4020 Revenue Audit Service"},
            new GLAccount { AccountTypeCode = "4000", AccountTypeDesc = "4000 Revenue", AccountCode = "4030", AccountDesc="4030 Revenue Consulting Service"},
            new GLAccount { AccountTypeCode = "5000", AccountTypeDesc = "5000 Operating Expenses", AccountCode = "5010", AccountDesc="5010 Mileage Expense"},
            new GLAccount { AccountTypeCode = "5000", AccountTypeDesc = "5000 Operating Expenses", AccountCode = "5020", AccountDesc="5020 Technology Expense"},
            new GLAccount { AccountTypeCode = "5000", AccountTypeDesc = "5000 Operating Expenses", AccountCode = "5030", AccountDesc="5030 Meals and Entertainment Expense"},
            new GLAccount { AccountTypeCode = "5000", AccountTypeDesc = "5000 Operating Expenses", AccountCode = "5040", AccountDesc="5040 Professional Expense"},
            };

        /// <summary>
        /// Returns the Accounts for the specified Account Type
        /// </summary>
        /// <param name="Org"></param>
        /// <param name="AcctType"></param>
        /// <returns></returns>
        public Task<IEnumerable<GLAccount>> AccountsQuery(int Org, string AcctType)
        {
            var types = accounts.Where(a => a.AccountTypeCode == AcctType);
            return Task.FromResult(types);
        }

        /// <summary>
        /// Returns the distinct list of Account Types
        /// </summary>
        /// <param name="Org"></param>
        /// <returns></returns>
        public Task<IEnumerable<GLType>> AccountTypesQuery(int Org)
        {
            var types = accounts.Select(a => new { a.AccountTypeCode, a.AccountTypeDesc }).Distinct()
                .Select(a => new GLType { AccountTypeCode = a.AccountTypeCode, AccountTypeDesc = a.AccountTypeDesc });
            return Task.FromResult(types);
        }

        /// <summary>
        /// Creates a Journal (just logs to the attached logger)
        /// </summary>
        /// <param name="Org"></param>
        /// <param name="lines"></param>
        /// <param name="journal"></param>
        /// <returns></returns>
        public Task CashJournalCmd(int Org, IEnumerable<JournalExtract> lines, string journal)
        {
            _logger.LogInformation("START Cash Journal for Org:{0} to Journal:{1}", Org, journal);
            foreach(var line in lines)
            {
                _logger.LogInformation(JsonConvert.SerializeObject(line));
            }
            _logger.LogInformation("FINISH Cash Journal for Org:{0} to Journal:{1}", Org, journal);
            return Task.CompletedTask;
        }

        /// <summary>
        /// Posts a Journal (just logs to the attached logger)
        /// </summary>
        /// <param name="Org"></param>
        /// <param name="lines"></param>
        /// <param name="journal"></param>
        /// <returns></returns>
        public Task PostJournalCmd(int Org, IEnumerable<JournalExtract> lines, string journal)
        {
            _logger.LogInformation("START (normal) Journal for Org:{0} to Journal:{1}", Org, journal);
            foreach (var line in lines)
            {
                _logger.LogInformation(JsonConvert.SerializeObject(line));
            }
            _logger.LogInformation("FINISH (normal) Journal for Org:{0} to Journal:{1}", Org, journal);
            return Task.CompletedTask;
        }

        /// <summary>
        /// Posts Stats Hours Journal (just logs to the attached logger)
        /// </summary>
        /// <param name="Org"></param>
        /// <param name="lines"></param>
        /// <param name="JournalSymbol"></param>
        /// <returns></returns>
        public Task PostStatHourJournalCmd(int Org, IEnumerable<IntacctStatHours> lines, string JournalSymbol)
        {
            _logger.LogInformation("START Stat Hours Journal for Org:{0} to Journal:{1}", Org, JournalSymbol);
            foreach (var line in lines)
            {
                _logger.LogInformation(JsonConvert.SerializeObject(line));
            }
            _logger.LogInformation("FINISH Stat Hours Journal for Org:{0} to Journal:{1}", Org, JournalSymbol);
            return Task.CompletedTask;
        }
    }
}

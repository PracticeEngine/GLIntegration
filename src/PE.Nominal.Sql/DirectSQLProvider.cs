using Hangfire.Server;
using Microsoft.EntityFrameworkCore;
using PE.Nominal.Intacct;
using PE.Nominal.Provider;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;

namespace PE.Nominal
{
    /// <summary>
    /// The built-In Legacy Provider (SQL-to-SQL integrations)
    /// </summary>
    public class DirectSqlProvider : IProviderType
    {
        private readonly DbContext context;

        /// <summary>
        /// Constructor expects a DbContext to the Correct Database is Injected
        /// </summary>
        /// <param name="context"></param>
        public DirectSqlProvider(DbContext context)
        {
            this.context = context;
        }

        public async Task<IEnumerable<GLType>> AccountTypesQuery(int Org)
        {
            var results = await context.Database.SqlQueryAsync<GLType>("pe_NL_Account_Types {0}", Org).ConfigureAwait(false);
            return results;
        }


        public async Task<IEnumerable<GLAccount>> AccountsQuery(int Org, string AcctType)
        {
            var results = await context.Database.SqlQueryAsync<GLAccount>("pe_NL_Accounts {0}, {1}", Org, AcctType).ConfigureAwait(false);
            return results;
        }


        public async Task CashJournalCmd(int Org, IEnumerable<JournalExtract> lines, string journal, PerformContext performContext)
        {
            // NOTE: journal parameter is ignored for this implementation


            // this is wasteful, but prevents changing the existing underlying SP's while implementing a new Interface that works for non-SQL-to-SQL integrations
            var batch = lines.Select(je => je.NomBatch).FirstOrDefault();
            var result = new SqlParameter("@Result", System.Data.SqlDbType.Int)
            {
                Direction = System.Data.ParameterDirection.Output
            };
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Cashbook_Post {0}, @Result", batch, result).ConfigureAwait(false);
        }

        public async Task PostJournalCmd(int Org, IEnumerable<JournalExtract> lines, string journal, PerformContext performContext)
        {
            // NOTE: journal parameter is ignored for this implementation


            // this is wasteful, but prevents changing the existing underlying SP's while implementing a new Interface that works for non-SQL-to-SQL integrations
            var batch = lines.Select(je => je.NomBatch).FirstOrDefault();
            var result = new SqlParameter("@Result", System.Data.SqlDbType.Int)
            {
                Direction = System.Data.ParameterDirection.Output
            };
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Journal_Post {0}, @Result", batch, result).ConfigureAwait(false);
        }


        /// <summary>
        ///  Not IMplemented in this Version
        /// </summary>
        /// <param name="Org"></param>
        /// <param name="lines"></param>
        /// <param name="JournalSymbol"></param>
        /// <returns></returns>
        public Task PostStatHourJournalCmd(int Org, IEnumerable<IntacctStatHours> lines, string JournalSymbol, PerformContext performContext)
        {
            throw new NotImplementedException();
        }

        public Task<IEnumerable<int>> PostMTDCmd(int Org, IEnumerable<MTDClient> clients, IEnumerable<MTDInvoice> invoices, PerformContext performContext)
        {
            throw new NotImplementedException();
        }
    }
}

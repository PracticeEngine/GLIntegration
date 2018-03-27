using Microsoft.EntityFrameworkCore;
using PE.Nominal.Intacct;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace PE.Nominal
{
    /// <summary>
    /// Contains all Special Extractions Created only for Intacct
    /// </summary>
    public class IntacctDAL
    {
        private readonly DbContext context;

        /// <summary>
        /// Actions Service Expects a DbContext to be injected pointing to the correct database
        /// </summary>
        /// <param name="context"></param>
        public IntacctDAL(DbContext context)
        {
            this.context = context;
        }

        /// <summary>
        /// Returns List of Intacct Stats Hours
        /// </summary>
        /// <param name="Org">The Organization to Extract</param>
        /// <param name="BatchID">Optional: The BatchID</param>
        /// <param name="Journal">Optional: A specific Journal</param>
        /// <param name="HangfireJobId">Optional: A Hangfire Job ID</param>
        /// <returns></returns>
        public async Task<IEnumerable<IntacctStatHours>> ExtractIntacctHoursJournalQuery(int Org, int BatchID = 0, string Journal = null, string HangfireJobId = null)
        {
            var results = await context.Database.SqlQueryAsync<IntacctStatHours>("pe_NL_Journal_Export {0}, {1}, {2}, {3}", Org, BatchID, Journal, HangfireJobId).ConfigureAwait(false);
            return results;
        }
        
        /// <summary>
        /// Returns List of Customer Data For Sync to Intacct
        /// </summary>
        /// <returns></returns>
        public async Task<IEnumerable<IntacctCustomer>> IntacctCustomerQuery()
        {
            var results = await context.Database.SqlQueryAsync<IntacctCustomer>("pe_NL_Intacct_Customer").ConfigureAwait(false);
            return results;
        }

        /// <summary>
        /// Returns List of Projects (Jobs) for Sync to Intacct
        /// </summary>
        /// <returns></returns>
        public async Task<IEnumerable<IntacctProject>> IntacctProjectsQuery()
        {
            var results = await context.Database.SqlQueryAsync<IntacctProject>("pe_NL_Intacct_Project").ConfigureAwait(false);
            return results;
        }

        /// <summary>
        /// Returns List of Employess (Staff) for Sync to Intacct
        /// </summary>
        /// <returns></returns>
        public async Task<IEnumerable<IntacctEmployee>> IntacctEmployeesQuery()
        {
            var results = await context.Database.SqlQueryAsync<IntacctEmployee>("pe_NL_Intacct_Employee").ConfigureAwait(false);
            return results;
        }
    }
}

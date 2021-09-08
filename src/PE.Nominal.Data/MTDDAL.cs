using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace PE.Nominal
{
    /// <summary>
    /// Contains all Actions related to the Making Tax Digital system
    /// </summary>
    public class MTDDAL
    {
        private readonly DbContext context;

        /// <summary>
        /// Actions Service Expects a DbContext to be injected pointing to the correct database
        /// </summary>
        /// <param name="context"></param>
        public MTDDAL(DbContext context)
        {
            this.context = context;
        }


        public async Task ExtractMTDCmd()
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_MTD_Extract").ConfigureAwait(false);
        }
        
        public async Task<IEnumerable<MTDClient>> MTDClientsQuery(int Org)
        {
            var results = await context.Database.SqlQueryAsync<MTDClient>("pe_NL_MTD_Export_Clients {0}", Org).ConfigureAwait(false);
            return results;
        }

        public async Task<IEnumerable<MTDInvoice>> MTDInvoicesQuery(int Org)
        {
            var results = await context.Database.SqlQueryAsync<MTDInvoice>("pe_NL_MTD_Export_Invoices {0}", Org).ConfigureAwait(false);
            return results;
        }

        public async Task<IEnumerable<MTDLineItem>> MTDInvoiceLinesQuery(int Org)
        {
            var results = await context.Database.SqlQueryAsync<MTDLineItem>("pe_NL_MTD_Export_Invoice_Lines {0}", Org).ConfigureAwait(false);
            return results;
        }

        public async Task MTDFlagAsProcessedCmd(int Id)
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_MTD_Mark_As_Processed {0}", Id).ConfigureAwait(false);
        }
    }
}

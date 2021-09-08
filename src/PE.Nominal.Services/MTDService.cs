using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Data.SqlClient;
using PE.Nominal.Intacct;
using Hangfire.Server;
using Hangfire.Console;

namespace PE.Nominal
{
    /// <summary>
    /// Contains all primary Actions which can be invoked from the UI (except for those provided by IProviderTypes
    /// </summary>
    public class MTDService
    {
        private readonly MTDDAL mtdDAL;

        /// <summary>
        /// Constructs a New Actions Service
        /// </summary>
        /// <param name="intacctDAL"></param>
        public MTDService(MTDDAL mtdDAL)
        {
            this.mtdDAL = mtdDAL;
        }

        public async Task ExtractMTDCmd()
        {
            await mtdDAL.ExtractMTDCmd().ConfigureAwait(false);
        }

        public async Task<IEnumerable<MTDClient>> MTDClientsQuery(int Org)
        {
            return await mtdDAL.MTDClientsQuery(Org).ConfigureAwait(false);
        }

        public async Task<IEnumerable<MTDInvoice>> MTDInvoicesQuery(int Org)
        {
            var invoices = await mtdDAL.MTDInvoicesQuery(Org).ConfigureAwait(false);

            var lines = await mtdDAL.MTDInvoiceLinesQuery(Org).ConfigureAwait(false);

            foreach(var inv in invoices)
            {
                inv.Lines = lines.Where(l => l.DebtTranIndex == inv.DebtTranIndex);
            }

            return invoices;
        }

        public async Task MTDFlagAsProcessedCmd(IEnumerable<int> Ids)
        {
            foreach (int Id in Ids)
            {
                await mtdDAL.MTDFlagAsProcessedCmd(Id).ConfigureAwait(false);
            }
        }

    }
}

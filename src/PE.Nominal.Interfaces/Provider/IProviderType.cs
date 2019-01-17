using Hangfire.Server;
using PE.Nominal.Intacct;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace PE.Nominal.Provider
{
    public interface IProviderType
    {
        /// <summary>
        /// Returns List of GL Account Types Available for a Specified Organization
        /// </summary>
        /// <param name="Org">The PracId from TblControl</param>
        /// <returns></returns>
        Task<IEnumerable<GLType>> AccountTypesQuery(int Org);

        /// <summary>
        /// Returns the List of GL Types for a specified Organization and AccountType
        /// </summary>
        /// <param name="Org"></param>
        /// <param name="AcctType"></param>
        /// <returns></returns>
        Task<IEnumerable<GLAccount>> AccountsQuery(int Org, string AcctType);

        /// <summary>
        /// Posts Journal Bits into the G/L
        /// Assumes the Batch posted if no exception is thrown
        /// </summary>
        /// <param name="Org"></param>
        /// <param name="lines"></param>
        /// <param name="journal"></param>
        /// <returns></returns>
        Task PostJournalCmd(int Org, IEnumerable<JournalExtract> lines, string journal, PerformContext performContext);

        /// <summary>
        /// Performs Bank Reconciliation (Cash Book Posting)
        /// </summary>
        /// <param name="Org"></param>
        /// <param name="lines"></param>
        /// <param name="journal"></param>
        /// <returns></returns>
        Task CashJournalCmd(int Org, IEnumerable<JournalExtract> lines, string journal, PerformContext performContext);

        /// <summary>
        /// Implemented for Intacct to post Statistics Journal (not required for other implemetnations)
        /// </summary>
        /// <param name="Org"></param>
        /// <param name="lines"></param>
        /// <param name="JournalSymbol"></param>
        /// <returns></returns>
        Task PostStatHourJournalCmd(int Org, IEnumerable<IntacctStatHours> lines, string JournalSymbol, PerformContext performContext);

        /// <summary>
        /// Implemented for MTD to post Sales Data
        /// </summary>
        /// <param name="Org"></param>
        /// <param name="clients"></param>
        /// <param name="invoices"></param>
        /// <param name="lines"></param>
        /// <returns></returns>
        Task<IEnumerable<int>> PostMTDCmd(int Org, IEnumerable<MTDClient> clients, IEnumerable<MTDInvoice> invoices, PerformContext performContext);
    }
}

﻿using Microsoft.EntityFrameworkCore;
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
    public class ActionsService
    {
        private readonly IntacctDAL intacctDAL;
        private readonly NominalDAL nominalDAL;

        /// <summary>
        /// Constructs a New Actions Service
        /// </summary>
        /// <param name="intacctDAL"></param>
        /// <param name="nominalDAL"></param>
        public ActionsService(IntacctDAL intacctDAL, NominalDAL nominalDAL)
        {
            this.intacctDAL = intacctDAL;
            this.nominalDAL = nominalDAL;
        }


        public async Task CreateMapCmd()
        {
            await nominalDAL.CreateMapCmd().ConfigureAwait(false);
        }

        public async Task ClearMapCmd()
        {
            await nominalDAL.ClearMapCmd().ConfigureAwait(false);
            await nominalDAL.ClearDisbMapCmd().ConfigureAwait(false);
        }

        public async Task<GLSetup> SetupQuery()
        {
            return await nominalDAL.SetupQuery().ConfigureAwait(false);
        }

        public async Task SaveSetupCmd(GLSetup setup)
        {
            await nominalDAL.SaveSetupCmd(setup).ConfigureAwait(false);
        }

        public async Task<IEnumerable<DisbCode>> DisbCodesQuery()
        {
            return await nominalDAL.DisbCodesQuery().ConfigureAwait(false);
        }

        public async Task<GLNumEntries> NumEntriesQuery()
        {
            return await nominalDAL.NumEntriesQuery().ConfigureAwait(false);
        }

        public async Task ExtractOpeningCmd()
        {
            await nominalDAL.ExtractOpeningCmd().ConfigureAwait(false);
        }

        public async Task ExtractCurrentCmd(PerformContext hangfireContext = null)
        {
            hangfireContext.WriteLine("Starting pe_NL_WIP Stored Procedure");
            await nominalDAL.ExtractWIPCmd().ConfigureAwait(false);

            hangfireContext.WriteLine("Starting pe_NL_DRS Stored Procedure");
            await nominalDAL.ExtractDebtorsCmd().ConfigureAwait(false);

            hangfireContext.WriteLine("Starting pe_NL_LOD Stored Procedure");
            await nominalDAL.ExtractLodgementsCmd().ConfigureAwait(false);

            hangfireContext.WriteLine("Starting pe_NL_EXP Stored Procedure");
            await nominalDAL.ExtractExpensesCmd().ConfigureAwait(false);
        }

        public async Task<IEnumerable<PostPeriods>> PostPeriodsQuery()
        {
            return await nominalDAL.PostPeriodsQuery().ConfigureAwait(false);
        }

        public async Task PostCreateCmd(int PeriodIndex)
        {
            await nominalDAL.PostCreateCmd(PeriodIndex).ConfigureAwait(false);
        }

        public async Task CostingUpdateCmd()
        {
            await nominalDAL.CostingUpdateCmd().ConfigureAwait(false);
        }

        public async Task<IEnumerable<MissingMap>> MissingMappingsQuery()
        {
            return await nominalDAL.MissingMappingsQuery().ConfigureAwait(false);
        }

        public async Task<GLMapping> MappingDetailQuery(int MapIndex)
        {
            return await nominalDAL.MappingDetailQuery(MapIndex).ConfigureAwait(false);
        }

        public async Task SaveAccountMappingCmd(int MapIndex, string AccountCode, string AccountTypeCode)
        {
            await nominalDAL.SaveAccountMappingCmd(MapIndex, AccountCode, AccountTypeCode).ConfigureAwait(false);
        }

        public async Task<IEnumerable<MissingMap>> NLMappingsQuery()
        {
            return await nominalDAL.NLMappingsQuery().ConfigureAwait(false);
        }

        public async Task<IEnumerable<ImportMap>> NLImportMappingsQuery()
        {
            return await nominalDAL.NLImportMappingsQuery().ConfigureAwait(false);
        }

        public async Task SaveImportMappingCmd(int MapIndex, string AccountCode)
        {
            await nominalDAL.SaveImportMappingCmd(MapIndex, AccountCode).ConfigureAwait(false);
        }

        public async Task<IEnumerable<DetailGroup>> DetailGroupsQuery(int PeriodIndex)
        {
            return await nominalDAL.DetailGroupsQuery(PeriodIndex).ConfigureAwait(false);
        }

        public async Task<IEnumerable<DetailLine>> DetailListQuery(int NLOrg, string NLSource, string NLSection, string NLAccount, string NLOffice, string NLService, int? NLPartner, string NLDept, int PeriodIndex)
        {
            return await nominalDAL.DetailListQuery(NLOrg, NLSource, NLSection, NLAccount, NLOffice, NLService, NLPartner, NLDept, PeriodIndex).ConfigureAwait(false);
        }

        public async Task<IEnumerable<JournalGroup>> JournalGroupsQuery() 
        {
            return await nominalDAL.JournalGroupsQuery().ConfigureAwait(false);
        }

        public async Task<IEnumerable<JournalMap>> JournalListQuery(int NomOrg, string NomSource, string NomSection, string NomAccount, string NomOffice, string NomService, int? NomPartner, string NomDept)
        {
            return await nominalDAL.JournalListQuery(NomOrg, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept).ConfigureAwait(false);
        }

        public async Task<IEnumerable<JournalExtract>> TransferJournalQuery(int Org, int BatchID = 0, string Journal = null, string HangfireJobId = null)
        {
            return await nominalDAL.TransferJournalQuery(Org, BatchID, Journal, HangfireJobId).ConfigureAwait(false);
        }

        public async Task<IEnumerable<ExpenseExtract>> TransferExpenseQuery(int Org, int BatchID = 0, string HangfireJobId = null)
        {
            return await nominalDAL.TransferExpenseQuery(Org, BatchID, HangfireJobId).ConfigureAwait(false);
        }

        public async Task<List<dynamic>> ExportJournalQuery(int BatchID = 0)
        {
            return await nominalDAL.ExtractJournalQuery(BatchID).ConfigureAwait(false);
        }

        public async Task<IEnumerable<IntacctStatHours>> ExtractIntacctHoursJournalQuery(int Org, int BatchID = 0, string Journal = null, string HangfireJobId = null)
        {
            return await intacctDAL.ExtractIntacctHoursJournalQuery(Org, BatchID, Journal, HangfireJobId).ConfigureAwait(false);
        }

        public async Task FlagTransferredCmd(int Org, string Journal = null, string HangfireJobId = null)
        {
            await nominalDAL.FlagTransferredCmd(Org, Journal, HangfireJobId).ConfigureAwait(false);
        }

        public async Task UnFlagTransferredCmd(int Org, string Journal = null, string HangfireJobId = null)
        {
            await nominalDAL.UnFlagTransferredCmd(Org, Journal, HangfireJobId).ConfigureAwait(false);
        }

        public async Task FlagExpensesTransferredCmd(int Org, string HangfireJobId = null)
        {
            await nominalDAL.FlagExpensesTransferredCmd(Org, HangfireJobId).ConfigureAwait(false);
        }

        public async Task UnFlagExpensesTransferredCmd(int Org, string HangfireJobId = null)
        {
            await nominalDAL.UnFlagExpensesTransferredCmd(Org, HangfireJobId).ConfigureAwait(false);
        }
        public async Task<IEnumerable<JournalRepostBatch>> JournalRepostListQuery(int NomPeriodIndex)
        {
            return await nominalDAL.JournalRepostListQuery(NomPeriodIndex).ConfigureAwait(false);
        }

        public async Task<IEnumerable<NomOrganisation>> OrgListQuery()
        {
            return await nominalDAL.OrgListQuery().ConfigureAwait(false);
        }

        public async Task UpdateOrgCmd(int PracID, string NLServer, string NLDatabase, bool NLTransfer)
        {
            await nominalDAL.UpdateOrgCmd(PracID, NLServer, NLDatabase, NLTransfer).ConfigureAwait(false);
        }

        public async Task<IEnumerable<JournalExtract>> ExtractBankRecQuery(int Org, int BatchID = 0, string Journal = null, string HangfireJobId = null)
        {
            return await nominalDAL.ExtractBankRecQuery(Org, BatchID, Journal, HangfireJobId).ConfigureAwait(false);
        }

        public async Task FlagBankRecTransferredCmd(int PracID, string journal, string HangfireJobId)
        {
            await nominalDAL.FlagBankRecTransferredCmd(PracID, journal, HangfireJobId).ConfigureAwait(false);
        }

        public async Task UnFlagBankRecTransferredCmd(int PracID, string Journal, string HangfireJobId)
        {
            await nominalDAL.UnFlagBankRecTransferredCmd(PracID, Journal, HangfireJobId).ConfigureAwait(false);
        }

        public async Task<IEnumerable<PostPeriods>> JournalPeriodsQuery()
        {
            return await nominalDAL.JournalPeriodsQuery().ConfigureAwait(false);
        }

        public async Task<IEnumerable<CashbookRepostBatch>> BankRecRepostListQuery(int NomPeriodIndex)
        {
            return await nominalDAL.BankRecRepostListQuery(NomPeriodIndex).ConfigureAwait(false);
        }

        public async Task<IEnumerable<IntacctCustomer>> IntacctCustomerQuery()
        {
            return await intacctDAL.IntacctCustomerQuery().ConfigureAwait(false);
        }

        public async Task<IEnumerable<IntacctProject>> IntacctProjectsQuery()
        {
            return await intacctDAL.IntacctProjectsQuery().ConfigureAwait(false);
        }

        public async Task<IEnumerable<IntacctEmployee>> IntacctEmployeesQuery()
        {
            return await intacctDAL.IntacctEmployeesQuery().ConfigureAwait(false);
        }

        public async Task<IEnumerable<ExpenseStaff>> ExpenseStaffQuery()
        {
            return await nominalDAL.ExpenseStaffQuery().ConfigureAwait(false);
        }

        public async Task<IEnumerable<ExpenseLines>> ExpenseLinesQuery(int ExpOrg, int ExpStaff)
        {
            return await nominalDAL.ExpenseLinesQuery(ExpOrg, ExpStaff).ConfigureAwait(false);
        }

        public async Task<IEnumerable<MissingExpenseAccountMap>> ExpenseMissingAccountsQuery()
        {
            return await nominalDAL.ExpenseMissingAccountsQuery().ConfigureAwait(false);
        }
        public async Task<IEnumerable<MissingExpenseStaff>> ExpenseMissingStaffQuery()
        {
            return await nominalDAL.ExpenseMissingStaffQuery().ConfigureAwait(false);
        }

        public async Task UpdateExpenseAccountMappingCmd(MissingExpenseAccountMap item)
        {
            await nominalDAL.UpdateExpenseAccountMappingCmd(item.ExpOrg, item.ChargeCode, item.ChargeExpAccount, item.NonChargeExpAccount, item.ChargeSuffix1, item.ChargeSuffix2, item.ChargeSuffix3, item.NonChargeSuffix1, item.NonChargeSuffix2, item.NonChargeSuffix3).ConfigureAwait(false);
        }
        public async Task<IEnumerable<MissingExpenseAccountMap>> ExpenseAccountsQuery()
        {
            return await nominalDAL.ExpenseAccountsQuery().ConfigureAwait(false);
        }
    }
}

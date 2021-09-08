using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Internal;
using Microsoft.EntityFrameworkCore.Storage;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Common;
using System.Data.SqlClient;
using System.Dynamic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace PE.Nominal
{
    /// <summary>
    /// Contains all Actions related to the Nominal Ledger, Including Mappings and Creating Journals
    /// </summary>
    public class NominalDAL
    {
        private readonly DbContext context;

        /// <summary>
        /// Actions Service Expects a DbContext to be injected pointing to the correct database
        /// </summary>
        /// <param name="context"></param>
        public NominalDAL(DbContext context)
        {
            this.context = context;
        }


        public async Task CreateMapCmd()
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Map_Create").ConfigureAwait(false);
        }

        public async Task ClearMapCmd()
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Map_Clear").ConfigureAwait(false);
        }

        public async Task ClearDisbMapCmd()
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_DisbMap_Clear").ConfigureAwait(false);
        }

        public async Task<GLSetup> SetupQuery()
        {
            var results = await context.Database.SqlQueryAsync<GLSetup>("pe_NL_Control_Details").ConfigureAwait(false);
            return results.FirstOrDefault();
        }

        public async Task SaveSetupCmd(GLSetup setup)
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Control_Update {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}, {11}, {12}, {13}, {14}, {15}, {16}, {17}, {18}",
                // Index 0
                setup.WIPServ, setup.WIPPart, setup.WIPOffice, setup.WIPDept, setup.WIPLevel, setup.DRSServ, setup.DRSPart, setup.DRSOffice, setup.DRSDept, setup.DRSLevel, // Ends with Index 9
                // Index 10
                setup.IntSystem, setup.FeeSource, setup.FeeProfit, setup.FeePart, setup.DisbLevel, setup.DisbStd, setup.InterCo, setup.Cashbook, setup.Expenses // Ends with Index 18
                ).ConfigureAwait(false);
        }

        public async Task<IEnumerable<DisbCode>> DisbCodesQuery()
        {
            var results = await context.Database.SqlQueryAsync<DisbCode>("pe_NL_Control_Disbs").ConfigureAwait(false);
            return results;
        }

        public async Task<GLNumEntries> NumEntriesQuery()
        {
            var results = await context.Database.SqlQueryAsync<GLNumEntries>("pe_NL_Num_Entries").ConfigureAwait(false);
            return results.FirstOrDefault();
        }

        public async Task ExtractOpeningCmd()
        {
            var result = new SqlParameter("@Result", System.Data.SqlDbType.Int)
            {
                Direction = System.Data.ParameterDirection.Output
            };
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Opening @Result", result).ConfigureAwait(false);
        }

        public async Task ExtractWIPCmd()
        {
            var result = new SqlParameter("@Result", System.Data.SqlDbType.Int)
            {
                Direction = System.Data.ParameterDirection.Output
            };
            await context.Database.ExecuteSqlCommandAsync("pe_NL_WIP @Result", result).ConfigureAwait(false);

        }

        public async Task ExtractDebtorsCmd()
        {
            var result = new SqlParameter("@Result", System.Data.SqlDbType.Int)
            {
                Direction = System.Data.ParameterDirection.Output
            };

            await context.Database.ExecuteSqlCommandAsync("pe_NL_DRS @Result", result).ConfigureAwait(false);

        }

        public async Task ExtractLodgementsCmd()
        {
            var result = new SqlParameter("@Result", System.Data.SqlDbType.Int)
            {
                Direction = System.Data.ParameterDirection.Output
            };

            await context.Database.ExecuteSqlCommandAsync("pe_NL_LOD @Result", result).ConfigureAwait(false);

        }

        public async Task ExtractExpensesCmd()
        {
            var result = new SqlParameter("@Result", System.Data.SqlDbType.Int)
            {
                Direction = System.Data.ParameterDirection.Output
            };

            await context.Database.ExecuteSqlCommandAsync("pe_NL_EXP @Result", result).ConfigureAwait(false);

        }

        public async Task<IEnumerable<PostPeriods>> PostPeriodsQuery()
        {
            var results = await context.Database.SqlQueryAsync<PostPeriods>("pe_NL_Post_Periods").ConfigureAwait(false);
            return results;
        }

        public async Task PostCreateCmd(int PeriodIndex)
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Post_Create {0}", PeriodIndex).ConfigureAwait(false);
        }

        public async Task CostingUpdateCmd()
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Costing_Update").ConfigureAwait(false);
        }

        public async Task<IEnumerable<MissingMap>> MissingMappingsQuery()
        {
            var results = await context.Database.SqlQueryAsync<MissingMap>("pe_NL_Missing_Map").ConfigureAwait(false);
            return results;
        }

        public async Task<GLMapping> MappingDetailQuery(int MapIndex)
        {
            var results = await context.Database.SqlQueryAsync<GLMapping>("pe_NL_Map_Line {0}", MapIndex).ConfigureAwait(false);
            return results.FirstOrDefault();
        }

        public async Task SaveAccountMappingCmd(int MapIndex, string AccountCode, string AccountTypeCode)
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Map_Line_Update {0}, {1}, {2}", MapIndex, AccountCode, AccountTypeCode).ConfigureAwait(false);
        }

        public async Task<IEnumerable<MissingMap>> NLMappingsQuery()
        {
            var results = await context.Database.SqlQueryAsync<MissingMap>("pe_NL_Mapping_List").ConfigureAwait(false);
            return results;
        }
        public async Task<IEnumerable<ImportMap>> NLImportMappingsQuery()
        {
            var results = await context.Database.SqlQueryAsync<ImportMap>("pe_NL_DisbMap_Details").ConfigureAwait(false);
            return results;
        }

        public async Task SaveImportMappingCmd(int MapIndex, string AccountCode)
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_DisbMap_Line_Update {0}, {1}", MapIndex, AccountCode).ConfigureAwait(false);
        }

        public async Task<IEnumerable<DetailGroup>> DetailGroupsQuery(int PeriodIndex)
        {
            var results = await context.Database.SqlQueryAsync<DetailGroup>("pe_NL_Detail_Groups {0}", PeriodIndex).ConfigureAwait(false);
            return results;
        }

        public async Task<IEnumerable<DetailLine>> DetailListQuery(int NLOrg, string NLSource, string NLSection, string NLAccount, string NLOffice, string NLService, int? NLPartner, string NLDept, int PeriodIndex)
        {
            var results = await context.Database.SqlQueryAsync<DetailLine>("pe_NL_Detail_Lines {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}", NLOrg, NLSource, NLSection, NLAccount, NLOffice, NLService, NLPartner, NLDept, PeriodIndex).ConfigureAwait(false);
            return results;
        }

        public async Task<IEnumerable<JournalGroup>> JournalGroupsQuery() 
        {
            var results = await context.Database.SqlQueryAsync<JournalGroup>("pe_NL_Journal_Groups").ConfigureAwait(false);
            return results;
        }

        public async Task<IEnumerable<JournalMap>> JournalListQuery(int NomOrg, string NomSource, string NomSection, string NomAccount, string NomOffice, string NomService, int? NomPartner, string NomDept)
        {
            var results = await context.Database.SqlQueryAsync<JournalMap>("pe_NL_Journal_Lines {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}", NomOrg, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept).ConfigureAwait(false);
            return results;
        }

        public async Task<List<dynamic>> ExtractJournalQuery(int BatchID = 0)
        {
            SqlConnection dbConnection = new SqlConnection(((SqlConnection)context.Database.GetDbConnection()).ConnectionString);
            using (var cmd = dbConnection.CreateCommand())
            {
                List<dynamic> lines = new List<dynamic>();
                try
                {
                    cmd.CommandText = "pe_NL_Journal_Export @BatchID";
                    cmd.Parameters.AddWithValue("@BatchID", BatchID);
                    await cmd.Connection.OpenAsync();
                    using (var reader = await cmd.ExecuteReaderAsync(CommandBehavior.CloseConnection))
                    {
                        while (await reader.ReadAsync())
                        {
                            var record = new ExpandoObject() as IDictionary<string, Object>;
                            for (var f = 0; f < reader.FieldCount; f++)
                            {
                                string name = reader.GetName(f);
                                if (name == "")
                                {
                                    name = "Field" + f.ToString();
                                }
                                int suffix = 1;
                                while (record.ContainsKey(name))
                                {
                                    name = name + suffix.ToString();
                                    suffix++;
                                }
                                record.Add(name, reader.GetValue(f));
                            }

                            lines.Add(record);
                        }
                    }
                    if (dbConnection.State == ConnectionState.Open)
                    {
                        dbConnection.Close();
                    }
                }
                catch(System.Exception exc)
                {
                    string s = exc.Message;
                }
                return lines;
            }
        }

        public async Task<IEnumerable<JournalExtract>> TransferJournalQuery(int Org, int BatchID = 0, string Journal = null, string HangfireJobId = null)
        {
            var results = await context.Database.SqlQueryAsync<JournalExtract>("pe_NL_Journal_Transfer {0}, {1}, {2}, {3}", Org, BatchID, Journal, HangfireJobId).ConfigureAwait(false);
            return results;
        }

        public async Task FlagTransferredCmd(int Org, string Journal = null, string HangfireJobId = null)
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Journal_Transfer_Worked {0}, {1}, {2}", Org, Journal, HangfireJobId).ConfigureAwait(false);
        }

        public async Task UnFlagTransferredCmd(int Org, string Journal = null, string HangfireJobId = null)
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Journal_Transfer_Failed {0}, {1}, {2}", Org, Journal, HangfireJobId).ConfigureAwait(false);
        }

        public async Task<IEnumerable<ExpenseExtract>> TransferExpenseQuery(int Org, int BatchID = 0, string HangfireJobId = null)
        {
            var results = await context.Database.SqlQueryAsync<ExpenseExtract>("pe_NL_Expenses_Transfer {0}, {1}, {2}", Org, BatchID, HangfireJobId).ConfigureAwait(false);
            return results;
        }

        public async Task FlagExpensesTransferredCmd(int Org, string HangfireJobId = null)
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Expenses_Transfer_Worked {0}, {1}", Org, HangfireJobId).ConfigureAwait(false);
        }

        public async Task UnFlagExpensesTransferredCmd(int Org, string HangfireJobId = null)
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Expenses_Transfer_Failed {0}, {1}", Org, HangfireJobId).ConfigureAwait(false);
        }

        public async Task<IEnumerable<JournalRepostBatch>> JournalRepostListQuery(int NomPeriodIndex)
        {
            var results = await context.Database.SqlQueryAsync<JournalRepostBatch>("pe_NL_Journal_Repost_List {0}", NomPeriodIndex).ConfigureAwait(false);
            return results;
        }

        public async Task<IEnumerable<NomOrganisation>> OrgListQuery()
        {
            var results = await context.Database.SqlQueryAsync<NomOrganisation>("pe_NL_Org_List").ConfigureAwait(false);
            return results;
        }

        public async Task UpdateOrgCmd(int PracID, string NLServer, string NLDatabase, bool NLTransfer)
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Org_Update {0}, {1}, {2}, {3}", PracID, NLServer, NLDatabase, NLTransfer).ConfigureAwait(false);
        }

        public async Task<IEnumerable<JournalExtract>> ExtractBankRecQuery(int Org, int BatchID = 0, string Journal = null, string HangFireJobId = null)
        {
            var results = await context.Database.SqlQueryAsync<JournalExtract>("pe_NL_Cashbook_Extract {0}, {1}, {2}, {3}", Org, BatchID, Journal, HangFireJobId).ConfigureAwait(false);
            return results;
        }

        public async Task FlagBankRecTransferredCmd(int PracID, string journal, string HangFireJobId)
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Cashbook_Worked {0}, {1}, {2}", PracID, journal, HangFireJobId).ConfigureAwait(false);
        }

        public async Task UnFlagBankRecTransferredCmd(int PracID, string journal, string HangFireJobId)
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Cashbook_Failed {0}, {1}, {2}", PracID, journal, HangFireJobId).ConfigureAwait(false);
        }

        public async Task<IEnumerable<PostPeriods>> JournalPeriodsQuery()
        {
            var results = await context.Database.SqlQueryAsync<PostPeriods>("pe_NL_Journal_Periods").ConfigureAwait(false);
            return results;
        }

        public async Task<IEnumerable<CashbookRepostBatch>> BankRecRepostListQuery(int NomPeriodIndex)
        {
            var results = await context.Database.SqlQueryAsync<CashbookRepostBatch>("pe_NL_Cashbook_List {0}", NomPeriodIndex).ConfigureAwait(false);
            return results;
        }

        public async Task<IEnumerable<ExpenseStaff>> ExpenseStaffQuery()
        {
            var results = await context.Database.SqlQueryAsync<ExpenseStaff>("pe_NL_Expense_Staff").ConfigureAwait(false);
            return results;
        }

        public async Task<IEnumerable<ExpenseLines>> ExpenseLinesQuery(int ExpOrg, int ExpStaff)
        {
            var results = await context.Database.SqlQueryAsync<ExpenseLines>("pe_NL_Expense_Lines {0}, {1}", ExpOrg, ExpStaff).ConfigureAwait(false);
            return results;
        }

        public async Task<IEnumerable<MissingExpenseAccountMap>> ExpenseMissingAccountsQuery()
        {
            var results = await context.Database.SqlQueryAsync<MissingExpenseAccountMap>("pe_NL_Missing_Expense_Accounts").ConfigureAwait(false);
            return results;
        }
        public async Task<IEnumerable<MissingExpenseStaff>> ExpenseMissingStaffQuery()
        {
            var results = await context.Database.SqlQueryAsync<MissingExpenseStaff>("pe_NL_Missing_Expense_Staff").ConfigureAwait(false);
            return results;
        }
        public async Task UpdateExpenseAccountMappingCmd(int ExpOrg, string ChargeCode, string ChargeExpAccount, string NonChargeExpAccount, int ChargeSuffix1, int ChargeSuffix2, int ChargeSuffix3, int NonChargeSuffix1, int NonChargeSuffix2, int NonChargeSuffix3)
        {
            await context.Database.ExecuteSqlCommandAsync("pe_NL_Expense_Account_Update {0}, {1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}", ExpOrg, ChargeCode, ChargeExpAccount, NonChargeExpAccount, ChargeSuffix1, ChargeSuffix2, ChargeSuffix3, NonChargeSuffix1, NonChargeSuffix2, NonChargeSuffix3).ConfigureAwait(false);
        }

        public async Task<IEnumerable<MissingExpenseAccountMap>> ExpenseAccountsQuery()
        {
            var results = await context.Database.SqlQueryAsync<MissingExpenseAccountMap>("pe_NL_Expense_Accounts").ConfigureAwait(false);
            return results;
        }
    }
}

using Hangfire;
using Hangfire.Console;
using Hangfire.Server;
using Intacct.SDK.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using PE.Nominal.Options;
using PE.Nominal.Provider;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal.Web.Controllers
{
    /// <summary>
    /// Service to Handle Actions from the UI
    /// </summary>
    [Produces("application/json")]
    [Route("api/Actions")]
    public class ActionsController : Controller
    {
        private readonly ILogger _logger;
        private readonly ViewOptions _options;
        private readonly ActionsService _actionService;
        private readonly IProviderType _glProvider;
        private readonly JournalOptions _journalOptions;

        public ActionsController(ILogger<ActionsController> logger, ActionsService actionService, IProviderType glProvider, IOptions<ViewOptions> options, IOptions<JournalOptions> journalOptions)
        {
            _logger = logger;
            _actionService = actionService;
            _glProvider = glProvider;
            _options = options.Value;
            _journalOptions = journalOptions.Value;
        }

        #region Methods for NominalControl (Integration Setup)

        [HttpGet]
        [Route("NominalControl")]
        public async Task<IActionResult> GetNominalControl()
        {
            try
            {
                var data = await _actionService.SetupQuery();
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpPost]
        [Route("NominalControl")]
        public async Task<IActionResult> GetNominalControl([FromBody] GLSetup data)
        {
            try
            {
                await _actionService.SaveSetupCmd(data);
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }


        [HttpGet]
        [Route("ClearMap")]
        public async Task<IActionResult> ClearMap()
        {
            try
            {
                await _actionService.ClearMapCmd();
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpGet]
        [Route("BuildMap")]
        public async Task<IActionResult> BuildMap()
        {
            try
            {
                await _actionService.CreateMapCmd();
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }


        [HttpGet]
        [Route("DisbCodes")]
        public async Task<IActionResult> DisbCodes()
        {
            try
            {
                var data = await _actionService.DisbCodesQuery();
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        #endregion Methods for NominalControl (Integration Setup)

        #region Methods for IntegrationExtract (Integration Extract)

        [HttpPost]
        [Route("IntegrationExtract")]
        public IActionResult IntegrationExtract()
        {
            try
            {
                BackgroundJob.Enqueue(() => RunIntegrationExtract(null));
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        public async Task RunIntegrationExtract(PerformContext context)
        {
            await _actionService.ExtractCurrentCmd(context);
        }

        #endregion Methods for IntegrationExtract (Integration Extract)

        #region Methods for PostCreate (Create Journal)

        [HttpGet]
        [Route("PostPeriods")]
        public async Task<IActionResult> PostPeriods()
        {
            try
            {
                var data = await _actionService.PostPeriodsQuery();
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpPost]
        [Route("PostPeriods")]
        public async Task<IActionResult> PostPeriods([FromBody] int PeriodIndex)
        {
            try
            {
                await _actionService.PostCreateCmd(PeriodIndex);
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        #endregion Methods for PostCreate (Create Journal)

        #region Methods for MissingMap (Missing Mappings)

        [HttpGet]
        [Route("MissingMap")]
        public async Task<IActionResult> MissingMap()
        {
            try
            {
                var data = await _actionService.MissingMappingsQuery();
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpGet]
        [Route("AccountTypes/{Org}")]
        public async Task<IActionResult> MissingMap(int Org)
        {
            try
            {
                var data = await _glProvider.AccountTypesQuery(Org);
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }


        [HttpGet]
        [Route("Accounts/{Org}/{AcctType}")]
        public async Task<IActionResult> AccountsList(int Org, string AcctType)
        {
            try
            {
                var data = await _glProvider.AccountsQuery(Org, AcctType);
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        #endregion Methods for MissingMap (Missing Mappings)

        [HttpGet]
        [Route("NLMap")]
        public async Task<IActionResult> NLMap()
        {
            try
            {
                var data = await _actionService.NLMappingsQuery();
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpPost]
        [Route("UpdateMapping")]
        public async Task<IActionResult> UpdateMapping([FromBody]MapUpdate mapping)
        {
            try
            {
                await _actionService.SaveAccountMappingCmd(mapping.MapIndex, mapping.AccountCode, mapping.AccountTypeCode);
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        #region Methods for Journal (Journal Posting)

        [HttpGet]
        [Route("JournalGroups")]
        public async Task<IActionResult> JournalGroups()
        {
            try
            {
                var data = await _actionService.JournalGroupsQuery();
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }


        [HttpPost]
        [Route("JournalList")]
        public async Task<IActionResult> LoadGroup([FromBody]JournalGroup group)
        {
            try
            {
                var data = await _actionService.JournalListQuery(group.NomOrg, group.NomSource, group.NomSection, group.NomAccount, group.NomOffice, group.NomService, group.NomPartner, group.NomDept);
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpPost]
        [Route("Transfer")]
        public IActionResult Transfer()
        {
            try
            {
                BackgroundJob.Enqueue(() => RunTransfer(null));
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }

        }

        public async Task RunTransfer(PerformContext context)
        {
            var orgList = await _actionService.OrgListQuery();
            var toTransfer = orgList.Where(o => o.NLTransfer);
            var hangfireJobId = context.BackgroundJob.Id;
            List<string> errors = new List<string>();
            foreach (var org in toTransfer)
            {
                try
                {
                    // Added Loop for Multiple-Journal Posting Process
                    foreach (var Journal in _journalOptions.Journals)
                    {
                        try
                        {
                            context.WriteLine($"Extracting Journal for organization {org.PracName} and journal {Journal}.");
                            var lines = await _actionService.TransferJournalQuery(org.PracID, Journal: Journal, HangfireJobId: hangfireJobId);

                            context.WriteLine($"Found {lines.Count()} lines for {org.PracName} and journal {Journal}.");
                            if (lines == null || lines.Count() == 0)
                                continue;

                            // Cheat to deal with SQL not working off next batch, expecting 0
                            if (_options.ProviderType.Equals("sql", StringComparison.OrdinalIgnoreCase))
                            {
                                foreach (var line in lines)
                                {
                                    line.NomBatch = 0;
                                }
                            }
                            context.WriteLine($"Preparing to send Post for organization {org.PracName}.");
                            await _glProvider.PostJournalCmd(org.PracID, lines, Journal, context);
                            context.WriteLine($"Sent Post for organization {org.PracName}, flagging records now.");
                            await _actionService.FlagTransferredCmd(org.PracID, Journal, hangfireJobId);
                        }
                        catch (Exception ex)
                        {
                            context.WriteLine($"Post Failed for organization {org.PracName}, unflagging records now.");
                            await _actionService.UnFlagTransferredCmd(org.PracID, Journal, hangfireJobId);
                            throw ex;
                        }
                    }
                }
                catch (ResultException re)
                {
                    context.WriteLine($"Intacct Errors during transfer of organization {org.PracName}:\n\t{String.Join("\r\n",re.Errors)}");
                }
                catch (AggregateException ax)
                {
                    var msgs = String.Join("\n\t", ax.InnerExceptions.Select(e => e.Message));
                    context.WriteLine($"The organization {org.PracName} failed to transfer due to:\n\t{msgs}");
                }
                catch (Exception ex)
                {
                    context.WriteLine($"The organization {org.PracName} failed to transfer due to {ex.Message}\n\n" + ex.StackTrace);
                }
            }
        }


        [HttpPost]
        [Route("StatHours")]
        public IActionResult StatHours()
        {
            try
            {
                BackgroundJob.Enqueue(() => RunStatHours(null));
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        public async Task RunStatHours(PerformContext context)
        {
            var orgList = await _actionService.OrgListQuery();
            var toTransfer = orgList.Where(o => o.NLTransfer);
            var hangfireJobId = context.BackgroundJob.Id;
            List<string> errors = new List<string>();
            foreach (var org in toTransfer)
            {
                try
                {
                    // Added Loop for Multiple-Journal Posting Process
                    foreach (var Journal in _journalOptions.IntacctHourJournals)
                    {
                        try
                        {
                            var lines = await _actionService.ExtractIntacctHoursJournalQuery(org.PracID, Journal: Journal, HangfireJobId: hangfireJobId);

                            if (lines == null || lines.Count() == 0)
                                continue;

                            await _glProvider.PostStatHourJournalCmd(org.PracID, lines, Journal, context);
                            await _actionService.FlagTransferredCmd(org.PracID, Journal, hangfireJobId);
                        }
                        catch (Exception ex)
                        {
                            await _actionService.UnFlagTransferredCmd(org.PracID, Journal, hangfireJobId);
                            throw ex;
                        }
                    }
                }
                catch (ResultException re)
                {
                    context.WriteLine($"Intacct Errors during transfer of organization {org.PracName}:\n\t{String.Join("\r\n", re.Errors)}");
                }
                catch (AggregateException ax)
                {
                    var msgs = String.Join("\n\t", ax.InnerExceptions.Select(e => e.Message));
                    context.WriteLine($"The organization {org.PracName} failed to transfer due to:\n\t{msgs}");
                }
                catch (Exception ex)
                {
                    context.WriteLine($"The organization {org.PracName} failed to transfer due to {ex.Message}\n\n" + ex.StackTrace);
                }
            }
        }


        [HttpGet]
        [Route("Journal.csv")]
        [Produces("text/csv")]
        public async Task<IActionResult> ExportJournal()
        {
            try
            {
                List<JournalExtract> csvData = new List<JournalExtract>();
                var lines = await _actionService.ExportJournalQuery();
                csvData.AddRange(lines);
                var csvBuilder = new StringBuilder();
                var textWriter = new StringWriter(csvBuilder);
                var csv = new CsvHelper.CsvWriter(textWriter);
                csv.WriteRecords(csvData);
                return Content(csvBuilder.ToString());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpGet]
        [Route("{batchId}/Journal.csv")]
        [Produces("text/csv")]
        public async Task<IActionResult> ExportJournal(int batchId)
        {
            try
            {
                List<JournalExtract> csvData = new List<JournalExtract>();
                var lines = await _actionService.ExportJournalQuery(batchId);
                csvData.AddRange(lines);
                var csvBuilder = new StringBuilder();
                var textWriter = new StringWriter(csvBuilder);
                var csv = new CsvHelper.CsvWriter(textWriter);
                csv.WriteRecords(csvData);
                return Content(csvBuilder.ToString());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpPost]
        [Route("FlagTransferred")]
        public async Task<IActionResult> FlagTransferred()
        {
            try
            {
                var orgList = await _actionService.OrgListQuery();
                var toTransfer = orgList.Where(o => o.NLTransfer);
                foreach (var org in toTransfer)
                {
                    await _actionService.FlagTransferredCmd(org.PracID);
                }
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        #endregion Methods for Journal (Journal Posting)

        #region Methods for BankRec (Bank Reconciliation)

        [HttpPost]
        [Route("BankReconciliation")]
        public async Task<IActionResult> BankReconciliation()
        {
            try
            {
                var orgList = await _actionService.OrgListQuery();
                var toTransfer = orgList.Where(o => o.NLTransfer);
                List<string> errors = new List<string>();
                foreach (var org in toTransfer)
                {
                    try
                    {
                        foreach (var journal in _journalOptions.Journals)
                        {
                            var lines = await _actionService.ExtractBankRecQuery(org.PracID, Journal: journal);

                            if (lines == null || lines.Count() == 0)
                                continue;

                            // Cheat to deal with SQL not working off next batch, expecting 0
                            if (_options.ProviderType.Equals("sql", StringComparison.OrdinalIgnoreCase))
                            {
                                foreach (var line in lines)
                                {
                                    line.NomBatch = 0;
                                }
                            }

                            await _glProvider.CashJournalCmd(org.PracID, lines, journal, null);
                            await _actionService.FlagBankRecTransferredCmd(org.PracID, journal);
                        }
                    }
                    catch (AggregateException ax)
                    {
                        var msgs = String.Join(" | ", ax.InnerExceptions.Select(e => e.Message));
                        errors.Add($"The organization {org.PracName} failed to transfer due to {msgs}");
                    }
                    catch (Exception ex)
                    {
                        errors.Add($"The organization {org.PracName} failed to transfer due to {ex.Message}");
                    }
                }
                if (errors.Count > 0)
                {
                    return BadRequest(String.Join("\n", errors));
                }
                return Ok();
            }
            catch (ResultException re)
            {
                _logger.LogError(re.Message, re);
                return BadRequest(String.Join("\n", re.Errors));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        #endregion Methods for BankRec (Bank Reconciliation)

        #region Methods for Repost Journal


        [HttpGet]
        [Route("JournalPeriods")]
        public async Task<IActionResult> JournalPeriods()
        {
            try
            {
                var data = await _actionService.JournalPeriodsQuery();
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpGet]
        [Route("JournalRepostList/{PeriodIndex}")]
        public async Task<IActionResult> RepostList([FromRoute]int PeriodIndex)
        {
            try
            {
                var data = await _actionService.JournalRepostListQuery(PeriodIndex);
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }


        [HttpPost]
        [Route("RepostJournal/{BatchID}")]
        public async Task<IActionResult> RepostJournal([FromRoute]int BatchID)
        {
            try
            {
                var orgList = await _actionService.OrgListQuery();
                var toTransfer = orgList.Where(o => o.NLTransfer);
                List<string> errors = new List<string>();
                foreach (var org in toTransfer)
                {
                    try
                    {
                        foreach (var Journal in _journalOptions.Journals)
                        {
                            var lines = await _actionService.TransferJournalQuery(org.PracID, BatchID, Journal);

                            if (lines == null || lines.Count() == 0)
                                continue;

                            // Cheat to deal with SQL not working off next batch, expecting 0
                            if (_options.ProviderType.Equals("sql", StringComparison.OrdinalIgnoreCase))
                            {
                                foreach (var line in lines)
                                {
                                    line.NomBatch = 0;
                                }
                            }

                            await _glProvider.PostJournalCmd(org.PracID, lines, Journal, null);
                        }
                    }
                    catch (AggregateException ax)
                    {
                        var msgs = String.Join(" | ", ax.InnerExceptions.Select(e => e.Message));
                        errors.Add($"The organization {org.PracName} failed to transfer due to {msgs}");
                    }
                    catch (Exception ex)
                    {
                        errors.Add($"The organization {org.PracName} failed to transfer due to {ex.Message}");
                    }
                }
                if (errors.Count > 0)
                {
                    return BadRequest(String.Join("\n", errors));
                }
                return Ok();
            }
            catch (ResultException re)
            {
                _logger.LogError(re.Message, re);
                return BadRequest(String.Join("\n", re.Errors));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        #endregion Methods for Repost Journal

        #region Methods for Organizations

        [HttpGet]
        [Route("OrgList")]
        public async Task<IActionResult> OrgList()
        {
            try
            {
                var data = await _actionService.OrgListQuery();
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpPost]
        [Route("OrgUpdate")]
        public async Task<IActionResult> OrgList([FromBody] NomOrganisation data)
        {
            try
            {
                await _actionService.UpdateOrgCmd(data.PracID, data.NLServer, data.NLDatabase, data.NLTransfer);
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        #endregion Methods for Organizations

        #region Methods for Repost BankRec


        [HttpGet]
        [Route("BankRecPeriods")]
        public async Task<IActionResult> BankRecPeriods()
        {
            try
            {
                var data = await _actionService.JournalPeriodsQuery();
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpGet]
        [Route("BankRecRepostList/{PeriodIndex}")]
        public async Task<IActionResult> BankRecRepostList([FromRoute]int PeriodIndex)
        {
            try
            {
                var data = await _actionService.BankRecRepostListQuery(PeriodIndex);
                return Ok(data);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }


        [HttpPost]
        [Route("RepostBankRec/{BatchID}")]
        public async Task<IActionResult> RepostBankRec([FromRoute]int BatchID)
        {
            try
            {
                var orgList = await _actionService.OrgListQuery();
                var toTransfer = orgList.Where(o => o.NLTransfer);
                List<string> errors = new List<string>();
                foreach (var org in toTransfer)
                {
                    try
                    {
                        foreach (var journal in _journalOptions.Journals)
                        {
                            var lines = await _actionService.ExtractBankRecQuery(org.PracID, BatchID, journal);

                            if (lines == null || lines.Count() == 0)
                                continue;

                            // Cheat to deal with SQL not working off next batch, expecting 0
                            if (_options.ProviderType.Equals("sql", StringComparison.OrdinalIgnoreCase))
                            {
                                foreach (var line in lines)
                                {
                                    line.NomBatch = 0;
                                }
                            }

                            await _glProvider.CashJournalCmd(org.PracID, lines, journal, null);
                        }
                    }
                    catch (AggregateException ax)
                    {
                        var msgs = String.Join(" | ", ax.InnerExceptions.Select(e => e.Message));
                        errors.Add($"The organization {org.PracName} failed to transfer due to {msgs}");
                    }
                    catch (Exception ex)
                    {
                        errors.Add($"The organization {org.PracName} failed to transfer due to {ex.Message}");
                    }
                }
                if (errors.Count > 0)
                {
                    return BadRequest(String.Join("\n", errors));
                }
                return Ok();
            }
            catch (ResultException re)
            {
                _logger.LogError(re.Message, re);
                return BadRequest(String.Join("\n", re.Errors));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        #endregion Methods for Repost Journal

    }
}
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using PE.Nominal.Web.Options;
using System;
using System.Threading.Tasks;

namespace PE.Nominal.Web.Controllers
{
    [Authorize]
    [Route("api/Reports")]
    public class ReportsController : Controller
    {
        private readonly ILogger _logger;
        private readonly ReportOptions _options;
        private readonly ReportConnectionOptions _connOptions;
        private readonly RepGen95.PERepGenSoap _client95;
        private readonly RepGen96.PERepGenSoap _client96;
        private readonly RepGen96.AuthenticationInformation _authInfo;

        /// <summary>
        /// Inject Options, then build up items we need
        /// </summary>
        /// <param name="options"></param>
        public ReportsController(ILogger<ReportsController> logger, IOptions<ReportOptions> options, IOptions<ReportConnectionOptions> connOptions, IServiceProvider provider)
        {
            // Injected Options
            _logger = logger;
            _options = options.Value;
            _connOptions = connOptions.Value;

            //Build the rest depending on setting
            if (_options.IncludeAuth)
            {
                _client96 = provider.GetRequiredService<RepGen96.PERepGenSoap>();
                _authInfo = provider.GetRequiredService<RepGen96.AuthenticationInformation>();
            }
            else
            {
                _client95 = provider.GetRequiredService<RepGen95.PERepGenSoap>();
            }
        }

        [HttpGet]
        [Route("DetailReport")]
        public async Task<ActionResult> DetailReport([FromQuery]int org, [FromQuery]string source, [FromQuery]string section, [FromQuery]string account, [FromQuery]string office, [FromQuery]string service, [FromQuery] int partner, [FromQuery]string dept, [FromQuery]DateTime start, [FromQuery] DateTime end)
        {
            try
            {
                object[] FlatParams = new object[30];
                FlatParams[0] = "@OrgID";
                FlatParams[1] = "int";
                FlatParams[2] = org;
                FlatParams[3] = "@Source";
                FlatParams[4] = "varchar";
                FlatParams[5] = source;
                FlatParams[6] = "@Section";
                FlatParams[7] = "varchar";
                FlatParams[8] = section;
                FlatParams[9] = "@Account";
                FlatParams[10] = "varchar";
                FlatParams[11] = account;
                FlatParams[12] = "@Office";
                FlatParams[13] = "varchar";
                FlatParams[14] = office;
                FlatParams[15] = "@Service";
                FlatParams[16] = "varchar";
                FlatParams[17] = service;
                FlatParams[18] = "@Partner";
                FlatParams[19] = "int";
                FlatParams[20] = partner;
                FlatParams[21] = "@Department";
                FlatParams[22] = "varchar";
                FlatParams[23] = dept;
                FlatParams[24] = "@FromDate";
                FlatParams[25] = "datetime";
                FlatParams[26] = start;
                FlatParams[27] = "@ToDate";
                FlatParams[28] = "datetime";
                FlatParams[29] = end;

                object[] Grouping = new object[15];
                string SortOrder = String.Empty;
                string Filter = String.Empty;

                if (_options.IncludeAuth)
                {
                    var request1 = new RepGen96.GenerateReportRequest(_authInfo, "Report_Menu_Params", new object[] { "Journal_Report.rpx", -100, "pe_NL_rpt_Journal", FlatParams, SortOrder, Filter, Grouping, _connOptions.EncryptedConnectionString }, "GL System", "-100", false, String.Empty);
                    var response1 = await _client96.GenerateReportAsync(request1);
                    if (!String.IsNullOrWhiteSpace(response1.Error))
                    {
                        throw new Exception(response1.Error);
                    }
                    var request2 = new RepGen96.ExportToPDFRequest(_authInfo, response1.GenerateReportResult);
                    var response2 = await _client96.ExportToPDFAsync(request2);
                    return File(response2.ExportToPDFResult, "application/pdf", "Detail_Report.pdf");
                }
                else
                {
                    var request1 = new RepGen95.GenerateReportRequest("Report_Menu_Params", new object[] { "Detail_Report.rpx", -100, "pe_NL_Detail_Report", FlatParams, SortOrder, Filter, Grouping, _connOptions.EncryptedConnectionString }, "GL System", "-100", false, String.Empty);
                    var response1 = await _client95.GenerateReportAsync(request1);
                    if (!String.IsNullOrWhiteSpace(response1.Error))
                    {
                        throw new Exception(response1.Error);
                    }
                    var request2 = new RepGen95.ExportToPDFRequest(response1.GenerateReportResult);
                    var response2 = await _client95.ExportToPDFAsync(request2);
                    return File(response2.ExportToPDFResult, "application/pdf", "Detail_Report.pdf");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpGet]
        [Route("JournalReport")]
        public async Task<ActionResult> JournalReport()
        {
            try
            {
                object[] FlatParams = new object[0];
                object[] Grouping = new object[15];
                string SortOrder = String.Empty;
                string Filter = String.Empty;

                if (_options.IncludeAuth)
                {
                    var request1 = new RepGen96.GenerateReportRequest(_authInfo, "Report_Menu_Params", new object[] { "Journal_Report.rpx", -100, "pe_NL_rpt_Journal", FlatParams, SortOrder, Filter, Grouping, _connOptions.EncryptedConnectionString }, "GL System", "-100", false, String.Empty);
                    var response1 = await _client96.GenerateReportAsync(request1);
                    if (!String.IsNullOrWhiteSpace(response1.Error))
                    {
                        throw new Exception(response1.Error);
                    }
                    var request2 = new RepGen96.ExportToPDFRequest(_authInfo, response1.GenerateReportResult);
                    var response2 = await _client96.ExportToPDFAsync(request2);
                    return File(response2.ExportToPDFResult, "application/pdf", "journal_report.pdf");
                }
                else
                {
                    var request1 = new RepGen95.GenerateReportRequest("Report_Menu_Params", new object[] { "Journal_Report.rpx", -100, "pe_NL_rpt_Journal", FlatParams, SortOrder, Filter, Grouping, _connOptions.EncryptedConnectionString }, "GL System", "-100", false, String.Empty);
                    var response1 = await _client95.GenerateReportAsync(request1);
                    if (!String.IsNullOrWhiteSpace(response1.Error))
                    {
                        throw new Exception(response1.Error);
                    }
                    var request2 = new RepGen95.ExportToPDFRequest(response1.GenerateReportResult);
                    var response2 = await _client95.ExportToPDFAsync(request2);
                    return File(response2.ExportToPDFResult, "application/pdf", "journal_report.pdf");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpGet]
        [Route("ReprintJournalReport")]
        public async Task<ActionResult> ReprintJournalReport([FromQuery]int batch)
        {
            try
            {
                object[] FlatParams = new object[3];
                FlatParams[0] = "@Batch";
                FlatParams[1] = "int";
                FlatParams[2] = batch;

                object[] Grouping = new object[15];
                string SortOrder = String.Empty;
                string Filter = String.Empty;

                if (_options.IncludeAuth)
                {
                    var request1 = new RepGen96.GenerateReportRequest(_authInfo, "Report_Menu_Params", new object[] { "Journal_Report.rpx", -100, "pe_NL_rpt_Journal", FlatParams, SortOrder, Filter, Grouping, _connOptions.EncryptedConnectionString }, "GL System", "-100", false, String.Empty);
                    var response1 = await _client96.GenerateReportAsync(request1);
                    if (!String.IsNullOrWhiteSpace(response1.Error))
                    {
                        throw new Exception(response1.Error);
                    }
                    var request2 = new RepGen96.ExportToPDFRequest(_authInfo, response1.GenerateReportResult);
                    var response2 = await _client96.ExportToPDFAsync(request2);
                    return File(response2.ExportToPDFResult, "application/pdf", "journal_report.pdf");
                }
                else
                {
                    var request1 = new RepGen95.GenerateReportRequest("Report_Menu_Params", new object[] { "Journal_Report.rpx", -100, "pe_NL_rpt_Journal", FlatParams, SortOrder, Filter, Grouping, _connOptions.EncryptedConnectionString }, "GL System", "-100", false, String.Empty);
                    var response1 = await _client95.GenerateReportAsync(request1);
                    if (!String.IsNullOrWhiteSpace(response1.Error))
                    {
                        throw new Exception(response1.Error);
                    }
                    var request2 = new RepGen95.ExportToPDFRequest(response1.GenerateReportResult);
                    var response2 = await _client95.ExportToPDFAsync(request2);
                    return File(response2.ExportToPDFResult, "application/pdf", "journal_report.pdf");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpGet]
        [Route("ReprintJournalDetails")]
        public async Task<ActionResult> ReprintJournalDetails([FromQuery]int batch, [FromQuery] int org, [FromQuery] string source)
        {
            try
            {
                object[] FlatParams = new object[9];
                FlatParams[0] = "@Batch";
                FlatParams[1] = "int";
                FlatParams[2] = batch;
                FlatParams[3] = "@Org";
                FlatParams[4] = "int";
                FlatParams[5] = org;
                FlatParams[6] = "@Source";
                FlatParams[7] = "varchar";
                FlatParams[8] = source;

                object[] Grouping = new object[15];
                string SortOrder = String.Empty;
                string Filter = String.Empty;

                if (_options.IncludeAuth)
                {
                    var request1 = new RepGen96.GenerateReportRequest(_authInfo, "Report_Menu_Params", new object[] { "Journal_Report.rpx", -100, "pe_NL_rpt_Journal", FlatParams, SortOrder, Filter, Grouping, _connOptions.EncryptedConnectionString }, "GL System", "-100", false, String.Empty);
                    var response1 = await _client96.GenerateReportAsync(request1);
                    if (!String.IsNullOrWhiteSpace(response1.Error))
                    {
                        throw new Exception(response1.Error);
                    }
                    var request2 = new RepGen96.ExportToPDFRequest(_authInfo, response1.GenerateReportResult);
                    request2.AuthenticationInformation = _authInfo;
                    var response2 = await _client96.ExportToPDFAsync(request2);
                    return File(response2.ExportToPDFResult, "application/pdf", "journal_report.pdf");
                }
                else
                {
                    var request1 = new RepGen95.GenerateReportRequest("Report_Menu_Params", new object[] { "Journal_Report.rpx", -100, "pe_NL_rpt_Journal", FlatParams, SortOrder, Filter, Grouping, _connOptions.EncryptedConnectionString }, "GL System", "-100", false, String.Empty);
                    var response1 = await _client95.GenerateReportAsync(request1);
                    if (!String.IsNullOrWhiteSpace(response1.Error))
                    {
                        throw new Exception(response1.Error);
                    }
                    var request2 = new RepGen95.ExportToPDFRequest(response1.GenerateReportResult);
                    var response2 = await _client95.ExportToPDFAsync(request2);
                    return File(response2.ExportToPDFResult, "application/pdf", "journal_report.pdf");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

    }
}
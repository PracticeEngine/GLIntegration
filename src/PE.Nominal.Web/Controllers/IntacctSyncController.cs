using Hangfire;
using Hangfire.Server;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using PE.Nominal.Intacct;
using System;
using System.Threading.Tasks;

namespace PE.Nominal.Web.Controllers
{
    [Produces("application/json")]
    [Route("api/IntacctSync")]
    public class IntacctSyncController : Controller
    {
        private readonly ILogger _logger;
        private readonly ActionsService _actionService;
        private readonly IntacctSyncService _intacctService;

        public IntacctSyncController(ILogger<IntacctSyncController> logger, ActionsService actionService, IntacctSyncService intacctService)
        {
            _logger = logger;
            _actionService = actionService;
            _intacctService = intacctService;
        }


        [HttpPost]
        [Route("SyncAll")]
        public IActionResult SyncAll()
        {
            try
            {
                bool syncOnlyNew = Convert.ToBoolean(Request.Query["OnlyNew"]);
                BackgroundJob.Enqueue(() => RunSyncAll(syncOnlyNew, null));
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpPost]
        [Route("Customers")]
        public IActionResult SyncCustomers()
        {
            try
            {
                bool syncOnlyNew = Convert.ToBoolean(Request.Query["OnlyNew"]);
                BackgroundJob.Enqueue(() => RunSyncCustomers(syncOnlyNew, null));
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpPost]
        [Route("Projects")]
        public IActionResult SyncProjects()
        {
            try
            {
                bool syncOnlyNew = Convert.ToBoolean(Request.Query["OnlyNew"]);
                BackgroundJob.Enqueue(() => RunSyncProjects(syncOnlyNew, null));
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        [HttpPost]
        [Route("Employees")]
        public IActionResult SyncEmployees()
        {
            try
            {
                bool syncOnlyNew = Convert.ToBoolean(Request.Query["OnlyNew"]);
                BackgroundJob.Enqueue(() => RunSyncEmployees(syncOnlyNew, null));
                return Ok();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message, ex);
                return BadRequest(ex.Message);
            }
        }

        public async Task RunSyncAll(bool OnlyNew, PerformContext context)
        {
            await RunSyncEmployees(OnlyNew, context);
            await RunSyncCustomers(OnlyNew, context);
            await RunSyncProjects(OnlyNew, context);
        }

        public async Task RunSyncCustomers(bool OnlyNew, PerformContext context)
        {
            _intacctService.SyncOnlyNew = OnlyNew;
            var customers = await _actionService.IntacctCustomerQuery();
            await _intacctService.SyncAllCustomers(customers, context);
        }

        public async Task RunSyncProjects(bool OnlyNew, PerformContext context)
        {
            _intacctService.SyncOnlyNew = OnlyNew;
            var projects = await _actionService.IntacctProjectsQuery();
            await _intacctService.SyncAllProjects(projects, context);
        }

        public async Task RunSyncEmployees(bool OnlyNew, PerformContext context)
        {
            _intacctService.SyncOnlyNew = OnlyNew;
            var employees = await _actionService.IntacctEmployeesQuery();
            await _intacctService.SyncAllEmployees(employees, context);
        }
    }
}
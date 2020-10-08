using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using PE.Nominal.Options;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace PE.Nominal.Web.Controllers
{
    [Authorize]
    public class HomeController : Controller
    {
        private readonly PageService _pageService;
        private readonly ViewOptions _viewOptions;
        private readonly JournalOptions _journalOptions;

        public HomeController(PageService pageService, IOptions<ViewOptions> viewOptions, IOptions<JournalOptions> journalOptions)
        {
            _pageService = pageService;
            _viewOptions = viewOptions.Value;
            _journalOptions = journalOptions.Value;
        }

        /// <summary>
        /// Return the SPA Page
        /// </summary>
        /// <returns></returns>
        public async Task<IActionResult> Index()
        {
            try
            {
                var vm = await _pageService.GetViewModel(User.Identity.Name);
                vm.ProviderType = _viewOptions.ProviderType;
                vm.SQLIntegration = _viewOptions.ProviderType.Equals("sql", StringComparison.OrdinalIgnoreCase);
                vm.IntacctHrsJournal = _viewOptions.ProviderType.Equals("intacct", StringComparison.OrdinalIgnoreCase) && _journalOptions.IntacctHourJournals == null ? false : _journalOptions.IntacctHourJournals.Count() > 0;
                return View(vm);
            }
            catch (Exception ex)
            {
                return View("Error", ex);
            }
        }

        public IActionResult Error()
        {
            return View();
        }

        public async Task<IActionResult> TenantError()
        {
            var vm = await _pageService.GetViewModel(User.Identity.Name);
            vm.ProviderType = _viewOptions.ProviderType;
            vm.SQLIntegration = _viewOptions.ProviderType.Equals("sql", StringComparison.OrdinalIgnoreCase);
            vm.IntacctHrsJournal = _viewOptions.ProviderType.Equals("intacct", StringComparison.OrdinalIgnoreCase) && _journalOptions.IntacctHourJournals == null ? false : _journalOptions.IntacctHourJournals.Count() > 0;
            return View(vm);
        }
    }
}

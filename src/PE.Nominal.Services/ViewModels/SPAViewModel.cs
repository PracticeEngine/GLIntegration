using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace PE.Nominal.ViewModels
{
    /// <summary>
    /// The Main ViewModel for the GL Application
    /// </summary>
    public class SPAViewModel
    {
        public SelectedDates Dates { get; set; }

        public IEnumerable<MenuItem> TaskPads { get; set; }

        public bool SQLIntegration { get; set; }

        public string ProviderType { get; set; }

        public bool IntacctHrsJournal { get; set; }

        public bool MTDAvailable { get; set; }

        public bool ExportOnly { get; set; }
    }
}

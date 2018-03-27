using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace PE.Nominal.Options
{
    /// <summary>
    /// Journal Options from the Configuartion
    /// </summary>
    public class JournalOptions
    {
        public IEnumerable<string> Journals { get; set; }


        public IEnumerable<string> IntacctHourJournals { get; set; }
    }
}

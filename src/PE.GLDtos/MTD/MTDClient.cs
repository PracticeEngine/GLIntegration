using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace PE.Nominal
{
    /// <summary>
    /// The Basic Client Info for syncing debtors data
    /// </summary>
    public class MTDClient
    {
        public int ContIndex { get; set; }

        public string ClientCode { get; set; }

        public string ClientName { get; set; }
    }
}
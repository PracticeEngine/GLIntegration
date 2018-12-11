using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class MTDLineItem
    {
        public int DebtTranIndex { get; set; }

        /// <summary>
        /// Line Value
        /// </summary>
        public decimal Amount { get; set; }

        /// <summary>
        /// Line VAT Code
        /// </summary>
        public string VATCode { get; set; }

        /// <summary>
        /// Line VAT Amount
        /// </summary>
        public decimal VATAmount { get; set; }
    }
}

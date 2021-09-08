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

        /// <summary>
        /// Line Description
        /// </summary>
        public string Description { get; set; }

        /// <summary>
        /// Tax Code
        /// </summary>
        public string TaxCode { get; set; }

        /// <summary>
        /// Sales Account Code
        /// </summary>
        public string AccountCode { get; set; }

        /// <summary>
        /// Tracking Category 1 Name
        /// </summary>
        public string TrackingName1 { get; set; }

        /// <summary>
        /// Tracking Category 1 Option
        /// </summary>
        public string TrackingOption1 { get; set; }

        /// <summary>
        /// Tracking Category 2 Name
        /// </summary>
        public string TrackingName2 { get; set; }

        /// <summary>
        /// Tracking Category 2 Option
        /// </summary>
        public string TrackingOption2 { get; set; }
    }
}

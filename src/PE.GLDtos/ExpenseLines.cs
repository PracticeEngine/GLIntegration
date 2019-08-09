using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class ExpenseLines
    {
        /// <summary>
        /// Number of blank lines
        /// </summary>
        public int NumBlank { get; set; }

        /// <summary>
        /// The Nominal Expense Index
        /// </summary>
        public int NomExpIndex { get; set; }

        /// <summary>
        /// The Period Index for the Nominal Entry
        /// </summary>
        public int PeriodIndex { get; set; }

        /// <summary>
        /// ID of the Org
        /// </summary>
        public int ExpOrg { get; set; }

        /// <summary>
        /// The PE Disb Code
        /// </summary>
        public string DisbCode { get; set; }

        /// <summary>
        /// The Organiztion Name
        /// </summary>
        public string OrgName { get; set; }

        /// <summary>
        /// The Disb Code Name
        /// </summary>
        public string DisbName { get; set; }

        /// <summary>
        /// The GL Account Code
        /// </summary>
        public string PostAcc { get; set; }

        public DateTime ExpDate { get; set; }

        public decimal Amount { get; set; }

        public decimal VATAmount { get; set; }

        public string Description { get; set; }

    }
}

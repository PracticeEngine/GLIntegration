using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class MissingExpenseAccountMap
    {

        /// <summary>
        /// ID of the Expense Code
        /// </summary>
        public int ExpMapIndex { get; set; }

        /// <summary>
        /// ID of the Organisation
        /// </summary>
        public int ExpOrg { get; set; }

        /// <summary>
        /// Name of the Organisation
        /// </summary>
        public string PracName { get; set; }

        /// <summary>
        /// The Expense Code
        /// </summary>
        public string ChargeCode { get; set; }

        /// <summary>
        /// The Expense Description
        /// </summary>
        public string ChargeName { get; set; }

        /// <summary>
        /// The Chargeable Nominal Expense Account 
        /// </summary>
        public string ChargeExpAccountType { get; set; }

        /// <summary>
        /// The Chargeable Nominal Expense Account 
        /// </summary>
        public string ChargeExpAccount { get; set; }

        /// <summary>
        /// The Non-Chargeable Nominal Expense Account 
        /// </summary>
        public string NonChargeExpAccountType { get; set; }
        /// <summary>
        /// The Non-Chargeable Nominal Expense Account 
        /// </summary>
        public string NonChargeExpAccount { get; set; }
    }
}

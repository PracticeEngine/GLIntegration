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
        public string ChargeExpAccount { get; set; }

        /// <summary>
        /// The Non-Chargeable Nominal Expense Account 
        /// </summary>
        public string NonChargeExpAccount { get; set; }

        /// <summary>
        /// The Chargeable Nominal Expense Account Suffix 1
        /// </summary>
        public int ChargeSuffix1 { get; set; }

        /// <summary>
        /// The Chargeable Nominal Expense Account Suffix 2
        /// </summary>
        public int ChargeSuffix2 { get; set; }

        /// <summary>
        /// The Chargeable Nominal Expense Account Suffix 3
        /// </summary>
        public int ChargeSuffix3 { get; set; }

        /// <summary>
        /// The Non-Chargeable Nominal Expense Account Suffix 1
        /// </summary>
        public int NonChargeSuffix1 { get; set; }

        /// <summary>
        /// The Non-Chargeable Nominal Expense Account Suffix 2
        /// </summary>
        public int NonChargeSuffix2 { get; set; }

        /// <summary>
        /// The Non-Chargeable Nominal Expense Account Suffix 3
        /// </summary>
        public int NonChargeSuffix3 { get; set; }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class DetailLine
    {
        /// <summary>
        /// The Nominal Index
        /// </summary>
        public int NLIndex { get; set; }

        /// <summary>
        /// The Period Index for the Nominal Entry
        /// </summary>
        public int NLPeriodIndex { get; set; }

        /// <summary>
        /// ID of the Org
        /// </summary>
        public int NLOrg { get; set; }

        /// <summary>
        /// The 'Source' such as WIP or DRS from Practice Engine
        /// </summary>
        public string NLSource { get; set; }

        /// <summary>
        /// The Nominal Section (BS or GL) financial statement Type
        /// </summary>
        public string NLSection { get; set; }

        /// <summary>
        /// The Nominal Account (the pseudo-account in the NomLedger)
        /// </summary>
        public string NLAccount { get; set; }

        public DateTime NLDate { get; set; }

        /// <summary>
        /// The GL Account Code
        /// </summary>
        public string NomPostAcc { get; set; }

        public string TransRefAlpha { get; set; }

        public decimal Amount { get; set; }

        public string TransTypeDescription { get; set; }
    }
}

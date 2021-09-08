using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class ImportMap
    {

        /// <summary>
        /// ID of the Mapping
        /// </summary>
        public int DisbMapIndex { get; set; }

        /// <summary>
        /// ID of the Org
        /// </summary>
        public int NLOrg { get; set; }

        /// <summary>
        /// The GL Expense Account Code
        /// </summary>
        public string NLAcc { get; set; }

        /// <summary>
        /// The Gl Expense Account Id
        /// </summary>
        public int NLIdx { get; set; }

        /// <summary>
        /// The PE Disbursement Code
        /// </summary>
        public string DisbCode { get; set; }

        /// <summary>
        /// The Organiztion Name
        /// </summary>
        public string OrgName { get; set; }
        
        /// <summary>
        /// The Disbursement Name
        /// </summary>
        public string DisbName { get; set; }

        /// <summary>
        /// Number of blank lines
        /// </summary>
        public int NumBlank { get; set; }
    }
}

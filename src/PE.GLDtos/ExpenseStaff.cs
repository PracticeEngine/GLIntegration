using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class ExpenseStaff
    {
        /// <summary>
        /// ID of the Org
        /// </summary>
        public int StaffOrg { get; set; }

        /// <summary>
        /// ID of the Staff
        /// </summary>
        public int StaffIndex { get; set; }

        /// <summary>
        /// The Organiztion Name
        /// </summary>
        public string OrgName { get; set; }

        /// <summary>
        /// The name of the Staff member
        /// </summary>
        public string StaffName { get; set; }

        /// <summary>
        /// Number of blank lines
        /// </summary>
        public int NumBlank { get; set; }
    }
}

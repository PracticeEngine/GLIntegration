using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class GLMapping
    {
        /// <summary>
        /// The GL Account Code
        /// </summary>
        public string AccountCode { get; set; }

        /// <summary>
        /// The GL Account Type (Group)
        /// </summary>
        public string AccountTypeCode { get; set; }

        /// <summary>
        /// The Id of the Mapping in the System
        /// </summary>
        public int MapIndex { get; set; }

        /// <summary>
        /// The Nominal (pseudo) account
        /// </summary>
        public string MapAccount { get; set; }

        public string MapDept { get; set; }

        public string MapOffice { get; set; }

        public int MapOrg { get; set; }

        public int MapPart { get; set; }

        /// <summary>
        /// BS, PL (type of financial statement)
        /// </summary>
        public string MapSection { get; set; }

        public string MapServ { get; set; }

        public string MapSource { get; set; }

        public string StaffName { get; set; }

        /// <summary>
        /// The Organiztion Name
        /// </summary>
        public string OrgName { get; set; }

        /// <summary>
        /// The Service Name
        /// </summary>
        public string ServiceName { get; set; }

        /// <summary>
        /// The Office Name
        /// </summary>
        public string OfficeName { get; set; }

        /// <summary>
        /// The Partner Name
        /// </summary>
        public string PartnerName { get; set; }

        /// <summary>
        /// The Department Name
        /// </summary>
        public string DepartmentName { get; set; }
    }
}

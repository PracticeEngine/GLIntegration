using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class JournalGroup
    {
        /// <summary>
        /// ID of the Org
        /// </summary>
        public int NomOrg { get; set; }

        /// <summary>
        /// The 'Source' such as WIP or DRS from Practice Engine
        /// </summary>
        public string NomSource { get; set; }

        /// <summary>
        /// The Nominal Section (BS or GL) financial statement Type
        /// </summary>
        public string NomSection { get; set; }

        /// <summary>
        /// The Nominal Account 
        /// </summary>
        public string NomAccount { get; set; }

        /// <summary>
        /// The Office Code
        /// </summary>
        public string NomOffice { get; set; }

        /// <summary>
        /// The Dept Code
        /// </summary>
        public string NomDept { get; set; }

        /// <summary>
        /// The Serv Index
        /// </summary>
        public string NomService { get; set; }

        /// <summary>
        /// The Partner's StaffIndex
        /// </summary>
        public int? NomPartner { get; set; }

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

        /// <summary>
        /// Number of blank lines
        /// </summary>
        public int NumBlank { get; set; }
    }
}

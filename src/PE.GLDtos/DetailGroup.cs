using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class DetailGroup
    {
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
        /// The Nominal Account 
        /// </summary>
        public string NLAccount { get; set; }

        /// <summary>
        /// The Office Code
        /// </summary>
        public string NLOffice { get; set; }

        /// <summary>
        /// The Dept Code
        /// </summary>
        public string NLDept { get; set; }

        /// <summary>
        /// The Serv Index
        /// </summary>
        public string NLService { get; set; }

        /// <summary>
        /// The Partner's StaffIndex
        /// </summary>
        public int? NLPartner { get; set; }

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

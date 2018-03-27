using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class JournalMap : JournalExtract
    {
        /// <summary>
        /// Number of blank lines
        /// </summary>
        public int NumBlank { get; set; }

        /// <summary>
        /// The Nominal Index
        /// </summary>
        public int NomIndex { get; set; }

        /// <summary>
        /// The Period Index for the Nominal Entry
        /// </summary>
        public int NomPeriodIndex { get; set; }

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
        /// The Nominal Account (the pseudo-account in the NomLedger)
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
        public int NomPartner { get; set; }

        /// <summary>
        /// Amount of the Tax (VAT) in the Account
        /// </summary>
        public decimal NomVATAmount { get; set; }

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
        /// The GL Account Code
        /// </summary>
        public string NomPostAcc { get; set; }

        /// <summary>
        /// Access Account specific
        /// </summary>
        public string NomVATAcc { get; set; }

        /// <summary>
        /// Access Account specific
        /// </summary>
        public string NomDRSAcc { get; set; }

        public int NomMaxRef { get; set; }

        public string NomJnlType { get; set; }

        public string NomDRSCode { get; set; }

        public string NomVATCode { get; set; }

        public string NomVATRateCode { get; set; }

        public bool NomPosted { get; set; }

        public DateTime? NomPostDate { get; set; }

        public string Job_Dept { get; set; }

        public string Staff_Dept { get; set; }

        public string ClientCode { get; set; }

        public string StaffCode { get; set; }

        public string Currency { get; set; }

        public decimal? ForeignAmount { get; set; }

    }
}

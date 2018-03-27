using System;
using System.Collections.Generic;
using System.Text;

namespace PE.Nominal.Intacct
{
    public class IntacctConfig
    {
        /// <summary>
        /// The Various Organization Configurations
        /// </summary>
        public IEnumerable<IntacctOrgConfig> OrgConfigs { get; set; }

        /// <summary>
        /// The Various Configurations for Cashbook Journals
        /// </summary>
        public IEnumerable<IntacctOrgConfig> CashbookConfigs { get; set; }

        /// <summary>
        /// The number of minutes to keep cache of Intacct responses
        /// </summary>
        public int CacheMinutes { get; set; }

        /// <summary>
        /// Turns on Logging to App_Data Folder
        /// </summary>
        public bool LogToAppData { get; set; }
    }

    public class IntacctOrgConfig
    {
        /// <summary>
        /// Organization ID to tie this configuration to
        /// </summary>
        public int Org { get; set; }

        /// <summary>
        /// Create Journals in Draft State
        /// </summary>
        public bool CreateAsDraft { get; set; }

        /// <summary>
        /// The Intacct URL to use
        /// </summary>
        public string IntacctURL { get; set; }

        /// <summary>
        /// The Sender ID for Web
        /// </summary>
        public string SenderID { get; set; }

        /// <summary>
        /// The Password for the Sender ID for web
        /// </summary>
        public string SenderPassword { get; set; }

        /// <summary>
        /// The Company ID for Intacct
        /// </summary>
        public string CompanyID { get; set; }

        /// <summary>
        /// The User ID for Intacct
        /// </summary>
        public string UserID { get; set; }

        /// <summary>
        /// The User Password for Intacct
        /// </summary>
        public string UserPassword { get; set; }
    }
}

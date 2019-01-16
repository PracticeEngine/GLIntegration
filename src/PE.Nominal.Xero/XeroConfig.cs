using System;
using System.Collections.Generic;
using System.Text;

namespace PE.Nominal.XeroGL
{
    public class XeroConfig
    {
        /// <summary>
        /// The Various Organization Configurations
        /// </summary>
        public IEnumerable<XeroOrgConfig> OrgConfigs { get; set; }

        /// <summary>
        /// The Various Configurations for Cashbook Journals
        /// </summary>
        public IEnumerable<XeroOrgConfig> CashbookConfigs { get; set; }

        /// <summary>
        /// The number of minutes to keep cache of Intacct responses
        /// </summary>
        public int CacheMinutes { get; set; }

        /// <summary>
        /// Turns on Logging to App_Data Folder
        /// </summary>
        public bool LogToAppData { get; set; }
    }

    public class XeroOrgConfig
    {
        /// <summary>
        /// Organization ID to tie this configuration to
        /// </summary>
        public int Org { get; set; }

        /// <summary>
        /// The Intacct URL to use
        /// </summary>
        public string XeroURL { get; set; }

        /// <summary>
        /// The Intacct URL to use
        /// </summary>
        public string XeroCertPath { get; set; }

        /// <summary>
        /// The Sender ID for Web
        /// </summary>
        public string SenderID { get; set; }

        /// <summary>
        /// The Password for the Sender ID for web
        /// </summary>
        public string SenderPassword { get; set; }
        
    }
}

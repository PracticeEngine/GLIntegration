using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Text;

namespace PE.Nominal.BusCent
{
    public class BusCentConfig
    {
        /// <summary>
        /// The Various Organization Configurations
        /// </summary>
        public IEnumerable<BusCentOrgConfig> OrgConfigs { get; set; }

        /// <summary>
        /// The number of minutes to keep cache of Business Central responses
        /// </summary>
        public int CacheMinutes { get; set; }

        /// <summary>
        /// Turns on Logging to App_Data Folder
        /// </summary>
        public bool LogToAppData { get; set; }
    }

    public class BusCentToken
    {
        [JsonProperty("access_token")]
        public string AccessToken { get; set; }

        [JsonProperty("expires_in")]
        public int ExpiresIn { get; set; }

        [JsonProperty("refresh_token")]
        public string RefreshToken { get; set; }
    }

    public class BusCentOrgConfig
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
        /// The Business Central URL to use
        /// </summary>
        public string BusinessCentralURL { get; set; }

        /// <summary>
        /// The Auth URL to use
        /// </summary>
        public string AuthenticationURL { get; set; }

        /// <summary>
        /// The Authentication Tenant ID
        /// </summary>
        public string TenantID { get; set; }

        /// <summary>
        /// The Authentication Client ID
        /// </summary>
        public string ClientID { get; set; }

        /// <summary>
        /// The Authentication Client Secret
        /// </summary>
        public string ClientSecret { get; set; }

        /// <summary>
        /// The Authentication Client ID
        /// </summary>
        public string CompanyID { get; set; }

        /// <summary>
        /// The Authentication Client ID
        /// </summary>
        public string CompanyName { get; set; }

        /// <summary>
        /// The Authentication Token
        /// </summary>
        public string AccessToken { get; set; }

        /// <summary>
        /// The Authentication Token Expiry Time
        /// </summary>
        public DateTime TokenExpiry { get; set; }
    }

}

using Newtonsoft.Json;
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

        /// <summary>
        /// Post as Draft
        /// </summary>
        public bool? PostAsDraft { get; set; }

        public string OAuthClientId { get; set; }

        public string OAuthClientSecret { get; set; }

        public string OAuthRedirectURI { get; set; }
        public string OAuthAccessToken { get; set; }
        public string OAuthRefreshToken { get; set; }
        public string OAuthScope { get; set; }
        public DateTime OAuthExpiry { get; set; }
    }

    public class XeroOrgConfig
    {
        /// <summary>
        /// Organization ID to tie this configuration to
        /// </summary>
        public int Org { get; set; }

        public string OAuthTenantId { get; set; }

        public string OAuthTenantName { get; set; }

    }

    public class XeroToken
    {
        [JsonProperty("access_token")]
        public string AccessToken { get; set; }

        [JsonProperty("id_token")]
        public string IdToken { get; set; }

        [JsonProperty("token_type")]
        public string TokenType { get; set; }

        [JsonProperty("expires_in")]
        public int ExpiresIn { get; set; }

        [JsonProperty("refresh_token")]
        public string RefreshToken { get; set; }
    }

    public class XeroTenant
    {
        [JsonProperty("tenantId")]
        public string TenantId { get; set; }

        [JsonProperty("tenantName")]
        public string TenantName { get; set; }
    }
}

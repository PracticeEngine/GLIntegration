using Microsoft.AspNetCore.Hosting;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Xero.NetStandard.OAuth2.Client;
using Xero.NetStandard.OAuth2.Config;

namespace PE.Nominal.XeroGL
{
    public abstract class XeroBaseService
    {
        private readonly IHostingEnvironment _env;
        protected readonly XeroConfig _config;

        public XeroBaseService(XeroConfig config, IHostingEnvironment env)
        {
            _config = config;
            _env = env;
        }
        
        /// <summary>
        /// Checks for Configuration Details for an Organization
        /// </summary>
        /// <param name="org"></param>
        /// <returns></returns>
        protected bool HasOrgConfig(int org)
        {
            var orgConfig = _config.OrgConfigs.FirstOrDefault(c => c.Org == org);
            if (orgConfig == null)
                return false;
            return true;
        }

        /// <summary>
        /// Returns Configuration Details for an Organization
        /// </summary>
        /// <param name="org"></param>
        /// <returns></returns>
        protected XeroOrgConfig GetOrgConfig(int org)
        {
            var orgConfig = _config.OrgConfigs.FirstOrDefault(c => c.Org == org);
            if (orgConfig == null)
                throw new Exception("No Xero Configuration found for Organization #" + org);

            return orgConfig;
        }

        protected async Task RefreshAccessToken()
        {
            if (!String.IsNullOrEmpty(_config.OAuthRefreshToken))
            {
                string authpassword = System.Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(_config.OAuthClientId + ":" + _config.OAuthClientSecret));
                var authbody = new FormUrlEncodedContent(new[] {
                new KeyValuePair<string, string>("grant_type", "refresh_token"),
                new KeyValuePair<string, string>("refresh_token", _config.OAuthRefreshToken)
            });
                HttpClient authClient = new HttpClient();
                authClient.BaseAddress = new System.Uri("https://identity.xero.com");
                authClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Basic", authpassword);
                try
                {
                    var authResponse = await authClient.PostAsync("/connect/token", authbody);
                    string jsonContent = await authResponse.Content.ReadAsStringAsync();
                    XeroToken tok = JsonConvert.DeserializeObject<XeroToken>(jsonContent);
                    _config.OAuthAccessToken = tok.AccessToken;
                    _config.OAuthExpiry = DateTime.Now.AddSeconds(tok.ExpiresIn);
                    _config.OAuthRefreshToken = tok.RefreshToken;
                }
                catch { }
            }
        }
    }
}

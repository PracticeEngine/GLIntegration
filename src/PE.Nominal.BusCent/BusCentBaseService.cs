using Microsoft.AspNetCore.Hosting;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace PE.Nominal.BusCent
{
    public abstract class BusCentBaseService
    {
        private readonly IHostingEnvironment _env;
        protected readonly BusCentConfig _config;

        public BusCentBaseService(BusCentConfig config, IHostingEnvironment env)
        {
            _config = config;
            _env = env;
        }

        protected string BusCentCleanString(string input)
        {
            return Regex.Replace(input, @"[^ \w]", "");
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
        protected BusCentOrgConfig GetOrgConfig(int org)
        {
            var orgConfig = _config.OrgConfigs.FirstOrDefault(c => c.Org == org);
            if (orgConfig == null)
                throw new Exception("No Business Central Configuration found for Organisation #" + org);

            return orgConfig;
        }


        /// <summary>
        /// Returns an Web Client Connected to the correct Organization
        /// </summary>
        /// <param name="org"></param>
        /// <returns></returns>
        protected async Task<HttpClient> GetClient(int org)
        {
            var orgConfig = GetOrgConfig(org);

            if (orgConfig.TokenExpiry < DateTime.Now.AddMinutes(10))
            {
                var authClient = new HttpClient();
                var authbody = new FormUrlEncodedContent(new[] {
                new KeyValuePair<string, string>("grant_type", "client_credentials"),
                new KeyValuePair<string, string>("client_id", orgConfig.ClientID),
                new KeyValuePair<string, string>("client_secret", orgConfig.ClientSecret),
                new KeyValuePair<string, string>("scope", "https://api.businesscentral.dynamics.com/.default")
            });
                authClient.BaseAddress = new System.Uri(orgConfig.AuthenticationURL);
                var authResponse = await authClient.PostAsync($"/{orgConfig.TenantID}/oauth2/v2.0/token", authbody);
                string jsonContent = await authResponse.Content.ReadAsStringAsync();
                BusCentToken tok = JsonConvert.DeserializeObject<BusCentToken>(jsonContent);
                orgConfig.AccessToken = tok.AccessToken;
                orgConfig.TokenExpiry = DateTime.Now.AddSeconds(tok.ExpiresIn);
                authClient.Dispose();
            }

            var busCentClient = new HttpClient();
            busCentClient.BaseAddress = new System.Uri(orgConfig.BusinessCentralURL);
            busCentClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", orgConfig.AccessToken);

            return busCentClient;
        }


        /// <summary>
        /// Returns an Web Client Connected to the correct Organization
        /// </summary>
        /// <param name="org"></param>
        /// <returns></returns>
        protected async Task<HttpClient> GetCashClient(int org)
        {
            var orgConfig = GetOrgConfig(org);

            var authClient = new HttpClient();
            var authbody = new FormUrlEncodedContent(new[] {
                new KeyValuePair<string, string>("grant_type", "client_credentials"),
                new KeyValuePair<string, string>("client_id", orgConfig.ClientID),
                new KeyValuePair<string, string>("client_secret", orgConfig.ClientSecret),
                new KeyValuePair<string, string>("scope", "https://api.businesscentral.dynamics.com/.default")
            });
            authClient.BaseAddress = new System.Uri(orgConfig.AuthenticationURL);
            var authResponse = await authClient.PostAsync($"/{orgConfig.TenantID}/oauth2/v2.0/token", authbody);
            string jsonContent = await authResponse.Content.ReadAsStringAsync();
            BusCentToken tok = JsonConvert.DeserializeObject<BusCentToken>(jsonContent);
            orgConfig.AccessToken = tok.AccessToken;
            orgConfig.TokenExpiry = DateTime.Now.AddSeconds(tok.ExpiresIn);
            authClient.Dispose();

            var busCentClient = new HttpClient();
            busCentClient.BaseAddress = new System.Uri(orgConfig.BusinessCentralURL);
            busCentClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", orgConfig.AccessToken);

            return busCentClient;
        }
    }
}

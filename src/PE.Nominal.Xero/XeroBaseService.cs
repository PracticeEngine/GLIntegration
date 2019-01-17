using Microsoft.AspNetCore.Hosting;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Xero.Api;
using Xero.Api.Core;
using Xero.Api.Infrastructure.Authenticators;
using Xero.Api.Infrastructure.Interfaces;
using Xero.Api.Infrastructure.OAuth;
using Xero.Api.Infrastructure.RateLimiter;

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

        protected IXeroCoreApi GetClient(int Org)
        {
            var orgConfig = GetOrgConfig(Org);

            return new XeroCoreApi(orgConfig.XeroURL, new PrivateAuthenticator(orgConfig.XeroCertPath),
                new Consumer(orgConfig.SenderID, orgConfig.SenderPassword), null, new RateLimiter(TimeSpan.FromMinutes(1), 50));
/*
            return new XeroCoreApi("https://api.xero.com", new PrivateAuthenticator(@"C:\Program Files\OpenSSL-Win64\bin\xero_pekey.pfx"),
                new Consumer("MFVXVWJY61DA8ZEKXNDDL8CQRYGLHS", "1HBYQBFVQWERWLOIVJ3OJWJFPGJVCH"));
*/
        }
    }
}

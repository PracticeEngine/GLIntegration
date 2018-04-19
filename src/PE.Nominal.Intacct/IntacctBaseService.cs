using Intacct.SDK;
using Intacct.SDK.Functions;
using Intacct.SDK.Xml;
using Microsoft.AspNetCore.Hosting;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace PE.Nominal.Intacct
{
    public abstract class IntacctBaseService
    {
        private readonly IHostingEnvironment _env;
        protected readonly IntacctConfig _config;

        public IntacctBaseService(IntacctConfig config, IHostingEnvironment env)
        {
            _config = config;
            _env = env;
        }

        protected string IntacctCleanString(string input)
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
        protected IntacctOrgConfig GetOrgConfig(int org)
        {
            var orgConfig = _config.OrgConfigs.FirstOrDefault(c => c.Org == org);
            if (orgConfig == null)
                throw new Exception("No Intacct Configuration found for Organization #" + org);

            return orgConfig;
        }


        /// <summary>
        /// Returns an Intacct Client Connected to the correct database for the Organization
        /// </summary>
        /// <param name="org"></param>
        /// <returns></returns>
        protected OnlineClient GetClient(int org)
        {
            var orgConfig = GetOrgConfig(org);

            var intacctClient = new OnlineClient(new ClientConfig
            {
                SenderId = orgConfig.SenderID,
                SenderPassword = orgConfig.SenderPassword,
                CompanyId = orgConfig.CompanyID,
                UserId = orgConfig.UserID,
                UserPassword = orgConfig.UserPassword,
                Logger = NLog.LogManager.GetLogger("Intacct")
            });

            return intacctClient;
        }


    }
}

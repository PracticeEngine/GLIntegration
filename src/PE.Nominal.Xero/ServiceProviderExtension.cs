using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using PE.Nominal.XeroGL;
using PE.Nominal.Provider;
using System;
using System.Collections.Generic;
using System.Text;

namespace PE.Nominal
{
    public static class ServiceProviderExtension
    {
        /// <summary>
        /// Adds the IntacctproviderTypes as an IProviderTypes to the Service Collection
        /// Also adds teh IntacctSyncService for Use
        /// </summary>
        /// <param name="services"></param>
        /// <param name="config"></param>
        public static void AddXeroGLProvider(this IServiceCollection services, IConfiguration config)
        {
            services.AddTransient<IProviderType, XeroProviderType>();
            services.Configure<XeroConfig>(config.GetSection("Xero"));
        }
    }
}

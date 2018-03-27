using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using PE.Nominal.Intacct;
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
        public static void AddIntacctGLProvider(this IServiceCollection services, IConfiguration config)
        {
            services.AddTransient<IProviderType, IntacctProviderType>();
            services.AddTransient<IntacctSyncService>();
            services.Configure<IntacctConfig>(config.GetSection("Intacct"));
            services.AddMemoryCache();
        }
    }
}

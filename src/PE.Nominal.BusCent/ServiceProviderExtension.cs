using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using PE.Nominal.BusCent;
using PE.Nominal.Provider;

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
        public static void AddBusCentGLProvider(this IServiceCollection services, IConfiguration config)
        {
            services.AddTransient<IProviderType, BusCentProviderType>();
            services.Configure<BusCentConfig>(config.GetSection("BusCent"));
            services.AddMemoryCache();
        }
    }
}

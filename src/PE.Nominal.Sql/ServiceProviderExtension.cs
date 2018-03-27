using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using PE.Nominal.Provider;

namespace PE.Nominal
{
    public static class ServiceProviderExtension
    {
        /// <summary>
        /// Adds the DirectSqlProvider as an IProviderType to the Service Collection
        /// </summary>
        /// <param name="services"></param>
        /// <param name="config"></param>
        public static void AddSqlGLProvider(this IServiceCollection services, IConfiguration config)
        {
            services.AddTransient<IProviderType, DirectSqlProvider>();
        }
    }
}

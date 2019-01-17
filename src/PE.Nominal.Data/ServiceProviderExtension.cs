using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace PE.Nominal
{
    public static class ServiceProviderExtension
    {
        /// <summary>
        /// Adds the Data Access Layer Classes to the Service Collection
        /// </summary>
        /// <param name="services"></param>
        /// <param name="config"></param>
        public static void AddDataAccessLayer(this IServiceCollection services, IConfiguration config)
        {
            services.AddTransient<UserDAL>();
            services.AddTransient<MenuDAL>();
            services.AddTransient<IntacctDAL>();
            services.AddTransient<NominalDAL>();
            services.AddTransient<MTDDAL>();

        }
    }
}

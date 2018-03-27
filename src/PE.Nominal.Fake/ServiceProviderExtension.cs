using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using PE.Nominal.Fake;
using PE.Nominal.Provider;

namespace PE.Nominal
{
    public static class ServiceProviderExtension
    {
        /// <summary>
        /// Adds the FakeGLProvider as an IProviderTypes to the Service Collection
        /// </summary>
        /// <param name="services"></param>
        /// <param name="config"></param>
        public static void AddFakeGLProvider(this IServiceCollection services, IConfiguration config)
        {
            services.AddTransient<IProviderType, FakeGLProvider>();
        }
    }
}

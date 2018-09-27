using Hangfire;
using Hangfire.Console;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Newtonsoft.Json.Serialization;
using PE.Nominal.Web.Filters;
using PE.Nominal.Web.Options;
using System;
using System.Security.Cryptography;
using System.ServiceModel;

namespace PE.Nominal.Web
{
    public class Startup
    {
        public Startup(IHostingEnvironment env)
        {
            var builder = new ConfigurationBuilder()
                .SetBasePath(env.ContentRootPath)
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
                .AddJsonFile($"appsettings.{env.EnvironmentName}.json", optional: true)
                .AddEnvironmentVariables();

            if (env.IsDevelopment())
            {
                builder.AddUserSecrets<Startup>();
            }

            Configuration = builder.Build();
        }

        public IConfigurationRoot Configuration { get; }

        
        /// <summary>
        /// Standard Convention-based Service Registration
        /// </summary>
        /// <param name="services"></param>
        public void ConfigureServices(IServiceCollection services)
        {
            // Add Basic/Standard ASP.Net services.
            services.AddOptions();
            services.AddLogging();
            services.AddMemoryCache();
            services.AddMvc()
                .AddJsonOptions(opt =>
                {
                    var res = opt.SerializerSettings.ContractResolver as DefaultContractResolver;
                    res.NamingStrategy = null;
                    opt.SerializerSettings.DateFormatString = "yyyy-MM-dd";
                });
            services.AddDbContext<DbContext>(options =>
                options.UseSqlServer(Configuration.GetConnectionString("EngineDb"),
                sqlServerOption => sqlServerOption.CommandTimeout(3600))
            );
            services.AddDataProtection();

            // Add The Custom DAL and Services in the Solution
            services.AddDataAccessLayer(Configuration);
            services.AddNominalLedgerServices(Configuration);
            services.AddPELoginSupport(Configuration);

            // Add Hangfire for Background Jobs
            services.AddHangfire(config =>
                config
                .UseSqlServerStorage(Configuration.GetConnectionString("EngineDb"))
                .UseConsole());

            // Add Provider according to the Configuration
            var provider = Configuration.GetValue<string>("ProviderType");
            switch (provider.ToLower())
            {
                case "fake":
                    services.AddFakeGLProvider(Configuration);
                    break;
                case "intacct":
                    services.AddIntacctGLProvider(Configuration);
                    break;
                default:
                    services.AddSqlGLProvider(Configuration);
                    break;
            }


            // Add Reporting
            //RegisterRepGen(services);
        }

        /// <summary>
        /// Standard App Configure Method
        /// </summary>
        /// <param name="app"></param>
        /// <param name="env"></param>
        /// <param name="loggerFactory"></param>
        public void Configure(IApplicationBuilder app, IHostingEnvironment env, ILoggerFactory loggerFactory)
        {
            loggerFactory.AddEventSourceLogger();
            if (env.IsDevelopment())
            {
                loggerFactory.AddDebug(LogLevel.Trace);
                app.UseDeveloperExceptionPage();
            }
            else
            {
                loggerFactory.AddDebug(LogLevel.Warning);
            }

            app.UseStaticFiles();

            app.UseAuthentication();

            // Add Hangfire for Background work
            app.UseHangfireDashboard(options: new DashboardOptions
            {
                Authorization = new[] { new HangfireAuthorizationFilter() },
                AppPath = env.WebRootPath
            });
            app.UseHangfireServer();


            app.UseMvc(routes =>
            {
                routes.MapRoute(
                    name: "default",
                    template: "{controller=Home}/{action=Index}/{id?}");
            });
        }

        /// <summary>
        /// This method registers our RepGen Services (we support 2 - pre/post 9.6)
        /// </summary>
        /// <param name="services"></param>
        private void RegisterRepGen(IServiceCollection services)
        {

            services.Configure<ReportOptions>(Configuration.GetSection("ReportService"));
            services.Configure<ReportConnectionOptions>((rco) =>
            {
                using (DESCryptoServiceProvider DES = new DESCryptoServiceProvider()
                {
                    Key = new byte[] { 0xEF, 0x9C, 0xD1, 0x2F, 0x91, 0x76, 0x85, 0x1C },
                    Mode = CipherMode.ECB
                })
                {
                    using (ICryptoTransform DESEncrypt = DES.CreateEncryptor())
                    {
                        byte[] Buffer = System.Text.ASCIIEncoding.ASCII.GetBytes(Configuration.GetConnectionString("EngineDb"));
                        rco.EncryptedConnectionString = Convert.ToBase64String(DESEncrypt.TransformFinalBlock(Buffer, 0, Buffer.Length));
                    }
                }
            });

            // 9.5 Resolution
            services.AddScoped<RepGen95.PERepGenSoap>(sp =>
            {
                var options = sp.GetRequiredService<IOptions<ReportOptions>>();
                var reportOptions = options.Value;
                // Build up the Service
                var binding = new BasicHttpBinding(BasicHttpSecurityMode.Transport);
                binding.MaxBufferPoolSize = 524288;
                binding.MaxBufferSize = Int32.MaxValue;
                binding.MaxReceivedMessageSize = Int32.MaxValue;
                binding.ReaderQuotas.MaxStringContentLength = Int32.MaxValue;
                binding.ReaderQuotas.MaxArrayLength = Int32.MaxValue;
                binding.ReaderQuotas.MaxBytesPerRead = 4096;
                binding.ReaderQuotas.MaxNameTableCharCount = 16384;
                binding.SendTimeout = TimeSpan.FromMinutes(15);
                EndpointAddress address = new EndpointAddress(reportOptions.URL);
                return new RepGen95.PERepGenSoapClient(binding, address);
            });

            // 9.6 Resolution
            services.AddScoped<RepGen96.PERepGenSoap>(sp =>
            {
                var options = sp.GetRequiredService<IOptions<ReportOptions>>();
                var reportOptions = options.Value;
                // Build up the Service
                var binding = new BasicHttpBinding(BasicHttpSecurityMode.Transport);
                binding.MaxBufferPoolSize = 524288;
                binding.MaxBufferSize = Int32.MaxValue;
                binding.MaxReceivedMessageSize = Int32.MaxValue;
                binding.ReaderQuotas.MaxStringContentLength = Int32.MaxValue;
                binding.ReaderQuotas.MaxArrayLength = Int32.MaxValue;
                binding.ReaderQuotas.MaxBytesPerRead = 4096;
                binding.ReaderQuotas.MaxNameTableCharCount = 16384;
                binding.SendTimeout = TimeSpan.FromMinutes(15);
                EndpointAddress address = new EndpointAddress(reportOptions.URL);
                return new RepGen96.PERepGenSoapClient(binding, address);
            });
            // 9.6 Authentication
            services.AddScoped<RepGen96.AuthenticationInformation>(sp =>
            {
                return new RepGen96.AuthenticationInformation
                {
                    Authorization = "305df5f62dacf9c2eea8ac82d1524317363a592d8d62a556c0e3ed2e9b41a360"
                };
            });
        }
    }
}

using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;
using PE.Nominal.Options;

namespace PE.Nominal
{
    public static class ServiceProviderExtension
    {
        /// <summary>
        /// Adds the NominalLedger Services to the Service Collection
        /// </summary>
        /// <param name="services"></param>
        /// <param name="config"></param>
        public static void AddNominalLedgerServices(this IServiceCollection services, IConfiguration config)
        {
            services.AddTransient<ActionsService>();
            services.AddTransient<MTDService>();
            services.AddTransient<LoginService>();
            services.AddTransient<PageService>();
            services.Configure<LoginOptions>(config.GetSection("PEAuth"));
            services.Configure<ViewOptions>(config);
            services.Configure<JournalOptions>(config);

        }

        /// <summary>
        /// Configures the Authentication for the App based on the Configuration
        /// </summary>
        /// <param name="services"></param>
        /// <param name="config"></param>
        public static void AddPELoginSupport(this IServiceCollection services, IConfiguration config)
        {
            // Add Password Hashing If LocalLogin is Enabled
            if (config.GetValue<bool>("PEAuth:EnableLocalLogin"))
            {
                services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
                    .AddCookie(options =>
                    {
                        options.LoginPath = new PathString("/Account/Login");
                    });
                // Set Password Hash Compatible with SimpleMembershipProvider
                services.Configure<PasswordHasherOptions>((options) =>
                {
                    options.CompatibilityMode = PasswordHasherCompatibilityMode.IdentityV2;
                    options.IterationCount = 1000;
                });
                services.AddScoped<PasswordHasher<PEUser>>();
            }
            else
            {
                services.AddAuthentication(options =>
                {
                    options.DefaultAuthenticateScheme = CookieAuthenticationDefaults.AuthenticationScheme;
                    options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
                })
                .AddCookie(CookieAuthenticationDefaults.AuthenticationScheme)
                    .AddOpenIdConnect(OpenIdConnectDefaults.AuthenticationScheme, options =>
                    {
                        options.Authority = config["OpenIdAuthority"];
                        options.ClientId = "pe.app";
                        options.ResponseType = OpenIdConnectResponseType.IdToken;
                        options.SignInScheme = CookieAuthenticationDefaults.AuthenticationScheme;
                        options.TokenValidationParameters = new TokenValidationParameters
                        {
                            NameClaimType = "name",
                            RoleClaimType = "role"
                        };
                        options.SaveTokens = true;
                    });
            }
        }
    }
}

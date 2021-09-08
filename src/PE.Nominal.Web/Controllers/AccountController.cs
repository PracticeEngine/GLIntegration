using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Newtonsoft.Json;
using PE.Nominal.Web.ViewModels;
using PE.Nominal.XeroGL;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Security.Claims;
using System.Threading.Tasks;

namespace PE.Nominal.Web.Controllers
{
    [AutoValidateAntiforgeryToken]
    public class AccountController : Controller
    {
        private readonly LoginService _loginService;
        protected readonly XeroConfig _config;

        public AccountController(LoginService loginService, IOptions<XeroConfig> config)
        {
            _loginService = loginService;
            _config = config.Value;
        }

        public IActionResult Login()
        {
            return View(new LoginViewModel());
        }

        [HttpPost]
        public async Task<IActionResult> Login(LoginViewModel model)
        {
            if (ModelState.IsValid)
            {
                var loginResult = await _loginService.ValidateCredentials(model.Login, model.Password);
                if (loginResult == LocalLoginResult.Success || loginResult == LocalLoginResult.Failure)
                {
                    var user = await _loginService.GetUserAsync(model.Login);
                    await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(new ClaimsIdentity(new[] {
                        new Claim("name", user.StaffUser),
                        new Claim("staffindex", user.StaffIndex.ToString())
                    }, CookieAuthenticationDefaults.AuthenticationScheme, "name", "role")));
                    return RedirectToAction("Index", "Home");
                }
                if (loginResult == LocalLoginResult.NoSuchUser)
                {
                    ModelState.AddModelError("", "Not a valid User.");
                }
                else if (loginResult == LocalLoginResult.LockedOut)
                {
                    ModelState.AddModelError("", "User is locked out.");
                }
                else
                {
                    ModelState.AddModelError("", "Invalid username or password.");
                }
            }
            return View(model);
        }

        [HttpGet]
        public async Task<IActionResult> Xero(string code)
        {
            string authpassword = System.Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(_config.OAuthClientId + ":" + _config.OAuthClientSecret));
            var authbody = new FormUrlEncodedContent(new[] {
                new KeyValuePair<string, string>("grant_type", "authorization_code"),
                new KeyValuePair<string, string>("code", code),
                new KeyValuePair<string, string>("redirect_uri", _config.OAuthRedirectURI)
            });
            HttpClient authClient = new HttpClient();
            authClient.BaseAddress = new System.Uri("https://identity.xero.com");
            authClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Basic", authpassword);
            var authResponse = await authClient.PostAsync("/connect/token", authbody);
            string jsonContent = await authResponse.Content.ReadAsStringAsync();
            XeroToken tok = JsonConvert.DeserializeObject<XeroToken>(jsonContent);
            _config.OAuthAccessToken = tok.AccessToken;
            _config.OAuthExpiry = DateTime.Now.AddSeconds(tok.ExpiresIn);
            _config.OAuthRefreshToken = tok.RefreshToken;

            HttpClient tenantClient = new HttpClient();
            tenantClient.BaseAddress = new System.Uri("https://api.xero.com");
            tenantClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", _config.OAuthAccessToken);
            var tenantResponse = await tenantClient.GetAsync("/connections");
            jsonContent = await tenantResponse.Content.ReadAsStringAsync();
            XeroTenant[] xeroTenants = JsonConvert.DeserializeObject<XeroTenant[]>(jsonContent);
            foreach(var orgconf in _config.OrgConfigs)
            {
                orgconf.OAuthTenantId = "";
                foreach(XeroTenant t in xeroTenants)
                {
                    if (t.TenantName == orgconf.OAuthTenantName)
                    {
                        orgconf.OAuthTenantId = t.TenantId;
                    }
                }
            }
            bool allGood = true;
            foreach (var orgconf in _config.OrgConfigs)
            {
                if (orgconf.OAuthTenantId == "")
                {
                    allGood = false;
                    break;
                }
            }
            if (!allGood)
            {
                _config.OAuthAccessToken = "";
                return RedirectToAction("TenantError", "Home");
            }
            return RedirectToAction("Index", "Home");
        }
    }
}
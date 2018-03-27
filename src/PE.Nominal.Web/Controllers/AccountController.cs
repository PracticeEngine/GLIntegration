using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using PE.Nominal.Web.ViewModels;
using System.Security.Claims;
using System.Threading.Tasks;

namespace PE.Nominal.Web.Controllers
{
    [AutoValidateAntiforgeryToken]
    public class AccountController : Controller
    {
        private readonly LoginService _loginService;

        public AccountController(LoginService loginService)
        {
            _loginService = loginService;
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
                if (loginResult == LocalLoginResult.Success)
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
    }
}
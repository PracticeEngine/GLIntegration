using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Options;
using PE.Nominal.Options;
using System;
using System.Threading.Tasks;

namespace PE.Nominal
{
    /// <summary>
    /// Login Result
    /// </summary>
    public enum LocalLoginResult
    {
        Success,
        Failure,
        LockedOut,
        NoSuchUser
    }

    /// <summary>
    /// This class implements the ValidateCredentials Method to support local forms login 
    /// should change to use Open ID Connect via PE /Auth application and remove this long-term
    /// </summary>
    public class LoginService
    {
        private readonly UserDAL userDAL;
        private readonly PasswordHasher<PEUser> passwordHasher;
        private readonly LoginOptions loginOptions;

        /// <summary>
        /// Constructs a Login Service
        /// </summary>
        /// <param name="userDAL">The User DAL for Database interaction</param>
        /// <param name="passwordHasher">A PasswordHasher from ASP.Net Core Identity to check the user's password</param>
        /// <param name="options">Options as configured for login</param>
        public LoginService(UserDAL userDAL, PasswordHasher<PEUser> passwordHasher, IOptions<LoginOptions> options)
        {
            this.userDAL = userDAL;
            this.passwordHasher = passwordHasher;
            this.loginOptions = options.Value;
        }

        /// <summary>
        /// Check username and password against the Database
        /// </summary>
        public async Task<LocalLoginResult> ValidateCredentials(string username, string password)
        {
            // Get the matching user details
            var user = await GetUserAsync(username);
            if (user == null)
            {
                return LocalLoginResult.NoSuchUser;
            }

            // Provide lockout logic
            if (user.LastPasswordFailureDate.HasValue)
            {
                if (user.PasswordFailuresSinceLastSuccess > this.loginOptions.LockoutAfter && user.LastPasswordFailureDate.Value > DateTime.UtcNow.Subtract(this.loginOptions.LockoutFor))
                {
                    // User is locked out currently
                    await userDAL.IncrementLockout(user.StaffIndex);
                    return LocalLoginResult.LockedOut;
                }
                else if (user.LastPasswordFailureDate.Value < DateTime.UtcNow.Subtract(this.loginOptions.LockoutFor))
                {
                    // Reset their attempts (time has passed)
                    await userDAL.ClearLockout(user.StaffIndex);
                }
            }

            // Validate the Password
            var verificationResult = passwordHasher.VerifyHashedPassword(user, user.Password, password);

            // Update the Hash if Needed
            if (verificationResult == PasswordVerificationResult.SuccessRehashNeeded)
            {
                var newPasswordHash = passwordHasher.HashPassword(user, password);
                await userDAL.SetPasswordAsync(user.StaffIndex, newPasswordHash);
            }

            // Apply lockout Counting
            if (verificationResult == PasswordVerificationResult.Failed)
            {
                await userDAL.IncrementLockout(user.StaffIndex);
            }

            // Return Status
            if (verificationResult != PasswordVerificationResult.Failed)
            {
                if (user.LastPasswordFailureDate.HasValue)
                {
                    // Reset their attempts (on successful login)
                    await userDAL.ClearLockout(user.StaffIndex);
                }
                return LocalLoginResult.Success;
            }
            return LocalLoginResult.Failure;
        }

        /// <summary>
        /// Retrieves the User Details
        /// </summary>
        /// <param name="UserName"></param>
        /// <returns></returns>
        public async Task<PEUser> GetUserAsync(string UserName)
        {
            return await userDAL.GetUserAsync(UserName).ConfigureAwait(false);
        }
        
    }
}

using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace PE.Nominal
{

    /// <summary>
    /// Class Returns Users and Performs User Actions in the Database that support login
    /// </summary>
    public class UserDAL
    {
        private readonly DbContext context;

        /// <summary>
        /// The UserDAL expects a properly configured DbContext to be injected
        /// </summary>
        /// <param name="context"></param>
        public UserDAL(DbContext context)
        {
            this.context = context;
        }
        

        /// <summary>
        /// Retrieves the User, or Null if no user exists
        /// </summary>
        /// <param name="UserName"></param>
        /// <returns></returns>
        public async Task<PEUser> GetUserAsync(string UserName)
        {
            var query = await context.Database.SqlQueryAsync<PEUser>(
                sql: "SELECT S.[StaffIndex], S.[StaffUser], U.[Password], U.[LastPasswordFailureDate], U.[PasswordFailuresSinceLastSuccess] "+
                "FROM [dbo].[tblStaff] S INNER JOIN [dbo].[webpages_Membership] U ON S.StaffIndex = U.UserId WHERE S.[StaffUser] = {0}",
                parameters: new object[] { UserName }).ConfigureAwait(false);


            var user = query.FirstOrDefault();

            return user;
        }

        /// <summary>
        /// Increments a User's Lockout Count
        /// </summary>
        /// <param name="Username"></param>
        /// <returns></returns>
        public async Task IncrementLockout(int StaffIndex)
        {
            await context.Database.ExecuteSqlCommandAsync(
                    sql: "UPDATE [webpages_Membership] SET [PasswordFailuresSinceLastSuccess] = [PasswordFailuresSinceLastSuccess]+1, [LastPasswordFailureDate] = GETUTCDATE() WHERE [UserId] = {0}",
                    parameters: new object[] { StaffIndex }).ConfigureAwait(false);
        }

        /// <summary>
        /// Clears a User's Lockout Count
        /// </summary>
        /// <param name="Username"></param>
        /// <returns></returns>
        public async Task ClearLockout(int StaffIndex)
        {
            await context.Database.ExecuteSqlCommandAsync(
                    sql: "UPDATE [webpages_Membership] SET [PasswordFailuresSinceLastSuccess] = 0, [LastPasswordFailureDate] = NULL WHERE [UserId] = {0}",
                    parameters: new object[] { StaffIndex }).ConfigureAwait(false);
        }

        /// <summary>
        /// Saves a Users Password Hash
        /// </summary>
        /// <param name="StaffIndex"></param>
        /// <param name="PasswordHash"></param>
        /// <returns></returns>
        public async Task SetPasswordAsync(int StaffIndex, string PasswordHash)
        {
            await context.Database.ExecuteSqlCommandAsync(
                    sql: "UPDATE [webpages_Membership] SET [Password] = {0}, [IsConfirmed] = 1, [PasswordVerificationTokenExpirationDate] = NULL, [PasswordVerificationToken] = NULL WHERE [UserId] = {1}",
                    parameters: new object[] { PasswordHash, StaffIndex }).ConfigureAwait(false);
        }
    }
}

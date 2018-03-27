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
    public class MenuDAL
    {
        private readonly DbContext context;

        /// <summary>
        /// The MenuDAL expects a properly configured DbContext to be injected
        /// </summary>
        /// <param name="context"></param>
        public MenuDAL(DbContext context)
        {
            this.context = context;
        }


        /// <summary>
        /// Returns the List of Nominal Ledger Menu Items from the Database
        /// </summary>
        /// <param name="UserName">Username that is logged in</param>
        /// <returns></returns>
        public async Task<IEnumerable<MenuItem>> GetMenuItemsAsync(string UserName)
        {
            var results = await context.Database.SqlQueryAsync<MenuItem>(
                sql: "pe_NL_Menu_List {0}",
                parameters: new object[] { UserName }).ConfigureAwait(false);

            return results;
        }

        /// <summary>
        /// Returns the Nominal Ledger Selected Dates from the Database
        /// </summary>
        /// <param name="UserName">Username that is logged in</param>
        /// <returns></returns>
        public async Task<SelectedDates> GetSelectedDatesAsync(string UserName)
        {
            var results = await context.Database.SqlQueryAsync<SelectedDates>("pe_NL_Select_Dates").ConfigureAwait(false);

            return results.FirstOrDefault();
        }
        
    }
}

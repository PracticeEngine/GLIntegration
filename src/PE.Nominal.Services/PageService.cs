using PE.Nominal.ViewModels;
using System.Threading.Tasks;

namespace PE.Nominal
{
    /// <summary>
    /// This Class builds up a SPAViewModel to generate the Page
    /// </summary>
    public class PageService
    {
        private readonly MenuDAL menuDAL;

        /// <summary>
        /// Constructs a new PageService
        /// </summary>
        /// <param name="menuDAL"></param>
        public PageService(MenuDAL menuDAL)
        {
            this.menuDAL = menuDAL;
        }


        /// <summary>
        /// Returns the Main ViewModel for the Page with all data
        /// </summary>
        /// <param name="username">The name of the logged in user</param>
        /// <returns></returns>
        public async Task<SPAViewModel> GetViewModel(string username)
        {
            var result = new SPAViewModel()
            {
                TaskPads = await menuDAL.GetMenuItemsAsync(username).ConfigureAwait(false),
                Dates = await menuDAL.GetSelectedDatesAsync(username).ConfigureAwait(false)
            };

            return result;
        }
    }
}

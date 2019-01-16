using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class MTDInvoiceLine
    {
        /// <summary>
        /// ID of the Org
        /// </summary>
        public int ClientID { get; set; }

        /// <summary>
        /// The 'Source' such as WIP or DRS from Practice Engine
        /// </summary>
        public string ClientCode { get; set; }

        /// <summary>
        /// The Nominal Section (BS or GL) financial statement Type
        /// </summary>
        public string ClientName { get; set; }
    }
}

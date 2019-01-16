using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class MTDClient
    {
        /// <summary>
        /// ID of the client in the GL system
        /// </summary>
        public string GLClientID { get; set; }

        /// <summary>
        /// ID of the client in PE
        /// </summary>
        public int PEClientID { get; set; }

        /// <summary>
        /// The Code of the client
        /// </summary>
        public string ClientCode { get; set; }

        /// <summary>
        /// The Name of the client
        /// </summary>
        public string ClientName { get; set; }

        /// <summary>
        /// The Status of the client
        /// </summary>
        public string ClientStatus { get; set; }

        /// <summary>
        /// The Name of the client
        /// </summary>
        public string Address { get; set; }

        /// <summary>
        /// The Name of the client
        /// </summary>
        public string TownCity { get; set; }

        /// <summary>
        /// The Name of the client
        /// </summary>
        public string County { get; set; }

        /// <summary>
        /// The Name of the client
        /// </summary>
        public string Country { get; set; }

        /// <summary>
        /// The Name of the client
        /// </summary>
        public string PostCode { get; set; }
    }
}

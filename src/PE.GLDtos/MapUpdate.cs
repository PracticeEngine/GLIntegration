using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class MapUpdate
    {
        /// <summary>
        /// The Mapping Index
        /// </summary>
        public int MapIndex { get; set; }

        /// <summary>
        /// The Selected Account Code
        /// </summary>
        public string AccountCode { get; set; }

        /// <summary>
        /// The Selected Account Type
        /// </summary>
        public string AccountTypeCode { get; set; }
    }
}

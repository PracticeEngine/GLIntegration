using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public abstract class MapBase
    {
        /// <summary>
        /// The Mapping ID
        /// </summary>
        public int MapIndex { get; set; }

        /// <summary>
        /// GL Account Type
        /// </summary>
        public string AccountTypeCode { get; set; }

        /// <summary>
        /// GL Account Code
        /// </summary>
        public string AccountCode { get; set; }

    }
}

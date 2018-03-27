using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class NomOrganisation
    {
        public int PracID { get; set; }

        public string PracName { get; set; }

        public string NLServer { get; set; }

        public string NLDatabase { get; set; }

        public bool NLTransfer { get; set; }
    }
}

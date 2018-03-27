using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class JournalRepostBatch
    {
        public int NomBatch { get; set; }

        public int NumLines { get; set; }

        public decimal Debits { get; set; }

        public decimal Credits { get; set; }

        public DateTime PostDate { get; set; }
    }
}

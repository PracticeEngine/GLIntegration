using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class MTDInvoice
    {
        public int DebtTranIndex { get; set; }

        public int ContIndex { get; set; }

        public string Address { get; set; }

        public string DebtTranRefAlpha { get; set; }

        public int DebtTranRefNum { get; set; }

        public DateTime DebtTranDate { get; set; }

        public decimal DebtTranAmount { get; set; }

        public decimal DebtTranVAT { get; set; }

        public IEnumerable<MTDLineItem> Lines { get; set; }
    }
}

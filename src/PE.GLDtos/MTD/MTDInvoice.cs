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

        public DateTime InvoiceDate { get; set; }

        public decimal InvoiceNet { get; set; }

        public decimal InvoiceVAT { get; set; }

        public IEnumerable<MTDLineItem> Lines { get; set; }

        public MTDClient Client { get; set; }
    }
}

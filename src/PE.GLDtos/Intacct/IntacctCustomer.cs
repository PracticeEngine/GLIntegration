using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal.Intacct
{
    public class IntacctCustomer
    {
        public int Org { get; set; }

        public string CUSTOMERID { get; set; }

        public string CUSTNAME { get; set; }

        public string CUSTTYPENAME { get; set; }

        public string STATUS { get; set; }

        public string CONTACTNAME { get; set; }

        public string EMAIL1 { get; set; }

        public string ADDRESS1 { get; set; }

        public string CITY { get; set; }

        public string STATE { get; set; }

        public string COUNTRY { get; set; }

        public string ZIP { get; set; }

        public string FIRSTNAME { get; set; }

        public string LASTNAME { get; set; }

        public string PARENTID { get; set; }
    }
}

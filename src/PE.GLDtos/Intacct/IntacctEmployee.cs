using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal.Intacct
{
    public class IntacctEmployee
    {
        public int Org { get; set; }

        public string EMPLOYEEID { get; set; }

        public string EMPLOYEENAME { get; set; }

        public DateTime EMPLOYEESTART { get; set; }

        public DateTime? EMPLOYEETERMINATION { get; set; }

        public string EMPLOYEEACTIVE { get; set; }

        public string DEPARTMENTID { get; set; }

        public string LOCATIONID { get; set; }

        public string PE_STAFF_CODE { get; set; }

        public string FIRSTNAME { get; set; }

        public string LASTNAME { get; set; }

        public string PHONE { get; set; }

        public string EMAIL { get; set; }
    }
}

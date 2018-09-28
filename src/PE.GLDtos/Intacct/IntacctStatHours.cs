using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal.Intacct
{

    /// <summary>
    /// This is a custom Journal Extract type for Hogan Taylor to push Hours to Intacct Statistics Journal
    /// </summary>
    public class IntacctStatHours
    {
        public string Journal { get; set; }

        public string ProjectID { get; set; }

        public string EmployeeID { get; set; }

        public decimal Hours { get; set; }

        public string Account { get; set; }

        public DateTime BatchDate { get; set; }

        public string BatchID { get; set; }

        public string IntacctCustomerID {get; set; }

        public string IntacctDepartment { get; set; }

        public string IntacctLocation { get; set; }

        public string client_partner_id { get; set; }

        public string category_name_id { get; set; }

        public string owner_name_id { get; set; }

        public string service_type_id { get; set; }

    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal
{
    public class JournalExtract : MapBase
    {

        /// <summary>
        /// This is the Batch (for the GL)
        /// </summary>
        public int NomBatch { get; set; }

        /// <summary>
        /// The Narrative  (for the GL)
        /// </summary>
        public string NomNarrative { get; set; }

        /// <summary>
        /// The Reference (for the GL)
        /// </summary>
        public string NomTransRef { get; set; }


        /// <summary>
        /// Amount of the Nominal Account (for the GL)
        /// </summary>
        public decimal NomAmount { get; set; }

        /// <summary>
        /// The Date and Time of the Nominal Entry (for the GL)
        /// </summary>
        public DateTime NomDate { get; set; }


        /// <summary>
        /// Optional, Extra Intacct Data
        /// </summary>
        public string IntacctCustomerID { get; set; }

        /// <summary>
        /// Optional, Extra Intacct Data
        /// </summary>
        public string IntacctProjectID { get; set; }

        /// <summary>
        /// Optional, Extra Intacct Data
        /// </summary>
        public string IntacctEmployeeID { get; set; }
        
        /// <summary>
        /// Optional, Extra Intacct Data
        /// </summary>
        public string IntacctDepartment { get; set; }
        
        /// <summary>
        /// Optional, Extra Intacct Data
        /// </summary>
        public string IntacctLocation { get; set; }

        public string client_partner_id { get; set; }

        public string category_name_id { get; set; }

        public string owner_name_id { get; set; }

        public string service_type_id { get; set; }

        public string client_partner { get; set; }

        public string category_name { get; set; }

        public string owner_name { get; set; }

        public string service_type { get; set; }
    }
}

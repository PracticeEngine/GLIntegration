using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PE.Nominal.Intacct
{
    public class IntacctProject
    {
        public int Org { get; set; }

        public string PROJECTID { get; set; }

        public string PROJECTNAME { get; set; }

        public string CUSTOMERID { get; set; }

        public string PROJECTCATEGORY { get; set; }

        public string PROJECTSTATUS { get; set; }

        public string PROJECTACTIVE { get; set; }

        public string DEPARTMENTID { get; set; }

        public string LOCATIONID { get; set; }

        public string PROJECTMANAGERID { get; set; }

        public string PROJECTPARENTID { get; set; }

        public string PE_JOB_CODE { get; set; }

        public string USER_RESTRICTIONS { get; set; }

    }
}

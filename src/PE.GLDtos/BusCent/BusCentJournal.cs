using System;
using System.Collections.Generic;
using System.Text;

namespace PE.Nominal.BusCent
{
    public class BusCentJournal
    {
        public string odatacontext { get; set; }
        public BCJournal[] value { get; set; }
    }

    public class BCJournal
    {
        public string id { get; set; }
        public string code { get; set; }
        public string displayName { get; set; }
        public string templateDisplayName { get; set; }
        public DateTime lastModifiedDateTime { get; set; }
        public string balancingAccountId { get; set; }
        public string balancingAccountNumber { get; set; }
    }

}

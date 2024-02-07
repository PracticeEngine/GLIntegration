using System;
using System.Collections.Generic;
using System.Text;

namespace PE.Nominal.BusCent
{
    public class BusCentCompanies
    {
        public string odatacontext { get; set; }
        public BusCentCompany[] value { get; set; }
    }

    public class BusCentCompany
    {
        public string id { get; set; }
        public string systemVersion { get; set; }
        public int timestamp { get; set; }
        public string name { get; set; }
        public string displayName { get; set; }
        public string businessProfileId { get; set; }
        public DateTime systemCreatedAt { get; set; }
        public string systemCreatedBy { get; set; }
        public DateTime systemModifiedAt { get; set; }
        public string systemModifiedBy { get; set; }
    }
}

using System;
using System.Collections.Generic;
using System.Text;

namespace PE.Nominal.BusCent
{
    public class BusCentAccounts
    {
        public string odatacontext { get; set; }
        public BusCentAccount[] value { get; set; }
    }

    public class BusCentAccount
    {
        public string odataetag { get; set; }
        public string id { get; set; }
        public string number { get; set; }
        public string displayName { get; set; }
        public string category { get; set; }
        public string subCategory { get; set; }
        public bool blocked { get; set; }
        public string accountType { get; set; }
        public bool directPosting { get; set; }
        public float netChange { get; set; }
        public string consolidationTranslationMethod { get; set; }
        public string consolidationDebitAccount { get; set; }
        public string consolidationCreditAccount { get; set; }
        public DateTime lastModifiedDateTime { get; set; }
    }
}

using System;

public class BusCentJournalLines
{
    public string odatacontext { get; set; }
    public BCJournalLine[] value { get; set; }
}

public class BCJournalLine
{
    public string id { get; set; }
    public string journalId { get; set; }
    public string journalDisplayName { get; set; }
    public int lineNumber { get; set; }
    public string accountType { get; set; }
    public string accountId { get; set; }
    public string accountNumber { get; set; }
    public string postingDate { get; set; }
    public string documentNumber { get; set; }
    public string externalDocumentNumber { get; set; }
    public decimal amount { get; set; }
    public string description { get; set; }
    public string comment { get; set; }
    public string taxCode { get; set; }
    public string balanceAccountType { get; set; }
    public string balancingAccountId { get; set; }
    public string balancingAccountNumber { get; set; }
    public DateTime lastModifiedDateTime { get; set; }
}


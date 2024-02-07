using System;

public class BusCentDimensions
{
    public string odatacontext { get; set; }
    public BCDimension[] value { get; set; }
}

public class BCDimension
{
    public string id { get; set; }
    public string code { get; set; }
    public string displayName { get; set; }
    public string consolidationCode { get; set; }
    public DateTime lastModifiedDateTime { get; set; }
}

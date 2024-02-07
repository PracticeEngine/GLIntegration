using System;

public class BusCentDimensionValues
{
    public string odatacontext { get; set; }
    public BCDimensionValue[] value { get; set; }
}

public class BCDimensionValue
{
    public string id { get; set; }
    public string code { get; set; }
    public string dimensionId { get; set; }
    public string displayName { get; set; }
    public string consolidationCode { get; set; }
    public DateTime lastModifiedDateTime { get; set; }
}

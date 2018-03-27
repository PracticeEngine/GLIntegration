CREATE PROCEDURE [dbo].[pe_NL_Intacct_Customer]
AS

SELECT 
E.[ClientOrganisation] AS [Org],
LTrim(RTrim(E.[ClientCode])) AS [CUSTOMERID],
LTrim(RTrim(Replace(Replace(Replace(Replace(E.[ClientName], '&', '+'), '<', '-'), '>', '-'), '''', '\'''))) AS [CUSTNAME],
LTrim(RTrim(OT.[OwnerName])) AS [CUSTTYPENAME],
LTrim(RTrim(CASE WHEN E.[ClientStatus] IN ('NEW','ACTIVE')
       THEN 'active'
       ELSE 'inactive'
END)) AS [STATUS],
LTrim(RTrim(Replace(Replace(Replace(Replace(C.[ContName], '&', '+'), '<', '-'), '>', '-'), '''', '\'''))) AS [CONTACTNAME],
Coalesce(LTrim(RTrim(C.[ContEmail])), '') AS [EMAIL1],
Coalesce(LTrim(RTrim(Replace(Replace(Replace(Replace(C.[ContAddress], '&', '+'), '<', '-'), '>', '-'), '''', '\'''))), '') AS [ADDRESS1],
Coalesce(LTrim(RTrim(Replace(Replace(Replace(Replace(C.[ContTownCity], '&', '+'), '<', '-'), '>', '-'), '''', '\'''))), '') AS [CITY],
Coalesce(LTrim(RTrim(C.[ContCounty])), '') AS [STATE],
Coalesce(LTrim(RTrim(C.[ContCountry])), '') AS [COUNTRY],
Coalesce(LTrim(RTrim(C.[ContPostCode])), '') aS [ZIP]
FROM [dbo].[tblEngagement] E
INNER JOIN [dbo].[tblContacts] C ON E.[ContIndex] = C.[ContIndex]
INNER JOIN [dbo].[tblOwnerType] OT ON E.[ClientOwnership] = OT.[OwnerIndex]
WHERE E.[ContIndex] < 900000


RETURN 0

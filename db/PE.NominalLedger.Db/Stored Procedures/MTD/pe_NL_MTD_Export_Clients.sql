CREATE PROCEDURE [dbo].[pe_NL_MTD_Export_Clients]

@Org int

AS

SELECT	E.ContIndex, E.ClientCode, E.ClientName, E.ClientStatus,
		C.ContAddress, C.ContTownCity, C.ContCounty, C.ContCountry, C.ContPostCode
FROM	tblEngagement E
INNER JOIN tblContacts C ON E.ClientRef = C.ContIndex
WHERE E.ContIndex IN (SELECT D.ContIndex
						FROM tblTranDebtor D 
						INNER JOIN tblTranNominalMTD M ON D.DebtTranIndex = M.DebtTranIndex
						WHERE M.Processed = 0 AND D.PracID = @Org)
ORDER BY E.ContIndex

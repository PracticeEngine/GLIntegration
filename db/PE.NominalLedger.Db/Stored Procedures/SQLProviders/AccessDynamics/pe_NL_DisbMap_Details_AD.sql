CREATE PROCEDURE [dbo].[pe_NL_DisbMap_Details_AD]

AS

SELECT Map.*, C.PracName As OrgName, TCC.ChargeName As DisbName
FROM tblTranNominalDisbMap Map
INNER JOIN tblControl C ON Map.NLOrg = C.PracID
LEFT JOIN tblTimeChargeCode TCC ON Map.DisbCode = TCC.ChargeCode AND TCC.ChargeClass = 'DISB'
ORDER BY C.PracName, Map.NLAcc
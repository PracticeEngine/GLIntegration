CREATE PROCEDURE [dbo].[pe_NL_Control_Disbs]

AS

SELECT ChargeCode, ChargeName
FROM tblTimeChargeCode
WHERE ChargeClass = 'DISB'
ORDER BY ChargeCode
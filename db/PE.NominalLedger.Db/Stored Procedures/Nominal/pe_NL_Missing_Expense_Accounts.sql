CREATE PROCEDURE [dbo].[pe_NL_Missing_Expense_Accounts]

AS

SELECT DISTINCT C.ChargeIndex, C.ChargeCode, C.ChargeName, C.ChargeNominalWIP As ChargeExpAccount, C.ChargeNominalWoff As NonChargeExpAccount
FROM tblTranNominalPostExpenses P
INNER JOIN tblTimeChargeCode C ON P.DisbCode = C.ChargeCode AND C.ChargeClass = 'DISB'
WHERE P.PostAcc = '' AND P.Posted = 0

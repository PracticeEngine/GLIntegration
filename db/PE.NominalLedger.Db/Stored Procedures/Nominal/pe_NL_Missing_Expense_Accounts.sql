CREATE PROCEDURE [dbo].[pe_NL_Missing_Expense_Accounts]

AS

INSERT INTO tblTranNominalExpMap(ExpOrg, DisbCode)
SELECT P.ExpOrg, P.DisbCode
FROM tblTranNominalPostExpenses P
LEFT OUTER JOIN tblTranNominalExpMap M ON P.ExpOrg = M.ExpOrg AND P.DisbCode = M.DisbCode
WHERE P.Posted = 0 AND M.ExpMapIndex IS NULL

SELECT DISTINCT P.ExpOrg, O.PracName, C.ChargeCode, C.ChargeName, M.ExpMapIndex, M.ChargeExpAccountType, M.ChargeExpAccount, M.NonChargeExpAccountType, M.NonChargeExpAccount
FROM tblTranNominalPostExpenses P
INNER JOIN tblTimeChargeCode C ON P.DisbCode = C.ChargeCode AND C.ChargeClass = 'DISB'
INNER JOIN tblTranNominalExpMap M ON P.ExpOrg = M.ExpOrg AND P.DisbCode = M.DisbCode
INNER JOIN tblControl O ON P.ExpOrg = O.PracID
WHERE P.PostAcc = '' AND P.Posted = 0

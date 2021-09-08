CREATE PROCEDURE [dbo].[pe_NL_Expense_Accounts]

AS

INSERT INTO tblTranNominalExpMap(ExpOrg, DisbCode)
SELECT P.ExpOrg, P.DisbCode
FROM tblTranNominalPostExpenses P
LEFT OUTER JOIN tblTranNominalExpMap M ON P.ExpOrg = M.ExpOrg AND P.DisbCode = M.DisbCode
WHERE P.Posted = 0 AND M.ExpMapIndex IS NULL

SELECT DISTINCT M.ExpOrg, O.PracName, C.ChargeCode, C.ChargeName, M.ExpMapIndex, M.ChargeExpAccount, M.NonChargeExpAccount, M.ChargeSuffix1, M.ChargeSuffix2, M.ChargeSuffix3, M.NonChargeSuffix1, M.NonChargeSuffix2, M.NonChargeSuffix3
FROM tblTranNominalExpMap M
INNER JOIN tblTimeChargeCode C ON M.DisbCode = C.ChargeCode AND C.ChargeClass = 'DISB'
INNER JOIN tblControl O ON M.ExpOrg = O.PracID

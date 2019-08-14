CREATE PROCEDURE [dbo].[pe_NL_Missing_Expense_Staff]

AS

SELECT DISTINCT S.StaffIndex, S.StaffCode, S.StaffName
FROM tblTranNominalPostExpenses P
INNER JOIN tblStaff S ON P.VendorIndex = S.StaffIndex
WHERE P.VendorCode = '' AND P.Posted = 0

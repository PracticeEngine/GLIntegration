CREATE PROCEDURE [dbo].[pe_NL_Expense_Staff]

AS

SELECT DISTINCT S.StaffOrganisation As StaffOrg, S.StaffIndex, C.PracName As OrgName, S.StaffName, 
	(Select Count(NomExpIndex) From tblTranNominalPostExpenses WHERE Posted = 0 AND (PostAcc = '' OR VendorCode = ''))  AS NumBlank
FROM tblTranNominalPostExpenses P
INNER JOIN tblStaff S ON P.VendorIndex = S.StaffIndex
INNER JOIN tblControl C ON P.ExpOrg = C.PracID
INNER JOIN tblTranNominalOrgs O ON P.ExpOrg = O.PracID
WHERE P.Posted = 0 AND O.NLTransfer = 1
ORDER BY S.StaffOrganisation, S.StaffName

CREATE PROCEDURE [dbo].[pe_NL_Expense_Staff]

AS

DECLARE @BlankStaff int
DECLARE @BlankAccounts int

SELECT @BlankStaff = Count(DISTINCT VendorIndex) 
FROM tblTranNominalPostExpenses 
WHERE Posted = 0 AND VendorCode = ''

SELECT @BlankAccounts = Count(DISTINCT DisbCode) 
FROM tblTranNominalPostExpenses 
WHERE Posted = 0 AND PostAcc = ''

SELECT DISTINCT S.StaffOrganisation As StaffOrg, S.StaffIndex, C.PracName As OrgName, S.StaffName, @BlankStaff AS BlankStaff, @BlankAccounts AS BlankAccounts
FROM tblTranNominalPostExpenses P
INNER JOIN tblStaff S ON P.VendorIndex = S.StaffIndex
INNER JOIN tblControl C ON P.ExpOrg = C.PracID
INNER JOIN tblTranNominalOrgs O ON P.ExpOrg = O.PracID
WHERE P.Posted = 0 AND O.NLTransfer = 1
ORDER BY S.StaffOrganisation, S.StaffName

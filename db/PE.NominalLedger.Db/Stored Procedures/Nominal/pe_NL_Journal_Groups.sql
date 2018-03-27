CREATE PROCEDURE [dbo].[pe_NL_Journal_Groups]

AS

CREATE TABLE #Mappings(NomSource nvarchar(20) collate database_default, NomSection nvarchar(20) collate database_default, NomAccount nvarchar(20) collate database_default, 
						NomOffice nvarchar(20) collate database_default, NomService nvarchar(20) collate database_default,  NomPartner int, 
						NomDept nvarchar(20) collate database_default, NomOrg int, OrgName nvarchar(255) collate database_default, OfficeName nvarchar(255) collate database_default, 
						ServiceName nvarchar(255) collate database_default, PartnerName nvarchar(255) collate database_default, DepartmentName nvarchar(255) collate database_default, 
						NumBlank int)
						
INSERT INTO #Mappings(OrgName, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomOrg, OfficeName, ServiceName, PartnerName, DepartmentName, NumBlank)
SELECT PracName, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomOrg,
	OfficeName = CASE WHEN NomOffice = '' THEN 'No Office' ELSE NomOffice END,
	ServName = CASE WHEN NomService = '' THEN 'No Service' ELSE NomService END,
	PartName = CASE WHEN StaffIndex = 0 THEN 'No Partner' ELSE StaffName END,
	DeptName = CASE WHEN NomDept = '' THEN 'No Department' ELSE NomDept END,
	(Select Count(NomIndex) From tblTranNominalPost WHERE NomPostAcc = '')  AS Numblank
FROM tblTranNominalPost 
LEFT JOIN tblStaff ON tblTranNominalPost.NomPartner = tblStaff.StaffIndex
INNER JOIN tblControl ON tblTranNominalPost.NomOrg = tblControl.PracID
INNER JOIN tblTranNominalOrgs ON tblTranNominalPost.NomOrg = tblTranNominalOrgs.PracID
WHERE NomPosted = 0 AND NLTransfer = 1
GROUP BY NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomOrg, PracName, StaffIndex, StaffName

SELECT *
FROM #Mappings
ORDER BY NomOrg, NomSource, NomSection, NomAccount, OfficeName, ServiceName, PartnerName, DepartmentName

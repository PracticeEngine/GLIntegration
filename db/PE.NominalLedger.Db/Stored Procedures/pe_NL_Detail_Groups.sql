CREATE PROCEDURE [dbo].[pe_NL_Detail_Groups]

@PeriodIndex int

AS

CREATE TABLE #Mappings(NLSource nvarchar(20) collate database_default, NLSection nvarchar(20) collate database_default, NLAccount nvarchar(20) collate database_default, 
						NLOffice nvarchar(20) collate database_default, NLService nvarchar(20) collate database_default,  NLPartner int, 
						NLDept nvarchar(20) collate database_default, NLOrg int, OrgName nvarchar(255) collate database_default, OfficeName nvarchar(255) collate database_default, 
						ServiceName nvarchar(255) collate database_default, PartnerName nvarchar(255) collate database_default, DepartmentName nvarchar(255) collate database_default)
						
INSERT INTO #Mappings(OrgName, NLSource, NLSection, NLAccount, NLOffice, NLService, NLPartner, NLDept, NLOrg, OfficeName, ServiceName, PartnerName, DepartmentName)
SELECT PracName, NLSource, NLSection, NLAccount, Office, Service, Partner, Department, NLOrg,
	OfficeName = CASE WHEN Office = '' THEN 'No Office' ELSE Office END,
	ServName = CASE WHEN Service = '' THEN 'No Service' ELSE Service END,
	PartName = CASE WHEN StaffIndex = 0 THEN 'No Partner' ELSE StaffName END,
	DeptName = CASE WHEN Department = '' THEN 'No Department' ELSE Department END
FROM tblTranNominal N 
INNER JOIN tblControl C ON N.NLOrg = C.PracID
LEFT JOIN tblStaff S ON N.Partner = S.StaffIndex
WHERE NLPeriodIndex = @PeriodIndex
GROUP BY NLSource, NLSection, NLAccount, Office, Service, Partner, Department, NLOrg, PracName, StaffIndex, StaffName

SELECT *, @PeriodIndex As NLPeriodIndex
FROM #Mappings
ORDER BY NLOrg, NLSource, NLSection, NLAccount, OfficeName, ServiceName, PartnerName, DepartmentName

CREATE PROCEDURE [dbo].[pe_NL_Mapping_List]

AS

CREATE TABLE #Mappings(AccountCode nvarchar(60) collate database_default, AccountTypeCode nvarchar(60) collate database_default, MapIndex int, MapAccount nvarchar(20) collate database_default, 
                                        MapDept nvarchar(20) collate database_default, MapOrg int, MapOffice nvarchar(20) collate database_default, MapPart int, MapSection nvarchar(20) collate database_default,  
                                                                     MapServ nvarchar(20) collate database_default, MapSource nvarchar(20) collate database_default, StaffName nvarchar(255) collate database_default)

INSERT INTO #Mappings(AccountCode, AccountTypeCode, MapIndex, MapAccount, MapDept, MapOrg, MapOffice, MapPart, MapSection, MapServ, MapSource, StaffName)
SELECT M.MapTargetAcc, M.MapTargetType, M.MapIndex, M.MapAccount, M.MapDept, M.MapOrg, M.MapOffice, M.MapPart, M.MapSection, M.MapServ, M.MapSource, Coalesce(S.StaffName, '')
FROM tblTranNominalMap M 
INNER JOIN tblTranNominalOrgs O ON M.MapOrg = O.PracID
LEFT JOIN tblStaff S ON M.MapPart = S.StaffIndex
WHERE O.NLTransfer = 1

SELECT M.*, C.PracName As OrgName, Coalesce(O.OfficeName, 'No Office') As OfficeName, Coalesce(S.ServTitle, 'No Service') As ServiceName, M.StaffName As PartnerName, Coalesce(D.DeptName, 'No Dept') As DepartmentName
FROM #Mappings M
INNER JOIN tblControl C ON M.MapOrg = C.PracID
LEFT JOIN tblOffices O ON M.MapOffice = O.OfficeCode
LEFT JOIN tblServices S ON M.MapServ = S.ServIndex
LEFT JOIN tblDepartment D ON M.MapDept = D.DeptIdx
ORDER BY M.MapOrg, M.MapSource, M.MapSection, M.MapAccount, M.MapOffice, M.MapServ, M.MapDept

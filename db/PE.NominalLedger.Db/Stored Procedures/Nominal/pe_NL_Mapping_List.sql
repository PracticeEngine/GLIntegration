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

SELECT *
FROM #Mappings
ORDER BY MapOrg, MapSource, MapSection, MapAccount, MapOffice, MapServ, MapDept


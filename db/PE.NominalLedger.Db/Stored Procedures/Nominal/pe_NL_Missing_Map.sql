CREATE PROCEDURE [dbo].[pe_NL_Missing_Map]

AS

CREATE TABLE #Mappings(NomSource nvarchar(20) collate database_default, NomSection nvarchar(20) collate database_default, NomAccount nvarchar(20) collate database_default, 
                                        NomOffice nvarchar(20) collate database_default, NomService nvarchar(20) collate database_default,  NomPartner int, 
                                        NomDept nvarchar(20) collate database_default, NomOrg int, OrgName nvarchar(255) collate database_default, OfficeName nvarchar(255) collate database_default, 
                                        ServiceName nvarchar(255) collate database_default, PartnerName nvarchar(255) collate database_default, DepartmentName nvarchar(255) collate database_default, 
                                        NumBlank int, MapIndex int)

INSERT INTO #Mappings(OrgName, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomOrg, OfficeName, ServiceName, PartnerName, DepartmentName, NumBlank, MapIndex)
SELECT PracName, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomOrg,
       CASE WHEN NomOffice = '' THEN 'No Office' ELSE NomOffice END,
       CASE WHEN NomService = '' THEN 'No Service' ELSE NomService END,
       CASE WHEN StaffIndex = 0 THEN 'No Partner' ELSE StaffName END,
       CASE WHEN NomDept = '' THEN 'No Department' ELSE NomDept END,
       (Select Count(NomIndex) From tblTranNominalPost WHERE NomPostAcc = '')  AS Numblank, 0
FROM tblTranNominalPost 
LEFT JOIN tblStaff ON tblTranNominalPost.NomPartner = tblStaff.StaffIndex
INNER JOIN tblControl ON tblTranNominalPost.NomOrg = tblControl.PracID
INNER JOIN tblTranNominalOrgs ON tblTranNominalPost.NomOrg = tblTranNominalOrgs.PracID
WHERE NomPosted = 0 And NomPostAcc = '' AND NLTransfer = 1
GROUP BY NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomOrg, PracName, StaffIndex, StaffName
UNION ALL
SELECT PracName, 'LOD' As NomSource, 'BS' As NomSection, 'BNKCON' AS NomAccount, TB.BankOffice As NomOffice, '' As NomService, -1 As NomPartner, '' As NomDept, TB.PracID As NomOrg,
       CASE WHEN BankOffice = '' THEN 'No Office' ELSE BankOffice END,
       'No Service',
       'No Partner',
       'No Department',
       (Select Count(DISTINCT BankIndex) From tblTranNominalBank NB INNER JOIN tblTranBank TB ON NB.LodgeBank = TB.BankIndex
             INNER JOIN tblControl ON TB.PracID = tblControl.PracID INNER JOIN tblTranNominalOrgs N ON TB.PracID = N.PracID
             LEFT JOIN tblTranNominalMap M ON TB.PracID = M.MapOrg AND 'LOD' = M.MapSource AND 'BNKCON' = M.MapAccount
             AND TB.BankOffice = M.MapOffice  WHERE LodgePosted = 1 AND TB.BankNominal <> '' And NLTransfer = 1
             AND Coalesce(MapTargetAcc,'') = '')  AS Numblank, 0
FROM tblTranNominalBank NB
INNER JOIN tblTranBank TB ON NB.LodgeBank = TB.BankIndex
INNER JOIN tblControl ON TB.PracID = tblControl.PracID
INNER JOIN tblTranNominalOrgs N ON TB.PracID = N.PracID
LEFT JOIN tblTranNominalMap M ON TB.PracID = M.MapOrg AND 'LOD' = M.MapSource AND 'BNKCON' = M.MapAccount AND TB.BankOffice = M.MapOffice 
WHERE LodgeBatch = 0 AND TB.BankNominal <> '' And NLTransfer = 1 AND Coalesce(M.MapTargetAcc,'') = ''
GROUP BY PracName, TB.BankOffice, TB.PracID

INSERT INTO tblTranNominalMap(MapOrg, MapSource, MapSection, MapAccount, MapOffice, MapServ, MapPart, MapDept, MapTargetAcc, MapTargetType)
SELECT T.NomOrg, T.NomSource, T.NomSection, T.NomAccount, T.NomOffice, T.NomService, T.NomPartner, T.NomDept, '', ''
FROM #Mappings T
LEFT JOIN tblTranNominalMap M ON T.NomOrg = M.MapOrg AND T.NomSource = M.MapSource AND T.NomSection = M.MapSection AND T.NomAccount = M.MapAccount AND T.NomOffice = M.MapOffice AND T.NomPartner = M.MapPart AND T.NomService = M.MapServ AND T.NomDept = M.MapDept
WHERE M.MapIndex IS NULL

UPDATE T
SET T.MapIndex = M.MapIndex 
FROM #Mappings T
INNER JOIN tblTranNominalMap M ON T.NomOrg = M.MapOrg AND T.NomSource = M.MapSource AND T.NomSection = M.MapSection AND T.NomAccount = M.MapAccount AND T.NomOffice = M.MapOffice AND T.NomPartner = M.MapPart AND T.NomService = M.MapServ AND T.NomDept = M.MapDept

SELECT *
FROM #Mappings
ORDER BY NomOrg, NomSource, NomSection, NomAccount, OfficeName, ServiceName, PartnerName, DepartmentName


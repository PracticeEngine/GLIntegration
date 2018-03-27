CREATE PROCEDURE [dbo].[pe_NL_Map_Line_SS]

@Org int,
@MapIdx int

AS

DECLARE @Server varchar(50)
DECLARE @DB varchar(50)
DECLARE @SQL varchar(8000)

SELECT @Server = NLServer, @DB = NLDatabase
FROM tblTranNominalOrgs
WHERE PracID = @Org

SELECT M.*, A.AccountDescription AS AccountDesc, Cast(A.AccountGroup as nvarchar(10)) AS AccountTypeCode, S.StaffName
FROM tblTranNominalMap M 
LEFT OUTER JOIN tblStaff S ON M.MapPart = S.StaffIndex
LEFT OUTER JOIN SunSystems_Accounts A ON A.AccountCode = M.MapTargetAcc
WHERE M.MapIndex = @MapIdx
ORDER BY M.MapOrg, M.MapSource, M.MapSection, M.MapAccount

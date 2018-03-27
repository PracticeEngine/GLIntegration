CREATE PROCEDURE [dbo].[pe_NL_Map_Line_GP]

@Org int,
@MapIdx int

AS

DECLARE @Server varchar(50)
DECLARE @DB varchar(50)
DECLARE @SQL varchar(8000)

SELECT @Server = NLServer, @DB = NLDatabase
FROM tblTranNominalOrgs
WHERE PracID = @Org

SET @SQL = 'SELECT M.*, A.ACTDESCR AS AccountDesc, Cast(A.ACCATNUM as nvarchar(10)) AS AccountTypeCode, S.StaffName
FROM (tblTranNominalMap M LEFT OUTER JOIN tblStaff S ON M.MapPart = S.StaffIndex)  LEFT OUTER JOIN '

IF @Server <> ''
	SET @SQL = @SQL + @Server + '.'

SET @SQL = @SQL + @DB + '..GL00100 A ON RTRIM(Mast.ACTNUMBR_1) + RTRIM(Mast.ACTNUMBR_2) + RTRIM(Mast.ACTNUMBR_3) + RTRIM(Mast.ACTNUMBR_4) = M.MapTargetAcc
WHERE M.MapIndex = ' + LTrim(Str(@MapIdx)) + ' 
ORDER BY M.MapOrg, M.MapSource, M.MapSection, M.MapAccount'

PRINT @SQL

EXEC (@SQL)
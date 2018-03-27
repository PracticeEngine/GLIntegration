CREATE PROCEDURE [dbo].[pe_NL_Map_Line_AD]

@Org int,
@MapIdx int

AS

DECLARE @Server varchar(50)
DECLARE @DB varchar(50)
DECLARE @SQL varchar(8000)

SELECT @Server = NLServer, @DB = NLDatabase
FROM tblTranNominalOrgs
WHERE PracID = @Org

SET @SQL = 'SELECT M.*, A.NNAME AS AccountDesc, Cast(A.NMAJORHEADCODE As nvarchar(10)) AS AcccountTypeCode, S.StaffName
FROM (tblTranNominalMap M LEFT OUTER JOIN tblStaff S ON M.MapPart = S.StaffIndex)  LEFT OUTER JOIN '

IF @Server <> ''
	SET @SQL = @SQL + @Server + '.'

SET @SQL = @SQL + @DB + '..NL_ACCOUNTS A ON A.NCODE = M.MapTargetAcc
WHERE M.MapIndex = ' + LTrim(Str(@MapIdx)) + ' 
ORDER BY M.MapOrg, M.MapSource, M.MapSection, M.MapAccount'

PRINT @SQL

EXEC (@SQL)
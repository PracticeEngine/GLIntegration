CREATE PROCEDURE [dbo].[pe_NL_Accounts_GP]

@Org int,
@Type nvarchar(10)

AS

DECLARE @Server varchar(50)
DECLARE @DB varchar(50)
DECLARE @SQL varchar(8000)

SELECT @Server = NLServer, @DB = NLDatabase
FROM tblTranNominalOrgs
WHERE PracID = @Org

SET @SQL = 'SELECT RTRIM(Mast.ACTNUMBR_1) + RTRIM(Mast.ACTNUMBR_2) + RTRIM(Mast.ACTNUMBR_3) + RTRIM(Mast.ACTNUMBR_4) AS AccountCode, Mast.ACTDESCR AS AccountDesc, 
			CAST(Mast.ACCATNUM as nvarchar(10)) AS AccountTypeCode, Type.ACCATDSC AS AccountTypeDesc
FROM '

IF @Server <> ''
	SET @SQL = @SQL + @Server + '.'

SET @SQL = @SQL + @DB + '.dbo.GL00100 Mast INNER JOIN '

IF @Server <> ''
	SET @SQL = @SQL + @Server + '.'

SET @SQL = @SQL + @DB + '.dbo.GL00102 Type ON Mast.ACCATNUM = Type.ACCATNUM
WHERE CAST(Mast.ACCATNUM as nvarchar(10)) = ''' + LTrim(Str(@Type)) + '''
ORDER BY AccDesc'

PRINT @SQL

EXEC (@SQL)
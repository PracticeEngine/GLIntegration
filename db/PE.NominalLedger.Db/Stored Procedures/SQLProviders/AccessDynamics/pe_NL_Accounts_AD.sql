CREATE PROCEDURE [dbo].[pe_NL_Accounts_AD]

@Org int,
@Type nvarchar(10)

AS

DECLARE @Server varchar(50)
DECLARE @DB varchar(50)
DECLARE @SQL varchar(8000)

SELECT @Server = NLServer, @DB = NLDatabase
FROM tblTranNominalOrgs
WHERE PracID = @Org

SET @SQL = 'SELECT LTRIM(RTRIM(Mast.NCODE)) AS AccountCode, Mast.NNAME AS AccountDesc, CAST(Mast.NMAJORHEADCODE as nvarchar(10)) AS AccountTypeCode, Type.NL_MAJORNAME AS AccountTypeDesc
FROM '

IF @Server <> ''
	SET @SQL = @SQL + @Server + '.'

SET @SQL = @SQL + @DB + '.dbo.NL_ACCOUNTS Mast INNER JOIN '

IF @Server <> ''
	SET @SQL = @SQL + @Server + '.'

SET @SQL = @SQL + @DB + '.dbo.NL_MAJORHEADING Type ON Mast.NMAJORHEADCODE = Type.NL_MAJORCODE
WHERE CAST(Mast.NMAJORHEADCODE as nvarchar(10)) = ''' + LTrim(Str(@Type)) + '''
ORDER BY AccNum'

PRINT @SQL

EXEC (@SQL)
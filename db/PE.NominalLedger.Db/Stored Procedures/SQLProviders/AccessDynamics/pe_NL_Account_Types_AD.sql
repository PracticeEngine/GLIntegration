CREATE PROCEDURE [dbo].[pe_NL_Account_Types_AD]

@Org int

AS

DECLARE @Server varchar(50)
DECLARE @DB varchar(50)
DECLARE @SQL varchar(8000)

SELECT @Server = NLServer, @DB = NLDatabase
FROM tblTranNominalOrgs
WHERE PracID = @Org

SET @SQL = 'SELECT CAST(NL_MAJORCODE as nvarchar(10)) As AccountTypeCode, NL_MAJORNAME As AccountTypeDesc
FROM '

IF @Server <> ''
	SET @SQL = @SQL + @Server + '.'

SET @SQL = @SQL + @DB + '.dbo.NL_MAJORHEADING'

EXEC (@SQL)
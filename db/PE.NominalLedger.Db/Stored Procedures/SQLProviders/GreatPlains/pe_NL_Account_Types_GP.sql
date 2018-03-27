CREATE PROCEDURE [dbo].[pe_NL_Account_Types_GP]

@Org int

AS

DECLARE @Server varchar(50)
DECLARE @DB varchar(50)
DECLARE @SQL varchar(8000)

SELECT @Server = NLServer, @DB = NLDatabase
FROM tblTranNominalOrgs
WHERE PracID = @Org

SET @SQL = 'SELECT CAST(ACCATNUM as nvarchar(10)) As AccountTypeCode, ACCATDSC As AccountTypeDesc
FROM '

IF @Server <> ''
	SET @SQL = @SQL + @Server + '.'

SET @SQL = @SQL + @DB + '.dbo.GL00102'

EXEC (@SQL)
CREATE PROCEDURE [dbo].[pe_NL_Suppliers_AD]

@Org int

AS

DECLARE @Server varchar(50)
DECLARE @DB varchar(50)
DECLARE @SQL varchar(8000)

SELECT @Server = NLServer, @DB = NLDatabase
FROM tblTranNominalOrgs
WHERE PracID = @Org

SET @SQL = 'SELECT LTRIM(RTRIM(Mast.SUCODE)) AS SupplierCode, Mast.SUNAME AS SupplierName
FROM '

IF @Server <> ''
	SET @SQL = @SQL + @Server + '.'

SET @SQL = @SQL + @DB + '.dbo.PL_ACCOUNTS Mast
WHERE Mast.SUUSED = 1
ORDER BY Mast.SUNAME'

PRINT @SQL

EXEC (@SQL)
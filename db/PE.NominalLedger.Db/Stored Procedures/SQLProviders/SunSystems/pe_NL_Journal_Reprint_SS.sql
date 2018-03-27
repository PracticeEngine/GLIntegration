CREATE PROCEDURE [dbo].[pe_NL_Journal_Reprint_SS]

@Batch int

AS

DECLARE @Org int
DECLARE @Server varchar(50)
DECLARE @DB varchar(50)
DECLARE @SQL varchar(8000)

SET @SQL = ''

DECLARE csr_Org CURSOR DYNAMIC		
FOR SELECT Orgs.PracID, Orgs.NLServer, Orgs.NLDatabase
FROM tblTranNominalOrgs Orgs
WHERE Orgs.NLTransfer = 1

OPEN csr_Org
FETCH 	csr_Org INTO @Org, @Server, @DB
WHILE (@@FETCH_STATUS=0) 
	BEGIN
	IF @SQL <> ''
		SET @SQL = @SQL + '
UNION ALL
'
	SET @SQL = @SQL + 'SELECT Post.*, CASE WHEN Post.NomAmount >= 0 THEN Post.Nomamount ELSE 0 END As Debits, CASE WHEN Post.NomAmount < 0 THEN Post.Nomamount ELSE 0 END As Credits, Mast.AccountCode AS AccNum, Mast.AccountCode + '' - '' + Mast.AccountDescription As AccDesc
	FROM SunSystems_Accounts Mast RIGHT OUTER JOIN tblTranNominalPost Post ON Mast.AccountID = Post.NomPostAcc
	WHERE Post.NomBatch = ' + LTrim(Str(@Batch)) + ' AND Post.NomOrg = ' + LTrim(Str(@Org))

	FETCH csr_Org INTO @Org, @Server, @DB
	END

CLOSE csr_Org
DEALLOCATE csr_Org

PRINT @SQL

EXEC (@SQL)






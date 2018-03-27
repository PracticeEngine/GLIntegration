CREATE PROCEDURE [dbo].[pe_NL_Journal_Reprint_AD]

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
	SET @SQL = @SQL + 'SELECT ''' + @DB + ''' AS DB, Post.*, LTRIM(RTRIM(Mast.NCODE)) COLLATE Latin1_General_CI_AS AS AccNum, Mast.NNAME COLLATE Latin1_General_CI_AS As AccDesc
	FROM '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..NL_ACCOUNTS Mast RIGHT OUTER JOIN tblTranNominalPost Post ON Mast.NCODE = Post.NomPostAcc
	WHERE Post.NomBatch = ' + LTrim(Str(@Batch)) + ' AND Post.NomOrg = ' + LTrim(Str(@Org))

	FETCH csr_Org INTO @Org, @Server, @DB
	END

CLOSE csr_Org
DEALLOCATE csr_Org

PRINT @SQL

EXEC (@SQL)
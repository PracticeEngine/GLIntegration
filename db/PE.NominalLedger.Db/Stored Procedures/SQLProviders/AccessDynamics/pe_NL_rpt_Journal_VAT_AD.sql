CREATE PROCEDURE [dbo].[pe_NL_rpt_Journal_VAT_AD]

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
	SET @SQL = @SQL + 'SELECT Max(Post.NomDate) AS NomDate, Sum(Post.NomAmount * -1) AS NomAmount, '''' AS NomNarrative,
		Coalesce(LTRIM(RTRIM(Mast.NCODE)), ' + CHAR(39) + CHAR(39) + ') AS AccNum,
		Coalesce(Mast.NNAME,' + CHAR(39) + 'No Mapping' + CHAR(39) + ') As AccDesc
	FROM tblTranNominalPost Post LEFT OUTER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..NL_ACCOUNTS Mast  ON Mast.NCODE = Post.NomPostAcc
	WHERE Post.NomPosted = 0 AND Post.NomOrg = ' + LTrim(Str(@Org)) + ' AND Post.NomJnlType = ' + CHAR(39) + 'VJL' + CHAR(39) + '
	GROUP BY Mast.NCODE, Mast.NName'

	SET @SQL = @SQL + '
UNION ALL
'
	SET @SQL = @SQL + 'SELECT Max(Post.NomDate) AS NomDate, Sum(Post.NomAmount + Post.NomVATAmount) AS NomAmount, '''' AS NomNarrative,
		Coalesce(LTRIM(RTRIM(Mast.NCODE)), ' + CHAR(39) + CHAR(39) + ') AS AccNum,
		Coalesce(Mast.NNAME,' + CHAR(39) + 'No Mapping' + CHAR(39) + ') As AccDesc
	FROM tblTranNominalPost Post LEFT OUTER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..NL_ACCOUNTS Mast  ON Mast.NCODE = Post.NomDRSAcc
	WHERE Post.NomPosted = 0 AND Post.NomOrg = ' + LTrim(Str(@Org)) + ' AND Post.NomJnlType = ' + CHAR(39) + 'VJL' + CHAR(39) + '
	GROUP BY Mast.NCODE, Mast.NName'

	SET @SQL = @SQL + '
UNION ALL
'
	SET @SQL = @SQL + 'SELECT Max(Post.NomDate) AS NomDate, Sum(Post.NomVATAmount * -1) AS NomAmount, '''' AS NomNarrative,
		Coalesce(LTRIM(RTRIM(Mast.NCODE)), ' + CHAR(39) + CHAR(39) + ') AS AccNum,
		Coalesce(Mast.NNAME,' + CHAR(39) + 'No Mapping' + CHAR(39) + ') As AccDesc
	FROM tblTranNominalPost Post LEFT OUTER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..NL_ACCOUNTS Mast  ON Mast.NCODE = Post.NomVATAcc
	WHERE Post.NomPosted = 0 AND Post.NomOrg = ' + LTrim(Str(@Org)) + ' AND Post.NomJnlType = ' + CHAR(39) + 'VJL' + CHAR(39) + '
	GROUP BY Mast.NCODE, Mast.NName'

	FETCH csr_Org INTO @Org, @Server, @DB
	END

CLOSE csr_Org
DEALLOCATE csr_Org

PRINT @SQL

EXEC (@SQL)
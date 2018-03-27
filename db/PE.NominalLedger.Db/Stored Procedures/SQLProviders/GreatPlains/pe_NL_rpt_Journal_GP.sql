CREATE PROCEDURE [dbo].[pe_NL_rpt_Journal_GP]

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
	SET @SQL = @SQL + 'SELECT Post.*, Coalesce(RTRIM(A.ACTNUMBR_1) + RTRIM(A.ACTNUMBR_2) + RTRIM(A.ACTNUMBR_3) + RTRIM(A.ACTNUMBR_4), ' + CHAR(39) + CHAR(39) + ') AS AccNum, Coalesce(A.ACTDESCR,' + CHAR(39) + 'No Mapping' + CHAR(39) + ') As AccDesc
	FROM ('
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..DTA00300 D INNER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..GL00100 A ON D.ACTINDX = A.ACTINDX) RIGHT OUTER JOIN tblTranNominalPost Post ON RTRIM(A.ACTNUMBR_1) + RTRIM(A.ACTNUMBR_2) + RTRIM(A.ACTNUMBR_3) + RTRIM(A.ACTNUMBR_4) = Post.NomPostAcc
	WHERE Post.NomPosted = 0'

	FETCH csr_Org INTO @Org, @Server, @DB
	END

CLOSE csr_Org
DEALLOCATE csr_Org

EXEC (@SQL)
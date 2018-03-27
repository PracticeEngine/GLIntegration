CREATE PROCEDURE [dbo].[pe_NL_DisbMap_Create_GP]

AS

DECLARE @Org int
DECLARE @Server varchar(50)
DECLARE @DB varchar(50)
DECLARE @SQL varchar(8000)

DECLARE csr_Org CURSOR DYNAMIC		
FOR SELECT Orgs.PracID, Orgs.NLServer, Orgs.NLDatabase
FROM tblTranNominalOrgs Orgs
WHERE Orgs.NLTransfer = 1

OPEN csr_Org
FETCH 	csr_Org INTO @Org, @Server, @DB
WHILE (@@FETCH_STATUS=0) 
	BEGIN
	SET @SQL = 'INSERT INTO tblTranNominalDisbMap (NLOrg, NLAcc, NLIdx, DisbCode)
	SELECT ' + LTrim(Str(@Org)) + ', RTRIM(A.ACTNUMBR_1) + RTRIM(A.ACTNUMBR_2) + RTRIM(A.ACTNUMBR_3) + RTRIM(A.ACTNUMBR_4) , A.ACTINDX, ' + CHAR(39) + CHAR(39) + '
	FROM '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '.dbo.DTA00300 D INNER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '.dbo.GL00100 A ON D.ACTINDX = A.ACTINDX LEFT OUTER JOIN tblTranNominalDisbMap Map ON A.ACTINDX = Map.NLIdx
	WHERE Map.NLIdx IS NULL AND D.GROUPID = ' + CHAR(39) + 'PE' + CHAR(39)

	EXEC (@SQL)

	FETCH csr_Org INTO @Org, @Server, @DB
	END

CLOSE csr_Org
DEALLOCATE csr_Org
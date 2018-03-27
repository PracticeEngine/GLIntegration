CREATE PROCEDURE [dbo].[pe_NL_DisbMap_Details_GP]

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
	SET @SQL = @SQL + 'SELECT Map.*, A.ACTDESCR As AccDesc, Coalesce(Disb.ChargeName,' + CHAR(39) + 'No Mapping' + CHAR(39) + ') As DisbDesc
	FROM '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '.dbo.DTA00300 D INNER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '.dbo.GL00100 A ON D.ACTINDX = A.ACTINDX INNER JOIN tblTranNominalDisbMap Map ON A.ACTINDX = Map.NLIdx LEFT OUTER JOIN tblTimeChargeCode Disb ON Map.DisbCode = Disb.ChargeCode
	WHERE D.GROUPID = ' + CHAR(39) + 'PE' + CHAR(39) + ' AND Map.NLOrg = ' + LTrim(Str(@Org))

	FETCH csr_Org INTO @Org, @Server, @DB
	END

CLOSE csr_Org
DEALLOCATE csr_Org

EXEC (@SQL)
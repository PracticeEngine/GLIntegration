CREATE PROCEDURE [dbo].[pe_NL_DisbMap_Line_GP]

@Org int,
@MapIdx int

AS

DECLARE @Server varchar(50)
DECLARE @DB varchar(50)
DECLARE @SQL varchar(8000)

SELECT @Server = NLServer, @DB = NLDatabase
FROM tblTranNominalOrgs
WHERE PracID = @Org

SET @SQL = 'SELECT Map.*, A.ACTDESCR As AccDesc, Coalesce(Disb.ChargeName,' + CHAR(39) + 'No Mapping' + CHAR(39) + ') As DisbDesc
FROM '
IF @Server <> ''
	SET @SQL = @SQL + @Server + '.'
SET @SQL = @SQL + @DB + '..DTA00300 D INNER JOIN '
IF @Server <> ''
	SET @SQL = @SQL + @Server + '.'
SET @SQL = @SQL + @DB + '..GL00100 A ON D.ACTINDX = A.ACTINDX INNER JOIN tblTranNominalDisbMap Map ON A.ACTINDX = Map.NLIdx LEFT OUTER JOIN tblTimeChargeCode Disb ON Map.DisbCode = Disb.ChargeCode
WHERE D.GROUPID = ' + CHAR(39) + 'PE' + CHAR(39) + ' AND Map.NLOrg = ' + LTrim(Str(@Org)) + ' AND Map.DisbMapIndex = ' + LTrim(Str(@MapIdx))

EXEC (@SQL)
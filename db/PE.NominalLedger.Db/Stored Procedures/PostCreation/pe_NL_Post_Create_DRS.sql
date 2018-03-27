CREATE PROCEDURE [dbo].[pe_NL_Post_Create_DRS]

@DRSOffice bit,
@DRSServ bit,
@DRSPart bit,
@DRSDept bit,
@DRSDetail bit,
@DRSPeriod int

AS

DECLARE @SQL varchar(8000)

SET @SQL = 'INSERT INTO tblTranNominalPost(NomPeriodIndex, NomDate, NomOrg, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomAmount, NomVATAmount, NomPostAcc, NomNarrative, NomMaxRef, NomPosted)
SELECT NLPeriodIndex, '

IF @DRSDetail = 1
	SET @SQL = @SQL + 'NLDate, '
ELSE
	SET @SQL = @SQL + 'Max(NLDate), '

SET @SQL = @SQL + 'NLOrg, NLSource, NLSection, NLAccount'

IF @DRSOffice = 1
	SET @SQL = @SQL + ', Office'
ELSE
	SET @SQL = @SQL + ', ' +CHAR(39) + CHAR(39)
IF @DRSServ = 1
	SET @SQL = @SQL + ', Service'
ELSE
	SET @SQL = @SQL + ', ' +CHAR(39) + CHAR(39)
IF @DRSPart = 1
	SET @SQL = @SQL + ', Partner'
ELSE
	SET @SQL = @SQL + ', 0'
IF @DRSDept = 1
	SET @SQL = @SQL + ', Department'
ELSE
	SET @SQL = @SQL + ', ' +CHAR(39) + CHAR(39)

IF @DRSDetail = 1
	SET @SQL = @SQL + ', Coalesce(NetAmount, Amount), Coalesce(VATAmount, 0)'
ELSE
	SET @SQL = @SQL + ', Sum(Coalesce(NetAmount, Amount)), Sum(Coalesce(VATAmount, 0))'

SET @SQL = @SQL + ', '''' AS PostAcc'

IF @DRSDetail = 1
	SET @SQL = @SQL + ', ' + CHAR(39) + 'Ref:' + CHAR(39) + ' + TransRefAlpha + ' + CHAR(39) + '/Client:' + CHAR(39) + ' + ClientName + ' + CHAR(39) + '/' + CHAR(39) + ' + NLNarrative'
ELSE
	SET @SQL = @SQL + ', ' +CHAR(39) + CHAR(39)

IF @DRSDetail = 1
	SET @SQL = @SQL + ', NLIndex'
ELSE
	SET @SQL = @SQL + ', Max(NLIndex)'

SET @SQL = @SQL + ', 0
FROM tblTranNominal '

IF @DRSDetail = 1
	SET @SQL = @SQL + 'LEFT OUTER JOIN tblEngagement ON tblTranNominal.ContIndex = tblengagement.ContIndex'

SET @SQL = @SQL + '
WHERE NLPosted = 0 AND NLSource = ''DRS'' AND NLAccount IN (''DRCON'',''DRSUS'',''BANK'',''CHQCL'',''BADDR'',''DISC'',''DRTRF'',''VATOUT'',''VATDUE'',''VATSUS'') AND TransTypeIndex NOT IN (3,4,6,14) AND NLPeriodIndex = ' + LTrim(Str(@DRSPeriod))

IF @DRSDetail = 0
	BEGIN
	SET @SQL = @SQL +
--' GROUP BY Case When Amount > 0 Then 1 Else 0 End, NLPeriodIndex, NLOrg, NLSource, NLSection, NLAccount'
' GROUP BY NLPeriodIndex, NLOrg, NLSource, NLSection, NLAccount'

	IF @DRSOffice = 1
		SET @SQL = @SQL + ', Office'
	IF @DRSServ = 1
		SET @SQL = @SQL + ', Service'
	IF @DRSPart = 1
		SET @SQL = @SQL + ', Partner'
	IF @DRSDept = 1
		SET @SQL = @SQL + ', Department'
	END

PRINT @SQL

EXEC (@SQL)
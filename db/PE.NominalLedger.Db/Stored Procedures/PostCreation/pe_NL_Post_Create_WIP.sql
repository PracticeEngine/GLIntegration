CREATE PROCEDURE [dbo].[pe_NL_Post_Create_WIP]

@WIPOffice bit,
@WIPServ bit,
@WIPPart bit,
@WIPDept bit,
@WIPDetail bit,
@WIPPeriod int

AS


DECLARE @SQL varchar(8000)

SET @SQL = 'INSERT INTO tblTranNominalPost(NomPeriodIndex, NomDate, NomOrg, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomAmount, NomPostAcc, NomNarrative, NomMaxRef, NomPosted)
SELECT NLPeriodIndex, '

IF @WIPDetail = 1
	SET @SQL = @SQL + 'NLDate, '
ELSE
	SET @SQL = @SQL + 'Max(NLDate), '

SET @SQL = @SQL + 'NLOrg, NLSource, NLSection, NLAccount'

IF @WIPOffice = 1
	SET @SQL = @SQL + ', Office'
ELSE
	SET @SQL = @SQL + ', ' +CHAR(39) + CHAR(39)
IF @WIPServ = 1
	SET @SQL = @SQL + ', Service'
ELSE
	SET @SQL = @SQL + ', ' +CHAR(39) + CHAR(39)
IF @WIPPart = 1
	SET @SQL = @SQL + ', Partner'
ELSE
	SET @SQL = @SQL + ', 0'
IF @WIPDept = 1
	SET @SQL = @SQL + ', Department'
ELSE
	SET @SQL = @SQL + ', ' +CHAR(39) + CHAR(39)

IF @WIPDetail = 1
	SET @SQL = @SQL + ', Amount'
ELSE
	SET @SQL = @SQL + ', Sum(Amount)'

SET @SQL = @SQL + ', '''' AS PostAcc'

IF @WIPDetail = 1
	SET @SQL = @SQL + ', NLNarrative'
ELSE
	SET @SQL = @SQL + ', ' +CHAR(39) + CHAR(39)

IF @WIPDetail = 1
	SET @SQL = @SQL + ', NLIndex'
ELSE
	SET @SQL = @SQL + ', Max(NLIndex)'

SET @SQL = @SQL + ', 0
FROM tblTranNominal '

SET @SQL = @SQL + '
WHERE NLPosted = 0 AND NLSource = ' + CHAR(39) + 'WIP' + CHAR(39) + ' AND NLPeriodIndex = ' + LTrim(Str(@WIPPeriod))

IF @WIPDetail = 0
	BEGIN
	SET @SQL = @SQL + 
--' GROUP BY Case When Amount > 0 Then 1 Else 0 End, NLPeriodIndex, NLOrg, NLSource, NLSection, NLAccount'
' GROUP BY Case When Amount > 0 Then 1 Else 0 End, NLPeriodIndex, NLOrg, NLSource, NLSection, NLAccount'

	IF @WIPOffice = 1
		SET @SQL = @SQL + ', Office'
	IF @WIPServ = 1
		SET @SQL = @SQL + ', Service'
	IF @WIPPart = 1
		SET @SQL = @SQL + ', Partner'
	IF @WIPDept = 1
		SET @SQL = @SQL + ', Department'
	END

PRINT @SQL

EXEC (@SQL)
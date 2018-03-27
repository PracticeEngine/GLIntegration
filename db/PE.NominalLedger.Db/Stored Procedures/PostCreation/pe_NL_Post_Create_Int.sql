CREATE PROCEDURE [dbo].[pe_NL_Post_Create_Int]

@INTOffice bit,
@INTServ bit,
@INTPart bit,
@INTDept bit,
@INTDetail bit,
@INTPeriod int

AS

DECLARE @SQL varchar(8000)

SET @SQL = 'INSERT INTO tblTranNominalPost(NomPeriodIndex, NomDate, NomOrg, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomAmount, NomPostAcc, NomNarrative, NomMaxRef, NomPosted)
SELECT NLPeriodIndex, '


IF @INTDetail = 1
	SET @SQL = @SQL + 'NLDate, '
ELSE
	SET @SQL = @SQL + 'Max(NLDate), '

SET @SQL = @SQL + 'NLOrg, NLSource, NLSection, NLAccount'

IF @INTOffice = 1
	SET @SQL = @SQL + ', Office'
ELSE
	SET @SQL = @SQL + ', ' +CHAR(39) + CHAR(39)
IF @INTServ = 1
	SET @SQL = @SQL + ', Service'
ELSE
	SET @SQL = @SQL + ', ' +CHAR(39) + CHAR(39)
IF @INTPart = 1
	SET @SQL = @SQL + ', Partner'
ELSE
	SET @SQL = @SQL + ', 0'
IF @INTDept = 1
	SET @SQL = @SQL + ', Department'
ELSE
	SET @SQL = @SQL + ', ' +CHAR(39) + CHAR(39)

IF @INTDetail = 1
	SET @SQL = @SQL + ', Amount'
ELSE
	SET @SQL = @SQL + ', Sum(Amount)'

SET @SQL = @SQL + ', '''' AS PostAcc'

IF @INTDetail = 1
	SET @SQL = @SQL + ', NLSource + '' - '' + NLSection + '' - '' + NLAccount + '' - '' + ''TIME - '' + Department'
ELSE
	SET @SQL = @SQL + ', ' +CHAR(39) + CHAR(39)

IF @INTDetail = 1
	SET @SQL = @SQL + ', NLIndex'
ELSE
	SET @SQL = @SQL + ', Max(NLIndex)'

SET @SQL = @SQL + ', 0
FROM tblTranNominal '

SET @SQL = @SQL + '
WHERE NLPosted = 0 AND NLSource = ' + CHAR(39) + 'INT' + CHAR(39) + ' AND NLPeriodIndex = ' + LTrim(Str(@INTPeriod))

IF @INTDetail = 0
	BEGIN
	SET @SQL = @SQL + 
--' GROUP BY Case When Amount > 0 Then 1 Else 0 End, NLPeriodIndex, NLOrg, NLSource, NLSection, NLAccount'
' GROUP BY NLPeriodIndex, NLOrg, NLSource, NLSection, NLAccount'

	IF @INTOffice = 1
		SET @SQL = @SQL + ', Office'
	IF @INTServ = 1
		SET @SQL = @SQL + ', Service'
	IF @INTPart = 1
		SET @SQL = @SQL + ', Partner'
	IF @INTDept = 1
		SET @SQL = @SQL + ', Department'
	END

PRINT @SQL

EXEC (@SQL)
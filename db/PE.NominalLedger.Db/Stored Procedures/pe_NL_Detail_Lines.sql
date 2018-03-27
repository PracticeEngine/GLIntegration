CREATE PROCEDURE [dbo].[pe_NL_Detail_Lines]

@OrgID int,
@Source varchar(10),
@Section varchar(10),
@Account varchar(10),
@Office varchar(10),
@Service varchar(10),
@Partner int,
@Department varchar(10),
@FromDate Datetime,
@ToDate Datetime

AS

DECLARE @SQL varchar(8000)

SET @SQL = 'SELECT tblTranNominal.*, TransTypeDescription
FROM tblTranNominal LEFT JOIN tblTranTypes ON tblTranNominal.TransTypeIndex = tblTranTypes.TransTypeIndex
WHERE NLOrg = ' + LTrim(Str(@OrgID)) + ' AND NLSource = ' + CHAR(39) + @Source + CHAR(39) + ' AND NLSection = ' + CHAR(39) + @Section + CHAR(39) + ' AND NLAccount = ' + CHAR(39) + @Account + CHAR(39) + ' AND NLDate >= ' + CHAR(39) + CONVERT(varchar(30), @FromDate, 112) + CHAR(39) + ' AND NLDate <= ' + CHAR(39) + Convert(varchar(30), @ToDate, 112) + CHAR(39) + ' '

IF @Office <> '~'
	SET @SQL = @SQL + 'AND Office = ' + CHAR(39) + @Office + CHAR(39) + ' '
IF @Service <> '~'
	SET @SQL = @SQL + 'AND Service = ' + CHAR(39) + @Service + CHAR(39) + ' '
IF @Department <> '~'
	SET @SQL = @SQL + 'AND Department = ' + CHAR(39) + @Department + CHAR(39) + ' '
IF @Partner <> -1
	SET @SQL = @SQL + 'AND Partner = ' + LTrim(Str(@Partner))
SET @SQL = @SQL + '
ORDER BY NLOrg, NLSource, NLSection, NLAccount, NLDate'

PRINT @SQL

EXEC (@SQL)
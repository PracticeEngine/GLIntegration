CREATE PROCEDURE [dbo].[pe_NL_Detail_Lines]

@OrgID int,
@Source varchar(10),
@Section varchar(10),
@Account varchar(10),
@Office varchar(10),
@Service varchar(10),
@Partner int,
@Department varchar(10),
@PeriodIndex int

AS

DECLARE @SQL varchar(8000)

SET @SQL = 'SELECT N.*, T.TransTypeDescription
FROM tblTranNominal N LEFT JOIN tblTranTypes T ON N.TransTypeIndex = T.TransTypeIndex
WHERE NLOrg = ' + LTrim(Str(@OrgID)) + ' AND NLSource = ' + CHAR(39) + @Source + CHAR(39) + ' AND NLSection = ' + CHAR(39) + @Section + CHAR(39) + ' AND NLAccount = ' + CHAR(39) + @Account + CHAR(39) + ' AND N.NLPeriodIndex = ' + CONVERT(varchar(30), @PeriodIndex) + ' '

IF @Office IS NOT NULL
	SET @SQL = @SQL + 'AND Coalesce(Office, '''') = ' + CHAR(39) + @Office + CHAR(39) + ' '
IF @Service IS NOT NULL
	SET @SQL = @SQL + 'AND Coalesce(Service, '''') = ' + CHAR(39) + @Service + CHAR(39) + ' '
IF @Department IS NOT NULL
	SET @SQL = @SQL + 'AND Coalesce(Department, '''') = ' + CHAR(39) + @Department + CHAR(39) + ' '
IF @Partner IS NOT NULL
	SET @SQL = @SQL + 'AND Coalesce(Partner, 0) = ' + LTrim(Str(@Partner))
SET @SQL = @SQL + '
ORDER BY NLOrg, NLSource, NLSection, NLAccount, NLDate'

PRINT @SQL

EXEC (@SQL)

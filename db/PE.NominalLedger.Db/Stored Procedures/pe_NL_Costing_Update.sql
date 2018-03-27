CREATE PROCEDURE [dbo].[pe_NL_Costing_Update]

AS

DECLARE @Org int
DECLARE @Server varchar(50)
DECLARE @DB varchar(50)
DECLARE @SQL varchar(8000)
DECLARE @OldCode VarChar(10)
DECLARE @NewCode VarChar(10)

SET @SQL = ''
CREATE TABLE #CodeChanges (OldCode VarChar(10) Collate Database_Default, NewCode VarChar(10) Collate Database_Default)

DECLARE csr_Org CURSOR DYNAMIC		
FOR SELECT Orgs.PracID, Orgs.NLServer, Orgs.NLDatabase
FROM tblTranNominalOrgs Orgs
WHERE Orgs.NLTransfer = 1
-- GTI Custom because ALL clients go to ALL orgs, there's no need to do 1, 2 and 4 since they each go to GTPartnership. Only need to do 1 once.
AND PracID = 1

OPEN csr_Org
FETCH 	csr_Org INTO @Org, @Server, @DB
WHILE (@@FETCH_STATUS=0) 
	BEGIN
	
	-- *********************************************
	-- Deal properly with clients whose code has changed......

	SET @SQL = 'TRUNCATE TABLE #CodeChanges'
	PRINT @SQL
	EXEC (@SQL)

	SET @SQL = 'INSERT INTO #CodeChanges (OldCode, NewCode) SELECT V.CH_CODE, E.ClientCode
FROM tblEngagement E INNER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTHEADER V ON E.ContIndex = V.CH_PRIMARY
WHERE LTrim(RTrim(E.ClientCode)) COLLATE database_default <> LTrim(RTrim(V.CH_CODE)) COLLATE database_default'

	PRINT @SQL
	EXEC (@SQL)

	SET @SQL = 'UPDATE #CodeChanges SET NewCode = Left(NewCode + ''          '', Len(OldCode)) WHERE Len(OldCode) > Len(NewCode)'
	PRINT @SQL
	EXEC (@SQL)

	SET @SQL = 'UPDATE #CodeChanges SET OldCode = Left(OldCode + ''          '', Len(NewCode)) WHERE Len(NewCode) > Len(OldCode)'
	PRINT @SQL
	EXEC (@SQL)

	DECLARE csr_CodeChanges CURSOR DYNAMIC		
	FOR SELECT OldCode, NewCode FROM #CodeChanges

	OPEN csr_CodeChanges
	FETCH 	csr_CodeChanges INTO @OldCode, @NewCode
	WHILE (@@FETCH_STATUS=0) 
	BEGIN

		SET @SQL = 'UPDATE ' + Case When @Server <> '' Then @Server + '.' Else '' End + @DB + '.dbo.CST_COSTCENTRE SET CC_CONCAT_CODES = Replace(CC_CONCAT_CODES, ''' + @OldCode + ''', ''' + @NewCode + ''') WHERE CC_CONCAT_CODES LIKE ''%' + @OldCode + '%'''
		PRINT @SQL
		EXEC (@SQL)
		SET @SQL = 'UPDATE ' + Case When @Server <> '' Then @Server + '.' Else '' End + @DB + '.dbo.CST_COSTCENTRE SET CC_COPYHEADER = Replace(CC_COPYHEADER, ''' + LTrim(RTrim(@OldCode)) + ''', ''' + LTrim(RTrim(@NewCode)) + ''') WHERE CC_COPYHEADER LIKE ''%' + @OldCode + '%'''
		PRINT @SQL
		EXEC (@SQL)
		SET @SQL = 'UPDATE ' + Case When @Server <> '' Then @Server + '.' Else '' End + @DB + '.dbo.CST_COSTCENTRE2 SET CC_CONCAT_CODES2 = Replace(CC_CONCAT_CODES2, ''' + @OldCode + ''', ''' + @NewCode + ''') WHERE CC_CONCAT_CODES2 LIKE ''%' + @OldCode + '%'''
		PRINT @SQL
		EXEC (@SQL)
		SET @SQL = 'UPDATE ' + Case When @Server <> '' Then @Server + '.' Else '' End + @DB + '.dbo.CST_COSTHEADER SET CH_CODE = Replace(CH_CODE, ''' + LTrim(RTrim(@OldCode)) + ''', ''' + LTrim(RTrim(@NewCode)) + ''') WHERE CH_CODE LIKE ''%' + @OldCode + '%'''
		PRINT @SQL
		EXEC (@SQL)
		SET @SQL = 'UPDATE ' + Case When @Server <> '' Then @Server + '.' Else '' End + @DB + '.dbo.CST_DETAIL SET CT_COSTHEADER = Replace(CT_COSTHEADER, ''' + LTrim(RTrim(@OldCode)) + ''', ''' + LTrim(RTrim(@NewCode)) + ''') WHERE CT_COSTHEADER LIKE ''%' + @OldCode + '%'''
		PRINT @SQL
		EXEC (@SQL)
		SET @SQL = 'UPDATE ' + Case When @Server <> '' Then @Server + '.' Else '' End + @DB + '.dbo.SL_PL_NL_DETAIL SET DET_COSTHEADER = Replace(DET_COSTHEADER, ''' + LTrim(RTrim(@OldCode)) + ''', ''' + LTrim(RTrim(@NewCode)) + ''') WHERE DET_COSTHEADER LIKE ''%' + @OldCode + '%'''
		PRINT @SQL
		EXEC (@SQL)

		FETCH csr_CodeChanges INTO @OldCode, @NewCode
	END

	CLOSE csr_CodeChanges
	DEALLOCATE csr_CodeChanges
	-- *********************************************

	SET @SQL = 'UPDATE V
SET V.CH_CODE = E.ClientCode, V.CH_NAME = Left(E.ClientName,40), CH_DESCRIPTION = ''Practice Engine Client '' + E.ClientShortCode
FROM tblEngagement E INNER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTHEADER V ON E.ContIndex = V.CH_PRIMARY'

	PRINT @SQL
	EXEC (@SQL)

	SET @SQL = 'INSERT INTO '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTHEADER (CH_CODE, CH_NAME, CH_DESCRIPTION, CH_STATUS, CH_USED, CH_PRIMARY, CH_LEVEL, CH_SOURCE)
SELECT E.ClientCode, Left(E.ClientName,40), ' + CHAR(39) + 'Practice Engine Client ' +CHAR(39) + ' + E.ClientShortCode, ' + CHAR(39) + 'A' + CHAR(39) + ', 0, E.ContIndex, 0, ' + CHAR(39) + 'P' + CHAR(39) + '
FROM tblEngagement E LEFT OUTER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTHEADER V ON E.ContIndex = V.CH_PRIMARY
WHERE V.CH_CODE IS NULL'

	PRINT @SQL
	EXEC (@SQL)

	SET @SQL = 'UPDATE V
SET CH_STATUS = ''A''
FROM tblEngagement E INNER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTHEADER V ON E.ContIndex = V.CH_PRIMARY'


	PRINT @SQL
	EXEC (@SQL)

	SET @SQL = 'UPDATE V
SET CH_STATUS = ''X''
FROM tblEngagement E INNER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTHEADER V ON E.ContIndex = V.CH_PRIMARY
WHERE E.ClientStatus IN (''LOST'',''LOCKED'') AND V.CH_STATUS <> ''X'''


	PRINT @SQL
	EXEC (@SQL)

	SET @SQL = 'UPDATE V
SET CH_STATUS = ''S''
FROM tblEngagement E INNER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTHEADER V ON E.ContIndex = V.CH_PRIMARY
WHERE E.ClientStatus = ''SUSPENDED'' AND V.CH_STATUS <> ''S'''


	PRINT @SQL
	EXEC (@SQL)

	SET @SQL = 'UPDATE V
SET V.CC_CONCAT_CODES = Left(E.ClientCode + ''          '',10) + CS.ServIndex, V.CC_COPYHEADER = E.ClientCode, V.CC_CODE = CS.ServIndex, V.CC_NAME = Left(LTrim(RTrim(CS.ServTitle)),40), V.CC_DESCRIPTION = ' + CHAR(39) + 'Generic' + CHAR(39) + '
FROM tblEngagement E INNER JOIN tblClientServices CS ON E.ContIndex = CS.ContIndex INNER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTCENTRE V ON CS.CSIndex = V.CC_PRIMARY'

	PRINT @SQL
	EXEC (@SQL)

	SET @SQL = 'INSERT INTO '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTCENTRE (CC_CODE, CC_NAME, CC_DESCRIPTION, CC_USED, CC_STATUS, CC_CHRG_RATE, CC_ANALYSIS, CC_SORT, CC_USER_SUBTOT, CC_LEVEL, CC_LEVELPOINTER, CC_CONCAT_CODES, CC_COPYHEADER, CC_PRIMARY, CC_SOURCE)
SELECT CS.ServIndex, Left(LTrim(RTrim(S.ServTitle)),40), ' + CHAR(39) + 'Generic' + CHAR(39) + ', 0, ' + CHAR(39) + 'A' + CHAR(39) + ', ' + CHAR(39) + CHAR(39) + ', ' + CHAR(39) + CHAR(39) + ', ' + CHAR(39) + CHAR(39) + ', ' + CHAR(39) + CHAR(39) + ', 1, ' + CHAR(39) + CHAR(39) + ', Left(E.ClientCode + ' + CHAR(39) + '          ' + CHAR(39) + ',10) + CS.ServIndex, E.ClientCode, CS.CSIndex, ' + CHAR(39) + 'P' + CHAR(39)  + '
FROM tblClientServices CS INNER JOIN tblEngagement E ON CS.ContIndex = E.ContIndex INNER JOIN tblServices S ON CS.ServIndex = S.ServIndex LEFT OUTER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTCENTRE V ON CS.CSIndex = V.CC_PRIMARY
WHERE V.CC_PRIMARY IS NULL AND Left(E.ClientCode + ' + CHAR(39) + '          ' + CHAR(39) + ',10) + CS.ServIndex COLLATE database_default NOT IN (Select CC_CONCAT_CODES COLLATE database_default From '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTCENTRE)'

	PRINT @SQL
	EXEC (@SQL)

	SET @SQL = 'UPDATE V
SET CC_STATUS = ' + CHAR(39) + 'A' + CHAR(39) + '
FROM tblClientServices CS INNER JOIN tblEngagement E ON CS.ContIndex = E.ContIndex INNER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTCENTRE V ON CS.CSIndex = V.CC_PRIMARY'


	PRINT @SQL
	EXEC (@SQL)

	SET @SQL = 'UPDATE V
SET CC_STATUS = ' + CHAR(39) + 'X' + CHAR(39) + '
FROM tblClientServices CS INNER JOIN tblEngagement E ON CS.ContIndex = E.ContIndex INNER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTCENTRE V ON CS.CSIndex = V.CC_PRIMARY
WHERE (E.ClientStatus = ' + CHAR(39) + 'LOST' +CHAR(39) + ' AND V.CC_STATUS <> ' + CHAR(39) + 'X' + CHAR(39) + ') OR CS.ServActPos = 0'


	PRINT @SQL
	EXEC (@SQL)

	SET @SQL = 'UPDATE V
SET CC_STATUS = ' + CHAR(39) + 'S' + CHAR(39) + '
FROM tblClientServices CS INNER JOIN tblEngagement E ON CS.ContIndex = E.ContIndex INNER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTCENTRE V ON CS.CSIndex = V.CC_PRIMARY
WHERE E.ClientStatus = ' + CHAR(39) + 'SUSPENDED' +CHAR(39) + ' AND V.CC_STATUS <> ' + CHAR(39) + 'S' + CHAR(39)

	PRINT @SQL
	EXEC (@SQL)


	SET @SQL = 'INSERT INTO '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTCENTRE (CC_CODE, CC_NAME, CC_DESCRIPTION, CC_USED, CC_STATUS, CC_CHRG_RATE, CC_ANALYSIS, CC_SORT, CC_USER_SUBTOT, CC_LEVEL, CC_LEVELPOINTER, CC_CONCAT_CODES, CC_COPYHEADER, CC_PRIMARY, CC_SOURCE)
SELECT Ltrim(RTrim(Str(J.Job_Idx))), Left(LTrim(RTrim(S.ServTitle)) + ' + CHAR(39) + ' - ' + CHAR(39) + ' + LTrim(RTrim(J.Job_Name)),40), J.Job_Name, 0, ' + CHAR(39) + 'A' + CHAR(39) + ', ' + CHAR(39) + CHAR(39) + ', ' + CHAR(39) + CHAR(39) + ', ' + CHAR(39) + CHAR(39) + ', ' + CHAR(39) + CHAR(39) + ', 1, ' + CHAR(39) + CHAR(39) + ', Left(E.ClientCode + ' + CHAR(39) + '          '  + CHAR(39) + ',10) + Ltrim(RTrim(Str(J.Job_Idx))), E.ClientCode, J.Job_Idx, ' + CHAR(39) + 'P' + CHAR(39)  + '
FROM tblJob_Header J INNER JOIN tblJob_Serv JS ON J.Job_Idx = JS.Job_Idx INNER JOIN tblServices S ON JS.ServIndex = S.ServIndex INNER JOIN tblEngagement E ON J.ContIndex = E.ContIndex LEFT OUTER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTCENTRE V ON J.Job_Idx = V.CC_PRIMARY
WHERE V.CC_PRIMARY IS NULL AND E.ClientOrganisation = ' + LTrim(Str(@Org))

	PRINT @SQL
	EXEC (@SQL)
	
	SET @SQL = 'UPDATE V
SET CC_STATUS = ' + CHAR(39) + 'X' + CHAR(39) + '
FROM tblJob_Header J INNER JOIN tblEngagement E ON J.ContIndex = E.ContIndex INNER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..CST_COSTCENTRE V ON J.Job_Idx = V.CC_PRIMARY
WHERE (E.ClientStatus = ' + CHAR(39) + 'LOST' +CHAR(39) + ' AND V.CC_STATUS <> ' + CHAR(39) + 'X' + CHAR(39) + ') OR J.Job_Status > 2 AND E.ClientOrganisation = ' + LTrim(Str(@Org))

	PRINT @SQL
	EXEC (@SQL)
	
	SET @SQL = 'INSERT INTO '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..SYS_DIMENSIONS (DIM_TEXT, DIM_USER_PUTIN, DIM_DATE_PUTIN, DIM_TYPE1, DIM_TYPE2, DIM_TYPE3, DIM_SORTORDER, DIM_SL, DIM_NL, DIM_PL, DIM_SOP, DIM_POP)
SELECT Left(C.ChargeCode + '' - '' + C.ChargeName,20), ''SA'', GetDate(), 0, 0, 1, 0, 0, 1, 1, 0, 1
FROM tblTimechargeCode C LEFT OUTER JOIN '
	IF @Server <> ''
		SET @SQL = @SQL + @Server + '.'
	SET @SQL = @SQL + @DB + '..SYS_DIMENSIONS D ON C.ChargeCode COLLATE database_default = D.DIM_USER_PUTIN COLLATE database_default 
WHERE C.ChargeCategory = ''ACCESS'' AND D.DIM_PRIMARY IS NULL'

	PRINT @SQL 
	EXEC (@SQL)

	FETCH csr_Org INTO @Org, @Server, @DB
	END

CLOSE csr_Org
DEALLOCATE csr_Org
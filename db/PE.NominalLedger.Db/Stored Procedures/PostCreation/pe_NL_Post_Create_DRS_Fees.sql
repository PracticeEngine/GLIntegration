CREATE PROCEDURE [dbo].[pe_NL_Post_Create_DRS_Fees]
	@DRSOffice bit,
	@DRSServ bit,
	@DRSPart bit,
	@DRSDept bit,
	@DRSDetail bit,
	@DRSPeriod int
AS

	DECLARE @SQL varchar(8000)
	
	SELECT	RefMin As DebtTranIndex, Max(NLIndex) As MaxNLIndex
	INTO	#Idxs
	FROM	tblTranNominal
	WHERE	NLPosted = 0 AND NLPeriodIndex = @DRSPeriod AND NLSource = 'DRS' AND TransTypeIndex IN (3,4,6,14)
	GROUP BY RefMin
	
	SELECT @DRSPeriod As NLPeriodIndex, D.DebtTranDate As NLDate, D.PracID AS NLOrg, 'DRS' AS NLSource, 'PL' AS NLSection,
		CASE WHEN Coalesce(DD.DebtDetType, 'TIME') = 'TIME' THEN 'FEES-T' ELSE 'FEES-D' END AS NLAccount, 
		CASE WHEN D.DebtTranType IN (3,6) THEN 'DRCON' ELSE 'DRSUS' END As DRSCode,
		CASE WHEN D.DebtTranType IN (3,6) THEN 'VATOUT' ELSE 'VATSUS' END As VATCode,
		E.ClientOffice As Office, DD.DebtDetService As Service, D.DebtTranPartner As Partner, E.ClientDepartment As Department, D.DebtTranRefAlpha As TransRefAlpha,
		D.DebtTranMemo As NLNarrative, D.ContIndex, Amount As Sales, VATAmount As VAT, I.MaxNLIndex, DD.VATRate As VATRateCode
	INTO #POST
	FROM tblTranDebtor D 
	INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
	INNER JOIN tblTranDebtorDetail DD ON D.DebtTranIndex = DD.DebtTranIndex
	INNER JOIN #Idxs I ON D.DebtTranIndex = I.DebtTranIndex
	
	--SELECT * FROM #Post
	
	SET @SQL = 'INSERT INTO tblTranNominalPost(NomPeriodIndex, NomDate, NomOrg, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomAmount, NomVATAmount, NomPostAcc, NomNarrative, NomMaxRef, NomJnlType, NomDRSCode, NomVATCode, NomVATRateCode, NomPosted)
	SELECT NLPeriodIndex, NLDate, NLOrg, ''DRS'', ''PL'', NLAccount'
	
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
	
	SET @SQL = @SQL + ', Sales, VAT, '''' AS PostAcc'
	
	IF @DRSDetail = 1
		SET @SQL = @SQL + ', ' + CHAR(39) + 'Ref:' + CHAR(39) + ' + TransRefAlpha + ' + CHAR(39) + '/Client:' + CHAR(39) + ' + ClientName + ' + CHAR(39) + '/' + CHAR(39) + ' + NLNarrative'
	ELSE
		SET @SQL = @SQL + ', ' +CHAR(39) + CHAR(39)
	
	SET @SQL = @SQL + ', MaxNLIndex, ''VJL'', DRSCode, VATCode, VATRateCode, 0
	FROM #Post '
	
	IF @DRSDetail = 1
		SET @SQL = @SQL + 'LEFT OUTER JOIN tblEngagement ON #Post.ContIndex = tblEngagement.ContIndex'
	
	PRINT @SQL
	
	EXEC (@SQL)
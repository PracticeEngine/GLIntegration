CREATE PROCEDURE [dbo].[pe_NL_Disbs_AD]

@Org int,
@PeriodEnd datetime,
@User int,
@Result as int = 0 OUTPUT

AS
DECLARE @DisbIndex int
DECLARE @MaxDisb int
DECLARE @ClientCode varchar(10)
DECLARE @Job_Idx varchar(10)
DECLARE @ServIndex varchar(10)
DECLARE @Narr varchar(255)
DECLARE @PostDesc varchar(255)
DECLARE @Rest varchar(255)
DECLARE @TotAmt money
DECLARE @NumTrans int
DECLARE @NumTransAll int
DECLARE @DisbCode varchar(10)
DECLARE @DisbDate datetime
DECLARE @StaffUser nvarchar(256)

SELECT @StaffUser = StaffUser FROM tblStaff WHERE StaffIndex = @User

SET @NumTransAll = 0

		CREATE TABLE #wrk (
					CT_NETT money, 
					CT_VAT money, 
					CT_VATCODE varchar(4) Collate Database_Default, 
					CT_GROSS money, 
					CT_INVOICE_FLAG tinyint, 
					CT_TRANTYPE varchar(3) Collate Database_Default, 
					CT_STATUS varchar(1) Collate Database_Default, 
					CT_HEADER_REF varchar(25) Collate Database_Default, 
					CT_POSTTYPE varchar(1) Collate Database_Default, 
					CT_SORTTYPE varchar(6) Collate Database_Default,
					CT_DATE datetime, 
					CT_DETAIL varchar(240) Collate Database_Default, 
					CT_DESCRIPTION varchar(20) Collate Database_Default, 
					CT_ACCOUNT varchar(10) Collate Database_Default, 
					CT_COSTHEADER varchar(10) Collate Database_Default, 
					CT_COSTCENTRE varchar(10) Collate Database_Default, 
					CT_TRANSACTION_LINK float, 
					CT_PRIMARY int, 
					CT_SOURCE varchar(1) Collate Database_Default,
					DisbCode varchar(10) Collate Database_Default,
					ClientCode varchar(10) Collate Database_Default,
					Job_Idx int,
					ServIndex varchar(10) Collate Database_Default,
					Narrative varchar(240) Collate Database_Default,
					VendorID varchar(20) Collate Database_Default,
					SupplierName varchar(60) Collate Database_Default,
					PostIt bit,
					DisbDate datetime,
					Office varchar(10) Collate Database_Default
					)

		CREATE TABLE #map (NLCode varchar(5) Collate Database_Default, DisbCode varchar(10) Collate Database_Default)

		INSERT INTO #Map(NLCode, DisbCode) VALUES('ACC', 'ACC')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('ADV', 'ADV')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('ANN', 'ANR')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('CFI', 'CROFL')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('CAP', 'CCD')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('CFO', 'COF')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('COS', 'COS')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('SEA', 'SCH')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('CON', 'CRO')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('DEE', 'DOC')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('DEL', 'DEL')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('COU', 'DEL')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('FEE', 'FEE')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('COF', 'FOR')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('FOR', 'FOR')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('FXC', 'FXCOM')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('GEN', 'GEN')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('MEA', 'ML')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('MIL', 'MLG')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('MOB', 'MOB')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('ONA', 'ON')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('PRK', 'PKG')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('PAR', 'PEX')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('POS', 'STA')
		--INSERT INTO #Map(NLCode, DisbCode) VALUES('CFI', 'REG')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('REV', 'REV')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('SHT', 'STR')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('STA', 'STD')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('TAX', 'TXI')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('AIR', 'TRA')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('TRA', 'TRA')
		INSERT INTO #Map(NLCode, DisbCode) VALUES('WOF', 'WO')

	SET @DisbCode = (SELECT DisbStd FROM tblTranNominalControl)
	SET @DisbDate = (SELECT Min(TimePeriodEndDate) FROM tblControlTimePeriods WHERE PeriodEndDate = @PeriodEnd)
	IF @DisbDate IS NULL
		SET @DisbDate = @PeriodEnd


	Declare @Server varchar(50),
		@DB varchar(50),
		@SQL varchar(8000)

	SELECT @Server = NLServer, @DB = NLDatabase
	FROM tblTranNominalOrgs
	WHERE PracID = @Org

		-- PL Transactions
		SET @SQL = 'INSERT INTO #wrk(CT_NETT, CT_VAT, CT_VATCODE, CT_GROSS, CT_INVOICE_FLAG, CT_TRANTYPE, CT_STATUS, CT_HEADER_REF, CT_POSTTYPE, CT_SORTTYPE, CT_DATE, CT_DETAIL, CT_DESCRIPTION, CT_ACCOUNT, CT_COSTHEADER, CT_COSTCENTRE, CT_TRANSACTION_LINK, CT_PRIMARY, CT_SOURCE, DisbCode, ClientCode, Job_Idx, ServIndex, Narrative, VendorID, SupplierName, PostIt, DisbDate, Office)
		SELECT C.CT_NETT, C.CT_VAT, C.CT_VATCODE, C.CT_GROSS, C.CT_INVOICE_FLAG, C.CT_TRANTYPE, C.CT_STATUS, C.CT_HEADER_REF, C.CT_POSTTYPE, C.CT_SORTTYPE, C.CT_DATE, C.CT_DETAIL, C.CT_DESCRIPTION, C.CT_ACCOUNT, C.CT_COSTHEADER, C.CT_COSTCENTRE, C.CT_TRANSACTION_LINK, C.CT_PRIMARY, C.CT_SOURCE, 
		COALESCE (CASE WHEN LEFT(C.CT_NOMINAL,3) = ''104'' THEN ''D'' ELSE ''E'' END + M.DisbCode,''' + LTrim(@DisbCode) + ''') As DisbCode, '''' AS ClientCode, '''' AS Job_Idx, '''' As ServIndex, '''' AS Narrative, C.CT_ACCOUNT AS VendorID, P.SUNAME As Supplier, 0 AS PostIt, C.CT_DATE As DisbDate, '''' As Office 
		FROM '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '..CST_DETAIL C INNER JOIN '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '..NL_ACCOUNTS N ON C.CT_NOMINAL = N.NCODE INNER JOIN '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '..PL_ACCOUNTS P ON C.CT_ACCOUNT = P.SUCODE INNER JOIN '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '..SL_PL_NL_DETAIL D ON C.CT_TRANSACTION_LINK = D.DET_PRIMARY LEFT OUTER JOIN #Map M ON Right(C.CT_NOMINAL,3) COLLATE database_default = M.NLCode
		WHERE C.CT_Invoice_Flag = 0 AND C.CT_TRANTYPE IN (''INV'',''CRN'') AND N.N_FORCE_COSTING = 1'

		PRINT @SQL

		EXEC (@SQL)
		--CRO Transactions
		SET @SQL = 'INSERT INTO #wrk(CT_NETT, CT_VAT, CT_VATCODE, CT_GROSS, CT_INVOICE_FLAG, CT_TRANTYPE, CT_STATUS, CT_HEADER_REF, CT_POSTTYPE, CT_SORTTYPE, CT_DATE, CT_DETAIL, CT_DESCRIPTION, CT_ACCOUNT, CT_COSTHEADER, CT_COSTCENTRE, CT_TRANSACTION_LINK, CT_PRIMARY, CT_SOURCE, DisbCode, ClientCode, Job_Idx, ServIndex, Narrative, VendorID, SupplierName, PostIt, DisbDate, Office)
		SELECT C.CT_NETT, C.CT_VAT, C.CT_VATCODE, C.CT_GROSS, C.CT_INVOICE_FLAG, C.CT_TRANTYPE, C.CT_STATUS, C.CT_HEADER_REF, C.CT_POSTTYPE, CT_SORTTYPE, C.CT_DATE, C.CT_DETAIL, C.CT_DESCRIPTION, C.CT_ACCOUNT, C.CT_COSTHEADER, C.CT_COSTCENTRE, C.CT_TRANSACTION_LINK, C.CT_PRIMARY, C.CT_SOURCE, 
		COALESCE (M.DisbCode,''' + LTrim(@DisbCode) + ''') As DisbCode, '''' AS ClientCode, '''' AS Job_Idx, '''' As ServIndex, '''' AS Narrative, '''' AS VendorID, '''' As Supplier, 0 AS PostIt, C.CT_DATE As DisbDate, '''' As Office 
		FROM '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '..CST_DETAIL C LEFT OUTER JOIN #Map M ON Right(C.CT_NOMINAL,3) COLLATE database_default = M.NLCode INNER JOIN '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '..NL_ACCOUNTS N ON C.CT_NOMINAL = N.NCODE 
		WHERE C.CT_Invoice_Flag = 0 AND C.CT_TRANTYPE = ''JNL'' AND N.N_FORCE_COSTING = 1'

		PRINT @SQL

		EXEC (@SQL)
		-- Bank Transactions
		SET @SQL = 'INSERT INTO #wrk(CT_NETT, CT_VAT, CT_VATCODE, CT_GROSS, CT_INVOICE_FLAG, CT_TRANTYPE, CT_STATUS, CT_HEADER_REF, CT_POSTTYPE, CT_SORTTYPE, CT_DATE, CT_DETAIL, CT_DESCRIPTION, CT_ACCOUNT, CT_COSTHEADER, CT_COSTCENTRE, CT_TRANSACTION_LINK, CT_PRIMARY, CT_SOURCE, DisbCode, ClientCode, Job_Idx, ServIndex, Narrative, VendorID, SupplierName, PostIt, DisbDate, Office)
		SELECT C.CT_NETT, C.CT_VAT, C.CT_VATCODE, C.CT_GROSS, C.CT_INVOICE_FLAG, C.CT_TRANTYPE, C.CT_STATUS, C.CT_HEADER_REF, C.CT_POSTTYPE, CT_SORTTYPE, C.CT_DATE, C.CT_DETAIL, C.CT_DESCRIPTION, C.CT_ACCOUNT, C.CT_COSTHEADER, C.CT_COSTCENTRE, C.CT_TRANSACTION_LINK, C.CT_PRIMARY, C.CT_SOURCE, 
		COALESCE (M.DisbCode,''' + LTrim(@DisbCode) + ''') As DisbCode, '''' AS ClientCode, '''' AS Job_Idx, '''' As ServIndex, '''' AS Narrative, C.CT_ACCOUNT AS VendorID, A.NNAME As Supplier, 0 AS PostIt, C.CT_DATE As DisbDate, '''' As Office 
		FROM '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '..CST_DETAIL C INNER JOIN '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '..NL_ACCOUNTS F ON C.CT_NOMINAL = F.NCODE INNER JOIN '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '..NL_TRANSACTIONS N ON C.CT_HEADER_REF = N.NT_HEADER_REF AND C.CT_HEADER_LINK = N.NT_HEADER_KEY INNER JOIN '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '..NL_ACCOUNTS A ON N.NT_GROSS_CONTRA = A.NCODE LEFT OUTER JOIN #Map M ON Right(C.CT_NOMINAL,3) COLLATE database_default = M.NLCode
		WHERE C.CT_Invoice_Flag = 0 AND C.CT_TRANTYPE = ''VJL'' AND F.N_FORCE_COSTING = 1'

		PRINT @SQL

		EXEC (@SQL)

		SET @NumTrans = (SELECT Count(*) FROM #wrk)
		IF @NumTrans IS NULL
			SET @NumTrans = 0
	
		PRINT Str(@NumTrans)

		IF @NumTrans = 0 GOTO NOTRANS

		UPDATE W
		SET W.ClientCode = W.CT_CostHeader, W.Job_Idx = J.Job_Idx, W.ServIndex = JS.ServIndex
		FROM #wrk W INNER JOIN tblJob_Header J ON W.CT_CostCentre = J.Job_Idx INNER JOIN tblJob_Serv JS ON J.Job_Idx = JS.Job_Idx
		WHERE Ascii(W.CT_CostCentre) < 65

		UPDATE W
		SET W.ClientCode = W.CT_CostHeader, W.Job_Idx = 0, W.ServIndex = W.CT_CostCentre
		FROM #wrk W
		WHERE Ascii(W.CT_CostCentre) > 64

		UPDATE W
		SET W.Office = E.ClientOffice
		FROM #wrk W INNER JOIN tblEngagement E ON W.ClientCode = E.ClientCode

		UPDATE W
		SET W.Narrative = Left(W.SupplierName + '/' + W.CT_Header_Ref + '/' + W.CT_Detail, 240)
		FROM #wrk W
		WHERE W.CT_TRANTYPE IN ('INV','CRN','VJL')

		UPDATE W
		SET W.Narrative = Left(W.CT_Header_Ref + '/' + W.CT_Detail, 240)
		FROM #wrk W
		WHERE W.CT_TRANTYPE = 'JNL'
		
		UPDATE W
		SET CT_NETT = CT_NETT * -1, CT_VAT = CT_VAT * -1, CT_GROSS = CT_GROSS * -1
		FROM #wrk W
		WHERE CT_SORTTYPE IN ('PLCRN','NLVJLC')

		BEGIN TRAN

		Declare @Office varchar(10)
	
		DECLARE 	csr_Office CURSOR DYNAMIC		
		FOR SELECT 	Office
		FROM 		#wrk
		GROUP BY	Office

		OPEN csr_Office
		FETCH 	csr_Office INTO @Office
		WHILE (@@FETCH_STATUS=0) 
			BEGIN
			SET @TotAmt = (SELECT Sum(CT_Gross) FROM #wrk WHERE Office = @Office)
			IF @TotAmt IS NULL
				SET @TotAmt = 0
	
			IF @@ERROR <> 0 GOTO TRAN_ABORT
	
			INSERT INTO tblExpenseHeader (ExpOffice, ExpType, ExpStatus, ExpDate, ExpDesc, ExpAdvance, ExpBalRec, ExpTotal, ExpComments, ExpUpdated, ExpUpdatedBy)
			SELECT @Office, 'GENERAL', 'ACTIVE',
				Case When GetDate() > (Select PracPeriodEnd From tblControl Where PracID = 1) Then (Select PracPeriodEnd From tblControl Where PracID = 1) Else GetDate() End AS ExpDate,
				'Access Dimensions', 0, 0, @TotAmt, 'Import From Access Dimensions', GetDate(), @StaffUser
	
			IF @@ERROR <> 0 GOTO TRAN_ABORT
	
			SET @DisbIndex = @@IDENTITY
	
			IF @@ERROR <> 0 GOTO TRAN_ABORT
	
			INSERT INTO tblExpenseDetail (ExpIndex, [Description], ExpDate, Status, ClientCode, ClientIndex, ClientName, ServiceCode, ServPeriod, DisbCode, ChargeBand, Quantity, ChargeRate, ChargeAmount, VATRate, ChargeVAT, Supplier, Reference)
			SELECT @DisbIndex, #wrk.Narrative, DisbDate, 'ACTIVE', Eng.ClientCode, Eng.ContIndex, Eng.ClientName, #wrk.ServIndex, Job.Job_Idx, DisbCode, 1, 0, #wrk.CT_Nett, #wrk.CT_Nett, '1', #wrk.CT_VAT, Coalesce(RTrim(#wrk.VendorID), ''), left(RTrim(#wrk.CT_Header_Ref),20)
			FROM (#wrk INNER JOIN tblEngagement AS Eng ON #wrk.clientcode = Eng.ClientCode) INNER JOIN tblJob_Header AS Job ON #wrk.Job_Idx = Job.Job_Idx
			WHERE Office = @Office

			IF @@ERROR <> 0 GOTO TRAN_ABORT

			SET @SQL = 'UPDATE D
			SET D.CT_Invoice_Flag = 1
			FROM '
			IF @Server <> ''
				SET @SQL = @SQL + @Server + '.'
			SET @SQL = @SQL + @DB + '..CST_DETAIL D INNER JOIN #wrk W ON D.CT_Primary = W.CT_Primary
			WHERE W.Office = ''' + LTrim(@Office) + ''''

			EXEC (@SQL)
	
			IF @@ERROR <> 0 GOTO TRAN_ABORT

			FETCH csr_Office INTO @Office
			END
	
		CLOSE csr_Office
		DEALLOCATE csr_Office

		COMMIT TRAN

		NOTRANS:
		IF @NumTrans = 0
		BEGIN
			IF @NumTransAll = 0 SET @NumTransAll = 0
		END
		ELSE
		BEGIN
			SET @NumTransAll = 1
		END

	IF @NumTransAll = 0 GOTO NOTRANS2

	GOTO FINISH

TRAN_ABORT:
	ROLLBACK TRAN
	SET @Result = -1
	GOTO DONE

FINISH:
	SET @Result = 0
	GOTO DONE

NOTRANS2:
	SET @Result = -2

DONE:
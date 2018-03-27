/*
CUSTOM: This Stored Procedure should be customized for your environment
This StoredProcedure Creates the Nominal Ledger in bulk from the WIP Transactions in PE
*/

CREATE PROCEDURE [dbo].[pe_NL_WIP]

@Result int OUTPUT

AS

DECLARE @MonthEnd datetime,
@PeriodIdx int,
@WIPRef int,
@FeeSource char(3),
@MinFee int,
@MaxFee int,
@WIPFactor decimal (9,2),
@ICFactor decimal (9,2),
@InterCompany bit,
@InterCo int,
@ProvIdx int

	SET @MonthEnd  = (Select PracPeriodEnd From tblControl Where PracID = 1)
	IF @MonthEnd IS NULL GOTO TRAN_ABORT

	SET @PeriodIdx = (Select PeriodIndex From tblControlPeriods WHERE PeriodEndDate = @MonthEnd)

	SET @WIPRef = (Select Max(RefMax) FROM tblTranNominal WHERE NLSource = 'WIP')
	IF @WIPRef IS NULL
		SET @WIPRef = 0

	SET @ProvIdx = (Select Max(RefMax) FROM tblTranNominal WHERE NLAccount = 'WPROV')
	IF @ProvIdx IS NULL
		SET @ProvIdx = 0

	SELECT @FeeSource = FeeSource, @InterCompany = InterCo
	From tblTranNominalControl

	BEGIN TRAN
	--/Update Prior Month Transactions dated in this period with correct PeriodIndex
	UPDATE tblTranNominal
	SET NLPeriodIndex = @PeriodIdx
	WHERE NLPeriodIndex = 0 AND NLDate <= @MonthEnd 

	DECLARE @WIPInd int
	DECLARE @StaffInd int
	DECLARE @TranType int
	DECLARE @WIPType varchar(10)
	DECLARE @Client int

	DECLARE csr_Trans CURSOR DYNAMIC 
	FOR SELECT W.WIPIndex, W.StaffIndex, W.TransTypeIndex, W.WIPType, W.ContIndex
	FROM tblTranWIP AS W
	WHERE W.WIPIndex > @WIPRef 

	OPEN csr_Trans

	FETCH csr_Trans INTO @WIPInd, @StaffInd, @TranType, @WIPType, @Client
	WHILE (@@FETCH_STATUS=0) 
		BEGIN
		IF @TranType = 1 --Process Timesheet Entries
			BEGIN
			IF @Client < 900000
				BEGIN
				--/Debit Chargeable Time (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END,W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'BS' AS NLSection, 'WIP' AS NLAccount, W.TransTypeIndex, 'UNKNOWN' AS Office, W.WIPService As Service, E.ClientPartner, ''  AS Department, 
					W.WIPHours AS Units, W.WIPAmount AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblServices Srv ON Srv.ServIndex = W.WIPService
				WHERE W.WIPIndex = @WIPInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
			
				--/Credit Chargeable Time (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END,W.WIPDate AS NLDate, S.StaffOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'REV' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, ''  AS Department, 
					W.WIPHours*-1 AS Units, W.WIPAmount*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex
				WHERE W.WIPIndex = @WIPInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				END
			END

		IF @TranType = 2 --Process Disbursement Entries
			BEGIN
			IF @Client < 900000
				BEGIN
				--/Debit Chargeable Disbs (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd  THEN 0 ELSE @PeriodIdx END,W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'BS' AS NLSection, 'WIP' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, '' AS Department, 
					W.WIPHours AS Units, W.WIPAmount AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex 
				INNER JOIN tblExpenseDetail D ON W.WIPRef = D.DetailIndex INNER JOIN tblExpenseHeader H ON D.ExpIndex = H.ExpIndex
				WHERE W.WIPIndex = @WIPInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
			
				--/Credit Chargeable Disbs (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd  THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'CLIEXP' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, '' AS Department, 
					W.WIPHours*-1 AS Units, W.WIPAmount*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex 
				INNER JOIN tblExpenseDetail D ON W.WIPRef = D.DetailIndex INNER JOIN tblExpenseHeader H ON D.ExpIndex = H.ExpIndex
				WHERE W.WIPIndex = @WIPInd

				IF @@ERROR <> 0 GOTO TRAN_ABORT	
				
				--/Credit Chargeable Disbs Recoverable (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd  THEN 0 ELSE @PeriodIdx END,W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'BS' AS NLSection, 'EXPCON' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, '' AS Department, 
					W.WIPHours*-1 AS Units, W.WIPAmount*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex 
				INNER JOIN tblExpenseDetail D ON W.WIPRef = D.DetailIndex INNER JOIN tblExpenseHeader H ON D.ExpIndex = H.ExpIndex
				WHERE W.WIPIndex = @WIPInd AND W.StaffIndex <> 0
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
			
				--/Debit Expenses (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd  THEN 0 ELSE @PeriodIdx END,W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, W.WIPAnalysis AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, '' AS Department, 
					W.WIPHours AS Units, W.WIPAmount AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex 
				INNER JOIN tblExpenseDetail D ON W.WIPRef = D.DetailIndex INNER JOIN tblExpenseHeader H ON D.ExpIndex = H.ExpIndex
				WHERE W.WIPIndex = @WIPInd AND W.WIPAnalysis IN ('ENT','PROMO') AND S.StaffDepartment IN ('FINANCIAL','IT','CR','HR') AND W.StaffIndex <> 0
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
							
				--/Credit Chargeable Disbs (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd  THEN 0 ELSE @PeriodIdx END,W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, W.WIPAnalysis AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, '' AS Department, 
					W.WIPHours AS Units, W.WIPAmount AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex 
				INNER JOIN tblExpenseDetail D ON W.WIPRef = D.DetailIndex INNER JOIN tblExpenseHeader H ON D.ExpIndex = H.ExpIndex
				WHERE W.WIPIndex = @WIPInd AND W.WIPAnalysis IN ('ENT','PROMO') AND S.StaffDepartment NOT IN ('FINANCIAL','IT','CR','HR') AND W.StaffIndex <> 0
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				
				--/Credit Chargeable Disbs (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd  THEN 0 ELSE @PeriodIdx END,W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'CLIEXP' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, S.StaffDepartment AS Department, 
					W.WIPHours AS Units, W.WIPAmount AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex 
				INNER JOIN tblExpenseDetail D ON W.WIPRef = D.DetailIndex INNER JOIN tblExpenseHeader H ON D.ExpIndex = H.ExpIndex
				WHERE W.WIPIndex = @WIPInd AND W.WIPAnalysis NOT IN ('ENT','PROMO') AND S.StaffDepartment IN ('FINANCIAL','IT','CR','HR')  AND W.StaffIndex <> 0
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				--/Credit Chargeable Disbs (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd  THEN 0 ELSE @PeriodIdx END,W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'CLIEXP' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, '' AS Department, 
					W.WIPHours AS Units, W.WIPAmount AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex 
				INNER JOIN tblExpenseDetail D ON W.WIPRef = D.DetailIndex INNER JOIN tblExpenseHeader H ON D.ExpIndex = H.ExpIndex
				WHERE W.WIPIndex = @WIPInd AND W.WIPAnalysis NOT IN ('ENT','PROMO') AND S.StaffDepartment NOT IN ('FINANCIAL','IT','CR','HR')  AND W.StaffIndex <> 0
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				END
			ELSE
				BEGIN
				--/Credit Non charge Disbs (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd  THEN 0 ELSE @PeriodIdx END,W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'EXPCON' AS NLAccount, W.TransTypeIndex, 'UNKNOWN' AS Office, W.WIPService As Service, E.ClientPartner, S.StaffDepartment AS Department,
					W.WIPHours*-1 AS Units, W.WIPAmount*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex 
				INNER JOIN tblExpenseDetail D ON W.WIPRef = D.DetailIndex INNER JOIN tblExpenseHeader H ON D.ExpIndex = H.ExpIndex
				WHERE W.WIPIndex = @WIPInd AND S.StaffDepartment IN ('FINANCIAL','IT','CR','HR') AND W.StaffIndex <> 0
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				
				--/Credit Non charge Disbs (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd  THEN 0 ELSE @PeriodIdx END,W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'EXPCON' AS NLAccount, W.TransTypeIndex, S.StaffOffice AS Office, W.WIPService As Service, E.ClientPartner, '' AS Department,
					W.WIPHours*-1 AS Units, W.WIPAmount*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex 
				INNER JOIN tblExpenseDetail D ON W.WIPRef = D.DetailIndex INNER JOIN tblExpenseHeader H ON D.ExpIndex = H.ExpIndex
				WHERE W.WIPIndex = @WIPInd AND S.StaffDepartment NOT IN ('FINANCIAL','IT','CR','HR') AND W.StaffIndex <> 0
				IF @@ERROR <> 0 GOTO TRAN_ABORT
						
				--/Credit Non charge Disbs (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd  THEN 0 ELSE @PeriodIdx END,W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'EXPCON' AS NLAccount, W.TransTypeIndex, 'UNKNOWN'  AS Office, W.WIPService As Service, E.ClientPartner, S.StaffDepartment AS Department,
					W.WIPHours AS Units, W.WIPAmount AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex 
				INNER JOIN tblExpenseDetail D ON W.WIPRef = D.DetailIndex INNER JOIN tblExpenseHeader H ON D.ExpIndex = H.ExpIndex
				WHERE W.WIPIndex = @WIPInd AND S.StaffDepartment  IN ('FINANCIAL','IT','CR','HR') AND W.StaffIndex <> 0
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				
				--/Credit Non charge Disbs (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd  THEN 0 ELSE @PeriodIdx END,W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'EXPCON' AS NLAccount, W.TransTypeIndex, S.StaffOffice AS Office,  W.WIPService As Service, E.ClientPartner, 	'' AS Department,
					W.WIPHours AS Units, W.WIPAmount AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex 
				INNER JOIN tblExpenseDetail D ON W.WIPRef = D.DetailIndex INNER JOIN tblExpenseHeader H ON D.ExpIndex = H.ExpIndex
				WHERE W.WIPIndex = @WIPInd AND S.StaffDepartment NOT IN ('FINANCIAL','IT','CR','HR') AND W.StaffIndex <> 0
				IF @@ERROR <> 0 GOTO TRAN_ABORT
															
				
				END
			END

		IF @TranType IN (3,6) --Process Fee Entries
			BEGIN
			IF @Client < 900000
				BEGIN
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'DRCON' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, '', 
					W.WIPHours*-1 AS Units, W.WIPAmount*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex
				WHERE W.WIPIndex = @WIPInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT

				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'BS' AS NLSection, 'WIP' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, '',
					W.WIPHours AS Units, W.WIPAmount AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex
				WHERE W.WIPIndex = @WIPInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				END
			END

		IF @TranType NOT IN (1,2,3,6) --Process All Other Entries
			BEGIN
			IF @Client < 900000
				BEGIN
				--/Debit Journal (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLSource, 
					'BS' AS NLSection, 'WIP' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, '', 
					W.WIPHours AS Units, W.WIPAmount AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex 
				WHERE W.WIPIndex = @WIPInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
			
				--/Credit Journal (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLSource, 
					'PL' AS NLSection, CASE WHEN W.WIPAmount < 0 THEN 'DNADJ' ELSE 'UPADJ' END AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, '', 
					W.WIPHours*-1 AS Units, W.WIPAmount*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, Left(W.Narrative,200), W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex 
				WHERE W.WIPIndex = @WIPInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				END
			END

		FETCH 	csr_Trans INTO @WIPInd, @StaffInd, @TranType, @WIPType, @Client
		END

	CLOSE csr_Trans
	DEALLOCATE csr_Trans


	DECLARE csr_Trans CURSOR DYNAMIC 
	FOR SELECT P.ProvIndex
	FROM tblTranProvisions P
	WHERE P.ProvIndex > @ProvIdx AND P.ProvType = 'WIP'

	OPEN csr_Trans

	FETCH csr_Trans INTO @WIPInd
	WHILE (@@FETCH_STATUS=0) 
		BEGIN
		--/Debit Provisions (P/L)
		INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
		SELECT NLPeriodIndex = CASE WHEN P.ProvDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, P.ProvDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLSource, 
			'PL' AS NLSection, 'WPROV' AS NLAccount, 7, E.ClientOffice AS Office, 'UNKNOWN' As Service, E.ClientPartner, '', 
			0 AS Units, P.ProvAmount AS Amount, P.ContIndex, 'PROV', P.ProvReason, P.ProvIndex AS RefMin, P.ProvIndex AS RefMax
		FROM tblTranProvisions P INNER JOIN tblEngagement E ON P.ContIndex = E.ContIndex 
		WHERE P.ProvIndex = @WIPInd
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT
	
		--/Credit Provisions (B/S)
		INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
		SELECT NLPeriodIndex = CASE WHEN P.ProvDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, P.ProvDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLSource, 
			'BS' AS NLSection, 'WPROV' AS NLAccount, 7, E.ClientOffice AS Office, 'UNKNOWN' As Service, E.ClientPartner, '', 
			0 AS Units, P.ProvAmount*-1 AS Amount, P.ContIndex, 'PROV', P.ProvReason, P.ProvIndex AS RefMin, P.ProvIndex AS RefMax
		FROM tblTranProvisions P INNER JOIN tblEngagement E ON P.ContIndex = E.ContIndex 
		WHERE P.ProvIndex = @WIPInd
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT

		FETCH 	csr_Trans INTO @WIPInd
		END

	CLOSE csr_Trans
	DEALLOCATE csr_Trans

	COMMIT TRAN
	GOTO FINISH

TRAN_ABORT:
	ROLLBACK TRAN
	SET @Result = 1
	GOTO DONE

FINISH:
	SET @Result = 0

DONE:

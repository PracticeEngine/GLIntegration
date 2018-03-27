CREATE PROCEDURE [dbo].[pe_NL_DRS]

@Result int OUTPUT

AS
DECLARE @MonthEnd datetime,
@PeriodIdx int,
@DRSRef int,
@VATRef int,
@FeeSource char(3),
@MinFee int,
@MaxFee int,
@FirstEntry int,
@TrfIdx int,
@RRIdx int

	SET @MonthEnd  = (Select PracPeriodEnd From tblControl Where PracID = 1)
	IF @MonthEnd IS NULL GOTO TRAN_ABORT

	SET @PeriodIdx = (Select PeriodIndex From tblControlPeriods WHERE PeriodEndDate = @MonthEnd)

	SET @DRSRef = (Select Max(RefMax) FROM tblTranNominal WHERE NLSource = 'DRS')
	IF @DRSRef IS NULL
		SET @DRSRef = 0

	SET @TrfIdx = (Select Max(RefMax) FROM tblTranNominal WHERE NLAccount LIKE 'DTRF%')
	IF @TrfIdx IS NULL
		SET @TrfIdx = 0

	SET @VATRef = (Select Max(RefMax) FROM tblTranNominal WHERE NLAccount Like 'VAT%' and TransTypeIndex = 9)
	IF @VATRef IS NULL
		SET @VATRef = 0

	SET @FeeSource = (SELECT FeeSource From tblTranNominalControl)

	SET @FirstEntry = (SELECT Max(NLIndex) FROM tblTranNominal) + 1

	BEGIN TRAN

	--/Update Prior Month Transactions dated in this period with correct PeriodIndex
	UPDATE tblTranNominal
	SET NLPeriodIndex = @PeriodIdx
	WHERE NLPeriodIndex = 0 AND NLDate <= @MonthEnd

	DECLARE @DrsInd int
	DECLARE @TranType int
	DECLARE @DetType varchar(4)

	DECLARE csr_Trans CURSOR DYNAMIC 
	FOR SELECT D.DebtTranIndex, D.DebtTranType
	FROM  tblTranDebtor D
	WHERE D.DebtTranIndex > @DrsRef AND ClientCode <> 'GTFCIN'

	OPEN csr_Trans

	FETCH csr_Trans INTO @DrsInd, @TranType
	WHILE (@@FETCH_STATUS=0) 
		BEGIN
		IF @TranType IN (3,6) --Process Normal Invoice and Credit Note Entries
			BEGIN
			IF @FeeSource = 'DRS'
				BEGIN
				--/Credit Time sales analysis (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, [Service], Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'PL' AS NLSection, CASE WHEN Coalesce(DD.DebtDetType, 'TIME') = 'TIME' THEN 'FEES-T' ELSE 'FEES-D' END AS TranType, 
					D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, Coalesce(DD.DebtDetService, ''),
					TranAmount = CASE WHEN Amount IS NULL THEN DebtTranAmount*-1 ELSE Amount*-1 END, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(S.StaffDepartment, E.ClientDepartment, 'UNKNOWN')
				FROM (tblTranDebtor D INNER JOIN tblStaff S ON D.DebtTranPartner = S.StaffIndex INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex) LEFT JOIN tblTranDebtorDetail DD ON D.DebtTranIndex = DD.DebtTranIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT
		
				--/Credit VAT (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'VATOUT' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranVAT*-1 AS Amount, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT
		
				--/Debit Debtor Control (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, NetAmount, VATAmount, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 'BS' AS NLSection, 
					'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, D.DebtTranAmount, 
					D.DebtTranVAT, D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				END
			ELSE
				BEGIN
				--/Credit VAT (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'VATOUT' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranVAT*-1 AS Amount, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT
		
				--/Debit Debtor Control (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranVAT, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT
		
				--/Credit Debtor Non WIP Control (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'DRNON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranAmount*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT
		
				--/Debit Debtor Control (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranAmount, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				END
			END

		IF @TranType IN (4,14) --Process RFP Invoice and Credit Note Entries
			BEGIN
			IF @FeeSource = 'DRS'
				BEGIN
				--/Credit Time sales analysis (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Service, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'PL' AS NLSection, CASE WHEN Coalesce(DD.DebtDetType, 'TIME') = 'TIME' THEN 'FEES-T' ELSE 'FEES-D' END AS TranType, 
					D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, Coalesce(DD.DebtDetService, ''),
					TranAmount = CASE WHEN Amount IS NULL THEN DebtTranAmount*-1 ELSE Amount*-1 END, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(S.StaffDepartment, E.ClientDepartment, 'UNKNOWN')
				FROM (tblTranDebtor D INNER JOIN tblStaff S ON D.DebtTranPartner = S.StaffIndex INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex) LEFT JOIN tblTranDebtorDetail DD ON D.DebtTranIndex = DD.DebtTranIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT

				--/Credit VAT Suspense (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'VATSUS' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranVAT*-1 AS Amount, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT
/********************************************************************************************************************************************************************************************/		
				--/Debit Debtor Suspense (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, NetAmount, VATAmount, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 'BS' AS NLSection, 
					'DRSUS' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, D.DebtTranAmount, D.DebtTranVAT,
					D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				END
			ELSE
				BEGIN		
				--/Credit VAT Suspense (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'VATSUS' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranVAT*-1 AS Amount, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT
		
				--/Debit Debtor Suspense (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'DRSUS' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranVAT, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT
		
				--/Credit Debtor Non WIP Control (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'DRNON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranAmount*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT
		
				--/Debit Debtor Suspense (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'DRSUS' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranAmount, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
				WHERE D.DebtTranIndex = @DrsInd
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				END
			END

		IF @TranType = 7 --Process Journal Entries
			BEGIN
			--/Journals Clearing Account
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRJNL' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			--/Credit Debtors with Bad Debts (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END

		IF @TranType = 8 --Process Bad Debt Entries
			BEGIN
			--/Debit Bad Debt (P/L)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'PL' AS NLSection, 'BADDR' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranPMTMethod, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			--/Credit Debtors with Bad Debts (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranPMTMethod, E.ClientOffice, 
				D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END

		IF @TranType = 9 --Process Receipt Entries
			BEGIN
			--/Debit Bank with Receipts (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, B.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, CASE WHEN L.LodgeType = 'WTX' THEN 'WHTAX' ELSE 'BNKCON' END AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex INNER JOIN tblLodgementDetails L ON D.DebtTranRefNum = L.LodgeDetIndex INNER JOIN tblLodgementHeader H ON L.LodgeIndex = H.LodgeIndex INNER JOIN tblTranBank B ON H.LodgeBank = B.BankIndex 
			WHERE D.DebtTranIndex = @DrsInd

			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			--/Credit Debtors with Receipts (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT

			-- Extra Check For GT. If Client is in a different Org to the Original Bank then create receipt transfer
			IF (SELECT Count(*) FROM tblTranDebtor D INNER JOIN tblLodgementDetails L ON D.DebtTranRefNum = L.LodgeDetIndex INNER JOIN tblLodgementHeader H ON L.LodgeIndex = H.LodgeIndex INNER JOIN tblTranBank B ON H.LodgeBank = B.BankIndex WHERE D.PracID <> B.PracID AND D.DebtTranIndex = @DrsInd) > 0
				BEGIN
				--/Debit Intercompany account on client side with Receipts (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'ICC' + LTrim(Str(B.PracID)) AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex INNER JOIN tblLodgementDetails L ON D.DebtTranRefNum = L.LodgeDetIndex INNER JOIN tblLodgementHeader H ON L.LodgeIndex = H.LodgeIndex INNER JOIN tblTranBank B ON H.LodgeBank = B.BankIndex 
				WHERE D.DebtTranIndex = @DrsInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
			
				--/Credit Intercompany account on bank side with Receipts (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, B.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'ICC' + LTrim(Str(D.PracID)) AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex INNER JOIN tblLodgementDetails L ON D.DebtTranRefNum = L.LodgeDetIndex INNER JOIN tblLodgementHeader H ON L.LodgeIndex = H.LodgeIndex INNER JOIN tblTranBank B ON H.LodgeBank = B.BankIndex 
				WHERE D.DebtTranIndex = @DrsInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				END
			END

		IF @TranType = 15 --Process Reallocated Receipt Entries if organisations are different
			BEGIN
			IF (SELECT Count(*) FROM tblTranDebtor D, tblTranDebtor D2 WHERE D.DebtTranIndex = @DrsInd AND D2.DebtTranIndex = @DrsInd+1 AND D.DebtTranTotal + D2.DebtTranTotal = 0 AND D.DebtTranRefAlpha = D2.DebtTranRefAlpha AND D.DebtTranDate = D2.DebtTranDate) > 0
				SET @RRIdx = @DrsInd + 1
			ELSE
				SET @RRIdx = @DrsInd - 1

			IF (SELECT Count(*) FROM tblTranDebtor D, tblTranDebtor D2 WHERE D.DebtTranIndex = @DrsInd AND D2.DebtTranIndex = @RRIdx AND D.PracID <> D2.PracID) > 0
				BEGIN
				--/Debit/Credit DRS Contol with reallocated Receipts (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
				WHERE D.DebtTranIndex = @DrsInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
			
				--/Credit/Debit Intercompany account with reallocated Receipts (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
				SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
					'BS' AS NLSection, 'ICC' + LTrim(Str(D2.PracID)) AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
					D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex, tblTranDebtor D2
				WHERE D.DebtTranIndex = @DrsInd AND D2.DebtTranIndex = @RRIdx
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				END
			END

		IF @TranType = 11 --Process Payment Entries
			BEGIN
			--/Debit Debtor Payments (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd

			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			--/Credit Bank Payments (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'CHQCL' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END

		IF @TranType = 12 --Process R/D Cheque Entries
			BEGIN
			--/Credit Bank R/D Cheques (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'BANK' + LTrim(Str(D.DebtTranBank)) AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			--/Debit Debtor R/D Cheque (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END

		IF @TranType = 13 --Process Discount Entries
			BEGIN
			--/Debit Discount (P/L)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'PL' AS NLSection, 'DISC' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			--/Credit Debtors Discount (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END

		IF @TranType = 17 --Process Bank charge Entries
			BEGIN
			--/Debit Bank charges
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'BANKC' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			--/Credit Debtors Control (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END

		IF @TranType = 18 --Process Withholding Tax Entries
			BEGIN
			--/Debit Withholding Tax (P/L)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'WHTAX' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			--/Credit Debtors Control (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END


		IF @TranType = 21 --Process Exchange Diff Entries
			BEGIN
			--/Debit Exchange Diff (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'PL' AS NLSection, 'PLEX' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			--/Credit Debtors Control (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END


		IF @TranType = 22 --Process Withholding VAT Entries
			BEGIN
			--/Debit Discount (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'WHVAT' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			--/Credit Debtors Control (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END


		IF @TranType = 23 --Process VAT Exemption Entries
			BEGIN
			--/Debit Discount (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'EXVAT' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			--/Credit Debtors Control (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END

		IF @TranType NOT IN (3,4,6,7,8,9,11,12,13,14,15,17,18,21,22,23) --Process Journal Entries
			BEGIN
			--/Debit Debtors Journals (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			--/Credit Debtors Journals (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRJNL' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END

		FETCH 	csr_Trans INTO @DrsInd, @TranType
		END

	CLOSE csr_Trans
	DEALLOCATE csr_Trans


	DECLARE csr_Trans CURSOR DYNAMIC 
	FOR SELECT V.TransVATIndex
	FROM tblTranDebtor D INNER JOIN tblTransVAT V ON D.DebtTranIndex = V.DebitIndex
	WHERE V.TransVATIndex > @VATRef AND V.DebitType IN (4,14)

	OPEN csr_Trans

	FETCH csr_Trans INTO @DrsInd
	WHILE (@@FETCH_STATUS=0) 
		BEGIN
		--/Debit VAT Suspense with Receipts (B/S)
		INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
		SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
			'BS' AS NLSection, 'VATSUS' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, V.VAT, 
			V.TransVATIndex AS RefMin, V.TransVATIndex AS RefMax, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
		FROM tblTranDebtor D INNER JOIN tblTransVAT V ON D.DebtTranIndex = V.DebitIndex INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
		WHERE V.TransVATIndex = @DrsInd
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT
	
		--/Credit VAT with Receipts (B/S)
		INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
		SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
			'BS' AS NLSection, 'VATDUE' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, V.VAT*-1, 
			V.TransVATIndex AS RefMin, V.TransVATIndex AS RefMax, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
		FROM tblTranDebtor D INNER JOIN tblTransVAT V ON D.DebtTranIndex = V.DebitIndex INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
		WHERE V.TransVATIndex = @DrsInd
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT
	
		--/Debit Debtors Control with Receipts (B/S)
		INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
		SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
			'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, V.Amount, 
			V.TransVATIndex AS RefMin, V.TransVATIndex AS RefMax, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
		FROM tblTranDebtor D INNER JOIN tblTransVAT V ON D.DebtTranIndex = V.DebitIndex INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
		WHERE V.TransVATIndex = @DrsInd
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT
	
		--/Credit Debtors Suspense with Receipts (B/S)
		INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
		SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
			'BS' AS NLSection, 'DRSUS' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, V.Amount*-1, 
			V.TransVATIndex AS RefMin, V.TransVATIndex AS RefMax, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
		FROM tblTranDebtor D INNER JOIN tblTransVAT V ON D.DebtTranIndex = V.DebitIndex INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
		WHERE V.TransVATIndex = @DrsInd
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT

		FETCH 	csr_Trans INTO @DrsInd
		END

	CLOSE csr_Trans
	DEALLOCATE csr_Trans


	DECLARE csr_Trans CURSOR DYNAMIC 
	FOR SELECT D.DebtTransferIdx
	FROM tblTranDebtTransfer D
	INNER JOIN tblEngagement E1 ON D.ContFrom = E1.ContIndex
	INNER JOIN tblEngagement E2 ON D.ContTo = E2.ContIndex
	WHERE D.DebtTransferIdx > @TrfIdx AND E1.ClientOrganisation <> E2.ClientOrganisation 

	OPEN csr_Trans

	FETCH csr_Trans INTO @DrsInd
	WHILE (@@FETCH_STATUS=0) 
		BEGIN
		--/Debit Debtors On Original Client Side
		INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
		SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate AS NLDate, E1.ClientOrganisation, 'DRS' AS NLSource, 
			'BS' AS NLSection, 'DRCON' AS NLAccount, 9, E1.ClientOffice AS Office, 'UNKNOWN' As Service, E1.ClientPartner, Coalesce(E1.ClientDepartment, 'UNKNOWN'), 
			0 AS Units, D.DebtTranTotal*-1 AS Amount, E1.ContIndex, 'TRF', 'Receipt Transfer', T.DebtTransferIdx AS RefMin, T.DebtTransferIdx AS RefMax
		FROM tblTranDebtTransfer T INNER JOIN tblTranDebtor D ON T.DebtTranIndex = D.DebtTranIndex INNER JOIN tblEngagement E1 ON T.ContFrom = E1.ContIndex	INNER JOIN tblEngagement E2 ON T.ContTo = E2.ContIndex
		WHERE T.DebtTransferIdx = @DrsInd
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT
	
		--/Credit Debtors On New Client Side
		INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
		SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate AS NLDate, E2.ClientOrganisation, 'DRS' AS NLSource, 
			'BS' AS NLSection, 'DRCON' AS NLAccount, 9, E2.ClientOffice AS Office, 'UNKNOWN' As Service, E2.ClientPartner, Coalesce(E2.ClientDepartment, 'UNKNOWN'), 
			0 AS Units, D.DebtTranTotal AS Amount, E2.ContIndex, 'TRF', 'Receipt Transfer', T.DebtTransferIdx AS RefMin, T.DebtTransferIdx AS RefMax
		FROM tblTranDebtTransfer T INNER JOIN tblTranDebtor D ON T.DebtTranIndex = D.DebtTranIndex INNER JOIN tblEngagement E1 ON T.ContFrom = E1.ContIndex	INNER JOIN tblEngagement E2 ON T.ContTo = E2.ContIndex
		WHERE T.DebtTransferIdx = @DrsInd
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT

		--/Credit Intercompany account On Original Client Side
		INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
		SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate AS NLDate, E1.ClientOrganisation, 'DRS' AS NLSource, 
			'BS' AS NLSection, 'DTRF' + LTrim(Str(E2.ClientOrganisation)) AS NLAccount, 9, E1.ClientOffice AS Office, 'UNKNOWN' As Service, E1.ClientPartner, Coalesce(E1.ClientDepartment, 'UNKNOWN'), 
			0 AS Units, D.DebtTranTotal AS Amount, E1.ContIndex, 'TRF', 'Receipt Transfer', T.DebtTransferIdx AS RefMin, T.DebtTransferIdx AS RefMax
		FROM tblTranDebtTransfer T INNER JOIN tblTranDebtor D ON T.DebtTranIndex = D.DebtTranIndex INNER JOIN tblEngagement E1 ON T.ContFrom = E1.ContIndex	INNER JOIN tblEngagement E2 ON T.ContTo = E2.ContIndex
		WHERE T.DebtTransferIdx = @DrsInd
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT
	
		--/Debit Intercompany account On New Client Side
		INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
		SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate AS NLDate, E2.ClientOrganisation, 'DRS' AS NLSource, 
			'BS' AS NLSection, 'DTRF' + LTrim(Str(E1.ClientOrganisation)) AS NLAccount, 9, E2.ClientOffice AS Office, 'UNKNOWN' As Service, E2.ClientPartner, Coalesce(E2.ClientDepartment, 'UNKNOWN'), 
			0 AS Units, D.DebtTranTotal*-1 AS Amount, E2.ContIndex, 'TRF', 'Receipt Transfer', T.DebtTransferIdx AS RefMin, T.DebtTransferIdx AS RefMax
		FROM tblTranDebtTransfer T INNER JOIN tblTranDebtor D ON T.DebtTranIndex = D.DebtTranIndex INNER JOIN tblEngagement E1 ON T.ContFrom = E1.ContIndex	INNER JOIN tblEngagement E2 ON T.ContTo = E2.ContIndex
		WHERE T.DebtTransferIdx = @DrsInd
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT

		FETCH 	csr_Trans INTO @DrsInd
		END

	CLOSE csr_Trans
	DEALLOCATE csr_Trans

	COMMIT TRAN
	GOTO FINISH

TRAN_ABORT:
	ROLLBACK TRAN
	SET @Result = 1

FINISH:
	SET @Result = 0
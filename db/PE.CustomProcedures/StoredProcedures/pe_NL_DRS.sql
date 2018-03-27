/*
CUSTOM: This Stored Procedure should be customized for your environment
This StoredProcedure Creates the Nominal Ledger in bulk from the Debtors (Accounts Receivable) Transactions in PE
*/

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
	WHERE D.DebtTranIndex > @DrsRef  

	OPEN csr_Trans

	FETCH csr_Trans INTO @DrsInd, @TranType
	WHILE (@@FETCH_STATUS=0) 
		BEGIN
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
				'BS' AS NLSection, 'BNKCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
				FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex INNER JOIN tblLodgementDetails L ON D.DebtTranRefNum = L.LodgeDetIndex INNER JOIN tblLodgementHeader H ON L.LodgeIndex = H.LodgeIndex INNER JOIN tblTranBank B ON H.LodgeBank = B.BankIndex 
			WHERE D.DebtTranIndex = @DrsInd --AND D.PracID = 1

			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			--/Credit Debtors with Receipts (B/S)
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, ContIndex, Partner, TransRefAlpha, Office, Amount, RefMin, RefMax, NLNarrative, Department )
			SELECT NLPeriodIndex = CASE WHEN D.DebtTranDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, D.DebtTranDate, D.PracID, 'DRS' AS NLSource, 
				'BS' AS NLSection, 'DRCON' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd --AND D.PracID = 1
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END

		IF @TranType IN (10,22) --Process Finance Charges
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
				'BS' AS NLSection, 'FCALL' AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END
			
		IF @TranType NOT IN (3,6,8,9,10,15,22) --Process Adjustments
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
				'BS' AS NLSection, CASE WHEN D.DebtTranTotal > 0 THEN 'DRADJU' ELSE 'DRADJD' END AS NLAccount, D.DebtTranType, D.ContIndex, D.DebtTranPartner, D.DebtTranRefAlpha, E.ClientOffice, 
				D.DebtTranTotal*-1, D.DebtTranIndex, D.DebtTranIndex, D.DebtTranMemo, Coalesce(E.ClientDepartment, 'UNKNOWN')
			FROM tblTranDebtor D INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
			WHERE D.DebtTranIndex = @DrsInd
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END

		FETCH 	csr_Trans INTO @DrsInd, @TranType
		END

	CLOSE csr_Trans
	DEALLOCATE csr_Trans

	COMMIT TRAN
	
	SET @Result = 0
	
	GOTO FINISH
	
TRAN_ABORT:
	ROLLBACK TRAN
	SET @Result = 1

FINISH:
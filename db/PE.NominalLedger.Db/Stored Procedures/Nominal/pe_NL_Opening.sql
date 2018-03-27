CREATE PROCEDURE [dbo].[pe_NL_Opening]

@Result int OUTPUT

AS

DECLARE @WIPRef int,
@DRSRef int,
@PeriodIdx int,
@PeriodEnd datetime

	SET @PeriodEnd  = (Select PracPeriodStart-1 From tblControl Where PracID = 1)
	IF @PeriodEnd IS NULL GOTO TRAN_ABORT

	SET @PeriodIdx = (Select PeriodIndex From tblControlPeriods WHERE PeriodEndDate = @PeriodEnd)
	SET @WIPRef = (Select PeriodWIPMax From tblControlPeriods WHERE PeriodEndDate = @PeriodEnd)
	SET @DRSRef = (Select PeriodDRSMax From tblControlPeriods WHERE PeriodEndDate = @PeriodEnd)

	BEGIN TRAN

	--/Debit Opening Chargeable Time (B/S)
	INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Service, Partner, Department, Units, Amount, RefMin, RefMax )
	SELECT @PeriodIdx, Max(tblTranWIP.WIPDate) AS NLDate, tblTranWIP.ClientOffice, 'WIP' AS NLLedger, 'BS' AS NLSection, 'WIP' AS NLAccount, 0 AS TransTypeIndex, 
		tblTranWIP.WIPService AS Service, 0 AS Partner, 'GENERAL' AS Department, Sum(tblTranWIP.WIPHours) AS Units, Sum(tblTranWIP.WIPAmount) AS Amount, 
		Min(tblTranWIP.WIPIndex) AS RefMin, Max(tblTranWIP.WIPIndex) AS RefMax
	FROM tblTranWIP
	WHERE ((tblTranWIP.ContIndex<900000) AND (tblTranWIP.WIPIndex <= @WIPRef))
	GROUP BY tblTranWIP.ClientOffice, tblTranWIP.WIPService

	IF @@ERROR <> 0 GOTO TRAN_ABORT

	--/Credit Opening Chargeable Time (PL)
	INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Service, Partner, Department, Units, Amount, RefMin, RefMax )
	SELECT @PeriodIdx, Max(tblTranWIP.WIPDate) AS NLDate, tblTranWIP.ClientOffice, 'WIP' AS NLLedger, 'PL' AS NLSection, 'WIP' AS NLAccount, 0 AS TransTypeIndex, 
		tblTranWIP.WIPService AS Service, 0 AS Partner, 'GENERAL' AS Department, Sum([WIPHours]*-1) AS Units, Sum([WIPAmount]*-1) AS Amount, 
		Min(tblTranWIP.WIPIndex) AS RefMin, Max(tblTranWIP.WIPIndex) AS RefMax
	FROM tblTranWIP
	WHERE ((tblTranWIP.ContIndex<900000) AND (tblTranWIP.ContIndex<900000) AND (tblTranWIP.WIPIndex <= @WIPRef))
	GROUP BY tblTranWIP.ClientOffice, tblTranWIP.WIPService

	IF @@ERROR <> 0 GOTO TRAN_ABORT

	--/Debit Opening Debtors (B/S)
	INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, Partner, TransTypeIndex, NetAmount, VATAmount, Amount, RefMin, RefMax )
	SELECT @PeriodIdx, Max(tblTranDebtor.DebtTranDate) AS MaxOfDebtTranDate, tblTranDebtor.PracID, 'DRS' AS NLSource, 'BS' AS NLSection, 'DRCON' AS NLAccount, 
		tblTranDebtor.DebtTranPartner, 0 AS DebtTranType, 0 AS DebtTranAmount, 0 AS DebtTranTotal, Sum(tblTranDebtor.DebtTranTotal) AS SumOfDebtTranUnpaid, 
		Min(tblTranDebtor.DebtTranIndex) AS RefMin, Max(tblTranDebtor.DebtTranIndex) AS RefMax
	FROM tblTranDebtor
	WHERE DebtTranIndex <= @DRSRef
	GROUP BY tblTranDebtor.PracID, tblTranDebtor.DebtTranPartner

	IF @@ERROR <> 0 GOTO TRAN_ABORT

	--/Credit Opening Debtors (B/S)
	INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, Partner, TransTypeIndex, NetAmount, VATAmount, Amount, RefMin, RefMax )
	SELECT @PeriodIdx, Max(tblTranDebtor.DebtTranDate) AS MaxOfDebtTranDate, tblTranDebtor.PracID, 'DRS' AS NLSource, 'BS' AS NLSection, 'DRSUS' AS NLAccount, 
		tblTranDebtor.DebtTranPartner, 0 AS DebtTranType, 0 AS DebtTranAmount, 0 AS DebtTranTotal, Sum(DebtTranTotal*-1) AS Expr1, 
		Min(tblTranDebtor.DebtTranIndex) AS RefMin, Max(tblTranDebtor.DebtTranIndex) AS RefMax
	FROM tblTranDebtor
	WHERE DebtTranIndex <= @DRSRef
	GROUP BY tblTranDebtor.PracID, tblTranDebtor.DebtTranPartner

	IF @@ERROR <> 0 GOTO TRAN_ABORT


	INSERT INTO tblTranNominalBank (LodgeIndex, LodgeDate, LodgeBank, LodgeStatus, LodgePrac, LodgePosted)
	SELECT tblLodgementHeader.LodgeIndex, tblLodgementHeader.LodgeDate, tblLodgementHeader.LodgeBank, tblLodgementHeader.LodgeStatus, tblTranBank.PracID, 1
	FROM (tblLodgementHeader INNER JOIN tblTranBank ON tblLodgementHeader.LodgeBank = tblTranBank.BankIndex) LEFT OUTER JOIN tblTranNominalBank ON tblLodgementHeader.LodgeIndex = tblTranNominalBank.LodgeIndex
	WHERE tblTranNominalBank.LodgeIndex IS NULL AND tblLodgementHeader.LodgeStatus = 'COMPLETE' AND tblLodgementHeader.PeriodEndDate <= @PeriodEnd

	IF @@ERROR <> 0 GOTO TRAN_ABORT

	COMMIT TRAN
	GOTO FINISH

TRAN_ABORT:
	ROLLBACK TRAN
	SET @Result = 1

FINISH:
	SET @Result = 0
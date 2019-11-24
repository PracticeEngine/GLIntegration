CREATE PROCEDURE [dbo].[pe_NL_EXP]

@Result int OUTPUT

AS

DECLARE @MonthEnd datetime
DECLARE @PeriodIdx int

SET @MonthEnd  = (Select PracPeriodEnd From tblControl Where PracID = 1)

SET @PeriodIdx = (Select PeriodIndex From tblControlPeriods WHERE PeriodEndDate = @MonthEnd)
	
	BEGIN TRAN

	INSERT INTO tblTranNominalExpense (ExpIndex, ExpDate, ExpPrac, ExpPeriod)
	SELECT H.ExpIndex, H.ExpDate, S.StaffOrganisation, CASE WHEN H.ExpDate > @MonthEnd THEN 0 ELSE @PeriodIdx END
	FROM  tblExpenseHeader H 
	INNER JOIN tblStaff S ON H.ExpStaff = S.StaffIndex
	LEFT OUTER JOIN tblTranNominalExpense E ON H.ExpIndex = E.ExpIndex
	WHERE E.ExpIndex IS NULL AND H.ExpStatus = 'POSTED' AND H.ExpType = 'OWN'
	
	IF @@ERROR <> 0 GOTO TRAN_ABORT

	COMMIT TRAN
	GOTO FINISH

TRAN_ABORT:
	ROLLBACK TRAN
	SET @Result = 1

FINISH:
	SET @Result = 0
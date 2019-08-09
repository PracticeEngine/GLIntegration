CREATE PROCEDURE [dbo].[pe_NL_EXP]

@Result int OUTPUT

AS

	BEGIN TRAN

	INSERT INTO tblTranNominalExpense (ExpIndex, ExpDate, ExpPrac)
	SELECT H.ExpIndex, H.ExpDate, S.StaffOrganisation
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




CREATE PROCEDURE [dbo].[pe_NL_Cashbook_Post_GP]

@BatchID int,
@Result int OUTPUT

AS

Declare @CurId int
Declare @CurStr varchar(10)
Declare @Db varchar(10)
Declare @BatchNum int

	BEGIN TRAN
	SET @CurId  = (SELECT GPCur FROM tblTranNominalControl)
	SET @CurStr  = (SELECT GPCurStr FROM tblTranNominalControl)
	SET @Db  = (SELECT GPDb FROM tblTranNominalControl)
	
	IF @BatchID > 0
		BEGIN
		SET @BatchNum = @BatchID
		END
	ELSE
		BEGIN
		UPDATE tblTranNominalControl
		SET LastBatch = LastBatch + 1
		SET @BatchNum  = (SELECT LastBatch FROM tblTranNominalControl)
		END

	IF @@ERROR <> 0 GOTO TRAN_ABORT

	DECLARE @NomCBId varchar(20)
	DECLARE @BatchDate datetime
	DECLARE @LodgeInd int
	DECLARE @LodgeRef varchar(20)

	DECLARE @LodgeDate datetime
	DECLARE @LodgeType varchar(10)
	DECLARE @LodgeDebtor int
	DECLARE @LodgeClient varchar(10)
	DECLARE @LodgePayor varchar(60)
	DECLARE @LodgeAmt money
	DECLARE @LineCount int

	DECLARE csr_Bank CURSOR DYNAMIC		
	FOR SELECT TB.BankNominal, H.LodgeIndex, H.LodgeDate, H.LodgeRef
		FROM (tblTranNominalBank NB INNER JOIN tblLodgementHeader H ON NB.LodgeIndex = H.LodgeIndex) INNER JOIN tblTranBank TB ON H.LodgeBank = TB.BankIndex
		WHERE NB.LodgeBatch = @BatchID AND LTrim(TB.BankNominal) <> ''

		OPEN csr_Bank
		FETCH 	csr_Bank INTO @NomCBId, @LodgeInd, @LodgeRef, @BatchDate
		WHILE (@@FETCH_STATUS=0) 
			BEGIN
			INSERT INTO pe_view_NL_GP_CashBatch(BACHNUMB, BACHDATE, CHEKBKID, CURNYID)
			VALUES(@LodgeRef, @BatchDate, @NomCBId, @CurId) 


			DECLARE csr_Cash CURSOR DYNAMIC		
			FOR SELECT D.ChequeDate, D.LodgeType, D.LodgeDebtor, D.ClientCode, D.LodgePayor, D.LodgeAmount, D.LodgeDetIndex
				FROM tblLodgementDetails D
				WHERE D.LodgeIndex = @LodgeInd

				OPEN csr_Cash
				FETCH 	csr_Cash INTO @LodgeDate, @LodgeType, @LodgeDebtor, @LodgeClient, @LodgePayor, @LodgeAmt, @LineCount
				WHILE (@@FETCH_STATUS=0) 
					BEGIN
					INSERT INTO pe_view_NL_GP_CashTrans(BACHNUMB, BACHDATE, CHEKBKID, CURNYID, CB_Trans_Type, depositnumber, DATE1, CB_Ref_No, DATE2, CB_Type, CB_Payer, payment_method, ACTNUMBR_1, ACTNUMBR_2, ACTNUMBR_3, ACTNUMBR_4, ACTNUMBR_5, CB_Type_Description, CB_Trans_Amount, TAXSCHID, CB_Exc_Inc)
					VALUES(@LodgeRef, @BatchDate, @NomCBId, @CurId, 'R', @LodgeRef, @BatchDate, @LineCount, @LodgeDate, 1, @LodgePayor, @LodgeType, '', '', '', '', '', 'Cashbook Entry From PE. Client : ' + @LodgeClient, @LodgeAmt, 0, 2)

					FETCH 	csr_Cash INTO @LodgeDate, @LodgeType, @LodgeDebtor, @LodgeClient, @LodgePayor, @LodgeAmt, @LineCount
					END
	
				CLOSE csr_Cash
				DEALLOCATE csr_Cash

			IF @@ERROR <> 0 GOTO TRAN_ABORT

			UPDATE tblTranNominalBank
			SET LodgeBatch = @BatchNum
			WHERE LodgeIndex = @LodgeInd

			IF @@ERROR <> 0 GOTO TRAN_ABORT

			FETCH 	csr_Bank INTO @NomCBId, @LodgeInd, @LodgeRef, @BatchDate
			END


		CLOSE csr_Bank
		DEALLOCATE csr_Bank


	COMMIT TRAN
	GOTO FINISH

TRAN_ABORT:
	ROLLBACK TRAN
	SET @Result = 1

FINISH:
	SET @Result = 0
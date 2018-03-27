CREATE PROCEDURE [dbo].[pe_NL_Journal_Post_GP]

@PostDate varchar(11),
@BatchID int,
@Result int OUTPUT

AS

Declare @BatchNum int
Declare @TranCount int
Declare @CurId int
Declare @CurStr varchar(10)
Declare @Db varchar(10)

	BEGIN TRAN

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

	SET @CurId  = (SELECT GPCur FROM tblTranNominalControl)
	SET @CurStr  = (SELECT GPCurStr FROM tblTranNominalControl)
	SET @Db  = (SELECT GPDb FROM tblTranNominalControl)
	
	IF @@ERROR <> 0 GOTO TRAN_ABORT

	SET @TranCount = (SELECT Count(NomIndex) FROM tblTranNominalPost WHERE NomBatch = @BatchID)

	IF @@ERROR <> 0 GOTO TRAN_ABORT

	INSERT INTO pe_view_NL_Sys_Batches(GLPOSTDT, BCHSOURC, BACHNUMB, SERIES, NUMOFTRX, BACHFREQ, BCHCOMNT, CNTRLTRX, CREATDDT, ORIGIN)
	VALUES (@PostDate, 'GL_Normal',@BatchNum, 2, @TranCount, 1, 'PE Batch', @TranCount, @PostDate, 1)

	IF @@ERROR <> 0 GOTO TRAN_ABORT

	INSERT INTO pe_view_NL_Batch_Header(BACHNUMB, BCHSOURC, JRNENTRY, SOURCDOC, REFRENCE, TRXDATE, PSTGSTUS, SQNCLINE, SERIES, CURNCYID, CURRNIDX, PRNTSTUS, TAX_DATE)
	VALUES (@BatchNum, 'GL_Normal', @BatchNum, 'GJ', 'PracEng', @PostDate, 1, @TranCount, 2, @CurStr, @CurId, 1, @PostDate)

	IF @@ERROR <> 0 GOTO TRAN_ABORT

	DECLARE @AccIndex int
	DECLARE @AccType int
	DECLARE @NomAmt money
	DECLARE @NomDesc varchar(500)
	DECLARE @LineCount int
	DECLARE csr_Lines CURSOR DYNAMIC
		
	FOR SELECT AccIndex, AccType, NomAmount, NomNarrative
		FROM tblTranNominalPost INNER JOIN pe_view_NL_Accounts ON tblTranNominalPost.NomPostAcc = pe_view_NL_Accounts.AccIndex
		WHERE tblTranNominalPost.NomBatch = @BatchID

		SET @LineCount = 0
		
		OPEN csr_Lines
		FETCH 	csr_Lines INTO @AccIndex, @AccType, @NomAmt, @NomDesc
		WHILE (@@FETCH_STATUS=0) 
			BEGIN
			SET @LineCount = @LineCount + 1
			IF @NomDesc IS NULL
				SET @NomDesc = ''
			IF @NomAmt > 0
				BEGIN
				INSERT INTO pe_view_NL_Batch_Lines(BACHNUMB, JRNENTRY, SQNCLINE, DSCRIPTN, ACTINDX, CURRNIDX, ACCTTYPE, DEBITAMT, ORDBTAMT, INTERID)
				VALUES (@BatchNum, @BatchNum, @LineCount, @NomDesc, @AccIndex, @CurId, @AccType, @NomAmt, @NomAmt, @Db)
				END
			
			IF @NomAmt <= 0
				BEGIN
				INSERT INTO pe_view_NL_Batch_Lines(BACHNUMB, JRNENTRY, SQNCLINE, DSCRIPTN, ACTINDX, CURRNIDX, ACCTTYPE, CRDTAMNT, ORCRDAMT, INTERID)
				VALUES (@BatchNum, @BatchNum, @LineCount, @NomDesc, @AccIndex, @CurId, @AccType, @NomAmt * -1, @NomAmt * -1, @Db)
				END

			FETCH 	csr_Lines INTO @AccIndex, @AccType, @NomAmt, @NomDesc
			END
	
		CLOSE csr_Lines
		DEALLOCATE csr_Lines

	IF @@ERROR <> 0 GOTO TRAN_ABORT


	IF @BatchID = 0
		BEGIN
		UPDATE tblTranNominalPost
		SET NomPosted = 1, NomBatch = @BatchNum, NomPostDate = GetDate()
		WHERE NomPosted = 0
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT

		UPDATE tblTranNominal
		SET NomIndex = 2, NLPosted = 1, NomBatch = @BatchNum
		WHERE NomIndex = 1
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT
		END

	COMMIT TRAN
	GOTO FINISH

TRAN_ABORT:
	ROLLBACK TRAN
	SET @Result = 1

FINISH:
	SET @Result = 0
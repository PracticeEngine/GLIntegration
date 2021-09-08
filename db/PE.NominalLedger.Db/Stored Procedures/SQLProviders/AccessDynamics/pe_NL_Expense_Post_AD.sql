CREATE PROCEDURE [dbo].[pe_NL_Expense_Post_AD]
	@PostDate varchar(30),
	@BatchID int,
	@Result int OUTPUT
AS
	SET NOCOUNT ON

	Declare @BatchNum int,
		@TranCount int,
		@SQLStr varchar(8000),
		@Org int,
		@Server varchar(50),
		@DB varchar(50),
		@SQL varchar(8000),
		@PerNum int,
		@Period int

	-- May need to change how the batch id is created. Dimensions seems to have its own identity value.

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
		
	SELECT	@PerNum = P.PeriodNumber, @Period = P.PeriodIndex
	FROM	tblControlPeriods P
	INNER	JOIN tblTranNominalPostExpenses NP ON P.PeriodIndex = NP.PeriodIndex
	WHERE	NP.Batch = @BatchID AND NP.Posted = 0

	SET	@SQL = ''
	SET	@Result = 1

BEGIN TRAN

	DECLARE 	csr_Org CURSOR DYNAMIC		
	FOR SELECT 	Orgs.PracID, Orgs.NLServer, Orgs.NLDatabase
	FROM 		tblTranNominalOrgs Orgs
	WHERE		Orgs.NLTransfer = 1

	OPEN csr_Org
	FETCH 	csr_Org INTO @Org, @Server, @DB
	WHILE (@@FETCH_STATUS=0) 
		BEGIN				
		SET @SQL = 'INSERT INTO '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '.dbo.PL_TRN_TEMP(PL_TRAN_ID, PL_DETAIL_LINE_NO, PL_STATUS_TEMP, PL_USE_DEFAULT, PL_USER_ID, PL_TRANSACTION_TYPE, PL_SUPPLIER_CODE, PL_TRAN_REFERENCE, PL_BATCH_REFERENCE, PL_TRAN_DATE, PL_TRAN_DESCRIPTION, PL_DETAIL_ANALYSIS_CODE, PL_DETAIL_HOME_VALUE)
		SELECT ROW_NUMBER() OVER (ORDER BY A.ExpIndex, A.AllocIndex), 1, 0, '''', ''INT'', ''INV'', E.VendorCode, A.ExpIndex, E.VendorCode, E.ExpDate, A.[Description], E.PostAcc, E.Amount
		FROM tblTranNominalPostExpenses E 
		INNER JOIN tblExpenseAllocation A ON E.AllocIndex = A.AllocIndex
		WHERE E.PeriodIndex = ' + LTrim(Str(@Period)) + 'AND E.Posted = 0 AND E.Batch = ' + LTrim(Str(@BatchID)) + ' AND E.ExpOrg = '  + LTrim(Str(@Org))

		PRINT @SQL
		EXEC (@SQL)

		SET @SQL = 'UPDATE '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '.dbo.PL_TRN_TEMP
		SET PL_STATUS_TEMP = 1
		WHERE PL_TRAN_ID = ' + LTrim(Str(@BatchNum))
	
		PRINT @SQL
		EXEC (@SQL)
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT
		
		SET @SQL = 'UPDATE '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '.dbo.PL_TRN_TEMP
		SET PL_STATUS_TEMP = 2
		WHERE PL_TRAN_ID = ' + LTrim(Str(@BatchNum))
	
		PRINT @SQL
		EXEC (@SQL)
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT

		CREATE TABLE #Count ( NumRows int )

		SET @SQL = 'INSERT INTO #Count (NumRows)
		SELECT Count(*) FROM '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '.dbo.PL_TRN_TEMP
		WHERE PL_STATUS_TEMP = 3 AND PL_TRAN_ID = ' + LTrim(Str(@BatchNum)) 
	
		PRINT @SQL
		EXEC (@SQL)

		IF (SELECT NumRows FROM #Count) > 0
			BEGIN
			SET @SQL = 'DELETE
			FROM '
			IF @Server <> ''
				SET @SQL = @SQL + @Server + '.'
			SET @SQL = @SQL + @DB + '.dbo.PL_TRN_TEMP
			WHERE PL_TRAN_ID = ' + LTrim(Str(@BatchNum)) 
		
			PRINT @SQL
			EXEC (@SQL)

			GOTO TRAN_ABORT					
			END
			
		DROP TABLE #Count

		FETCH csr_Org INTO @Org, @Server, @DB
		END

	CLOSE csr_Org
	DEALLOCATE csr_Org

	COMMIT TRAN
	GOTO FINISH

TRAN_ABORT:
	ROLLBACK TRAN
	SET @Result = 1
	GOTO THEEND

FINISH:
	SET @Result = 0

THEEND:
	SET NOCOUNT OFF
CREATE PROCEDURE [dbo].[pe_NL_Journal_Post_AD]
	@PostDate varchar(30),
	@BatchID int,
	@Result int OUTPUT
AS
	SET NOCOUNT ON

	Declare @BatchNum int,
		@TranCount int,
		@DRSOff bit,
		@DRSServ bit,
		@DRSPart bit,
		@DRSDept bit,
		@DRSDetail bit,
		@SQLStr varchar(8000),
		@Org int,
		@Server varchar(50),
		@DB varchar(50),
		@Office varchar(10),	--GT Office journal split
		@SQL varchar(8000),
		@PerNum int

	SELECT	@DRSOff = DRSOffice, @DRSServ = DRSServ, @DRSPart = DRSPart, @DRSDept = DRSDept, @DRSDetail = DRSLevel
	FROM	tblTranNominalControl

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

	SELECT	@PerNum = Min(PeriodNumber)
	FROM	tblControlPeriods P
	INNER	JOIN tblTranNominalPost NP ON P.PeriodIndex = NP.NomPeriodIndex
	WHERE	NP.NomBatch = @BatchID

	SET	@SQL = ''
	SET	@Result = 1

	CREATE TABLE #JNL (
		NomIndex int,
		AccNum varchar(25) Collate Database_Default,
		DRSNum varchar(25) Collate Database_Default,
		VATNum varchar(25) Collate Database_Default,
		)

BEGIN TRAN
	-- GTI to split journal posting to one journal per org, per OFFICE and per type (net/vat)

	DECLARE 	csr_Org CURSOR DYNAMIC		
	FOR SELECT 	Orgs.PracID, Ofcs.OfficeCode, Orgs.NLServer, Orgs.NLDatabase
	FROM 		tblTranNominalOrgs Orgs CROSS JOIN tblOffices Ofcs
	WHERE		Orgs.NLTransfer = 1

	OPEN csr_Org
	FETCH 	csr_Org INTO @Org, @Office, @Server, @DB
	WHILE (@@FETCH_STATUS=0) 
		BEGIN		

		SET @SQL = 'INSERT INTO #JNL( NomIndex, AccNum, DRSNum, VATNum )
		SELECT Post.NomIndex, LTRIM(RTRIM(Mast.NCODE)), LTRIM(RTRIM(Coalesce(DRS.NCODE,''''))), LTRIM(RTRIM(Coalesce(VAT.NCODE,'''')))
		FROM tblTranNominalPost Post 
		INNER JOIN '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '.dbo.NL_ACCOUNTS Mast ON Mast.NCODE = Post.NomPostAcc
		LEFT OUTER JOIN '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '.dbo.NL_ACCOUNTS DRS ON DRS.NCODE = Post.NomDRSAcc
		LEFT OUTER JOIN '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'
		SET @SQL = @SQL + @DB + '.dbo.NL_ACCOUNTS VAT ON VAT.NCODE = Post.NomVATAcc
		WHERE Post.NomBatch = ' + LTrim(Str(@BatchID)) + ' AND Post.NomOrg = ' + LTrim(Str(@Org)) + ' AND Post.NomOffice = ''' + @Office + ''''

		PRINT @SQL
		EXEC (@SQL)

		DECLARE @AccNum varchar(25)
		DECLARE @DRSAcc varchar(25)
		DECLARE @VATAcc varchar(25)
		DECLARE @VATRate varchar(3)
		DECLARE @NomAmt money
		DECLARE @VATAmt money
		DECLARE @NomDesc varchar(500)
		DECLARE @LineCount int

		PRINT 'Start of Lines Cursor'

		DECLARE csr_Lines CURSOR DYNAMIC		
		FOR SELECT AccNum, NomAmount, NomNarrative
			FROM #JNL J INNER JOIN tblTranNominalPost P ON J.NomIndex = P.NomIndex
			WHERE NomJnlType = ''
	
			SET @LineCount = 0
			
			OPEN csr_Lines
			FETCH 	csr_Lines INTO @AccNum, @NomAmt, @NomDesc
			WHILE (@@FETCH_STATUS=0) 
				BEGIN
				SET @LineCount = @LineCount + 1
				IF @NomDesc IS NULL
					SET @NomDesc = ''
				IF @NomAmt > 0
					BEGIN
					SET @SQL = 'INSERT INTO '
					IF @Server <> ''
						SET @SQL = @SQL + @Server + '.'
					SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP(NL_TRAN_ID, NL_DETAIL_LINE_NO, NL_STATUS_TEMP, NL_USER_ID, NL_MODULE, NL_TRANSACTION_TYPE, NL_MAXIMUM_POSTING_NO, NL_CREDIT_DEBIT_TRANSACTION, NL_TRANSACTION_DATE, NL_JOURNAL_ACCOUNT, NL_HOME_TRANSACTION_VALUE, NL_DETAIL_DESCRIPTION, NL_TRAN_REFERENCE)
					VALUES ( ' + LTrim(Str(@BatchNum)) + ', ' + LTrim(Str(@LineCount)) + ', 0, ''INT'' , ''NL'' , ''JNL'', 0 , ''DR'', ''' + LTrim(@PostDate) + ''', ''' + LTrim(@AccNum) + ''', ' + LTrim(Cast(@NomAmt as varchar)) + ', ''' + LTrim(@NomDesc) + ''', ''' + LTrim(Str(@BatchNum)) + ''')'
					END
			
				IF @NomAmt < 0
					BEGIN
					SET @SQL = 'INSERT INTO '
					IF @Server <> ''
						SET @SQL = @SQL + @Server + '.'
					SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP(NL_TRAN_ID, NL_DETAIL_LINE_NO, NL_STATUS_TEMP, NL_USER_ID, NL_MODULE, NL_TRANSACTION_TYPE, NL_MAXIMUM_POSTING_NO, NL_CREDIT_DEBIT_TRANSACTION, NL_TRANSACTION_DATE, NL_JOURNAL_ACCOUNT, NL_HOME_TRANSACTION_VALUE, NL_DETAIL_DESCRIPTION, NL_TRAN_REFERENCE)
					VALUES ( ' + LTrim(Str(@BatchNum)) + ', ' + LTrim(Str(@LineCount)) + ', 0, ''INT'' , ''NL'' , ''JNL'', 0 , ''CR'', ''' + LTrim(@PostDate) + ''', ''' + LTrim(@AccNum) + ''', ' + LTrim(Cast(@NomAmt*-1 as varchar)) + ', ''' + LTrim(@NomDesc) + ''', ''' + LTrim(Str(@BatchNum)) + ''')'
					END

				PRINT @SQL
				EXEC (@SQL)

				FETCH 	csr_Lines INTO @AccNum, @NomAmt, @NomDesc
				END
		
			CLOSE csr_Lines
			DEALLOCATE csr_Lines
	
		PRINT 'End of Lines Cursor'

		IF @LineCount > 0
			BEGIN
			SET @SQL = 'UPDATE '
			IF @Server <> ''
				SET @SQL = @SQL + @Server + '.'
			SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP
			SET NL_STATUS_TEMP = 1
			WHERE NL_TRAN_ID = ' + LTrim(Str(@BatchNum))
	
			PRINT @SQL
			EXEC (@SQL)
	
			IF @@ERROR <> 0 GOTO TRAN_ABORT
		
			SET @SQL = 'UPDATE '
			IF @Server <> ''
				SET @SQL = @SQL + @Server + '.'
			SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP
			SET NL_STATUS_TEMP = 2
			WHERE NL_TRAN_ID = ' + LTrim(Str(@BatchNum))
	
			PRINT @SQL
			EXEC (@SQL)
	
			IF @@ERROR <> 0 GOTO TRAN_ABORT

			CREATE TABLE #Count ( NumRows int )

			SET @SQL = 'INSERT INTO #Count (NumRows)
			SELECT Count(*) FROM '
			IF @Server <> ''
				SET @SQL = @SQL + @Server + '.'
			SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP
			WHERE NL_STATUS_TEMP = 3 AND NL_TRAN_ID = ' + LTrim(Str(@BatchNum)) 
	
			PRINT @SQL
			EXEC (@SQL)

			IF (SELECT NumRows FROM #Count) > 0
				BEGIN
				SET @SQL = 'DELETE
				FROM '
				IF @Server <> ''
					SET @SQL = @SQL + @Server + '.'
				SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP
				WHERE NL_TRAN_ID = ' + LTrim(Str(@BatchNum)) 
		
				PRINT @SQL
				EXEC (@SQL)

				GOTO TRAN_ABORT					
				END
			
			DROP TABLE #Count
			END

		PRINT 'Start of VAT Cursor'

		DECLARE csr_Accs CURSOR DYNAMIC
		FOR SELECT DRSNum, VATNum
		FROM #JNL
		WHERE DRSNum <> ''
		GROUP BY DRSNum, VATNum
	
			OPEN csr_Accs
			FETCH csr_Accs INTO @DRSAcc, @VATAcc
			WHILE (@@FETCH_STATUS = 0)
				BEGIN
				DECLARE @LineCountDr int
				DECLARE @LineCountCr int

				DECLARE csr_Lines CURSOR DYNAMIC		
				FOR SELECT AccNum,  NomAmount, NomNarrative, NomVATAmount, NomVATRateCode
					FROM #JNL J INNER JOIN tblTranNominalPost P ON J.NomIndex = P.NomIndex
					WHERE NomJnlType = 'VJL' AND DRSNum = @DRSAcc AND VATNum = @VATAcc
	
					SET @LineCountDr = 0
					SET @LineCountCr = 0
	
					OPEN csr_Lines
					FETCH 	csr_Lines INTO @AccNum, @NomAmt, @NomDesc, @VATAmt, @VATRate
					WHILE (@@FETCH_STATUS=0) 
						BEGIN
						IF @NomDesc IS NULL
							SET @NomDesc = ''
							BEGIN
							SET @LineCountCr = @LineCountCr + 1
							SET @SQL = 'INSERT INTO '
							IF @Server <> ''
								SET @SQL = @SQL + @Server + '.'
							SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP(NL_TRAN_ID, NL_DETAIL_LINE_NO, NL_STATUS_TEMP, NL_USER_ID, NL_MODULE, NL_TRANSACTION_TYPE, NL_GROSS_CONTRA, NL_VAT_CONTRA, NL_MAXIMUM_POSTING_NO, NL_CREDIT_DEBIT_TRANSACTION, NL_TRANSACTION_DATE, NL_JOURNAL_ACCOUNT, NL_HOME_TRANSACTION_VALUE, NL_VATCODE, NL_HOME_VAT_VALUE, NL_DETAIL_DESCRIPTION, NL_TRAN_REFERENCE)
							VALUES ( ' + LTrim(Str(@BatchNum)) + ', ' + LTrim(Str(@LineCountCr)) + ', 0, ''INT'' , ''NL'' , ''VJL'', ''' + LTrim(@DRSAcc) + ''', ''' + LTrim(@VATAcc) + ''', 0 , ''CR'', ''' + LTrim(@PostDate) + ''', ''' + LTrim(@AccNum) + ''', ' + LTrim(Cast(@NomAmt as varchar)) + ', ''' + LTrim(@VATRate) + ''', ' + LTrim(Cast(@VATAmt as varchar)) + ', ''' + LTrim(@NomDesc) + ''', ''' + LTrim(Str(@BatchNum)) + ''')'
							END

						PRINT @SQL
						EXEC (@SQL)
	
						FETCH 	csr_Lines INTO @AccNum, @NomAmt, @NomDesc, @VATAmt, @VATRate
						END
		
					CLOSE csr_Lines
					DEALLOCATE csr_Lines
	
				IF @LineCountCr > 0
					BEGIN
					SET @SQL = 'UPDATE '
					IF @Server <> ''
						SET @SQL = @SQL + @Server + '.'
					SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP
					SET NL_STATUS_TEMP = 1
					WHERE NL_TRAN_ID = ' + LTrim(Str(@BatchNum))
			
					PRINT @SQL
					EXEC (@SQL)
				
					IF @@ERROR <> 0 GOTO TRAN_ABORT
				
					SET @SQL = 'UPDATE '
					IF @Server <> ''
						SET @SQL = @SQL + @Server + '.'
					SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP
					SET NL_STATUS_TEMP = 2
					WHERE NL_TRAN_ID = ' + LTrim(Str(@BatchNum))
			
					PRINT @SQL
					EXEC (@SQL)
			
					IF @@ERROR <> 0 GOTO TRAN_ABORT
					
					CREATE TABLE #VCountCr ( NumRows int )
	
					SET @SQL = 'INSERT INTO #VCountCr (NumRows)
					SELECT Count(*) FROM '
					IF @Server <> ''
						SET @SQL = @SQL + @Server + '.'
					SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP
					WHERE NL_STATUS_TEMP = 3 AND NL_TRAN_ID = ' + LTrim(Str(@BatchNum)) 
			
					PRINT @SQL
					EXEC (@SQL)
	
					IF (SELECT NumRows FROM #VCountCr) > 0
						BEGIN
						SET @SQL = 'DELETE
						FROM '
						IF @Server <> ''
							SET @SQL = @SQL + @Server + '.'
						SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP
						WHERE NL_TRAN_ID = ' + LTrim(Str(@BatchNum)) 
				
						PRINT @SQL
						EXEC (@SQL)
	
						GOTO TRAN_ABORT					
						END
					
					DROP TABLE #VCountCr
				END
	
				IF @LineCountDr > 0
					BEGIN
					SET @SQL = 'UPDATE '
					IF @Server <> ''
						SET @SQL = @SQL + @Server + '.'
					SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP
					SET NL_STATUS_TEMP = 1
					WHERE NL_TRAN_ID = ' + LTrim(Str(@BatchNum+1))
			
					PRINT @SQL
					EXEC (@SQL)
				
					IF @@ERROR <> 0 GOTO TRAN_ABORT
				
					SET @SQL = 'UPDATE '
					IF @Server <> ''
						SET @SQL = @SQL + @Server + '.'
					SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP
					SET NL_STATUS_TEMP = 2
					WHERE NL_TRAN_ID = ' + LTrim(Str(@BatchNum+1))
			
					PRINT @SQL
					EXEC (@SQL)
			
					IF @@ERROR <> 0 GOTO TRAN_ABORT
					
					CREATE TABLE #VCountDr ( NumRows int )
	
					SET @SQL = 'INSERT INTO #VCountDr (NumRows)
					SELECT Count(*) FROM '
					IF @Server <> ''
						SET @SQL = @SQL + @Server + '.'
					SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP
					WHERE NL_STATUS_TEMP = 3 AND NL_TRAN_ID = ' + LTrim(Str(@BatchNum+1)) 
			
					PRINT @SQL
					EXEC (@SQL)
	
					IF (SELECT NumRows FROM #VCountDr) > 0
						BEGIN
						SET @SQL = 'DELETE
						FROM '
						IF @Server <> ''
							SET @SQL = @SQL + @Server + '.'
						SET @SQL = @SQL + @DB + '.dbo.NL_TRN_TEMP
						WHERE NL_TRAN_ID = ' + LTrim(Str(@BatchNum+1)) 
				
						PRINT @SQL
						EXEC (@SQL)
	
						GOTO TRAN_ABORT					
						END
					
					DROP TABLE #VCountDr
				END

				FETCH csr_Accs INTO @DRSAcc, @VATAcc
				END
			
			CLOSE csr_Accs
			DEALLOCATE csr_Accs

		PRINT 'End of VAT Cursor'

		IF @BatchID = 0
			BEGIN
			UPDATE tblTranNominalPost
			SET NomPosted = 1, NomBatch = @BatchNum, NomPostDate = GetDate()
			WHERE NomPosted = 0 AND NomOrg = @Org AND NomOffice = @Office
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
	
			UPDATE tblTranNominal
			SET NomIndex = 2, NLPosted = 1, NomBatch = @BatchNum
			WHERE NomIndex = 1 AND NLOrg = @Org AND Office = @Office
		
			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END

		DELETE FROM #JNL
		--DELETE FROM #VAT

		FETCH csr_Org INTO @Org, @Office, @Server, @DB
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
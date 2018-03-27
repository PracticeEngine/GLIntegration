CREATE PROCEDURE [dbo].[pe_NL_Cashbook_Post_AD]

@BatchID int,
@Result int OUTPUT

AS

	Declare @BatchNum int,
		@Org int,
		@Server varchar(50),
		@DB varchar(50),
		@SQL varchar(8000),
		@SysCur char(3)

	SELECT @SysCur = TranSetCur 
	FROM tblTransactionSettings
	WHERE TranSetIndex = 1

	BEGIN TRAN

	DECLARE 	csr_Org CURSOR DYNAMIC		
	FOR SELECT 	Orgs.PracID, Orgs.NLServer, Orgs.NLDatabase
	FROM 		tblTranNominalOrgs Orgs
	WHERE 	Orgs.NLTransfer = 1

	OPEN csr_Org
	FETCH 	csr_Org INTO @Org, @Server, @DB
	WHILE (@@FETCH_STATUS=0) 
		BEGIN
		
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
	
		DECLARE @NomBank varchar(20)
		DECLARE @BatchDate datetime
		DECLARE @LodgeInd int
		DECLARE @LodgeRef varchar(20)
		DECLARE @BankCur char(3)
		DECLARE @LodgeCurTotal decimal(19,4)
		DECLARE @LodgeTotal decimal(19,4)
		DECLARE @LodgeRate decimal(19,6)
		DECLARE @CurPrefix char(1)
	
		DECLARE @LodgePayor varchar(60)
		DECLARE @LodgeAmt money
		DECLARE @LodgeDebtor bit
		DECLARE @CreditCard varchar(10)
		DECLARE @LodgeType varchar(10)

		DECLARE @LineCount int
		DECLARE @BankOffice varchar(10)
		DECLARE @BankClear varchar(20)
		DECLARE @MapAcc varchar(8)

		SET @BankClear = ''
	
		DECLARE csr_Bank CURSOR DYNAMIC		
		FOR SELECT TB.BankNominal, H.LodgeIndex, H.LodgeDate, Left(Coalesce(H.LodgeRef,''), 10) As LodgeRef, TB.BankCurrency, H.LodgeAccAmount, H.LodgeAccRate, H.LodgeAmount, TB.BankOffice
			FROM (tblTranNominalBank NB INNER JOIN tblLodgementHeader H ON NB.LodgeIndex = H.LodgeIndex) INNER JOIN tblTranBank TB ON H.LodgeBank = TB.BankIndex
			WHERE NB.LodgeBatch = @BatchID AND LTrim(TB.BankNominal) <> '' AND TB.PracID = @Org
			ORDER BY H.LodgeIndex
	
			OPEN csr_Bank
			FETCH 	csr_Bank INTO @NomBank, @LodgeInd, @BatchDate, @LodgeRef, @BankCur, @LodgeCurTotal, @LodgeRate, @LodgeTotal, @BankOffice
			WHILE (@@FETCH_STATUS=0) 
				BEGIN
				SET @LineCount = 0
				IF @BankCur <> @SysCur 
					SET @CurPrefix = ''
				ELSE
					SET @CurPrefix = ''

				DECLARE csr_Cash CURSOR DYNAMIC		
				FOR SELECT D.LodgeAmount, D.LodgePayor, D.LodgeDebtor, D.CreditCard, D.LodgeType
				FROM tblLodgementDetails D
				WHERE D.LodgeIndex = @LodgeInd
	
					OPEN csr_Cash
					FETCH 	csr_Cash INTO @LodgeAmt, @LodgePayor, @LodgeDebtor, @CreditCard, @LodgeType
					WHILE (@@FETCH_STATUS=0) 
						BEGIN
						-- Special For GT. Need to find Contra account for sundry cash, not just post to Bank clearance.  Use Bank Office and Card Type to work out MapAccount
						SET @BankClear = ''
						IF @LodgeDebtor = 1 
							SET @MapAcc = 'BNKCON'
						ELSE
							SET @MapAcc = 'SC' + CASE WHEN @LodgeType = 'CARD' THEN Left(@CreditCard,4) ELSE 'GEN' END

						SET @BankClear = (SELECT TOP 1 MapTargetAcc FROM tblTranNominalMap WHERE MapSource = 'LOD' AND MapAccount =@MapAcc AND MapOrg = @Org AND MapOffice = @BankOffice AND MapTargetAcc <> '')
						IF @BankClear IS NULL
							SET @BankClear = ''

						SET @LineCount = @LineCount + 1
						IF @LodgeAmt > 0
							BEGIN
							SET @SQL = 'INSERT INTO '
							IF @Server <> ''
								SET @SQL = @SQL + @Server + '.'
							SET @SQL = @SQL + @DB + '..NL_TRN_TEMP(NL_TRAN_ID, NL_DETAIL_LINE_NO, NL_STATUS_TEMP, NL_USER_ID, NL_MODULE, NL_TRANSACTION_TYPE, NL_MAXIMUM_POSTING_NO, NL_CREDIT_DEBIT_TRANSACTION, NL_TRANSACTION_DATE, NL_JOURNAL_ACCOUNT, NL_HOME_TRANSACTION_VALUE, NL_DETAIL_DESCRIPTION, NL_DO_NOT_BATCH, NL_TRAN_REFERENCE)
							VALUES ( ' + LTrim(Str(@BatchNum)) + ', ' + LTrim(Str(@LineCount)) + ', 0, ''INT'' , ''CB'' , ''TFR'', 0 , ''CR'', ''' + LTrim(@BatchDate) + ''',  ''' + LTrim(@BankClear) + ''', ' + LTrim(Cast(@LodgeAmt as varchar)) + ', ''PE Lodgement - ' + LTrim(Replace(@LodgeRef,'''','')) + ' - ' + LTrim(Replace(@LodgePayor,'''', '')) + ''', 1, ''' + LTrim(Replace(@LodgeRef,'''',''))  + ''')'
							END
			
						IF @LodgeAmt <= 0
							BEGIN
							SET @SQL = 'INSERT INTO '
							IF @Server <> ''
								SET @SQL = @SQL + @Server + '.'
							SET @SQL = @SQL + @DB + '..NL_TRN_TEMP(NL_TRAN_ID, NL_DETAIL_LINE_NO, NL_STATUS_TEMP, NL_USER_ID, NL_MODULE, NL_TRANSACTION_TYPE, NL_MAXIMUM_POSTING_NO, NL_CREDIT_DEBIT_TRANSACTION, NL_TRANSACTION_DATE, NL_JOURNAL_ACCOUNT, NL_HOME_TRANSACTION_VALUE, NL_DETAIL_DESCRIPTION, NL_DO_NOT_BATCH, NL_TRAN_REFERENCE)
							VALUES ( ' + LTrim(Str(@BatchNum)) + ', ' + LTrim(Str(@LineCount)) + ', 0, ''INT'' , ''CB'' , ''TFR'', 0 , ''DR'', ''' + LTrim(@BatchDate) + ''',  ''' + LTrim(@BankClear) + ''', ' + LTrim(Cast(@LodgeAmt* -1 as varchar)) + ', ''PE Lodgement - ' + LTrim(Replace(@LodgeRef,'''','')) + ' - ' + LTrim(Replace(@LodgePayor,'''', '')) + ''', 1, ''' + LTrim(Replace(@LodgeRef,'''',''))  + ''')'
							END

						PRINT @SQL

						EXEC (@SQL)
	
						FETCH 	csr_Cash INTO @LodgeAmt, @LodgePayor, @LodgeDebtor, @CreditCard, @LodgeType
						END
		
					CLOSE csr_Cash
					DEALLOCATE csr_Cash

				SET @LineCount = @LineCount + 1

				IF @BankCur = @SysCur
					BEGIN
					IF @LodgeCurTotal > 0
						BEGIN
						SET @SQL = 'INSERT INTO '
						IF @Server <> ''
							SET @SQL = @SQL + @Server + '.'
						SET @SQL = @SQL + @DB + '..NL_TRN_TEMP(NL_TRAN_ID, NL_DETAIL_LINE_NO, NL_STATUS_TEMP, NL_USER_ID, NL_MODULE, NL_TRANSACTION_TYPE, NL_MAXIMUM_POSTING_NO, NL_CREDIT_DEBIT_TRANSACTION, NL_TRANSACTION_DATE, NL_JOURNAL_ACCOUNT, NL_HOME_TRANSACTION_VALUE, NL_DETAIL_DESCRIPTION, NL_DO_NOT_BATCH, NL_TRAN_REFERENCE)
						VALUES ( ' + LTrim(Str(@BatchNum)) + ', ' + LTrim(Str(@LineCount)) + ', 0, ''INT'' , ''CB'' , ''TFR'', 0 , ''DR'', ''' + LTrim(@BatchDate) + ''', ''' + LTrim(@NomBank) + ''', ' + LTrim(Cast(@LodgeTotal as varchar)) + ', ''PE Lodgement - ' +  LTrim(Replace(@LodgeRef,'''','')) + ''', 1, ''' + LTrim(Replace(@LodgeRef,'''',''))  + ''')'
						END
		
					IF @LodgeCurTotal <= 0
						BEGIN
						SET @SQL = 'INSERT INTO '
						IF @Server <> ''
							SET @SQL = @SQL + @Server + '.'
						SET @SQL = @SQL + @DB + '..NL_TRN_TEMP(NL_TRAN_ID, NL_DETAIL_LINE_NO, NL_STATUS_TEMP, NL_USER_ID, NL_MODULE, NL_TRANSACTION_TYPE, NL_MAXIMUM_POSTING_NO, NL_CREDIT_DEBIT_TRANSACTION, NL_TRANSACTION_DATE, NL_JOURNAL_ACCOUNT, NL_HOME_TRANSACTION_VALUE, NL_DETAIL_DESCRIPTION, NL_DO_NOT_BATCH, NL_TRAN_REFERENCE)
						VALUES ( ' + LTrim(Str(@BatchNum)) + ', ' + LTrim(Str(@LineCount)) + ', 0, ''INT'' , ''CB'' , ''TFR'', 0 , ''CR'', ''' + LTrim(@BatchDate) + ''', ''' + LTrim(@NomBank) + ''', ' + LTrim(Cast(@LodgeTotal*-1 as varchar)) + ', ''PE Lodgement - ' + LTrim(Replace(@LodgeRef,'''','')) + ''', 1, ''' + LTrim(Replace(@LodgeRef,'''',''))  + ''')'
						END
					END
				ELSE
					BEGIN
					IF @BankCur = 'STG' SET @BankCur = 'GBP'
					IF @LodgeCurTotal > 0
						BEGIN
						SET @SQL = 'INSERT INTO '
						IF @Server <> ''
							SET @SQL = @SQL + @Server + '.'
						SET @SQL = @SQL + @DB + '..NL_TRN_TEMP(NL_TRAN_ID, NL_DETAIL_LINE_NO, NL_STATUS_TEMP, NL_USER_ID, NL_MODULE, NL_TRANSACTION_TYPE, NL_MAXIMUM_POSTING_NO, NL_CREDIT_DEBIT_TRANSACTION, NL_TRANSACTION_DATE, NL_CURRENCYSYMBOL, NL_CURRENCYCODE, NL_CURRENCY_TYPE, NL_CURRENCY_RATE, NL_CURRENCY_GROSS, NL_JOURNAL_ACCOUNT, NL_HOME_TRANSACTION_VALUE, NL_DETAIL_DESCRIPTION, NL_DO_NOT_BATCH, NL_TRAN_REFERENCE)
						VALUES ( ' + LTrim(Str(@BatchNum)) + ', ' + LTrim(Str(@LineCount)) + ', 0, ''INT'' , ''CB'' , ''TFR'', 0 , ''DR'', ''' + LTrim(@BatchDate) + ''', ''' + LTrim(@BankCur) + ''', ''D' + LTrim(@BankCur) + ''', ''D'', ' + LTrim(Cast(@LodgeRate as varchar)) + ', ' + LTrim(Cast(@LodgeCurTotal as varchar)) + ', ''' + LTrim(@NomBank) + ''', ' + LTrim(Cast(@LodgeTotal as varchar)) + ', ''PE Lodgement - ' +  LTrim(Replace(@LodgeRef,'''','')) + ''', 1, ''' + LTrim(Replace(@LodgeRef,'''',''))  + ''')'
						END
		

					IF @LodgeCurTotal <= 0
						BEGIN
						SET @SQL = 'INSERT INTO '
						IF @Server <> ''
							SET @SQL = @SQL + @Server + '.'
						SET @SQL = @SQL + @DB + '..NL_TRN_TEMP(NL_TRAN_ID, NL_DETAIL_LINE_NO, NL_STATUS_TEMP, NL_USER_ID, NL_MODULE, NL_TRANSACTION_TYPE, NL_MAXIMUM_POSTING_NO, NL_CREDIT_DEBIT_TRANSACTION, NL_TRANSACTION_DATE, NL_CURRENCYSYMBOL, NL_CURRENCYCODE, NL_CURRENCY_TYPE, NL_CURRENCY_RATE, NL_CURRENCY_GROSS, NL_JOURNAL_ACCOUNT, NL_HOME_TRANSACTION_VALUE, NL_DETAIL_DESCRIPTION, NL_DO_NOT_BATCH, NL_TRAN_REFERENCE)
						VALUES ( ' + LTrim(Str(@BatchNum)) + ', ' + LTrim(Str(@LineCount)) + ', 0, ''INT'' , ''CB'' , ''TFR'', 0 , ''CR'', ''' + LTrim(@BatchDate) + ''', ''' + LTrim(@BankCur) + ''', ''D' + LTrim(@BankCur) + ''', ''D'', ' + LTrim(Cast(@LodgeRate as varchar)) + ', ' + LTrim(Cast(@LodgeCurTotal*-1 as varchar)) + ', ''' + LTrim(@NomBank) + ''', ' + LTrim(Cast(@LodgeTotal*-1 as varchar)) + ', ''PE Lodgement - ' + LTrim(Replace(@LodgeRef,'''','')) + ''',1, ''' + LTrim(Replace(@LodgeRef,'''','')) + ''')'
						END
					END
		
				PRINT @SQL

				EXEC (@SQL)

				IF @@ERROR <> 0 GOTO TRAN_ABORT
	
				SET @SQL = 'UPDATE '
				IF @Server <> ''
					SET @SQL = @SQL + @Server + '.'
				SET @SQL = @SQL + @DB + '..NL_TRN_TEMP
				SET NL_STATUS_TEMP = 1
				WHERE NL_TRAN_ID = ' + LTrim(Str(@BatchNum))
		
				EXEC (@SQL)
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
			
				SET @SQL = 'UPDATE '
				IF @Server <> ''
					SET @SQL = @SQL + @Server + '.'
				SET @SQL = @SQL + @DB + '..NL_TRN_TEMP
				SET NL_STATUS_TEMP = 2
				WHERE NL_TRAN_ID = ' + LTrim(Str(@BatchNum))
		
				EXEC (@SQL)
		
				IF @@ERROR <> 0 GOTO TRAN_ABORT

				CREATE TABLE #Count ( NumRows int )
	
				SET @SQL = 'INSERT INTO #Count (NumRows)
				SELECT Count(*) FROM '
				IF @Server <> ''
					SET @SQL = @SQL + @Server + '.'
				SET @SQL = @SQL + @DB + '..NL_TRN_TEMP
				WHERE NL_STATUS_TEMP = 3 AND NL_TRAN_ID = ' + LTrim(Str(@BatchNum)) 
		
				EXEC (@SQL)
	
				IF (SELECT NumRows FROM #Count) > 0
					BEGIN
					SET @SQL = 'DELETE
					FROM '
					IF @Server <> ''
						SET @SQL = @SQL + @Server + '.'
					SET @SQL = @SQL + @DB + '..NL_TRN_TEMP
					WHERE NL_TRAN_ID = ' + LTrim(Str(@BatchNum)) 
			
					EXEC (@SQL)
	
					GOTO TRAN_ABORT					
					END
				
				DROP TABLE #Count
			
				UPDATE tblTranNominalBank
				SET LodgeBatch = @BatchNum
				WHERE LodgeIndex = @LodgeInd
	
				IF @@ERROR <> 0 GOTO TRAN_ABORT
	
				FETCH 	csr_Bank INTO @NomBank, @LodgeInd, @BatchDate, @LodgeRef, @BankCur, @LodgeCurTotal, @LodgeRate, @LodgeTotal, @BankOffice
				END
	
	
			CLOSE csr_Bank
			DEALLOCATE csr_Bank

		FETCH csr_Org INTO @Org, @Server, @DB
		END

	CLOSE csr_Org
	DEALLOCATE csr_Org

	COMMIT TRAN
	GOTO FINISH

TRAN_ABORT:
	ROLLBACK TRAN
	SET @Result = 1

FINISH:
	SET @Result = 0
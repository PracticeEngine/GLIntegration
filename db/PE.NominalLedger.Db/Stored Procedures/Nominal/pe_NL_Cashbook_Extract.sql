CREATE PROCEDURE [dbo].[pe_NL_Cashbook_Extract]
	@NomOrg int,
	@BatchID int = 0
AS

	DECLARE @Batch int

	IF @BatchID > 0
		BEGIN
		SET @Batch = @BatchID
		END
	ELSE
		BEGIN
		SELECT @Batch = LastBatch + 1 FROM tblTranNominalControl
		END
		
	Declare @SysCur char(3)

	SELECT @SysCur = TranSetCur 
	FROM tblTransactionSettings
	WHERE TranSetIndex = 1

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

	DECLARE @BankMapIndex int
	DECLARE @BankOffice varchar(10)
	DECLARE @MapIndex int
	DECLARE @BankClear varchar(20)
	DECLARE @MapAcc varchar(8)

	SET @BankClear = ''
	
	CREATE TABLE #Cash(LineCount int IDENTITY(1,1), MapIndex int, Account nvarchar(20), LodgeInd int, BatchDate date, LodgeRef nvarchar(20), LodgeAmt money, LodgePayor nvarchar(255))

	DECLARE csr_Bank CURSOR DYNAMIC		
	FOR SELECT TB.BankNominal, H.LodgeIndex, H.LodgeDate, Left(Coalesce(H.LodgeRef,''), 10) As LodgeRef, TB.BankCurrency, H.LodgeAccAmount, H.LodgeAccRate, H.LodgeAmount, TB.BankOffice
		FROM (tblTranNominalBank NB INNER JOIN tblLodgementHeader H ON NB.LodgeIndex = H.LodgeIndex) INNER JOIN tblTranBank TB ON H.LodgeBank = TB.BankIndex
		WHERE NB.LodgeBatch = @BatchID AND LTrim(TB.BankNominal) <> '' AND TB.PracID = @NomOrg
		ORDER BY H.LodgeIndex
	
		OPEN csr_Bank
		FETCH 	csr_Bank INTO @NomBank, @LodgeInd, @BatchDate, @LodgeRef, @BankCur, @LodgeCurTotal, @LodgeRate, @LodgeTotal, @BankOffice
		WHILE (@@FETCH_STATUS=0) 
			BEGIN
			IF @BankCur <> @SysCur 
				SET @CurPrefix = ''
			ELSE
				SET @CurPrefix = ''
			SELECT @BankMapIndex = MIN(MapIndex) FROM tblTranNominalMap WHERE MapOrg = @NomOrg AND MapTargetAcc = @NomBank

			DECLARE csr_Cash CURSOR DYNAMIC		
			FOR SELECT D.LodgeAmount, D.LodgePayor, D.LodgeDebtor, D.CreditCard, D.LodgeType
			FROM tblLodgementDetails D
			WHERE D.LodgeIndex = @LodgeInd
	
				OPEN csr_Cash
				FETCH 	csr_Cash INTO @LodgeAmt, @LodgePayor, @LodgeDebtor, @CreditCard, @LodgeType
				WHILE (@@FETCH_STATUS=0) 
					BEGIN
					SET @MapAcc = 'BNKCON'
					SET @BankClear = ''
					SET @MapIndex = (SELECT TOP 1 MapIndex FROM tblTranNominalMap WHERE MapSource = 'LOD' AND MapAccount = @MapAcc AND MapOrg = @NomOrg AND MapOffice = @BankOffice AND MapTargetAcc <> '')
					IF Coalesce(@MapIndex, 0) > 0
						SELECT @BankClear = MapTargetAcc FROM tblTranNominalMap WHERE MapIndex = @MapIndex

					INSERT INTO #Cash(MapIndex, Account, LodgeInd, BatchDate, LodgeRef, LodgeAmt, LodgePayor)
					VALUES (@MapIndex, @BankClear, @LodgeInd, @BatchDate, @LodgeRef, @LodgeAmt, @LodgePayor)
	
					FETCH 	csr_Cash INTO @LodgeAmt, @LodgePayor, @LodgeDebtor, @CreditCard, @LodgeType
					END
		
				CLOSE csr_Cash
				DEALLOCATE csr_Cash

			INSERT INTO #Cash(MapIndex, Account, LodgeInd, BatchDate, LodgeRef, LodgeAmt, LodgePayor)
			VALUES (@BankMapIndex, @NomBank, @LodgeInd, @BatchDate, @LodgeRef, @LodgeTotal, '')
	
			FETCH 	csr_Bank INTO @NomBank, @LodgeInd, @BatchDate, @LodgeRef, @BankCur, @LodgeCurTotal, @LodgeRate, @LodgeTotal, @BankOffice
			END
		
		CLOSE csr_Bank
		DEALLOCATE csr_Bank
		
	SELECT C.MapIndex, M.MapTargetType as AccountTypeCode, M.MapTargetAcc as AccountCode,
	@Batch As NomBatch, C.LodgeAmt As NomAmount, C.LodgePayor As NomNarrative, C.LodgeRef As NomTransRef, C.BatchDate As NomDate, CAST(M.MapOrg AS int) AS NomOrg
	FROM #Cash C
	INNER JOIN tblTranNominalMap M ON C.MapIndex = M.MapIndex

RETURN 0

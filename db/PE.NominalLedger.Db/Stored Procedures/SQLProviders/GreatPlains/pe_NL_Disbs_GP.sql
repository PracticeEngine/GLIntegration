CREATE PROCEDURE [dbo].[pe_NL_Disbs_GP]

@PeriodEnd datetime,
@UserCode varchar(10),
@LastDisb int,
@Result as int OUTPUT

AS
DECLARE @DisbIndex int
DECLARE @MaxDisb int
DECLARE @ClientCode varchar(10)
DECLARE @Job_Idx varchar(10)
DECLARE @ServIndex varchar(10)
DECLARE @Narr varchar(255)
DECLARE @PostDesc varchar(255)
DECLARE @Rest varchar(255)
DECLARE @TotAmt money
DECLARE @NumTrans int
DECLARE @DisbCode varchar(10)
DECLARE @DisbDate datetime

	SET @DisbCode = (SELECT DisbStd FROM tblTranNominalControl)
	SET @DisbDate = (SELECT Min(TimePeriodEndDate) FROM tblControlTimePeriods WHERE PeriodEndDate = @PeriodEnd)
	IF @DisbDate IS NULL
		SET @DisbDate = @PeriodEnd

	SELECT pe_view_NL_GP_Disb.*, DisbCode = CASE WHEN tblTranNominalDisbMap.DisbCode IS NULL THEN @DisbCode ELSE tblTranNominalDisbMap.DisbCode END, SPACE(10) AS ClientCode, SPACE(10) AS Job_Idx, SPACE(10) AS ServIndex, SPACE(255) AS Narrative, SPACE(20) AS VendorID, 0 AS PostIt, @DisbDate As DisbDate INTO #wrk
	FROM pe_view_NL_GP_Disb LEFT OUTER JOIN tblTranNominalDisbMap ON pe_view_NL_GP_Disb.ACTINDX = tblTranNominalDisbMap.NLIdx
	WHERE Left(PostDesc,1) <> 'Â¬' AND Ltrim(PostDesc) <> ''

	UPDATE #wrk
	SET DisbCode = @DisbCode
	WHERE DisbCode = ''

	SET @NumTrans = (SELECT Count(Dex_Row_ID) FROM #wrk)
	IF @NumTrans IS NULL
		SET @NumTrans = 0

	IF @NumTrans = 0 GOTO NOTRANS

	DECLARE csr_Lines CURSOR DYNAMIC
		
	FOR SELECT PostDesc
		FROM #wrk
		
		OPEN csr_Lines
		FETCH 	csr_Lines INTO @PostDesc
		WHILE (@@FETCH_STATUS=0)
			BEGIN
			SET @PostDesc = RTrim(@PostDesc)
			SET @ClientCode = SubString(@PostDesc,1,CharIndex('/',@PostDesc)-1)
			SET @Rest = Right(@PostDesc,Len(@PostDesc)-Len(@ClientCode)-1)
			SET @Job_Idx = SubString(@Rest,1,CharIndex('/',@Rest)-1)
			SET @Rest = Right(@Rest,Len(@Rest)-Len(@Job_Idx)-1)
			SET @ServIndex = SubString(@Rest,1,CharIndex('/',@Rest)-1)
			SET @Narr = Right(@Rest,Len(@Rest)-Len(@ServIndex)-1)
			IF @Job_Idx = '1027'
				SET @Job_Idx = '0'

			UPDATE #wrk
			SET ClientCode = @ClientCode, Job_Idx = @Job_Idx, ServIndex = @ServIndex, Narrative = @Narr
			WHERE CURRENT OF csr_Lines

			FETCH 	csr_Lines INTO @PostDesc
			END
	
		CLOSE csr_Lines
		DEALLOCATE csr_Lines

	UPDATE #wrk
	SET VendorID = ORMSTRID, PostIt = 1, DisbDate = Tra.TRXDATE
	FROM #wrk INNER JOIN pe_view_NL_GP_GLTrans Tra ON #wrk.JRNENTRY = Tra.JRNENTRY AND #wrk.ACTINDX = Tra.ACTINDX AND #wrk.DTASERIES = Tra.OrigDTASeries

	DELETE
	FROM #wrk
	WHERE PostIt = 0

	BEGIN TRAN

	SET @TotAmt = (SELECT Sum(CodeAmt) FROM #wrk)
	IF @TotAmt IS NULL
		SET @TotAmt = 0

	IF @@ERROR <> 0 GOTO TRAN_ABORT

	INSERT INTO tblDisbHeader (TimePeriodEndDate, DisbOffice, DisbStaff, DisbInput, DisbType, DisbStatus, DisbTotal, DisbComments, DisbUpdated, DisbUpdatedBy)
	VALUES (@DisbDate, 'LONA', 0, 'GENERAL', '', 'ACTIVE', @TotAmt, 'Import From Great Plains', GetDate(), @UserCode)

	IF @@ERROR <> 0 GOTO TRAN_ABORT

	SET @DisbIndex = (SELECT Max(DisbIndex) FROM tblDisbHeader)
	
	IF @@ERROR <> 0 GOTO TRAN_ABORT

	INSERT INTO tblDisbursements (DisbIndex, DisbDate, Chargeable, ClientCode, ClientIndex, ClientName, Service, ChargeCode, OverRide, Description, Supplier, SupplierIndex, Reference, ChargeScale, ChargeUnits, ChargeRate, ChargeAmount, ChargeVAT, ChargeVATRate, ServPeriod)
	SELECT @DisbIndex, DisbDate, 0, Eng.ClientCode, Eng.ContIndex, Eng.ClientName, #wrk.ServIndex, DisbCode, 0, LefT(RTrim(#wrk.ClientRef) + '-' + RTrim(#wrk.VendorID) + '-' + RTrim(#wrk.Narrative),60), '', 0, '', 0, 0, 0, #wrk.CodeAmt, 0, 1, Job.Job_Idx
	FROM (#wrk INNER JOIN tblEngagement AS Eng ON #wrk.clientcode = Eng.ClientCode) INNER JOIN tblJob_Header AS Job ON #wrk.Job_Idx = Job.Job_Idx

	IF @@ERROR <> 0 GOTO TRAN_ABORT

	SET @MaxDisb = (SELECT Max(Dex_Row_ID) FROM #wrk)
	IF @MaxDisb IS NULL 
		SET @MaxDisb = 0

	UPDATE pe_view_NL_GP_Disb
	SET pe_view_NL_GP_Disb.PostDesc = 'Â¬' + pe_view_NL_GP_Disb.PostDesc
	FROM pe_view_NL_GP_Disb INNER JOIN #wrk ON pe_view_NL_GP_Disb.DEX_ROW_ID = #wrk.DEX_ROW_ID

	IF @@ERROR <> 0 GOTO TRAN_ABORT

	COMMIT TRAN
	GOTO FINISH

TRAN_ABORT:
	ROLLBACK TRAN
	SET @Result = -1
	GOTO DONE

FINISH:
	SET @Result = @MaxDisb
	GOTO DONE

NOTRANS:
	SET @Result = -2

DONE:
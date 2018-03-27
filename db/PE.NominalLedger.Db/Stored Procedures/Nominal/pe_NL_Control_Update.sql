CREATE PROCEDURE [dbo].[pe_NL_Control_Update]

@WIPServ bit,
@WIPPart bit,
@WIPOffice bit,
@WIPDept bit,
@WIPDetail bit,
@DRSServ bit,
@DRSPart bit,
@DRSOffice bit,
@DRSDept bit,
@DRSDetail bit,
@IntSystem varchar(30),
@FeeSource char(3),
@FeeProfit bit,
@FeePart bit,
@DisbLevel bit,
@DisbStd varchar(10),
@InterCo bit,
@Cashbook bit,
@Expenses bit

AS

DECLARE @Count as int

SET @Count = (SELECT Count(IntIndex) FROM tblTranNominalControl)

IF @Count = 0
	BEGIN
	INSERT INTO tblTranNominalControl(WIPServ, WIPPart, WIPOffice, WIPDept, WIPLevel, DRSServ, DRSPart, DRSOffice, DRSDept, DRSLevel, IntSystem, FeeSource, FeeProfit, FeePart, DisbLevel, DisbStd, InterCo, Cashbook, Expenses)
	VALUES (@WIPServ, @WIPPart, @WIPOffice, @WIPDept, @WIPDetail, @DRSServ, @DRSPart, @DRSOffice, @DRSDept, @DRSDetail, @IntSystem, @FeeSource, @FeeProfit, @FeePart, @DisbLevel, @DisbStd, @InterCo, @Cashbook, @Expenses)
	END

IF @Count > 0
	BEGIN
	UPDATE tblTranNominalControl
	SET WIPServ = @WIPServ, WIPPart = @WIPPart, WIPOffice = @WIPOffice, WIPDept = @WIPDept, WIPLevel = @WIPDetail, 
		DRSServ = @DRSServ, DRSPart = @DRSPart, DRSOffice = @DRSOffice, DRSDept = @DRSDept, DRSLevel = @DRSDetail, 
		IntSystem = @IntSystem, FeeSource = @FeeSource, FeeProfit = @FeeProfit, FeePart = @FeePart, DisbLevel = @DisbLevel, DisbStd = @DisbStd,
		InterCo = @InterCo, Cashbook = @Cashbook, Expenses = @Expenses
	END
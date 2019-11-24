CREATE PROCEDURE [dbo].[pe_NL_Expense_Post]

@BatchID int,
@Result int OUTPUT

AS

DECLARE @IntSys varchar(20)
DECLARE @PostDate datetime

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

SELECT @PostDate = PracPeriodEnd FROM tblControl WHERE PracID = 1

IF @PostDate > GetDate()
	SET @PostDate = Convert(varchar(20), GetDate(), 106)
	
IF @IntSys = 'AD'
	BEGIN
	exec  pe_NL_Expense_Post_AD @PostDate, @BatchID, @Result output
	END

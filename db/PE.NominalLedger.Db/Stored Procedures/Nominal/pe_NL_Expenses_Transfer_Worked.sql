CREATE PROCEDURE [dbo].[pe_NL_Expenses_Transfer_Worked]

@PracID int,
@HangfireJobID nvarchar(255)

AS

DECLARE @Batch int
SELECT @Batch = LastBatch + 1 FROM tblTranNominalControl

DECLARE @Period int
SELECT @Period = MAX(PeriodIndex) FROM tblTranNominalPostExpenses WHERE Posted = 0

UPDATE tblTranNominalExpense
SET HangfireJobID = NULL, ExpPosted = 1, ExpBatch = @Batch, ExpPostDate = GetDate()
WHERE ExpPrac = @PracID AND ExpPosted = 0 AND ExpPeriod = @Period AND HangfireJobID = @HangfireJobID

UPDATE tblTranNominalPostExpenses 
SET HangfireJobID = NULL, Posted = 1, PostDate = GETDATE()
WHERE Posted = 0 AND ExpOrg = @PracID AND PeriodIndex = @Period AND HangfireJobID = @HangfireJobID

UPDATE tblTranNominalControl
SET LastBatch = LastBatch + 1


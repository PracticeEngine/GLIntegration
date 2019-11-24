CREATE PROCEDURE [dbo].[pe_NL_Expenses_Transfer_Failed]

@PracID int,
@HangfireJobID nvarchar(255)

AS

DECLARE @Period int
SELECT @Period = MAX(PeriodIndex) FROM tblTranNominalPostExpenses WHERE Posted = 0

UPDATE tblTranNominalExpense
SET HangfireJobID = NULL 
WHERE ExpPosted = 0 AND ExpPrac = @PracID AND ExpPeriod = @Period AND HangfireJobID = @HangfireJobID

UPDATE tblTranNominalPostExpenses 
SET HangfireJobID = NULL
WHERE Posted = 0 AND ExpOrg = @PracID AND PeriodIndex = @Period AND HangfireJobID = @HangfireJobID

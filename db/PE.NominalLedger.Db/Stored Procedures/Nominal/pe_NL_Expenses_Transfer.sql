CREATE PROCEDURE [dbo].[pe_NL_Expenses_Transfer]

@PracID int,
@BatchID int = 0,
@HangfireJobID nvarchar(255)

AS

DECLARE @Batch int

IF (SELECT NLTransfer FROM tblTranNominalOrgs WHERE PracID = @PracID) = 0
	BEGIN
	RETURN 1
	END

IF @BatchID > 0
	BEGIN
	SET @Batch = @BatchID
	END
ELSE
	BEGIN
	SELECT @Batch = LastBatch + 1 FROM tblTranNominalControl
	END

DECLARE @Period int
SELECT @Period = MAX(PeriodIndex) FROM tblTranNominalPostExpenses WHERE Posted = 0

UPDATE tblTranNominalPostExpenses 
SET HangfireJobID = @HangfireJobID 
WHERE Posted = 0 AND ExpOrg = @PracID AND PeriodIndex = @Period AND HangfireJobID IS NULL

SELECT @Batch As NomBatch
FROM tblTranNominalPostExpenses
WHERE Posted = 0 AND ExpOrg = @PracID AND PeriodIndex = @Period AND HangfireJobID = @HangfireJobID

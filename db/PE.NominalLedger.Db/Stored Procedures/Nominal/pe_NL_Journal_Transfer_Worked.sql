CREATE PROCEDURE [dbo].[pe_NL_Journal_Transfer_Worked]

@PracID int,
@Journal  varchar(4),
@HangfireJobID nvarchar(255)

AS

DECLARE @Period int
SELECT @Period = MAX(NomPeriodIndex) FROM tblTranNominalPost WHERE NomPosted = 0

DECLARE @JournalNo int
SELECT @JournalNo = LastBatch + 1 FROM tblTranNominalControl

CREATE TABLE #Source (Src VarChar(3))
IF @Journal = 'GJ'
               INSERT INTO #Source (Src) VALUES ('WIP'), ('DRS'), ('LOD')
IF @Journal = 'STA'
               INSERT INTO #Source (Src) VALUES ('STA')

UPDATE tblTranNominal SET NomIndex = 0, NLPosted = 1, NomBatch = @JournalNo, HangfireJobID = NULL
FROM tblTranNominal INNER JOIN #Source ON NLSource = Src
WHERE NLPeriodIndex = @Period AND NomIndex = 1 AND NLPosted = -1 AND NLOrg = @PracID AND HangfireJobId = @HangfireJobID

UPDATE tblTranNominalPost SET NomPosted = 1, NomBatch = @JournalNo, NomPostDate = GETDATE(), HangfireJobID = NULL
FROM tblTranNominalPost INNER JOIN #Source ON NomSource = Src
WHERE NomPeriodIndex = @Period AND NomPosted = -1 AND NomOrg = @PracID AND HangfireJobId = @HangfireJobID

UPDATE tblTranNominalControl
SET LastBatch = LastBatch + 1

RETURN 0

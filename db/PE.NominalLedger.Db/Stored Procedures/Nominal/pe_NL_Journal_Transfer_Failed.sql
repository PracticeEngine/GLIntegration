CREATE PROCEDURE [dbo].[pe_NL_Journal_Transfer_Failed]

@PracID int,
@Journal  varchar(4),
@HangfireJobID nvarchar(255)

AS

DECLARE @Period int
SELECT @Period = MAX(NomPeriodIndex) FROM tblTranNominalPost WHERE NomPosted = 0

CREATE TABLE #Source (Src VarChar(3))
IF @Journal = 'GJ'
               INSERT INTO #Source (Src) VALUES ('WIP'), ('DRS'), ('LOD')
IF @Journal = 'STA'
               INSERT INTO #Source (Src) VALUES ('STA')

UPDATE tblTranNominal SET NLPosted = 0, HangfireJobID = NULL
FROM tblTranNominal INNER JOIN #Source ON NLSource = Src
WHERE NLPeriodIndex = @Period AND NomIndex = 1 AND NLPosted = 0 AND NLOrg = @PracID AND HangfireJobID = @HangfireJobID

UPDATE tblTranNominalPost SET NomPosted = 0, HangfireJobID = NULL
FROM tblTranNominalPost INNER JOIN #Source ON NomSource = Src
WHERE NomPeriodIndex = @Period AND NomPosted = 0 AND NomOrg = @PracID AND HangfireJobID = @HangfireJobID

RETURN 0


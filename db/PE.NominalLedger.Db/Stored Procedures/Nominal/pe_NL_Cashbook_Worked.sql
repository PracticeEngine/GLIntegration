CREATE PROCEDURE [dbo].[pe_NL_Cashbook_Worked]

@NomOrg int,
@type varchar(3) = NULL

AS

DECLARE @JournalNo int
SELECT @JournalNo = LastBatch + 1 FROM tblTranNominalControl

UPDATE tblTranNominalBank SET LodgePosted = 1, LodgePostDate = GETDATE(), LodgeBatch = @JournalNo
WHERE LodgePosted = 0 AND LodgePrac = @NomOrg 

UPDATE tblTranNominalControl
SET LastBatch = LastBatch + 1


RETURN 0

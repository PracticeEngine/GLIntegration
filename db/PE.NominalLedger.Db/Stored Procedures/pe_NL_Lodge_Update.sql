CREATE PROCEDURE [dbo].[pe_NL_Lodge_Update]

AS

INSERT INTO tblTranNominalBank (LodgeIndex, LodgeDate, LodgeBank, LodgeStatus, LodgePrac)
SELECT tblLodgementHeader.LodgeIndex, tblLodgementHeader.LodgeDate, tblLodgementHeader.LodgeBank, tblLodgementHeader.LodgeStatus, tblTranBank.PracID
FROM (tblLodgementHeader INNER JOIN tblTranBank ON tblLodgementHeader.LodgeBank = tblTranBank.BankIndex) LEFT OUTER JOIN tblTranNominalBank ON tblLodgementHeader.LodgeIndex = tblTranNominalBank.LodgeIndex
WHERE tblTranNominalBank.LodgeIndex IS NULL AND tblLodgementHeader.LodgeStatus = 'COMPLETE'
CREATE PROCEDURE [dbo].[pe_NL_Cashbook_Entries]

@BatchID int

AS

SELECT Count(*) As Num_Entries
FROM tblTranNominalBank
WHERE LodgeBatch = @BatchID
CREATE PROCEDURE [dbo].[pe_NL_MTD_Mark_As_Processed]

@Id int

AS

UPDATE M
SET Processed = 1
FROM tblTranNominalMTD M 
WHERE M.DebtTranIndex = @Id

CREATE PROCEDURE [dbo].[pe_NL_MTD_Export_Invoices]

@Org int

AS

SELECT D.DebtTranIndex, D.ContIndex, D.DebtTranAddress, D.DebtTranRefAlpha, D.DebtTranRefNum, D.DebtTranDate, D.DebtTranAmount, D.DebtTranVAT
FROM tblTranDebtor D 
INNER JOIN tblTranNominalMTD M ON D.DebtTranIndex = M.DebtTranIndex
WHERE M.Processed = 0 AND D.PracID = @Org
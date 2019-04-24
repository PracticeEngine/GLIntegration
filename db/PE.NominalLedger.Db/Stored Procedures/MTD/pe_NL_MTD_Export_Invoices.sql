CREATE PROCEDURE [dbo].[pe_NL_MTD_Export_Invoices]

@Org int

AS

SELECT D.DebtTranIndex, D.DebtTranType, D.ContIndex, D.DebtTranAddress, D.DebtTranRefAlpha, D.DebtTranRefNum, D.DebtTranDate, DATEADD(dd, E.ClientTerms, D.DebtTranDate) As DueDate, D.DebtTranAmount, D.DebtTranVAT
FROM tblTranDebtor D 
INNER JOIN tblEngagement E ON D.ContIndex = E.ContIndex
INNER JOIN tblTranNominalMTD M ON D.DebtTranIndex = M.DebtTranIndex
WHERE M.Processed = 0 AND D.PracID = @Org
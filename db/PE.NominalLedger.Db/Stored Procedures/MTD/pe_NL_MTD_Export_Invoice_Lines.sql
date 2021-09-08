CREATE PROCEDURE [dbo].[pe_NL_MTD_Export_Invoice_Lines]

@Org int

AS

SELECT DD.DebtTranIndex, DD.Amount, DD.VATRate, DD.VATAmount, DD.FeeNarrative As [Description], CASE WHEN DD.VATAmount = 0 THEN 'NONE' ELSE 'OUTPUT2' END As TaxCode, '200' As AccountCode
FROM tblTranDebtor D 
INNER JOIN tblTranDebtorDetail DD ON D.DebtTranIndex = DD.DebtTranIndex
INNER JOIN tblTranNominalMTD M ON D.DebtTranIndex = M.DebtTranIndex
WHERE M.Processed = 0 AND D.PracID = @Org
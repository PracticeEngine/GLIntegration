CREATE PROCEDURE [dbo].[pe_NL_Post_Create_EXP]

@Period int

AS

INSERT INTO tblTranNominalPostExpenses(PeriodIndex, ExpDate, ExpOrg, VendorIndex, VendorCode, DisbCode, Amount, VATAmount, PostAcc, Description, AllocIndex, Posted)
SELECT @Period, N.ExpDate,  CASE WHEN H.ExpType = 'OWN' THEN S.StaffOrganisation ELSE 0 END, CASE WHEN H.ExpType = 'OWN' THEN H.ExpStaff ELSE 0 END, CASE WHEN H.ExpType = 'OWN' THEN S.StaffCode ELSE '' END, A.DisbCode, 
		A.ChargeAmount, A.ChargeVAT, CASE WHEN A.ClientIndex < 900000 THEN TCC.ChargeNominalWIP ELSE TCC.ChargeNominalWoff END, A.Description, A.AllocIndex, 0
FROM tblTranNominalExpense N
INNER JOIN tblExpenseHeader H ON N.ExpIndex = H.ExpIndex
INNER JOIN tblExpenseAllocation A ON N.ExpIndex = A.ExpIndex
INNER JOIN tblTimeChargeCode TCC ON A.DisbCode = TCC.ChargeCode AND TCC.ChargeClass = 'DISB'
LEFT JOIN tblExpenseReceipt R ON A.ReceiptIndex = R.ReceiptIndex
LEFT JOIN tblStaff S ON H.ExpStaff = S.StaffIndex
WHERE N.ExpPosted = 0
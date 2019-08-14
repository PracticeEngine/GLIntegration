CREATE PROCEDURE [dbo].[pe_NL_Post_Create_EXP]

@Period int

AS

INSERT INTO tblTranNominalPostExpenses(PeriodIndex, ExpDate, ExpOrg, VendorIndex, VendorCode, DisbCode, Amount, VATAmount, PostAcc, Description, AllocIndex, Posted)
SELECT @Period, N.ExpDate, N.ExpPrac, S.StaffIndex, '', A.DisbCode, A.ChargeAmount, A.ChargeVAT, 
		Coalesce(CASE WHEN A.ClientIndex < 900000 THEN EM.ChargeExpAccount ELSE EM.NonChargeExpAccount END, ''), A.[Description], A.AllocIndex, 0
FROM tblTranNominalExpense N
INNER JOIN tblExpenseHeader H ON N.ExpIndex = H.ExpIndex
INNER JOIN tblExpenseAllocation A ON N.ExpIndex = A.ExpIndex
INNER JOIN tblTranNominalExpMap EM ON N.ExpPrac = EM.ExpOrg AND A.DisbCode = EM.DisbCode 
LEFT JOIN tblExpenseReceipt R ON A.ReceiptIndex = R.ReceiptIndex
LEFT JOIN tblStaff S ON H.ExpStaff = S.StaffIndex
WHERE N.ExpPosted = 0
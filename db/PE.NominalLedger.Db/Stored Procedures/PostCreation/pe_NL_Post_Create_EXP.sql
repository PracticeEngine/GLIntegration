CREATE PROCEDURE [dbo].[pe_NL_Post_Create_EXP]

@Period int

AS

INSERT INTO tblTranNominalExpMap(ExpOrg, DisbCode)
SELECT S.StaffOrganisation, A.DisbCode
FROM tblTranNominalExpense N
INNER JOIN tblExpenseHeader H ON N.ExpIndex = H.ExpIndex
INNER JOIN tblExpenseAllocation A ON N.ExpIndex = A.ExpIndex
INNER JOIN tblStaff S ON H.ExpStaff = S.StaffIndex
LEFT JOIN tblTranNominalExpMap M ON S.StaffOrganisation = M.ExpOrg AND A.DisbCode = M.DisbCode
WHERE N.ExpPosted = 0 AND M.ExpMapIndex IS NULL
GROUP BY S.StaffOrganisation, A.DisbCode

INSERT INTO tblTranNominalPostExpenses(PeriodIndex, ExpDate, ExpOrg, VendorIndex, VendorCode, DisbCode, Chargeable, Amount, VATAmount, PostAcc, Description, AllocIndex, Posted)
SELECT @Period, N.ExpDate, N.ExpPrac, S.StaffIndex, '', A.DisbCode, CASE WHEN A.ClientIndex < 900000 THEN 1 ELSE 0 END, A.ChargeAmount, A.ChargeVAT, 
		'', A.[Description], A.AllocIndex, 0
FROM tblTranNominalExpense N
INNER JOIN tblExpenseHeader H ON N.ExpIndex = H.ExpIndex
INNER JOIN tblExpenseAllocation A ON N.ExpIndex = A.ExpIndex
LEFT JOIN tblExpenseReceipt R ON A.ReceiptIndex = R.ReceiptIndex
LEFT JOIN tblStaff S ON H.ExpStaff = S.StaffIndex
WHERE N.ExpPosted = 0 AND N.ExpPeriod = @Period
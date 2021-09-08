CREATE PROCEDURE [dbo].[pe_NL_Expense_Lines]

@ExpOrg int,
@ExpStaff int

AS

CREATE TABLE #Lines([NomExpIndex] int, [PeriodIndex] int, [ExpDate] DATETIME, [ExpOrg] TINYINT, [DisbCode] nvarchar (10), [OrgName] nvarchar (255), [DisbName] nvarchar (255), 
					[PostAcc] nvarchar (20), [Amount] MONEY, [VATAmount] MONEY, [Description] nvarchar (255))

INSERT INTO #Lines(NomExpIndex, PeriodIndex, ExpDate, ExpOrg, DisbCode, OrgName, DisbName, PostAcc, Amount, VATAmount, [Description])
SELECT P.NomExpIndex, P.PeriodIndex, P.ExpDate, P.ExpOrg, P.DisbCode, C.PracName, TCC.ChargeName, P.PostAcc, P.Amount, P.VATAmount, Coalesce(P.[Description], '')
FROM tblTranNominalPostExpenses P 
INNER JOIN tblControl C ON P.ExpOrg = C.PracId 
INNER JOIN tblTimeChargeCode TCC ON P.DisbCode = TCC.ChargeCode AND TCC.ChargeClass = 'DISB'
INNER JOIN tblTranNominalOrgs O ON C.PracID = O.PracID
WHERE O.NLTransfer = 1 AND P.Posted = 0 AND P.VendorIndex = @ExpStaff AND P.ExpOrg = @ExpOrg

SELECT *
FROM #Lines
ORDER BY ExpDate, PostAcc

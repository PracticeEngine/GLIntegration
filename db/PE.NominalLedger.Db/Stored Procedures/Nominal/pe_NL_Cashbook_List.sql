CREATE PROCEDURE [dbo].[pe_NL_Cashbook_List]

@Period int

AS

DECLARE @StartDate datetime
DECLARE @EndDate datetime

SELECT @StartDate = PeriodStartDate, @EndDate = PeriodEndDate
FROM tblControlPeriods
WHERE PeriodIndex = @Period

SELECT tnb.LodgeBatch, Count(lh.LodgeIndex) As NumDep, Sum(lh.LodgeAmount) As ValDep
FROM tbltrannominalbank tnb inner join tblTranBank tb on tnb.LodgeBank = tb.BankIndex inner join tblLodgementHeader lh on tnb.LodgeIndex = lh.LodgeIndex
WHERE tnb.LodgeDate Between @StartDate and @EndDate And tnb.LodgeBatch > 0 And tb.BankNominal <> ''
GROUP BY tnb.LodgeBatch
ORDER BY tnb.LodgeBatch
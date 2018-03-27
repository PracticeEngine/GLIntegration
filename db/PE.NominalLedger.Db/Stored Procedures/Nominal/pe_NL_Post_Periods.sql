CREATE PROCEDURE [dbo].[pe_NL_Post_Periods]

AS

SELECT tblTranNominal.NLPeriodIndex, tblControlPeriods.PeriodDescription, tblControlPeriods.PeriodStartDate, tblControlPeriods.PeriodEndDate
FROM tblControlPeriods 
INNER JOIN tblTranNominal ON tblControlPeriods.PeriodIndex = tblTranNominal.NLPeriodIndex
INNER JOIN tblTranNominalOrgs ON tblTranNominal.NLOrg = tblTranNominalOrgs.PracID
WHERE tblTranNominal.NLPosted = 0 AND tblTranNominalOrgs.NLTransfer = 1
GROUP BY tblTranNominal.NLPeriodIndex, tblControlPeriods.PeriodDescription, tblControlPeriods.PeriodStartDate, tblControlPeriods.PeriodEndDate
ORDER BY tblTranNominal.NLPeriodIndex, tblControlPeriods.PeriodDescription, tblControlPeriods.PeriodStartDate, tblControlPeriods.PeriodEndDate
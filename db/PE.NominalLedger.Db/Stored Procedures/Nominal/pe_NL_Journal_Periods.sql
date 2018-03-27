CREATE PROCEDURE [dbo].[pe_NL_Journal_Periods]

AS

SELECT tblTranNominalPost.NomPeriodIndex AS NLPeriodIndex, tblControlPeriods.PeriodDescription, tblControlPeriods.PeriodStartDate, tblControlPeriods.PeriodEndDate
FROM tblControlPeriods INNER JOIN tblTranNominalPost ON tblControlPeriods.PeriodIndex = tblTranNominalPost.NomPeriodIndex INNER JOIN tblTranNominalOrgs O ON tblTranNominalPost.NomOrg = O.PracID
WHERE tblTranNominalPost.NomBatch <> 0 AND O.NLTransfer = 1
GROUP BY tblTranNominalPost.NomPeriodIndex, tblControlPeriods.PeriodDescription, tblControlPeriods.PeriodStartDate, tblControlPeriods.PeriodEndDate
ORDER BY tblTranNominalPost.NomPeriodIndex DESC, tblControlPeriods.PeriodDescription, tblControlPeriods.PeriodStartDate, tblControlPeriods.PeriodEndDate
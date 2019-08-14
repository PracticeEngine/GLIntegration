CREATE PROCEDURE [dbo].[pe_NL_Post_Periods]

AS

SELECT N.NLPeriodIndex, C.PeriodDescription, C.PeriodStartDate, C.PeriodEndDate
FROM tblControlPeriods C
INNER JOIN (SELECT DISTINCT NLOrg, NLPEriodIndex FROM tblTranNominal WHERE NLPosted = 0) N ON C.PeriodIndex = N.NLPeriodIndex
INNER JOIN tblTranNominalOrgs O ON N.NLOrg = O.PracID
WHERE O.NLTransfer = 1
GROUP BY N.NLPeriodIndex, C.PeriodDescription, C.PeriodStartDate, C.PeriodEndDate
ORDER BY N.NLPeriodIndex, C.PeriodDescription, C.PeriodStartDate, C.PeriodEndDate
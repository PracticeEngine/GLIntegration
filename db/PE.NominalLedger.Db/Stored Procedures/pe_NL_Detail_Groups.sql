CREATE PROCEDURE [dbo].[pe_NL_Detail_Groups]

@FromDate datetime,
@ToDate datetime

AS

SELECT NLOrg, NLSource, NLSection, NLAccount, OfficeName = CASE WHEN Office IS NULL THEN 'No Office' ELSE Office END, ServName = CASE WHEN Service IS NULL THEN 'No Service' ELSE Service END, StaffIdx = CASE WHEN StaffIndex IS NULL THEN -1 ELSE StaffIndex END, PartName = CASE WHEN StaffIndex IS NULL THEN 'No Partner' ELSE StaffName END, DeptName = CASE WHEN Department IS NULL THEN 'No Department' ELSE Department END, PracName
FROM (tblTranNominal LEFT JOIN tblStaff ON tblTranNominal.Partner = tblStaff.StaffIndex) INNER JOIN tblControl ON tblTranNominal.NLOrg = tblControl.PracID
WHERE NLDate >= @FromDate AND NLDate <= @ToDate
GROUP BY NLOrg, NLSource, NLSection, NLAccount, Office, Service, StaffIndex, StaffName, Department, PracName
ORDER BY NLOrg, NLSource, NLSection, NLAccount, Office, Service, StaffName, Department, PracName
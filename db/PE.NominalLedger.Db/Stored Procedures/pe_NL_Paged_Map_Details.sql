CREATE PROCEDURE [dbo].[pe_NL_Paged_Map_Details]
	@startrow int,
	@endrow int
AS

WITH MapDetails AS 
(
	SELECT *, ROW_NUMBER() OVER (order by MapOrg, MapSource, MapSection, MapAccount) AS 'RowNumber' 
	FROM tblTranNominalMap
) 
SELECT P.*, OfficeName = CASE WHEN Coalesce(MapOffice,'') = '' THEN 'No Office' ELSE MapOffice END, 
			ServName = CASE WHEN Coalesce(MapServ,'') = '' THEN 'No Service' ELSE MapServ END, 
			PartName = CASE WHEN Coalesce(StaffIndex,0) = 0 THEN 'No Partner' ELSE StaffName END, 
			DeptName = CASE WHEN Coalesce(MapDept,'') = '' THEN 'No Department' ELSE MapDept END,
			PracName
FROM MapDetails P 
LEFT JOIN tblStaff S ON P.MapPart = S.StaffIndex 
INNER JOIN tblControl C ON P.MapOrg = C.PracID 
WHERE RowNumber between @startrow and @endrow
ORDER BY MapOrg, MapSource, MapSection, MapAccount;
CREATE PROCEDURE [dbo].[pe_NL_Map_Details]

AS

Select tblTranNominalMap.*, StaffName
FROM tblTranNominalMap LEFT OUTER JOIN tblStaff ON tblTranNominalMap.MapPart = tblStaff.StaffIndex
ORDER BY MapOrg, MapSource, MapSection, MapAccount
CREATE PROCEDURE [dbo].[pe_NL_Map_Count]
AS
Select Count(*) as rownum
FROM tblTranNominalMap LEFT OUTER JOIN tblStaff ON tblTranNominalMap.MapPart = tblStaff.StaffIndex
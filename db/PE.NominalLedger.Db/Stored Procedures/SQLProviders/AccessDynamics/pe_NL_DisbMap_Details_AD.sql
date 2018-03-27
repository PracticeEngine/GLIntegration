CREATE PROCEDURE [dbo].[pe_NL_DisbMap_Details_AD]

AS

SELECT Map.*, 'No Account Description' As AccDesc, 'No Mapping' As DisbDesc
FROM tblTranNominalDisbMap Map
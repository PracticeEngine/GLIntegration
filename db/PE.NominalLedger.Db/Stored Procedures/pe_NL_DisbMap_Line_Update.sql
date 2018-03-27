CREATE PROCEDURE [dbo].[pe_NL_DisbMap_Line_Update]

@MapIdx int,
@MapDisb varchar(10)

AS

Update tblTranNominalDisbMap
SET DisbCode = @MapDisb
WHERE DisbMapIndex = @MapIdx
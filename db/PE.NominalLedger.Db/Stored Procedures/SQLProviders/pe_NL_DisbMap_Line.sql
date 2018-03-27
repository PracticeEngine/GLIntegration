CREATE PROCEDURE [dbo].[pe_NL_DisbMap_Line]

@MapIdx int

AS

DECLARE @IntSys varchar(20)
DECLARE @Org int

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

SELECT @Org = NLOrg
FROM tblTranNominalDisbMap
WHERE DisbMapIndex = @MapIdx

IF @IntSys = 'AD'
	BEGIN
	EXEC pe_NL_DisbMap_Line_AD @Org, @MapIdx
	END

IF @IntSys = 'GP'
	BEGIN
	EXEC pe_NL_DisbMap_Line_GP @Org, @MapIdx
	END
CREATE PROCEDURE [dbo].[pe_NL_Map_Line]

@MapIdx int

AS

DECLARE @IntSys varchar(20)
DECLARE @Org int

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

SELECT @Org = MapOrg
FROM tblTranNominalMap
WHERE MapIndex = @MapIdx

IF @IntSys = 'AD'
	BEGIN
	EXEC pe_NL_Map_Line_AD @Org, @MapIdx
	END

IF @IntSys = 'GP'
	BEGIN
	EXEC pe_NL_Map_Line_GP @Org, @MapIdx
	END

IF @IntSys = 'SS'
	BEGIN
	EXEC pe_NL_Map_Line_SS @Org, @MapIdx
	END
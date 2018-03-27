CREATE PROCEDURE [dbo].[pe_NL_DisbMap_Details]

AS

DECLARE @IntSys varchar(20)

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

IF @IntSys = 'AD'
	BEGIN
	EXEC pe_NL_DisbMap_Details_AD
	END

IF @IntSys = 'GP'
	BEGIN
	EXEC pe_NL_DisbMap_Details_GP
	END
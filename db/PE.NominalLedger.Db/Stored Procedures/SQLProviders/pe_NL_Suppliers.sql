CREATE PROCEDURE [dbo].[pe_NL_Suppliers]

@Org int
AS

DECLARE @IntSys varchar(20)

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

IF @IntSys = 'AD'
	BEGIN
	EXEC pe_NL_Suppliers_AD @Org
	END

IF @IntSys = 'GP'
	BEGIN
	EXEC pe_NL_Suppliers_GP @Org
	END

IF @IntSys = 'SS'
	BEGIN
	EXEC pe_NL_Suppliers_SS @Org
	END
	
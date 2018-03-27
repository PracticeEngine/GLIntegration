CREATE PROCEDURE [dbo].[pe_NL_Account_Types]

@Org int

AS

DECLARE @IntSys varchar(20)

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

IF @IntSys = 'AD'
	BEGIN
	EXEC pe_NL_Account_Types_AD @Org
	END

IF @IntSys = 'GP'
	BEGIN
	EXEC pe_NL_Account_Types_GP @Org
	END
	
IF @IntSys = 'SS'
	BEGIN
	EXEC pe_NL_Account_Types_SS @Org
	END
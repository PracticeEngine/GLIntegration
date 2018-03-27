CREATE PROCEDURE [dbo].[pe_NL_Accounts]

@Org int,
@Type nvarchar(10)

AS

DECLARE @IntSys varchar(20)

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

IF @IntSys = 'AD'
	BEGIN
	EXEC pe_NL_Accounts_AD @Org, @Type
	END

IF @IntSys = 'GP'
	BEGIN
	EXEC pe_NL_Accounts_GP @Org, @Type
	END

IF @IntSys = 'SS'
	BEGIN
	EXEC pe_NL_Accounts_SS @Org, @Type
	END
	
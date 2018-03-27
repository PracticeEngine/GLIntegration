CREATE PROCEDURE [dbo].[pe_NL_Disbs]

@PeriodEnd datetime,
@UserCode varchar(10),
@Result as int OUTPUT

AS

DECLARE @IntSys varchar(20)

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

IF @IntSys = 'AD'
	BEGIN
	exec pe_NL_Disbs_AD @PeriodEnd, @UserCode,@Result OUTPUT
	END

IF @IntSys = 'GP'
	BEGIN
	exec pe_NL_Disbs_GP @PeriodEnd, @UserCode, @Result OUTPUT
	END
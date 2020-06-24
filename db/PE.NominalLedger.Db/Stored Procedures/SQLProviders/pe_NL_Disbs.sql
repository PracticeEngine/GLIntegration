CREATE PROCEDURE [dbo].[pe_NL_Disbs]

@Org int,
@User int,
@Result as int OUTPUT

AS
DECLARE @PeriodEnd datetime
DECLARE @IntSys varchar(20)

SELECT @PeriodEnd = PracPeriodEnd 
FROM tblControl
WHERE PracID = 1

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

IF @IntSys = 'AD'
	BEGIN
	exec pe_NL_Disbs_AD @Org, @PeriodEnd, @User, @Result OUTPUT
	END

IF @IntSys = 'GP'
	BEGIN
	exec pe_NL_Disbs_GP @Org, @PeriodEnd, @User, @Result OUTPUT
	END
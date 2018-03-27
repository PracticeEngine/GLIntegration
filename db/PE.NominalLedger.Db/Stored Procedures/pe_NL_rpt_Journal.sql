CREATE PROCEDURE [dbo].[pe_NL_rpt_Journal]

@Staff int

AS

DECLARE @IntSys varchar(20)

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

IF @IntSys = 'AD'
	BEGIN
	EXEC pe_NL_rpt_Journal_AD
	END

IF @IntSys = 'GP'
	BEGIN
	EXEC pe_NL_rpt_Journal_GP
	END

IF @IntSys = 'SS'
	BEGIN
	EXEC pe_NL_rpt_Journal_SS
	END
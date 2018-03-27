CREATE PROCEDURE [dbo].[pe_NL_rpt_Journal_VAT]

AS

DECLARE @IntSys varchar(20)

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

IF @IntSys = 'AD'
	BEGIN
	EXEC pe_NL_rpt_Journal_VAT_AD
	END

IF @IntSys = 'GP'
	BEGIN
	EXEC pe_NL_rpt_Journal_VAT_GP
	END
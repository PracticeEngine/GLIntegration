CREATE PROCEDURE [dbo].[pe_NL_Journal_Reprint_VAT]
	@Batch Int
AS

DECLARE @IntSys varchar(20)

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

IF @IntSys = 'AD'
	BEGIN
	EXEC pe_NL_Journal_Reprint_VAT_AD @Batch
	END

IF @IntSys = 'GP'
	BEGIN
	EXEC pe_NL_Journal_Reprint_VAT_GP @Batch
	END
CREATE PROCEDURE [dbo].[pe_NL_Journal_Reprint]

@Staff int,
@Batch int

AS

DECLARE @IntSys varchar(20)

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

IF @IntSys = 'AD'
	BEGIN
	exec pe_NL_Journal_Reprint_AD @Batch
	END

IF @IntSys = 'GP'
	BEGIN
	exec pe_NL_Journal_Reprint_GP @Batch
	END

IF @IntSys = 'SS'
	BEGIN
	exec pe_NL_Journal_Reprint_SS @Batch
	END
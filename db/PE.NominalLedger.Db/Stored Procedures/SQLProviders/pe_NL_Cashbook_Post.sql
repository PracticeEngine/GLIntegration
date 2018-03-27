CREATE PROCEDURE [dbo].[pe_NL_Cashbook_Post]

@BatchID int,
@Result int OUTPUT

AS

DECLARE @IntSys varchar(20)

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

IF @IntSys = 'AD'
	BEGIN
	exec pe_NL_Cashbook_Post_AD @BatchID, @Result output
	END

IF @IntSys = 'GP'
	BEGIN
	exec pe_NL_Cashbook_Post_GP @BatchID, @Result output
	END
CREATE PROCEDURE [dbo].[pe_NL_Map_Line_Update]

@MapIndex int,
@AccountCode varchar(30),
@AccountTypeCode varchar(10)

AS

Update tblTranNominalMap
SET MapTargetAcc = @AccountCode, MapTargetType = @AccountTypeCode
WHERE MapIndex = @MapIndex


EXEC pe_NL_Post_Create_AccNums
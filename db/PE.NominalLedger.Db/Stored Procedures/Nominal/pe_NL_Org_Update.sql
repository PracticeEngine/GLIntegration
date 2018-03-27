CREATE PROCEDURE [dbo].[pe_NL_Org_Update]

@PracID int,
@NLServer varchar(60),
@NLDatabase varchar(60),
@NLTransfer bit

AS

DECLARE @Count as int

SET @Count = (SELECT Count(*) FROM tblTranNominalOrgs WHERE PracID = @PracID)

IF @Count = 0
	BEGIN
	INSERT INTO tblTranNominalOrgs(PracID, NLServer, NLDatabase, NLTransfer)
	VALUES (@PracID, @NLServer, @NLDatabase, @NLTransfer)
	END

IF @Count > 0
	BEGIN
	UPDATE tblTranNominalOrgs
	SET NLServer = @NLServer, NLDatabase = @NLDatabase, NLTransfer = @NLTransfer
	WHERE PracID = @PracID
	END
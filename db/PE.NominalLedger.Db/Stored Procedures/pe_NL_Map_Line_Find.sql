CREATE PROCEDURE [dbo].[pe_NL_Map_Line_Find]

@OrgID int,
@Source varchar(10),
@Section varchar(10),
@Account varchar(10),
@Office varchar(10),
@Service varchar(10),
@Partner int,
@Department varchar(10)

AS

IF @Office = '~'
	SET @Office = ''

IF @Service = '~'
	SET @Service = ''

IF @Partner = -1
	SET @Partner = 0

IF @Department = '~'
	SET @Department = ''

SELECT MapIndex
FROM tblTranNominalMap
WHERE MapOrg = @OrgID AND MapSource = @Source AND MapSection = @Section AND MapAccount = @Account AND MapOffice = @Office AND MapServ = @Service AND MapPart = @Partner AND MapDept = @Department
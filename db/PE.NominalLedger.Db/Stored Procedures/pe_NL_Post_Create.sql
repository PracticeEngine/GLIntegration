/*
CREATED - AH - 2004



*/
CREATE PROCEDURE [dbo].[pe_NL_Post_Create]

@Period int

AS

DECLARE @WIPServ bit,
@WIPPart bit,
@WIPOffice bit,
@WIPDept bit,
@WIPDetail bit,
@DRSServ bit,
@DRSPart bit,
@DRSOffice bit,
@DRSDept bit,
@DRSDetail bit,
@InterCo bit,
@Cashbook bit,
@Expenses bit

DELETE
FROM tblTranNominalPost
WHERE NomPosted = 0

UPDATE tblTranNominal
SET NomIndex = 0
WHERE NomIndex = 1

UPDATE tblTranNominal
SET NLNarrative = ''
WHERE NLNarrative IS NULL

SELECT @WIPServ = WIPServ, @WIPPart = WIPPart, @WIPOffice = WIPOffice, @WIPDept = WIPDept, @WIPDetail = WIPLevel,
	@DRSServ = DRSServ, @DRSPart = DRSPart, @DRSOffice= DRSOffice, @DRSDept = DRSDept, @DRSDetail = DRSLevel,
	@InterCo = InterCo, @Cashbook = Cashbook, @Expenses = Expenses
FROM tblTranNominalControl

EXEC pe_NL_Post_Create_WIP @WIPOffice, @WIPServ, @WIPPart, @WIPDept, @WIPDetail, @Period

EXEC pe_NL_Post_Create_DRS @DRSOffice, @DRSServ, @DRSPart, @DRSDept, @DRSDetail, @Period

EXEC pe_NL_Post_Create_DRS_Fees @DRSOffice, @DRSServ, @DRSPart, @DRSDept, @DRSDetail, @Period

EXEC pe_NL_Post_Create_DRS_Other @DRSDetail, @Period

IF @Cashbook = 0
	EXEC pe_NL_Post_Create_LOD @DRSDetail, @Period

IF @InterCo = 1
	EXEC pe_NL_Post_Create_Int @WIPOffice, @WIPServ, @WIPPart, @WIPDept, @WIPDetail, @Period
	
IF @Expenses = 1
EXEC pe_NL_Post_Create_EXP @Period

UPDATE tblTranNominalPost
SET NomOffice = ''
WHERE NomOffice IS NULL

UPDATE tblTranNominalPost
SET NomService = ''
WHERE NomService IS NULL

UPDATE tblTranNominalPost
SET NomPartner = 0
WHERE NomPartner Is NULL

UPDATE tblTranNominalPost
SET NomDept = ''
WHERE NomDept Is NULL

DELETE
FROM tblTranNominalPost
WHERE NomAmount = 0 AND NomPosted = 0

DELETE N
FROM tblTranNominalPost N
INNER JOIN tblTranNominalOrgs O ON N.NomOrg = O.PracID
WHERE N.NomPosted = 0 AND N.NomPeriodIndex = @Period AND O.NLTransfer = 0

UPDATE tblTranNominal
SET NomIndex = 1
WHERE NomIndex = 0 AND NLPeriodIndex = @Period


EXEC pe_NL_Post_Create_AccNums
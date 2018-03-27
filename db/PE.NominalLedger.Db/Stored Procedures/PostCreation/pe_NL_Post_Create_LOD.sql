/*
CREATED - AH - 2004



*/
CREATE PROCEDURE [dbo].[pe_NL_Post_Create_LOD]

@LODDetail bit,
@LODPeriod int

AS

DECLARE @Cashbook bit

SELECT @Cashbook = Cashbook
FROM tblTranNominalControl

IF @Cashbook = 0
	BEGIN
	IF @LODDetail = 1
		BEGIN
		INSERT INTO tblTranNominalPost(NomPeriodIndex, NomDate, NomOrg, NomSource, NomSection, NomAccount, NomService, NomPartner, NomDept, NomAmount, NomPostAcc, NomTransRef, NomNarrative, NomMaxRef, NomPosted)
		SELECT NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, '', 0, '', Amount, '' AS PostAcc, TransRefAlpha, NLNarrative, NLIndex,0
		FROM tblTranNominal
		WHERE NLPosted = 0 AND NLSource = 'LOD' AND NLPeriodIndex = @LODPeriod
		END
	
	IF @LODDetail = 0
		BEGIN
		INSERT INTO tblTranNominalPost(NomPeriodIndex, NomDate, NomOrg, NomSource, NomSection, NomAccount, NomService, NomPartner, NomDept, NomAmount, NomPostAcc, NomTransRef, NomNarrative, NomMaxRef, NomPosted)
		SELECT NLPeriodIndex, Max(NLDate) AS MaxDate, NLOrg, NLSource, NLSection, NLAccount, '', 0, '', Sum(Amount) AS TotAmount, '' AS PostAcc, TransRefAlpha, NLSource + '/' + NLSection + '/' + NLAccount, Max(NLIndex),0
		FROM tblTranNominal
		WHERE NLPosted = 0 AND NLSource = 'LOD' AND NLPeriodIndex = @LODPeriod
		GROUP BY NLPeriodIndex, NLOrg, NLSource, NLSection, NLAccount, TransRefAlpha
		END
	END
ELSE
	BEGIN
	SELECT RefMin
	INTO #Ref
	FROM tblTranNominal
	WHERE NLSource = 'LOD' AND NLAccount LIKE 'SC%' AND NLPosted = 0 AND NLPeriodIndex = @LODPeriod

	INSERT INTO tblTranNominalPost(NomPeriodIndex, NomDate, NomOrg, NomSource, NomSection, NomAccount, NomService, NomPartner, NomDept, NomAmount, NomPostAcc, NomTransRef, NomNarrative, NomMaxRef, NomPosted)
	SELECT N.NLPeriodIndex, Max(N.NLDate) AS MaxDate, N.NLOrg, N.NLSource, N.NLSection, N.NLAccount, '', 0, '', Sum(N.Amount) AS TotAmount, '' AS PostAcc, N.TransRefAlpha, N.NLSource + '/' + N.NLSection + '/' + N.NLAccount, Max(N.NLIndex),0
	FROM tblTranNominal N 
	WHERE N.NLPosted = 0 AND N.NLSource = 'LOD' AND NLAccount LIKE 'SC%' AND N.NLPeriodIndex = @LODPeriod
--	GROUP BY Case When Amount > 0 Then 1 Else 0 End, N.NLPeriodIndex, N.NLOrg, N.NLSource, N.NLSection, N.NLAccount, N.TransRefAlpha
	GROUP BY N.NLPeriodIndex, N.NLOrg, N.NLSource, N.NLSection, N.NLAccount, N.TransRefAlpha
	END
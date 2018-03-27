CREATE PROCEDURE [dbo].[pe_NL_Post_Create_WIP_Other]

@WIPDetail bit,
@WIPPeriod int

AS


IF @WIPDetail = 1
	BEGIN
	INSERT INTO tblTranNominalPost(NomPeriodIndex, NomDate, NomOrg, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomAmount, NomPostAcc, NomNarrative, NomMaxRef, NomPosted)
	SELECT NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, Office, Service, 0, Department,  Amount, '' AS PostAcc, 'Ref:' + TransRefAlpha + '/Client:' + ClientName + '/' + NLNarrative, NLIndex,0
	FROM tblTranNominal  INNER JOIN tblTranNominalOrgs ON  tblTranNominal.NLOrg = tblTranNominalOrgs.PracID LEFT OUTER JOIN tblEngagement ON tblTranNominal.ContIndex = tblEngagement.ContIndex
	WHERE NLPosted = 0 AND NLSource = 'WIP' AND NLAccount IN ('WIPBIL','WIP') AND NLPeriodIndex = @WIPPeriod AND NLTransfer = 1
	END

IF @WIPDetail = 0
	BEGIN
	INSERT INTO tblTranNominalPost(NomPeriodIndex, NomDate, NomOrg, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomAmount, NomPostAcc, NomNarrative, NomMaxRef, NomPosted)
	SELECT NLPeriodIndex, Max(NLDate) AS MaxDate, NLOrg, NLSource, NLSection, NLAccount, '', '', 0, '', Sum(Amount) AS TotAmount, '' AS PostAcc, NLSource + '/' + NLSection + '/' + NLAccount, Max(NLIndex),0
	FROM tblTranNominal INNER JOIN tblTranNominalOrgs ON  tblTranNominal.NLOrg = tblTranNominalOrgs.PracID
	WHERE NLPosted = 0 AND NLSource = 'WIP' AND NLAccount IN ('WIPBIL','WIP') AND NLPeriodIndex = @WIPPeriod AND NLTransfer = 1
	GROUP BY NLPeriodIndex, NLOrg, NLSource, NLSection, NLAccount
	END
CREATE PROCEDURE [dbo].[pe_NL_Post_Create_DRS_Other]

@DRSDetail bit,
@DRSPeriod int

AS

IF @DRSDetail = 1
	BEGIN
	INSERT INTO tblTranNominalPost(NomPeriodIndex, NomDate, NomOrg, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomAmount, NomPostAcc, NomNarrative, NomMaxRef, NomPosted)
	SELECT NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, '', '', 0, '',  Amount, 0 AS PostAcc, 'Ref:' + TransRefAlpha + '/Client:' + ClientName + '/' + NLNarrative, NLIndex,0
	FROM tblTranNominal LEFT OUTER JOIN tblEngagement ON tblTranNominal.ContIndex = tblEngagement.ContIndex
	WHERE NLPosted = 0 AND NLSource = 'DRS' AND NLAccount NOT IN ('FEES-T','FEES-D','FEEP-T','FEEP-D','DRCON','DRSUS','BANK','CHQCL','BADDR','DISC','DRTRF','VATDUE','VATOUT','VATSUS') AND NLPeriodIndex = @DRSPeriod
	END

IF @DRSDetail = 0
	BEGIN
	INSERT INTO tblTranNominalPost(NomPeriodIndex, NomDate, NomOrg, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomAmount, NomPostAcc, NomNarrative, NomMaxRef, NomPosted)
	SELECT NLPeriodIndex, Max(NLDate) AS MaxDate, NLOrg, NLSource, NLSection, NLAccount, Office, '', 0, '', Sum(Amount) AS TotAmount, '' AS PostAcc, NLSource + '/' + NLSection + '/' + NLAccount + '/' + Office + '/' + Service + '/' + Department, Max(NLIndex),0
	FROM tblTranNominal
	WHERE NLPosted = 0 AND NLSource = 'DRS' AND NLAccount NOT IN ('FEES-T','FEES-D','FEEP-T','FEEP-D','DRCON','DRSUS','BANK','CHQCL','BADDR','DISC','DRTRF','VATDUE','VATOUT','VATSUS') AND NLPeriodIndex = @DRSPeriod
--	GROUP BY Case When Amount > 0 Then 1 Else 0 End, NLPeriodIndex, NLOrg, NLSource, NLSection, NLAccount, Office, Service, Department
	GROUP BY NLPeriodIndex, NLOrg, NLSource, NLSection, NLAccount, Office, Service, Department
	END
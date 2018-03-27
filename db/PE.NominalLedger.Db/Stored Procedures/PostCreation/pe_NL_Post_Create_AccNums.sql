CREATE PROCEDURE [dbo].[pe_NL_Post_Create_AccNums]

AS

	UPDATE tblTranNominalPost
	SET NomPostAcc = MapTargetAcc
	FROM tblTranNominalPost AS P INNER JOIN tblTranNominalMap AS M ON P.NomOrg = M.MapOrg AND P.NomSource = M.MapSource AND P.NomSection = M.MapSection
		 AND P.NomAccount = M.MapAccount AND P.NomOffice = M.MapOffice AND P.NomService = M.MapServ AND P.NomPartner = M.MapPart AND P.NomDept = M.MapDept
	WHERE P.NomPosted = 0
	
	
	UPDATE tblTranNominalPost
	SET NomDRSAcc = MapTargetAcc
	FROM tblTranNominalPost AS P INNER JOIN tblTranNominalMap AS M ON P.NomOrg = M.MapOrg AND P.NomSource = M.MapSource AND 'BS' = M.MapSection
		 AND P.NomDRSCode = M.MapAccount AND P.NomOffice = M.MapOffice AND P.NomService = M.MapServ AND P.NomPartner = M.MapPart AND P.NomDept = M.MapDept
	WHERE P.NomPosted = 0
	
	
	UPDATE tblTranNominalPost
	SET NomVATAcc = MapTargetAcc
	FROM tblTranNominalPost AS P INNER JOIN tblTranNominalMap AS M ON P.NomOrg = M.MapOrg AND P.NomSource = M.MapSource AND 'BS' = M.MapSection
		 AND P.NomVATCode = M.MapAccount AND P.NomOffice = M.MapOffice AND P.NomService = M.MapServ AND P.NomPartner = M.MapPart AND P.NomDept = M.MapDept
	WHERE P.NomPosted = 0
	
	
	UPDATE tblTranNominalPost
	SET NomDRSAcc = MapTargetAcc
	FROM tblTranNominalPost AS P INNER JOIN tblTranNominalMap AS M ON P.NomOrg = M.MapOrg AND P.NomSource = M.MapSource AND 'PL' = M.MapSection
		 AND P.NomDRSCode = M.MapAccount AND P.NomOffice = M.MapOffice AND P.NomService = M.MapServ AND P.NomPartner = M.MapPart AND P.NomDept = M.MapDept
	WHERE P.NomPosted = 0 AND NomDRSAcc = '' AND NomJnlType = 'VJL'
	
	
	UPDATE tblTranNominalPost
	SET NomVATAcc = MapTargetAcc
	FROM tblTranNominalPost AS P INNER JOIN tblTranNominalMap AS M ON P.NomOrg = M.MapOrg AND P.NomSource = M.MapSource AND 'PL' = M.MapSection
		 AND P.NomVATCode = M.MapAccount AND P.NomOffice = M.MapOffice AND P.NomService = M.MapServ AND P.NomPartner = M.MapPart AND P.NomDept = M.MapDept
	WHERE P.NomPosted = 0 AND NomVATAcc = '' AND NomJnlType = 'VJL'
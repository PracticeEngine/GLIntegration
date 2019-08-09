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

	
	DECLARE 	csr_Org CURSOR DYNAMIC		
	FOR SELECT 	Orgs.PracID, Orgs.NLServer, Orgs.NLDatabase
	FROM 		tblTranNominalOrgs Orgs 
	WHERE		Orgs.NLTransfer = 1
	
	Declare @Org int,
		@Server varchar(50),
		@DB varchar(50),
		@SQL varchar(8000)

	OPEN csr_Org
	FETCH 	csr_Org INTO @Org, @Server, @DB
	WHILE (@@FETCH_STATUS=0) 
		BEGIN		
		SET @SQL = 'UPDATE P SET P.VendorCode = A.VendorCode
		FROM tblTranNominalPostExpenses P
		INNER JOIN (SELECT CAST(Mast.SUUSER3 as int) As VendorIndex, LTRIM(RTRIM(Mast.SUCODE)) As VendorCode
		FROM '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'

		SET @SQL = @SQL + @DB + '.dbo.PL_ACCOUNTS Mast
		WHERE Mast.SUUSED = 1 AND IsNumeric(Mast.SUUSER3) = 1) A ON P.VendorIndex = A.VendorIndex
		WHERE P.Posted = 0 AND P.ExpOrg = ' + LTRIM(RTRIM(STR(@Org)))

		PRINT @SQL

		EXEC(@SQL)

		FETCH csr_Org INTO @Org, @Server, @DB
		END

	CLOSE csr_Org
	DEALLOCATE csr_Org

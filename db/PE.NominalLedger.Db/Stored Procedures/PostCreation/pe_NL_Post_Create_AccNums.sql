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
		
	UPDATE P
	SET PostAcc = M.ChargeExpAccount + CASE M.ChargeSuffix1 WHEN 1 THEN Coalesce(PM.CostCenter, '') WHEN 2 THEN Coalesce(DM.CostCenter, '') WHEN 3 THEN Coalesce(SDM.CostCenter, '') ELSE '' END + CASE M.ChargeSuffix2 WHEN 1 THEN Coalesce(PM.CostCenter, '') WHEN 2 THEN Coalesce(DM.CostCenter, '') WHEN 3 THEN Coalesce(SDM.CostCenter, '') ELSE '' END + CASE M.ChargeSuffix3 WHEN 1 THEN Coalesce(PM.CostCenter, '') WHEN 2 THEN Coalesce(DM.CostCenter, '') WHEN 3 THEN Coalesce(SDM.CostCenter, '') ELSE '' END
	FROM tblTranNominalPostExpenses P 
	INNER JOIN tblTranNominalExpMap M ON P.ExpOrg = M.ExpOrg AND P.DisbCode = M.DisbCode
	INNER JOIN tblStaff S ON P.VendorIndex = S.StaffIndex
	INNER JOIN tblStaffEx SX ON S.StaffIndex = SX.StaffIndex
	INNER JOIN tblTranNominalPartMap PM ON S.StaffIndex = PM.StaffIndex
	INNER JOIN tblTranNominalDeptMap DM ON S.StaffDepartment = DM.DeptIdx
	INNER JOIN tblTranNominalSubDeptMap SDM ON SX.StaffSubDepartment = SDM.SubDept
	WHERE P.Posted = 0 AND P.PostAcc = '' AND P.Chargeable = 1
		
	UPDATE P
	SET PostAcc = M.NonChargeExpAccount + CASE M.NonChargeSuffix1 WHEN 1 THEN Coalesce(PM.CostCenter, '') WHEN 2 THEN Coalesce(DM.CostCenter, '') WHEN 3 THEN Coalesce(SDM.CostCenter, '') ELSE '' END + CASE M.NonChargeSuffix2 WHEN 1 THEN Coalesce(PM.CostCenter, '') WHEN 2 THEN Coalesce(DM.CostCenter, '') WHEN 3 THEN Coalesce(SDM.CostCenter, '') ELSE '' END + CASE M.NonChargeSuffix3 WHEN 1 THEN Coalesce(PM.CostCenter, '') WHEN 2 THEN Coalesce(DM.CostCenter, '') WHEN 3 THEN Coalesce(SDM.CostCenter, '') ELSE '' END
	FROM tblTranNominalPostExpenses P 
	INNER JOIN tblTranNominalExpMap M ON P.ExpOrg = M.ExpOrg AND P.DisbCode = M.DisbCode
	INNER JOIN tblStaff S ON P.VendorIndex = S.StaffIndex
	INNER JOIN tblStaffEx SX ON S.StaffIndex = SX.StaffIndex
	INNER JOIN tblTranNominalPartMap PM ON S.StaffIndex = PM.StaffIndex
	INNER JOIN tblTranNominalDeptMap DM ON S.StaffDepartment = DM.DeptIdx
	INNER JOIN tblTranNominalSubDeptMap SDM ON SX.StaffSubDepartment = SDM.SubDept
	WHERE P.Posted = 0 AND P.PostAcc = '' AND P.Chargeable = 0

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
		INNER JOIN tblStaff S ON P.VendorIndex = S.StaffIndex
		INNER JOIN (SELECT CAST(Mast.SUUSER3 as int) As VendorIndex, LTRIM(RTRIM(Mast.SUCODE)) As VendorCode
		FROM '
		IF @Server <> ''
			SET @SQL = @SQL + @Server + '.'

		SET @SQL = @SQL + @DB + '.dbo.PL_ACCOUNTS Mast
		WHERE Mast.SUUSED = 1 AND IsNumeric(Mast.SUUSER3) = 1) A ON S.StaffReference = A.VendorIndex
		WHERE P.Posted = 0 AND P.ExpOrg = ' + LTRIM(RTRIM(STR(@Org)))

		PRINT @SQL

		EXEC(@SQL)

		FETCH csr_Org INTO @Org, @Server, @DB
		END

	CLOSE csr_Org
	DEALLOCATE csr_Org
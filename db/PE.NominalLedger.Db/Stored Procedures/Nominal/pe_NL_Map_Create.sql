CREATE PROCEDURE [dbo].[pe_NL_Map_Create]

AS

DECLARE @WIPServ bit,
@WIPPart bit,
@WIPOffice bit,
@WIPDept bit,
@DRSServ bit,
@DRSPart bit,
@DRSOffice bit,
@DRSDept bit

SET @WIPServ = (SELECT WIPServ FROM tblTranNominalControl)
SET @WIPPart = (SELECT WIPPart FROM tblTranNominalControl)
SET @WIPOffice = (SELECT WIPOffice FROM tblTranNominalControl)
SET @WIPDept = (SELECT WIPDept FROM tblTranNominalControl)

SET @DRSServ = (SELECT DRSServ FROM tblTranNominalControl)
SET @DRSPart = (SELECT DRSPart FROM tblTranNominalControl)
SET @DRSOffice = (SELECT DRSOffice FROM tblTranNominalControl)
SET @DRSDept = (SELECT DRSDept FROM tblTranNominalControl)

EXEC pe_NL_Map_Clear

DECLARE @SQL varchar(8000)

SET @SQL = 'INSERT INTO tblTranNominalMap (MapOrg, MapSource, MapSection, MapAccount, MapOffice, MapServ, MapPart, MapDept, MapTargetAcc) 
SELECT tblControl.PracID, Source, Section, Account, '

IF @WIPOffice = 1
	SET @SQL = @SQL + 'OfficeCode, '
ELSE
	SET @SQL = @SQL + CHAR(39) + CHAR(39) + ', '

IF @WIPServ = 1
	SET @SQL = @SQL + 'ServIndex, '
ELSE
	SET @SQL = @SQL + CHAR(39) + CHAR(39) + ', '

IF @WIPPart = 1
	SET @SQL = @SQL + 'StaffIndex, '
ELSE
	SET @SQL = @SQL + '0, '

IF @WIPDept = 1
	SET @SQL = @SQL + 'DeptIdx, '
ELSE
	SET @SQL = @SQL + CHAR(39) + CHAR(39) + ', '

SET @SQL = @SQL + CHAR(39) + CHAR(39) 

SET @SQL = @SQL + '
FROM tblControl, tblTranNominalStd'

IF @WIPOffice = 1
	SET @SQL = @SQL + ', tblOffices'

IF @WIPServ = 1
	SET @SQL = @SQL + ', tblServices'

IF @WIPPart = 1
	SET @SQL = @SQL + ', tblStaff'

IF @WIPDept = 1
	SET @SQL = @SQL + ', tblDepartment'

SET @SQL = @SQL + '
WHERE Source=' + CHAR(39) + 'WIP' + CHAR(39)

IF @WIPPart = 1
	SET @SQL = @SQL + ' AND tblStaff.StaffClientResponsible = 1'

PRINT @SQL

EXEC (@SQL)

SET @SQL = 'INSERT INTO tblTranNominalMap (MapOrg, MapSource, MapSection, MapAccount, MapOffice, MapServ, MapPart, MapDept, MapTargetAcc) 
SELECT tblControl.PracID, Source, Section, Account, '

IF @DRSOffice = 1
	SET @SQL = @SQL + 'OfficeCode, '
ELSE
	SET @SQL = @SQL + CHAR(39) + CHAR(39) + ', '

IF @DRSServ = 1
	SET @SQL = @SQL + 'ServIndex, '
ELSE
	SET @SQL = @SQL + CHAR(39) + CHAR(39) + ', '

IF @DRSPart = 1
	SET @SQL = @SQL + 'StaffIndex, '
ELSE
	SET @SQL = @SQL + '0, '

IF @DRSDept = 1
	SET @SQL = @SQL + 'DeptIdx, '
ELSE
	SET @SQL = @SQL + CHAR(39) + CHAR(39) + ', '

SET @SQL = @SQL + CHAR(39) + CHAR(39) 

SET @SQL = @SQL + '
FROM tblControl, tblTranNominalStd'

IF @DRSOffice = 1
	SET @SQL = @SQL + ', tblOffices'

IF @DRSServ = 1
	SET @SQL = @SQL + ', tblServices'

IF @DRSPart = 1
	SET @SQL = @SQL + ', tblStaff'

IF @DRSDept = 1
	SET @SQL = @SQL + ', tblDepartment'

SET @SQL = @SQL + '
WHERE Source=' + CHAR(39) + 'DRS' + CHAR(39) 

IF @DRSPart = 1
	SET @SQL = @SQL + ' AND tblStaff.StaffClientResponsible = 1'

PRINT @SQL

EXEC (@SQL)

   
INSERT INTO tblTranNominalMap (MapOrg, MapSource, MapSection, MapAccount, MapOffice, MapServ, MapPart, MapDept, MapTargetAcc) 
SELECT PracID, 'DRS', 'BS', 'VATOUT', '', '', 0, '', '' 
FROM tblControl

INSERT INTO tblTranNominalMap (MapOrg, MapSource, MapSection, MapAccount, MapOffice, MapServ, MapPart, MapDept, MapTargetAcc) 
SELECT PracID, 'DRS', 'BS', 'BNKCON', '', '', 0, '', '' 
FROM tblControl

INSERT INTO tblTranNominalMap (MapOrg, MapSource, MapSection, MapAccount, MapOffice, MapServ, MapPart, MapDept, MapTargetAcc) 
SELECT PracID, 'LOD', 'BS', 'BNKCON', '', '', 0, '', '' 
FROM tblControl

INSERT INTO tblTranNominalMap (MapOrg, MapSource, MapSection, MapAccount, MapOffice, MapServ, MapPart, MapDept, MapTargetAcc) 
SELECT tblControl.PracID, 'LOD', 'BS', 'BANK' + Cast(BankIndex as varchar(2)), '', '', 0, '', '' 
FROM tblControl, tblTranBank

INSERT INTO tblTranNominalMap (MapOrg, MapSource, MapSection, MapAccount, MapOffice, MapServ, MapPart, MapDept, MapTargetAcc) 
SELECT tblControl.PracID, 'LOD', 'BS', 'SUND' + Cast(BankIndex as varchar(2)), '', '', 0, '', '' 
FROM tblControl, tblTranBank
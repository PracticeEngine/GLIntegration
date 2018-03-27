CREATE PROCEDURE [dbo].[pe_NL_Journal_Lines]

@OrgID int,
@Source varchar(10),
@Section varchar(10),
@Account varchar(10),
@Office varchar(10) = null,
@Service varchar(10) = null,
@Partner int = null,
@Department varchar(10) = null

AS

DECLARE @NumBlank int
DECLARE @Server varchar(50)
DECLARE @DB varchar(50)
DECLARE @IntSys varchar(20)

SELECT @IntSys = IntSystem
FROM tblTranNominalControl

SELECT @Server = NLServer, @DB = NLDatabase
FROM tblTranNominalOrgs
WHERE PracID = @OrgID

DECLARE @SQL varchar(8000)

SELECT @NumBlank = Count(NomIndex) FROM tblTranNominalPost P INNER JOIN tblTranNominalOrgs O ON P.NomOrg = O.PracID WHERE NomPostAcc = '' AND NLTransfer = 1

CREATE TABLE #Lines([NomIndex] int, [NomPeriodIndex] int, [NomDate] DATETIME, [NomOrg] TINYINT, [NomSource] nvarchar (10), [NomSection] nvarchar (10), [NomAccount] nvarchar (10),
					[NomOffice] nvarchar (10), [NomService] nvarchar (10), [NomPartner] INT, [NomDept] nvarchar (10), [NomAmount] MONEY, [NomVATAmount] MONEY, [NomPostAcc] nvarchar (20),
				    [NomVATAcc] nvarchar (20), [NomDRSAcc] nvarchar (20), [NomTransRef] nvarchar (255), [NomNarrative] nvarchar (255), [NomMaxRef] INT, [NomJnlType] nvarchar (10), 
				    [NomDRSCode] nvarchar (10), [NomVATCode] nvarchar (10), [NomVATRateCode] nvarchar (3), [NomPosted] BIT, [NomBatch] INT, [NomPostDate] DATETIME, [Job_Dept] nvarchar(10),
					[Staff_Dept] nvarchar(10), [ClientCode]	nvarchar(10), [StaffCode] nvarchar(10), [Currency] nvarchar(3), [ForeignAmount] MONEY, AccountCode nvarchar(20), 
					[OfficeName] nvarchar(255) collate database_default, [ServiceName] nvarchar(255) collate database_default, [PartnerName] nvarchar(255) collate database_default, 
					[DepartmentName] nvarchar(255) collate database_default, [OrgName] nvarchar(100) collate database_default, NumBlank int, MapIndex int, AccountTypeCode nvarchar(20) collate database_default)

SET @SQL = 'INSERT INTO #Lines(NomIndex, NomPeriodIndex, NomDate, NomOrg, NomSource, NomSection, NomAccount, NomOffice, NomService, NomPartner, NomDept, NomAmount, NomVATAmount, NomPostAcc,
					NomVATAcc, NomDRSAcc, NomTransRef, NomNarrative, NomMaxRef, NomJnlType, NomDRSCode, NomVATCode, NomVATRateCode, NomPosted, NomBatch, NomPostDate, Job_Dept,
					Staff_Dept, ClientCode, StaffCode, Currency, ForeignAmount, AccountCode, OfficeName, ServiceName, PartnerName, DepartmentName, OrgName, NumBlank, MapIndex, AccountTypeCode)
'
SET @SQL = @SQL + 'SELECT P.NomIndex, P.NomPeriodIndex, P.NomDate, P.NomOrg, P.NomSource, P.NomSection, P.NomAccount, P.NomOffice, P.NomService, P.NomPartner, P.NomDept, P.NomAmount, P.NomVATAmount, P.NomPostAcc,
				P.NomVATAcc, P.NomDRSAcc, P.NomTransRef, P.NomNarrative, P.NomMaxRef, P.NomJnlType, P.NomDRSCode, P.NomVATCode, P.NomVATRateCode, P.NomPosted, P.NomBatch, P.NomPostDate, P.Job_Dept,
				P.Staff_Dept, P.ClientCode, P.StaffCode, P.Currency, P.ForeignAmount, P.NomPostAcc AS AccountCode, CASE WHEN NomOffice = '''' THEN ''No Office'' ELSE NomOffice END,
				CASE WHEN NomService = '''' THEN ''No Service'' ELSE NomService END, CASE WHEN StaffIndex = 0 THEN ''No Partner'' ELSE S.StaffName END, CASE WHEN NomDept = '''' THEN ''No Department'' ELSE NomDept END, C.PracName, 
				' + LTrim(Str(@NumBlank)) + ' As NumBlank, 0, ''''
FROM tblTranNominalPost P 
INNER JOIN tblControl C ON P.NomOrg = C.PracId 
LEFT OUTER JOIN tblStaff S ON P.NomPartner = S.StaffIndex '

SET @SQL = @SQL + '
WHERE NomOrg = ' + LTrim(Str(@OrgID)) + ' AND NomSource = ' + CHAR(39) + @Source + CHAR(39) + ' AND NomSection = ' + CHAR(39) + @Section + CHAR(39)  + ' AND NomAccount = ' + CHAR(39) + @Account + CHAR(39) + ' AND NomPosted = 0 '

IF @Office IS NOT NULL
	SET @SQL = @SQL + 'AND NomOffice = ' + CHAR(39) + @Office + CHAR(39) + ' '
	
IF @Service IS NOT NULL
	SET @SQL = @SQL + 'AND NomService = ' + CHAR(39) + @Service + CHAR(39) + ' '

IF @Department IS NOT NULL
	SET @SQL = @SQL + 'AND NomDept = ' + CHAR(39) + @Department + CHAR(39) + ' '
	
IF @Partner IS NOT NULL
	SET @SQL = @SQL + 'AND NomPartner = ' + LTrim(Str(@Partner))

PRINT @SQL

EXEC (@SQL)

INSERT INTO tblTranNominalMap(MapOrg, MapSource, MapSection, MapAccount, MapOffice, MapServ, MapPart, MapDept, MapTargetAcc, MapTargetType)
SELECT T.NomOrg, T.NomSource, T.NomSection, T.NomAccount, T.NomOffice, T.NomService, T.NomPartner, T.NomDept, '', ''
FROM #Lines T
LEFT JOIN tblTranNominalMap M ON T.NomOrg = M.MapOrg AND T.NomSource = M.MapSource AND T.NomSection = M.MapSection AND T.NomAccount = M.MapAccount AND T.NomOffice = M.MapOffice AND T.NomPartner = M.MapPart AND T.NomService = M.MapServ AND T.NomDept = M.MapDept
WHERE M.MapIndex IS NULL

UPDATE T
SET T.MapIndex = M.MapIndex, T.AccountCode = M.MapTargetAcc, T.AccountTypeCode = M.MapTargetType
FROM #Lines T
INNER JOIN tblTranNominalMap M ON T.NomOrg = M.MapOrg AND T.NomSource = M.MapSource AND T.NomSection = M.MapSection AND T.NomAccount = M.MapAccount AND T.NomOffice = M.MapOffice AND T.NomPartner = M.MapPart AND T.NomService = M.MapServ AND T.NomDept = M.MapDept

SELECT *
FROM #Lines
ORDER BY NomOrg, NomSource, NomSection, NomAccount, NomDate

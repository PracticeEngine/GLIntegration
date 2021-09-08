CREATE PROCEDURE [dbo].[pe_NL_MTD_Extract]

AS

DECLARE @MinRowVer binary(8)
DECLARE @MaxRowVer binary(8)

SELECT @MinRowVer = MaxRowVer FROM tblTranNominalMTDControl WHERE Id = 1
SET @MaxRowVer = MIN_ACTIVE_ROWVERSION()

INSERT INTO tblTranNominalMTD(DebtTranIndex, Processed, RowVer)
SELECT D.DebtTranIndex, CAST(0 as bit), D.RowVer 
FROM tblTranDebtor D 
INNER JOIN tblTranNominalOrgs O ON D.PracID = O.PracID
LEFT OUTER JOIN tblTranNominalMTD M ON D.DebtTranIndex = M.DebtTranIndex
WHERE D.DebtTranType IN (3,4,6,14,26) AND D.RowVer BETWEEN @MinRowVer AND @MaxRowVer AND M.DebtTranIndex IS NULL AND O.NLTransfer = 1

UPDATE tblTranNominalMTDControl
SET LastExtract = GETDATE(), MaxRowVer = @MaxRowVer
WHERE Id = 1

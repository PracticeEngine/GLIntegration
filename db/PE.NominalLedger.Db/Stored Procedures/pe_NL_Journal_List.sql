CREATE PROCEDURE [dbo].[pe_NL_Journal_List]

@Period int

AS

SELECT NomBatch, Count(*) As NumLines, Sum(CASE WHEN NomAmount > 0 THEN NomAmount ELSE 0 END) As Debits, Sum(CASE WHEN NomAmount < 0 THEN NomAmount ELSE 0 END) As Credits, Max(NomPostDate) As PostDate
FROM tblTranNominalPost
WHERE NomPeriodIndex = @Period
GROUP BY NomBatch
ORDER BY tblTranNominalPost.NomBatch
CREATE PROCEDURE [dbo].[pe_NL_Num_Entries]

AS

Select Count(NLIndex) AS NumEntries
FROM tblTranNominal
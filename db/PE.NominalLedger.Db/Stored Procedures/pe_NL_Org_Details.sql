CREATE PROCEDURE [dbo].[pe_NL_Org_Details]

@PracID int

AS

SELECT C.PracID, C.PracName, Coalesce(O.NLServer, '') As NLServer, Coalesce(O.NLDatabase, '') As NLDatabase, Coalesce(O.NLTransfer, 0) As NLTransfer
FROM tblControl C LEFT OUTER JOIN tblTranNominalOrgs O ON O.PracID = C.PracID
WHERE C.PracID = @PracID
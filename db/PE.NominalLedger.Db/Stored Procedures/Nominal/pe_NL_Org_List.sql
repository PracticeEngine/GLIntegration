CREATE PROCEDURE [dbo].[pe_NL_Org_List]

AS

SELECT C.PracID, 
              C.PracName, 
              Coalesce(O.NLServer, '') As NLServer, 
              Coalesce(O.NLDatabase, '') As NLDatabase, 
              Coalesce(O.NLTransfer, Cast(0 as bit)) As NLTransfer
FROM tblControl C 
LEFT OUTER JOIN tblTranNominalOrgs O ON O.PracID = C.PracID

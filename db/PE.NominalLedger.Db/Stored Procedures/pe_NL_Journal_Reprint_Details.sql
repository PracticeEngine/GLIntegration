CREATE PROCEDURE [dbo].[pe_NL_Journal_Reprint_Details]

@Staff int,
@Batch int,
@Org int,
@Source varchar(10)

AS

SELECT N.*, E.ClientCode, E.ClientName, Coalesce(O.OfficeName, 'No Office') As OfficeName, Coalesce(D.DeptName, 'No Dept') As DeptName, C.PracName, T.TransTypeDescription
FROM tblTranNominal N INNER JOIN 
	tblEngagement E ON N.ContIndex = E.ContIndex INNER JOIN
	tblTranTypes T ON N.TransTypeIndex = T.TransTypeIndex INNER JOIN
	tblControl C ON N.NLOrg = C.PracID LEFT OUTER JOIN
	tblOffices O ON N.Service = O.OfficeCode LEFT OUTER JOIN
	tblDepartment D ON N.Department = D.DeptIdx
WHERE NomBatch = @Batch and NLOrg = @Org and NLSource = @Source
ORDER BY C.PracName, Coalesce(O.OfficeName, 'No Office'), Coalesce(D.DeptName, 'No Dept'), N.NLSource, N.NLSection, N.NLAccount, N.NLDate
CREATE PROCEDURE [dbo].[pe_NL_Intacct_Project]
AS
	SELECT 
       E.[ClientOrganisation] AS [Org],
       '~' + Left(LTrim(RTrim(E.[ClientCode])), 9) AS PROJECTID,
       LTrim(RTrim(Replace(Replace(Replace(Replace(E.[ClientName], '&', '+'), '<', '-'), '>', '-'), '''', '\'''))) AS PROJECTNAME,
       LTrim(RTrim(E.[ClientCode])) AS CUSTOMERID,
       'Contract' AS PROJECTCATEGORY,
       'Active' AS PROJECTSTATUS,
       'active' AS PROJECTACTIVE,
       Case When Coalesce(E.[ClientDepartment], 'UNKNOWN') = 'UNKNOWN' Then '' Else E.[ClientDepartment] End AS DEPARTMENTID,
       Case When Coalesce(E.[ClientOffice], 'UNKNOWN') = 'UNKNOWN' Then '1' Else E.[ClientOffice] End AS LOCATIONID,
       LTrim(RTrim(E.[ClientCode])) AS PROJECTPARENTID,
       LTrim(RTrim(E.[ClientCode])) AS [PE_JOB_CODE]
       FROM [dbo].[tblJob_Header] J
       INNER JOIN [dbo].[tblEngagement] E ON J.[ContIndex] = E.[ContIndex]
       WHERE E.[ContIndex] < 900000 AND E.[ContIndex] > 0 AND J.[Job_Type] < 255
       GROUP BY E.[ClientOrganisation], E.[ClientCode], E.[ClientName],
       Case When Coalesce(E.[ClientDepartment], 'UNKNOWN') = 'UNKNOWN' Then '' Else E.[ClientDepartment] End,
       Case When Coalesce(E.[ClientOffice], 'UNKNOWN') = 'UNKNOWN' Then '1' Else E.[ClientOffice] End
       
       UNION ALL

       SELECT 
       E.[ClientOrganisation] AS [Org],
       Cast(J.[Job_Idx] AS nVarChar(10)) AS PROJECTID,
       LTrim(RTrim(Replace(Replace(Replace(Replace(J.[Job_Name], '&', '+'), '<', '-'), '>', '-'), '''', '\'''))) AS PROJECTNAME,
       LTrim(RTrim(E.[ClientCode])) AS CUSTOMERID,
       'Contract' AS PROJECTCATEGORY,
       CASE 
             WHEN J.[Job_Status] = 0 THEN 'Active'
             WHEN J.[Job_Status] = 1 THEN 'In Progress'
             WHEN J.[Job_Status] > 90 THEN 'On Hold'
             WHEN J.[Job_Status] IN (2,3) THEN 'Complete'
       END AS PROJECTSTATUS,
       CASE WHEN J.[Job_Status] < 3 THEN 'active'
             ELSE 'inactive'
       END AS PROJECTACTIVE,
       Case When Coalesce(J.[Job_Dept], 'UNKNOWN') = 'UNKNOWN' Then '' Else J.[Job_Dept] End AS DEPARTMENTID,
       Case When Coalesce(J.[Job_Office], 'UNKNOWN') = 'UNKNOWN' Then '1' Else J.[Job_Office] End AS LOCATIONID,
       '~' + Left(LTrim(RTrim(E.[ClientCode])), 9) AS PROJECTPARENTID,
       J.[Job_Code] AS [PE_JOB_CODE]
       FROM [dbo].[tblJob_Header] J
       INNER JOIN [dbo].[tblEngagement] E ON J.[ContIndex] = E.[ContIndex]
       WHERE E.[ContIndex] < 900000 AND E.[ContIndex] > 0 AND J.[Job_Type] < 255


RETURN 0

CREATE PROCEDURE [dbo].[pe_NL_Intacct_Employee]
AS
	               SELECT 
               S.[StaffOrganisation] AS [Org],
               S.[StaffIndex] AS EMPLOYEEID,
               LTrim(RTrim(S.[StaffName])) +
                              Case When Row_Number() Over (Partition By StaffName Order By StaffIndex) > 1
                              Then '_' + Cast(Row_Number() Over (Partition By StaffName Order By StaffIndex) AS nVarChar(10))
                              Else '' End            AS EMPLOYEENAME,
               S.[StaffStarted] AS EMPLOYEESTART,
               S.[StaffEnded] AS EMPLOYEETERMINATION,
               CASE WHEN S.[StaffEnded] IS NULL OR S.[StaffEnded] > GETDATE() THEN 'active'
                              ELSE 'inactive'
               END AS EMPLOYEEACTIVE,
               Coalesce(LTrim(RTrim(P.[PersonKnownAs])), '') AS FIRSTNAME,
               Coalesce(LTrim(RTrim(S.[StaffSurname])), '') AS LASTNAME,
               Coalesce(LTrim(RTrim(P.[PersonTitle])), '') AS PREFIX,
               Coalesce(LTrim(RTrim(C.[ContPhone])), '') AS PHONE,
               Coalesce(LTrim(RTrim(S.[StaffEmail])), '') AS EMAIL,
               LTrim(RTrim(S.[StaffCode])) AS [PE_STAFF_CODE],
               Case When S.[StaffDepartment] = 'UNKNOWN' Then '' Else S.[StaffDepartment] End AS DEPARTMENTID,
               Case When S.[StaffOffice] = 'UNKNOWN' Then '1' Else S.[StaffOffice] End AS LOCATIONID
               FROM [dbo].[tblStaff] S
               INNER JOIN [dbo].[tblPerson] P ON S.StaffIndex = P.ContIndex
               INNER JOIN [dbo].[tblContacts] C ON S.StaffIndex = C.ContIndex



RETURN 0

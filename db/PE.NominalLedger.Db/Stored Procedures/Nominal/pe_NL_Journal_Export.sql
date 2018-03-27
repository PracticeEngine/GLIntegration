CREATE PROCEDURE [dbo].[pe_NL_Journal_Export]

@BatchID int = 0

AS

        SELECT  MapIndex,
            MapTargetType as AccountTypeCode,
            MapTargetAcc as AccountCode,
            P.NomBatch,
            P.NomAmount,
            P.NomNarrative,
            P.NomTransRef,
            P.NomDate,
            LTrim(RTrim(P.ClientCode)) AS IntacctCustomerID,
            Coalesce(Cast(J1.[Job_Idx] AS nVarChar(10)), Cast(J2.[Job_Idx] AS nVarChar(10)), '') AS IntacctProjectID,
            Coalesce(Cast(Case When S.[StaffIndex] = 0 Then NULL Else S.[StaffIndex] End AS nVarChar(10)), '') AS IntacctEmployeeID,
            Case When Coalesce(J1.Job_Dept, J2.Job_Dept, '') = 'UNKNOWN' Then '' Else Coalesce(J1.Job_Dept, J2.Job_Dept, '') END AS IntacctDepartment,
            Coalesce(Case E.ClientOffice When 'UNKNOWN' Then '1' Else E.ClientOffice End, '1') AS IntacctLocation
        FROM    tblTranNominalPost AS P
			INNER JOIN tblTranNominalMap AS M ON M.MapTargetAcc = P.NomPostAcc
			AND P.NomOrg = M.MapOrg
			AND P.NomSource = M.MapSource
			AND P.NomAccount = M.MapAccount
			AND P.NomOffice = M.MapOffice
			AND P.NomPartner = M.MapPart
			AND P.NomService = M.MapServ
			AND P.NomDept = M.MapDept
			LEFT OUTER JOIN
							(tblTranProvisions TP INNER JOIN tblJob_Header J1 ON TP.Job_Idx = J1.Job_Idx) ON P.NomSource = 'WIP' AND P.NomAccount = 'WPROV' AND P.NomMaxRef = TP.ProvIndex
			LEFT OUTER JOIN
							(tblTranWIP W INNER JOIN tblJob_Header J2 ON W.ServPeriod = J2.Job_Idx) ON P.NomSource = 'WIP' AND P.NomAccount <> 'WPROV' AND P.NomMaxRef = W.WIPIndex
			LEFT OUTER JOIN
							tblEngagement E ON P.ClientCode = E.ClientCode
			LEFT OUTER JOIN -- Relies on index IX_StaffCode enforcing this to be a unique field
							tblStaff S ON P.StaffCode = S.StaffCode
        WHERE P.NomBatch = @BatchID



RETURN 0

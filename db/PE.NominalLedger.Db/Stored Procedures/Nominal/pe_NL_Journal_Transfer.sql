CREATE PROCEDURE [dbo].[pe_NL_Journal_Transfer]

@PracID int = NULL,
@BatchID int = 0,
@Journal  varchar(4) = NULL,
@HangfireJobID nVarChar(255)

AS
               DECLARE @Batch int

               -- If a PracID is provided, determine whether that batch is valid for a transfer
               IF @PracID IS NOT NULL
                              BEGIN
                              IF (Select NLTransfer From tblTranNominalOrgs Where PracID = @PracID) = 0
                              RETURN 1
                              END

               -- If re-running an existing batch, return that batch number,
               -- or if running a new batch, work out the next batch number and send that
               IF @BatchID > 0
                              BEGIN
                              SET @Batch = @BatchID
                              END
               ELSE
                              BEGIN
                              SELECT @Batch = LastBatch + 1 FROM tblTranNominalControl
                              END

               CREATE TABLE #Source (Src VarChar(3))
               IF @Journal = 'PE'
               INSERT INTO #Source (Src) VALUES ('WIP'), ('DRS'), ('LOD')
               IF @Journal = 'STA'
               INSERT INTO #Source (Src) VALUES ('STA')

               DECLARE @Period int
               SELECT @Period = MAX(NomPeriodIndex) FROM tblTranNominalPost WHERE NomPosted = 0

               UPDATE tblTranNominal SET HangfireJobID = @HangfireJobID
               FROM tblTranNominal INNER JOIN #Source ON NLSource = Src
               WHERE NLPeriodIndex = @Period AND NomIndex > 0 AND NLPosted = 0 AND NLOrg = @PracID AND HangfireJobId IS NULL

               UPDATE tblTranNominalPost SET HangfireJobID = @HangfireJobID
               FROM tblTranNominalPost INNER JOIN #Source ON NomSource = Src
               WHERE NomPeriodIndex = @Period AND NomPosted = 0 AND NomOrg = @PracID AND HangfireJobId IS NULL

               IF @Journal = 'PE' OR @Journal IS NULL
               BEGIN
                              SELECT  MapIndex,
                                                            MapTargetType as AccountTypeCode,
                                                            MapTargetAcc as AccountCode,
                                                            @Batch As NomBatch,
                                                            P.NomAmount,
                                                            P.NomNarrative,
                                                            P.NomTransRef,
                                                            P.NomDate,
                                                            CAST(P.NomOrg AS int) AS NomOrg,
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
                                                            AND P.NomOrg = Coalesce(@PracID, P.NomOrg)
                                                            AND P.NomSource IN ('WIP', 'DRS', 'LOD')
                                                            AND P.NomPeriodIndex = @Period
                                                            AND P.HangfireJobID = @HangfireJobID
                                                            --and LTrim(RTrim(P.ClientCode)) like '%hje%'
               END

               IF @Journal = 'STAT'
               BEGIN
                              SELECT  'STAT' AS Journal,
                                                            P.ClientCode AS CustomerId,
                                                            Coalesce(Cast(J2.[Job_Idx] AS nVarChar(10)), '') AS ProjectID,
                                                            Coalesce(Cast(S.[StaffIndex] AS nVarChar(10)), '') AS EmployeeId,
                                                            P.NomAmount AS [Hours],
                                                            P.NomAccount AS Account,
                                                            P.NomDate AS BatchDate, 
                                                            @Batch AS BatchID
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
                                                                           (tblTranWIP W INNER JOIN tblJob_Header J2 ON W.ServPeriod = J2.Job_Idx) ON P.NomMaxRef = W.WIPIndex
                                                            LEFT OUTER JOIN -- Relies on index IX_StaffCode enforcing this to be a unique field
                                                                           tblStaff S ON P.StaffCode = S.StaffCode
                              WHERE P.NomBatch = @BatchID
                                                            AND P.NomOrg = Coalesce(@PracID, P.NomOrg)
                                                            AND P.NomSource IN ('STA')
                                                            AND P.NomPeriodIndex = @Period
                                                            AND P.HangfireJobID = @HangfireJobID
               END

RETURN 0

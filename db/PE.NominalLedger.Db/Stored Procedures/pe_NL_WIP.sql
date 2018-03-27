/*
CREATED - AH - 2004 earlier
REVISED - MF - Jul 2004
	WIP Fees to go to separate account
	Changed the Time to go to the Office and Department on the WIP record, not Engagement or Staff for all entry types
	Changed to point WIP Fees (when using WIP) to Job Department


*/
CREATE PROCEDURE [dbo].[pe_NL_WIP]

@Result int OUTPUT

AS

DECLARE @MonthEnd datetime,
@PeriodIdx int,
@WIPRef int,
@FeeSource char(3),
@MinFee int,
@MaxFee int,
@WIPFactor decimal (9,2),
@ICFactor decimal (9,2),
@InterCompany bit,
@InterCo int,
@ProvIdx int

GOTO FINISH

	SET @MonthEnd  = (Select PracPeriodEnd From tblControl Where PracID = 1)
	IF @MonthEnd IS NULL GOTO TRAN_ABORT

	SET @PeriodIdx = (Select PeriodIndex From tblControlPeriods WHERE PeriodEndDate = @MonthEnd)

	SET @WIPRef = (Select Max(RefMax) FROM tblTranNominal WHERE NLSource = 'WIP')
	IF @WIPRef IS NULL
		SET @WIPRef = 0

	SET @ProvIdx = (Select Max(RefMax) FROM tblTranNominal WHERE NLAccount = 'WPROV')
	IF @ProvIdx IS NULL
		SET @ProvIdx = 0

	SELECT @FeeSource = FeeSource, @InterCompany = InterCo
	From tblTranNominalControl

	BEGIN TRAN
	--/Update Prior Month Transactions dated in this period with correct PeriodIndex
	UPDATE tblTranNominal
	SET NLPeriodIndex = @PeriodIdx
	WHERE NLPeriodIndex = 0 AND NLDate <= @MonthEnd

	DECLARE @WIPInd int
	DECLARE @StaffInd int
	DECLARE @TranType int
	DECLARE @WIPType varchar(10)
	DECLARE @Client int

	DECLARE csr_Trans CURSOR DYNAMIC 
	FOR SELECT W.WIPIndex, W.StaffIndex, W.TransTypeIndex, W.WIPType, W.ContIndex
	FROM tblTranWIP AS W
	WHERE W.WIPIndex > @WIPRef

	OPEN csr_Trans

	FETCH csr_Trans INTO @WIPInd, @StaffInd, @TranType, @WIPType, @Client
	WHILE (@@FETCH_STATUS=0) 
		BEGIN
		SET @WIPFactor = 1 -- Set the proportion of the wip amount to bring through to the GL
		SET @ICFactor = 1 -- Set the proportion of the wip amount to bring through to the GL for intercompany entries

		IF @TranType = 1 --Process Timesheet Entries
			BEGIN
			IF @Client < 900000
				BEGIN
				--/Debit Chargeable Time (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'BS' AS NLSection, 'WIP' AS NLAccount, W.TransTypeIndex, W.WIPStaffOffice AS Office, W.WIPService As Service, E.ClientPartner, Srv.ServDept AS Department, 
					W.WIPHours AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2)) AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblServices Srv ON Srv.ServIndex = W.WIPService
				WHERE W.WIPIndex = @WIPInd AND S.StaffOrganisation = E.ClientOrganisation
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
			
				--/Credit Chargeable Time (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, S.StaffOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'WIP' AS NLAccount, W.TransTypeIndex, W.WIPStaffOffice AS Office, W.WIPService As Service, E.ClientPartner, W.WIPStaffDept AS Department, 
					W.WIPHours*-1 AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2))*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex
				WHERE W.WIPIndex = @WIPInd AND S.StaffOrganisation = E.ClientOrganisation
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT

				IF @InterCompany = 1
					BEGIN
					SET @InterCo =	(SELECT Count(*)
							FROM	tblTranWIP W INNER JOIN
								tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN
								tblStaff S ON W.StaffIndex = S.StaffIndex
							WHERE	W.WIPIndex = @WIPInd AND S.StaffOrganisation <> E.ClientOrganisation)
					IF @InterCo IS NULL
						SET @InterCo = 0

					IF @InterCo <> 0
						BEGIN
						--/Debit Staff InterCompany (B/S)
						INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
						SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, S.StaffOrganisation, 'INT' AS NLLedger, 
							'BS' AS NLSection, 'ORG' + LTrim(CAST(E.ClientOrganisation As varchar(2))) AS NLAccount, W.TransTypeIndex, S.StaffOffice AS Office, W.WIPService As Service, E.ClientPartner, S.StaffDepartment AS Department, 
							W.WIPHours AS Units, CAST(W.WIPAmount*@ICFactor as decimal(13,2)) AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
						FROM ((tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex) INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex)
						WHERE W.WIPIndex = @WIPInd
					
						IF @@ERROR <> 0 GOTO TRAN_ABORT
					
						--/Credit Sales Of Time (P/L)
						INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
						SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, S.StaffOrganisation, 'INT' AS NLLedger, 
							'PL' AS NLSection, 'SALES' AS NLAccount, W.TransTypeIndex, S.StaffOffice AS Office, W.WIPService As Service, E.ClientPartner, S.StaffDepartment AS Department, 
							W.WIPHours*-1 AS Units, CAST(W.WIPAmount*@ICFactor as decimal(13,2))*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
						FROM ((tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex) INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex)
						WHERE W.WIPIndex = @WIPInd
					
						IF @@ERROR <> 0 GOTO TRAN_ABORT
	
						--/Credit Client InterCompany (B/S)
						INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
						SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'INT' AS NLLedger, 
							'BS' AS NLSection, 'ORG' + LTrim(CAST(S.StaffOrganisation As varchar(2))) AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, S.StaffDepartment AS Department, 
							W.WIPHours*-1 AS Units, CAST(W.WIPAmount*@ICFactor as decimal(13,2))*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
						FROM ((tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex) INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex)
						WHERE W.WIPIndex = @WIPInd
					
						IF @@ERROR <> 0 GOTO TRAN_ABORT
					
						--/Debit Purchase Of Time (P/L)
						INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
						SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'INT' AS NLLedger, 
							'PL' AS NLSection, 'PURCH' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, S.StaffDepartment AS Department, 
							W.WIPHours AS Units, CAST(W.WIPAmount*@ICFactor as decimal(13,2)) AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
						FROM ((tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex) INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex)
						WHERE W.WIPIndex = @WIPInd
					
						IF @@ERROR <> 0 GOTO TRAN_ABORT
						END
					END
				END
			ELSE
				BEGIN		
				--/Debit Non charge Time (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, S.StaffOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'NCHG' AS NLAccount, W.TransTypeIndex, S.StaffOffice AS Office, W.WIPService As Service, E.ClientPartner, S.StaffDepartment AS Department, 
					W.WIPHours AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2)) AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex
				WHERE W.WIPIndex = @WIPInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
			
				--/Credit Non charge Time (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, S.StaffOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'LOST' AS NLAccount, W.TransTypeIndex, S.StaffOffice AS Office, W.WIPService As Service, E.ClientPartner, S.StaffDepartment AS Department, 
					W.WIPHours*-1 AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2))*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex
				WHERE W.WIPIndex = @WIPInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				END
			END

		IF @TranType = 2 --Process Disbursement Entries
			BEGIN
			IF @Client < 900000
				BEGIN
				--/Debit Chargeable Disbs (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'BS' AS NLSection, 'WIPD' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, J.Job_Dept AS Department, 
					W.WIPHours AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2)) AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header AS J ON W.ServPeriod = J.Job_Idx	
				WHERE W.WIPIndex = @WIPInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
			
				--/Credit Chargeable Disbs (P/L)
				IF (SELECT ExpDesc FROM tblTranWIP W INNER JOIN tblExpenseDetail D ON W.WIPRef = D.DetailIndex INNER JOIN tblExpenseHeader H ON D.ExpIndex = H.ExpIndex WHERE W.WIPIndex = @WIPInd) = 'Access Dimensions'
					BEGIN
					INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
					SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
						'PL' AS NLSection, 'WIPD' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, J.Job_Dept AS Department, 
						W.WIPHours*-1 AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2))*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
					FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header AS J ON W.ServPeriod = J.Job_Idx
					WHERE W.WIPIndex = @WIPInd
				
					IF @@ERROR <> 0 GOTO TRAN_ABORT
					END
				ELSE
					BEGIN
					INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
					SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
						'PL' AS NLSection, 'WIPDM' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, J.Job_Dept AS Department, 
						W.WIPHours*-1 AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2))*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
					FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex
						INNER JOIN tblJob_Header AS J ON W.ServPeriod = J.Job_Idx
					WHERE W.WIPIndex = @WIPInd
				
					IF @@ERROR <> 0 GOTO TRAN_ABORT
					END
				END
			ELSE
				BEGIN		
				--/Debit Non charge Disbs (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'NCHG' AS NLAccount, W.TransTypeIndex, S.StaffOffice AS Office, W.WIPService As Service, E.ClientPartner, J.Job_Dept AS Department, 
					W.WIPHours AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2)) AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex
					INNER JOIN tblJob_Header AS J ON W.ServPeriod = J.Job_Idx
				WHERE W.WIPIndex = @WIPInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
			
				--/Credit Non charge Disbs (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
					'PL' AS NLSection, 'LOST' AS NLAccount, W.TransTypeIndex, S.StaffOffice AS Office, W.WIPService As Service, E.ClientPartner, J.Job_Dept AS Department, 
					W.WIPHours*-1 AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2))*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex
					INNER JOIN tblJob_Header AS J ON W.ServPeriod = J.Job_Idx
				WHERE W.WIPIndex = @WIPInd

				IF @@ERROR <> 0 GOTO TRAN_ABORT
				END
			-- ************ CUSTOM FOR DELOITTES ***************** Adds an "EXP" / "BS" record for staff expenses so that they can be directed to a staff account
			INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
			SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, 2 AS NLOrg, 'EXP' AS NLLedger, 
				'BS' AS NLSection, 'EX' + S.StaffReference AS NLAccount,
				W.TransTypeIndex, S.StaffOffice AS Office, W.WIPService As Service, E.ClientPartner, S.StaffDepartment AS Department, 
				W.WIPHours AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2)) AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
			FROM tblTranWIP W INNER JOIN tblStaff S ON W.StaffIndex = S.StaffIndex INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex
				INNER JOIN tblJob_Header AS J ON W.ServPeriod = J.Job_Idx
			WHERE W.WIPIndex = @WIPInd AND W.StaffIndex != 0

			IF @@ERROR <> 0 GOTO TRAN_ABORT
			END

		IF @TranType IN (3,4,6,14) --Process Fee Entries
			BEGIN
			IF @Client < 900000
				BEGIN
				--/Debit WIP Fees (P/L)
				IF @WIPType = 'TIME'
					BEGIN
					INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
					SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
						'PL' AS NLSection, 'WFEE-T' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, J.Job_Dept, 
						W.WIPHours*-1 AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2))*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
					FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header  AS J ON W.ServPeriod = J.Job_Idx
					WHERE W.WIPIndex = @WIPInd
				
					IF @@ERROR <> 0 GOTO TRAN_ABORT
					END
				ELSE
					BEGIN
					INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
					SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
						'PL' AS NLSection, 'WFEE-D' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, J.Job_Dept, 
						W.WIPHours*-1 AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2))*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
					FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header  AS J ON W.ServPeriod = J.Job_Idx
					WHERE W.WIPIndex = @WIPInd
				
					IF @@ERROR <> 0 GOTO TRAN_ABORT
					END
								
				--/Credit WIP Fees (B/S)
				IF @WIPType = 'TIME'
					BEGIN
					INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
					SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
						'BS' AS NLSection, 'WIP' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, J.Job_Dept,
						W.WIPHours AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2)) AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
					FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header  AS J ON W.ServPeriod = J.Job_Idx
					WHERE W.WIPIndex = @WIPInd
				
					IF @@ERROR <> 0 GOTO TRAN_ABORT
					END
				ELSE
					BEGIN
					INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
					SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLLedger, 
						'BS' AS NLSection, 'WIPD' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, J.Job_Dept,
						W.WIPHours AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2)) AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
					FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header  AS J ON W.ServPeriod = J.Job_Idx
					WHERE W.WIPIndex = @WIPInd
				
					IF @@ERROR <> 0 GOTO TRAN_ABORT
					END

				IF @FeeSource = 'WIP'
					BEGIN
					IF @WIPType = 'TIME'
						BEGIN
						--/Credit Time Sales
						INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
						SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'DRS' AS NLLedger, 
							'PL' AS NLSection, 'FEES-T' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, Coalesce(J.Job_Dept, 'UNKNOWN'), 
							W.WIPAmount, W.ContIndex, W.WIPRefAlpha, W.Narrative, 0 AS RefMin, 0 AS RefMax
						FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header  AS J ON W.ServPeriod = J.Job_Idx
						WHERE W.WIPIndex = @WIPInd
				
						IF @@ERROR <> 0 GOTO TRAN_ABORT
						END
					ELSE
						BEGIN
						--/Credit Disb Sales
						INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
						SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'DRS' AS NLLedger, 
							'PL' AS NLSection, 'FEES-D' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, Coalesce(J.Job_Dept, 'UNKNOWN'), 
							W.WIPAmount AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, 0 AS RefMin, 0 AS RefMax
						FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header  AS J ON W.ServPeriod = J.Job_Idx
						WHERE W.WIPIndex = @WIPInd
				
						IF @@ERROR <> 0 GOTO TRAN_ABORT
						END
			
					--/Debit DRS Non WIP Suspense
					INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
					SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'DRS' AS NLLedger, 
						'BS' AS NLSection, 'DRNON' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, Coalesce(J.Job_Dept, 'UNKNOWN'), 
						W.WIPAmount*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, 0 AS RefMin, 0 AS RefMax
					FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header  AS J ON W.ServPeriod = J.Job_Idx
					WHERE W.WIPIndex = @WIPInd
			
					IF @@ERROR <> 0 GOTO TRAN_ABORT
					END
				END
			END

		IF @TranType = 5 --Process Write Off Entries
			BEGIN
			IF @Client < 900000
				BEGIN

				IF @WIPType = 'DISB'
					BEGIN
					--/Debit Write-off (P/L)
					INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
					SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLSource, 
						'PL' AS NLSection, 'WOD' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, Coalesce(J.Job_Dept, 'UNKNOWN'),  
						W.WIPHours*-1 AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2))*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
					FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header  AS J ON W.ServPeriod = J.Job_Idx
					WHERE W.WIPIndex = @WIPInd
				
					IF @@ERROR <> 0 GOTO TRAN_ABORT
				
					--/Credit Write-off (B/S)
					INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
					SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLSource, 
						'BS' AS NLSection, 'WOD' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, Coalesce(J.Job_Dept, 'UNKNOWN'),  
						W.WIPHours AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2)) AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
					FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header  AS J ON W.ServPeriod = J.Job_Idx
					WHERE W.WIPIndex = @WIPInd
				
					IF @@ERROR <> 0 GOTO TRAN_ABORT
					END
				ELSE
					BEGIN
					--/Debit Write-off (P/L)
					INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
					SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLSource, 
						'PL' AS NLSection, 'WOT' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, Coalesce(J.Job_Dept, 'UNKNOWN'),  
						W.WIPHours*-1 AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2))*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
					FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header  AS J ON W.ServPeriod = J.Job_Idx
					WHERE W.WIPIndex = @WIPInd
				
					IF @@ERROR <> 0 GOTO TRAN_ABORT
				
					--/Credit Write-off (B/S)
					INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
					SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLSource, 
						'BS' AS NLSection, 'WOT' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, Coalesce(J.Job_Dept, 'UNKNOWN'),  
						W.WIPHours AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2)) AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
					FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header  AS J ON W.ServPeriod = J.Job_Idx
					WHERE W.WIPIndex = @WIPInd
				
					IF @@ERROR <> 0 GOTO TRAN_ABORT
					END

				END
			END

		IF @TranType NOT IN (1,2,3,4,5,6,14) --Process All Other Entries
			BEGIN
			IF @Client < 900000
				BEGIN
				--/Debit Journal (P/L)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLSource, 
					'BS' AS NLSection, 'WIP' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, Coalesce(J.Job_Dept, 'UNKNOWN'), 
					W.WIPHours AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2)) AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header  AS J ON W.ServPeriod = J.Job_Idx
				WHERE W.WIPIndex = @WIPInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
			
				--/Credit Journal (B/S)
				INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
				SELECT NLPeriodIndex = CASE WHEN W.WIPDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, W.WIPDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLSource, 
					'PL' AS NLSection, 'WIP' AS NLAccount, W.TransTypeIndex, E.ClientOffice AS Office, W.WIPService As Service, E.ClientPartner, Coalesce(J.Job_Dept, 'UNKNOWN'), 
					W.WIPHours*-1 AS Units, CAST(W.WIPAmount*@WIPFactor as decimal(13,2))*-1 AS Amount, W.ContIndex, W.WIPRefAlpha, W.Narrative, W.WIPIndex AS RefMin, W.WIPIndex AS RefMax
				FROM tblTranWIP W INNER JOIN tblEngagement E ON W.ContIndex = E.ContIndex INNER JOIN tblJob_Header  AS J ON W.ServPeriod = J.Job_Idx
				WHERE W.WIPIndex = @WIPInd
			
				IF @@ERROR <> 0 GOTO TRAN_ABORT
				END
			END

		FETCH 	csr_Trans INTO @WIPInd, @StaffInd, @TranType, @WIPType, @Client
		END

	CLOSE csr_Trans
	DEALLOCATE csr_Trans


	DECLARE csr_Trans CURSOR DYNAMIC 
	FOR SELECT P.ProvIndex
	FROM tblTranProvisions P
	WHERE P.ProvIndex > @ProvIdx AND P.ProvType = 'WIP'

	OPEN csr_Trans

	FETCH csr_Trans INTO @WIPInd
	WHILE (@@FETCH_STATUS=0) 
		BEGIN
		--/Debit Provisions (P/L)
		INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
		SELECT NLPeriodIndex = CASE WHEN P.ProvDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, P.ProvDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLSource, 
			'PL' AS NLSection, 'WPROV' AS NLAccount, 7, E.ClientOffice AS Office, 'UNKNOWN' As Service, E.ClientPartner, Coalesce(E.ClientDepartment, 'UNKNOWN'), 
			0 AS Units, P.ProvAmount AS Amount, P.ContIndex, 'PROV', P.ProvReason, P.ProvIndex AS RefMin, P.ProvIndex AS RefMax
		FROM tblTranProvisions P INNER JOIN tblEngagement E ON P.ContIndex = E.ContIndex 
		WHERE P.ProvIndex = @WIPInd
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT
	
		--/Credit Provisions (B/S)
		INSERT INTO tblTranNominal ( NLPeriodIndex, NLDate, NLOrg, NLSource, NLSection, NLAccount, TransTypeIndex, Office, Service, Partner, Department, Units, Amount, ContIndex, TransRefAlpha, NLNarrative, RefMin, RefMax )
		SELECT NLPeriodIndex = CASE WHEN P.ProvDate > @MonthEnd THEN 0 ELSE @PeriodIdx END, P.ProvDate AS NLDate, E.ClientOrganisation, 'WIP' AS NLSource, 
			'BS' AS NLSection, 'WPROV' AS NLAccount, 7, E.ClientOffice AS Office, 'UNKNOWN' As Service, E.ClientPartner, Coalesce(E.ClientDepartment, 'UNKNOWN'), 
			0 AS Units, P.ProvAmount*-1 AS Amount, P.ContIndex, 'PROV', P.ProvReason, P.ProvIndex AS RefMin, P.ProvIndex AS RefMax
		FROM tblTranProvisions P INNER JOIN tblEngagement E ON P.ContIndex = E.ContIndex 
		WHERE P.ProvIndex = @WIPInd
	
		IF @@ERROR <> 0 GOTO TRAN_ABORT

		FETCH 	csr_Trans INTO @WIPInd
		END

	CLOSE csr_Trans
	DEALLOCATE csr_Trans

	COMMIT TRAN
	GOTO FINISH

TRAN_ABORT:
	ROLLBACK TRAN
	SET @Result = 1
	GOTO DONE

FINISH:
	SET @Result = 0

DONE:
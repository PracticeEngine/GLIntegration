

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[tblTaskPads] WHERE [TaskPadCode] = 'NLT')
	BEGIN

	PRINT 'Adding GL Integration TaskPad...'

	SET IDENTITY_INSERT [dbo].[tblTaskpads] ON;

	INSERT INTO [dbo].[tblTaskpads]([TaskpadId], [TaskPadCode], [TaskpadDescription])
	SELECT 13, N'NLT', N'GL Integration'
	RAISERROR (N'[dbo].[tblTaskpads]: Insert Batch: 1.....Done!', 10, 1) WITH NOWAIT;

	SET IDENTITY_INSERT [dbo].[tblTaskpads] OFF;

	END


PRINT 'Adding TaskPad Items...'

SET IDENTITY_INSERT [dbo].[tblTaskpadItems] ON;

INSERT INTO [dbo].[tblTaskpadItems]([TaskpadItemId], [TaskpadId], [ShortDescription], [LongDescription], [ImagePath], [NavigateUrl], [SelectedImagePath])

SELECT GTP.[TaskpadItemId], GTP.[TaskpadId], GTP.[ShortDescription], GTP.[LongDescription], GTP.[ImagePath], GTP.[NavigateUrl], GTP.[SelectedImagePath]
FROM
(
SELECT 301 as [TaskpadItemId], 13 as [TaskpadId], N'Create Journal' as [ShortDescription], N'Create Journal' as [LongDescription], N'content/images/taskpadicons/sales_add_48.png' as [ImagePath], N'_PostCreate' as [NavigateUrl], N'content/images/taskpadicons/sales_add_128.png'[SelectedImagePath] UNION ALL
SELECT 302, 13, N'Integration Setup', N'Integration Setup', N'content/images/taskpadicons/b2b_48.png', N'_NominalControl', N'content/images/taskpadicons/b2b_128.png' UNION ALL
SELECT 303, 13, N'Export Account Map', N'Export Account Map', N'content/images/taskpadicons/flow_48.png', N'_NLMap', N'content/images/taskpadicons/flow_128.png' UNION ALL
SELECT 304, 13, N'Create Disbursements', N'Create Disbursements', N'content/images/taskpadicons/open_safetybox_next_48.png', N'_NLImport', N'content/images/taskpadicons/open_safetybox_next_128.png' UNION ALL
SELECT 305, 13, N'Missing Mappings', N'Missing Mappings', N'content/images/taskpadicons/organigram_zoom_48.png', N'_MissingMap', N'content/images/taskpadicons/organigram_zoom_128.png' UNION ALL
SELECT 306, 13, N'Journal Posting', N'Journal Posting', N'content/images/taskpadicons/messages_next_48.png', N'_Journal', N'content/images/taskpadicons/messages_next_128.png' UNION ALL
SELECT 307, 13, N'Import Account Map', N'Import Account Map', N'content/images/taskpadicons/macro_next_48.png', N'_DisbMap', N'content/images/taskpadicons/macro_next_128.png' UNION ALL
SELECT 308, 13, N'Update Costing', N'Update Costing', N'content/images/taskpadicons/baseline_for_earned_save_48.png', N'_CostingUpdate', N'content/images/taskpadicons/baseline_for_earned_save_128.png' UNION ALL
SELECT 309, 13, N'Retransfer Cashbook', N'Retransfer Cashbook', N'content/images/taskpadicons/collection_account_reload_48.png', N'_BankRecPost', N'content/images/taskpadicons/collection_account_reload_128.png' UNION ALL
SELECT 310, 13, N'Update Bank Rec', N'Update Bank Rec', N'content/images/taskpadicons/credit_reload_48.png', N'_BankRec', N'content/images/taskpadicons/credit_reload_128.png' UNION ALL
SELECT 311, 13, N'Integration Extract', N'Integration Extract', N'content/images/taskpadicons/column_chart_ok_48.png', N'_IntegrationExtract', N'content/images/taskpadicons/column_chart_ok_128.png' UNION ALL
SELECT 312, 13, N'Integration details', N'Integration details', N'content/images/taskpadicons/group_data_48.png', N'_Integrationdetails', N'content/images/taskpadicons/group_data_128.png' UNION ALL
SELECT 313, 13, N'Organisations', N'Organisations', N'content/images/taskpadicons/focus_group_48.png', N'_Organisations', N'content/images/taskpadicons/focus_group_128.png' UNION ALL
SELECT 314, 13, N'Reprint Journal', N'Reprint Journal', N'content/images/taskpadicons/graphic_report_reload_48.png', N'_ReprintJournal', N'content/images/taskpadicons/graphic_report_reload_128.png' UNION ALL
SELECT 315, 13, N'Repost Journal', N'Repost Journal', N'content/images/taskpadicons/organigram_zoom_48.png', N'_RepostJournal', N'content/images/taskpadicons/organigram_zoom_128.png' UNION ALL
SELECT 316, 13, N'Reprint Journal Details', N'Reprint Journal Details', N'content/images/taskpadicons/line_chart_reload_48.png', N'_ReprintJournalDetails', N'content/images/taskpadicons/line_chart_reload_128.png' UNION ALL
SELECT 317, 13, N'Expense Posting', N'Expense Posting', N'content/images/taskpadicons/messages_next_48.png', N'_ExpPosting', N'content/images/taskpadicons/messages_next_128.png' UNION ALL
SELECT 318, 13, N'Intacct Sync', N'Intacct Sync', N'content/images/taskpadicons/messages_next_48.png', N'_IntacctSync', N'content/images/taskpadicons/messages_next_128.png' 
) GTP
LEFT OUTER JOIN [dbo].[tblTaskpadItems] TP ON GTP.[TaskpadItemId] = TP.[TaskpadItemId]
WHERE TP.[TaskpadItemId] IS NULL

SET IDENTITY_INSERT [dbo].[tblTaskpadItems] OFF;

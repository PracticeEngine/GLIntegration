CREATE PROCEDURE [dbo].[pe_NL_Menu_List]
	@StaffUser nvarchar(128)
AS
	SELECT DISTINCT
	TP.[ShortDescription] AS [MenuName], SUBSTRING(TP.NavigateUrl, 2, 500) AS VM
	FROM [dbo].[tblTaskpads] T
	INNER JOIN [dbo].[tblTaskpadItems] TP ON T.[TaskpadId] = TP.[TaskpadId]
	INNER JOIN [dbo].[tblPage] P ON TP.[NavigateUrl] = P.[PageName]
	INNER JOIN [dbo].[tblPageAccess] PA ON P.[PageName] = PA.[Page]
	INNER JOIN [dbo].[tblGroupMembership] G ON PA.[GroupIndex] = G.[GroupIndex]
	INNER JOIN [dbo].[tblStaff] S ON G.[ContIndex] = S.[StaffIndex]
	WHERE S.[StaffUser] = @StaffUser AND T.[TaskpadId] = 13
	ORDER BY TP.[ShortDescription]

RETURN 0


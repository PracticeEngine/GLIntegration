CREATE PROCEDURE [dbo].[pe_NL_GP_Accs]

@AccType int

AS

Select AccIndex, AccNum, AccDesc, AccType
FROM pe_view_NL_Accounts
WHERE AccType = @AccType
ORDER BY AccDesc
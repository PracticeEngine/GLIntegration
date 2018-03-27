CREATE PROCEDURE [dbo].[pe_NL_Account_Types_SS]

@Org int

AS

SELECT DISTINCT Cast(AccountGroup as nvarchar(10)) As AccountTypeCode, GroupDescription As AccountTypeDesc
FROM SunSystems_Accounts
ORDER BY GroupDescription 





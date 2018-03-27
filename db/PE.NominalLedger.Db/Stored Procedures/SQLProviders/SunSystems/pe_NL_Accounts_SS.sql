CREATE PROCEDURE [dbo].[pe_NL_Accounts_SS]

@Org int,
@Type nvarchar(10)

AS

SELECT A.AccountCode As AccountCode, A.AccountDescription As AccountDesc, CAST(A.AccountGroup as nvarchar(10)) As AccountTypeCode, A.GroupDescription As AccountTypeDesc
FROM SunSystems_Accounts A
WHERE CAST(A.AccountGroup as nvarchar(10)) = @Type
ORDER BY A.GroupDescription 


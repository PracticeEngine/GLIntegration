CREATE PROCEDURE [dbo].[pe_NL_Expense_Account_Update]

@ExpOrg int,
@DisbCode nvarchar(10),
@ChargeExpAccountType nvarchar(50),
@ChargeExpAccount nvarchar(50),
@NonChargeExpAccountType nvarchar(50),
@NonChargeExpAccount nvarchar(50)

AS

UPDATE tblTranNominalExpMap
SET ChargeExpAccountType = @ChargeExpAccountType, ChargeExpAccount = @ChargeExpAccount, NonChargeExpAccountType = @NonChargeExpAccountType, NonChargeExpAccount = @NonChargeExpAccount
WHERE ExpOrg = @ExpOrg AND DisbCode = @DisbCode

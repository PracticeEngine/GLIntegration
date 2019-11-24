CREATE PROCEDURE [dbo].[pe_NL_Expense_Account_Update]

@ExpOrg int,
@DisbCode nvarchar(10),
@ChargeExpAccount nvarchar(50),
@NonChargeExpAccount nvarchar(50),
@ChargeSuffix1 int = null,
@ChargeSuffix2 int = null,
@ChargeSuffix3 int = null,
@NonChargeSuffix1 int = null,
@NonChargeSuffix2 int = null,
@NonChargeSuffix3 int = null

AS

UPDATE tblTranNominalExpMap
SET ChargeExpAccount = @ChargeExpAccount, ChargeSuffix1 = @ChargeSuffix1, ChargeSuffix2 = @ChargeSuffix2, ChargeSuffix3 = @ChargeSuffix3, NonChargeExpAccount = @NonChargeExpAccount, NonChargeSuffix1 = @NonChargeSuffix1, NonChargeSuffix2 = @NonChargeSuffix2, NonChargeSuffix3 = @NonChargeSuffix3
WHERE ExpOrg = @ExpOrg AND DisbCode = @DisbCode

CREATE TABLE [dbo].[tblTranNominalExpMap]
(
    [ExpMapIndex]				INT				IDENTITY (1, 1) NOT NULL,
    [ExpOrg]					INT				CONSTRAINT [DF_tblTranNominalExpMap_ExpOrg] DEFAULT (0) NOT NULL,
    [DisbCode]					nvarchar (10)	NOT NULL,
    [ChargeExpAccount]			nvarchar (50)	NULL,
    [ChargeSuffix1]				INT				NULL,
    [ChargeSuffix2]				INT				NULL,
    [ChargeSuffix3]				INT				NULL,
    [NonChargeExpAccount]		nvarchar (50)	NULL,
    [NonChargeSuffix1]			INT				NULL,
    [NonChargeSuffix2]			INT				NULL,
    [NonChargeSuffix3]			INT				NULL,
    [RowVer]					ROWVERSION   NOT NULL,
    CONSTRAINT [PK_tblTranNominalExpMap] PRIMARY KEY CLUSTERED ([ExpMapIndex] ASC) 
)

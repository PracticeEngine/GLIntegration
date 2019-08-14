CREATE TABLE [dbo].[tblTranNominalExpMap]
(
    [ExpMapIndex]				INT				IDENTITY (1, 1) NOT NULL,
    [ExpOrg]					INT				CONSTRAINT [DF_tblTranNominalExpMap_ExpOrg] DEFAULT (0) NOT NULL,
    [DisbCode]					nvarchar (10)	NOT NULL,
    [ChargeExpAccountType]		nvarchar (50)	NULL,
    [ChargeExpAccount]			nvarchar (50)	NULL,
    [ChargeExpIdx]				INT				NULL,
    [NonChargeExpAccountType]	nvarchar (50)	NULL,
    [NonChargeExpAccount]		nvarchar (50)	NULL,
    [NonChargeExpIdx]			INT				NULL,
    [RowVer]					ROWVERSION   NOT NULL,
    CONSTRAINT [PK_tblTranNominalExpMap] PRIMARY KEY CLUSTERED ([ExpMapIndex] ASC) 
)

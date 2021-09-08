CREATE TABLE [dbo].[tblTranNominalMTD]
(
	[Id] INT IDENTITY (1, 1) NOT NULL,
	[DebtTranIndex] INT NOT NULL,
	[Processed] BIT NOT NULL,
	[RowVer] BINARY(8) NOT NULL,
    CONSTRAINT [PK_tblTranNominalMTD] PRIMARY KEY CLUSTERED ([Id] ASC)
);

GO
CREATE NONCLUSTERED INDEX [IX_DebtTranIndex]
    ON [dbo].[tblTranNominalMTD]([DebtTranIndex] ASC)

CREATE TABLE [dbo].[tblTranNominalMTDControl]
(
	[Id] INT IDENTITY (1, 1) NOT NULL,
	[LastExtract] DATETIME NULL,
	[MaxRowVer] BINARY(8) NULL,
    CONSTRAINT [PK_tblTranNominalMTDControl] PRIMARY KEY CLUSTERED ([Id] ASC)
)

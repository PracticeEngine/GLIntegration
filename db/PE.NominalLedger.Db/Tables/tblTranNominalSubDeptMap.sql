CREATE TABLE [dbo].[tblTranNominalSubDeptMap]
(
	[SubDeptIdx] [nvarchar](10) NOT NULL,
	[Entity] [nvarchar](10) NOT NULL,
	[RowVer] [timestamp] NOT NULL,
	CONSTRAINT [PK_tblTranNominalSubDeptMap] PRIMARY KEY CLUSTERED ([SubDeptIdx] ASC)
)

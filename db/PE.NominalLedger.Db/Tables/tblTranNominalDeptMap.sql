CREATE TABLE [dbo].[tblTranNominalDeptMap]
(
	[DeptIdx] [nvarchar](10) NOT NULL,
	[Entity] [nvarchar](10) NOT NULL,
	[RowVer] [timestamp] NOT NULL,
    CONSTRAINT [PK_tblTranNominalDeptMap] PRIMARY KEY CLUSTERED ([DeptIdx] ASC) 
)

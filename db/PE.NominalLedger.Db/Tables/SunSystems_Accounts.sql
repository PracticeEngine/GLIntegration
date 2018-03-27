CREATE TABLE [dbo].[SunSystems_Accounts](
	[AccountID] [int] IDENTITY(1,1) NOT NULL,
	[AccountCode] [nvarchar](255) NULL,
	[AccountDescription] [nvarchar](255) NULL,
	[AccountType] [nvarchar](255) NULL,
	[AccountGroup] [int] NULL,
	[GroupDescription] [varchar](50) NULL,
 CONSTRAINT [PK_SunSystems_Accounts] PRIMARY KEY CLUSTERED 
(
	[AccountID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

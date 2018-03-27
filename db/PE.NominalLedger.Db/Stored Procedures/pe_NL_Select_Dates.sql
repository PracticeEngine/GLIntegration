CREATE PROCEDURE [dbo].[pe_NL_Select_Dates]

AS

Select PracPeriodStart, PracPeriodEnd, (SELECT IntSystem FROM tblTranNominalControl WHERE IntIndex = 1) As IntSystem
From tblControl 
Where PracID = 1
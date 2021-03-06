USE [clinic_faculty_activity_report]
GO
/****** Object:  StoredProcedure [dbo].[spGetOutpatientClinicGrid]    Script Date: 07/29/2021 11:44:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[spGetOutpatientClinicGrid] (@year int, @month int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Dates AS NVARCHAR(MAX)
	DECLARE @query  AS NVARCHAR(MAX)
	--set @year = 2020
	--set @month = 12

	--DROP TABLE #temp

	;with b as(
	SELECT datelist =  LEFT(CONVERT(VARCHAR, datefromparts(s.schedule_year, s.schedule_month, a.Appointment_day), 120), 10) + ss.appointment_session_label
	  FROM [clinic_schedule].[dbo].[appointment] a 
	  left join [clinic_schedule].[dbo].[schedule] s on s.schedule_id = a.Appointment_schedule_id
	  left join [clinic_schedule].[dbo].physician p on p.Physician_id = a.Appointment_physician_id
	  inner join [clinic_faculty_activity_report].[dbo].[physician] pp on pp.physician_individual_id = p.physician_individual_id
	  left join [clinic_schedule].[dbo].appointment_session ss on ss.appointment_session_id = a.Appointment_session_id
		where s.schedule_year = @year and s.schedule_month = @month  
		)

	--select * into #temp from b


	select  @Dates =  STUFF((SELECT ',' + QUOTENAME(convert(CHAR(12), datelist, 120)) 
						from (select distinct datelist from b)sub order by datelist
				FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)') ,1,1,'')

	set @query ='with team as(
							SELECT distinct pp.physician_individual_id
								  ,pp.physician_name
								  ,t.site_team_name
							  FROM [clinic_schedule].[dbo].[appointment] a 
							  left join [clinic_schedule].[dbo].[schedule] s on s.schedule_id = a.Appointment_schedule_id
							  left join [clinic_schedule].[dbo].physician p on p.Physician_id = a.Appointment_physician_id
							  inner join [clinic_faculty_activity_report].[dbo].[physician] pp on pp.physician_individual_id = p.physician_individual_id
							  left join [clinic_schedule].[dbo].site_team t on t.site_team_id = a.Appointment_team_id
							  where s.schedule_year ='+CONVERT(varchar(10), @year)+' and s.schedule_month = '+CONVERT(varchar(10), @month)+' and p.physician_individual_id not in (5910,6385) and Appointment_type_id=1
							  group by pp.physician_individual_id, pp.physician_name,t.site_team_name
						),
						b as(
						SELECT datelist =  LEFT(CONVERT(VARCHAR, datefromparts(s.schedule_year, s.schedule_month, a.Appointment_day), 120), 10) + ss.appointment_session_label
								,pp.physician_name
								,pp.physician_individual_id
								,appointment_type = case when at.appointment_type_id = 1 and Appointment_cancelled=0 then ''P''
														 when at.appointment_type_id = 2 and Appointment_cancelled=0 then ''A'' 
														 --when a.Appointment_key_id in (3,8) and Appointment_cancelled = 1 then ''O'' E
														 else ''''
														 end
						  FROM [clinic_schedule].[dbo].[appointment] a 
						  left join [clinic_schedule].[dbo].[schedule] s on s.schedule_id = a.Appointment_schedule_id
						  left join [clinic_schedule].[dbo].physician p on p.Physician_id = a.Appointment_physician_id
						  inner join [clinic_faculty_activity_report].[dbo].[physician] pp on pp.physician_individual_id = p.physician_individual_id
						  left join [clinic_schedule].[dbo].appointment_session ss on ss.appointment_session_id = a.Appointment_session_id
						  left join [clinic_schedule].[dbo].appointment_type at on at.appointment_type_id = a.Appointment_type_id
						  left join [clinic_schedule].[dbo].site_team t on t.site_team_id = a.Appointment_team_id
							where s.schedule_year ='+CONVERT(varchar(10), @year)+' and s.schedule_month = '+CONVERT(varchar(10), @month)+'  and pp.physician_individual_id not in (5910,6385) 
							),
					Pivoted as (
						select * from  
						(
							select datelist = isnull(datelist,0),physician_name = isnull(te.physician_name,0),appointment_type=isnull(te.appointment_type,0),team = t.site_team_name
							from b te
							left join team t on t.physician_individual_id = te.physician_individual_id
						)x
						PIVOT(
							MAX (appointment_type)
							for datelist IN (' + @Dates + ')
						)p 
					)
					SELECT *
					FROM Pivoted
					ORDER BY physician_name


	'

	exec sp_executesql @query;
	--DROP TABLE #temp
END

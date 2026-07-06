
-- Table created for agents, repot targets or deadline and daily activity

CREATE TABLE agents (
    agent_id INT PRIMARY KEY,
    agent_name VARCHAR(50),
    team_lead VARCHAR(50),
    join_date DATE)


CREATE TABLE report_targets (
    report_type VARCHAR(50) PRIMARY KEY,
    daily_target INT,
    tat_hours INT)


INSERT INTO agents (agent_id, agent_name, team_lead, join_date)
VALUES
(1,'Rahul','TL_A','2024-01-01'),
(2,'Sneha','TL_A','2024-02-01'),
(3,'Sunita','TL_B','2024-03-01'),
(4,'Amit','TL_B','2024-01-15'),
(5,'Ravi','TL_A','2024-02-10'),
(6,'Priya','TL_C','2024-01-20'),
(7,'Karan','TL_C','2024-02-25'),
(8,'Neha','TL_B','2024-03-10'),
(9,'Ankit','TL_A','2024-01-05'),
(10,'Pooja','TL_C','2024-02-18');

select * from agents

INSERT INTO report_targets (report_type, daily_target, tat_hours)
VALUES
('SETT',50,4),
('TLLS',40,4),
('TAV',30,8),
('TAD',25,8),
('Auxilis',20,12),
('Telematics',15,12),
('DSC',18,12),
('Home Insurance',22,12),
('LIA',10,24),
('Classic Car',8,24);

select * from report_targets

CREATE TABLE daily_activity (
    activity_id INT IDENTITY(1,1) PRIMARY KEY,
    agent_id INT,
    activity_date DATE,
    report_type VARCHAR(50),
    reports_completed INT,
    productive_hours FLOAT,
    meeting_hours FLOAT,
    is_half_day BIT,
    errors INT)

INSERT INTO daily_activity 
(agent_id, activity_date, report_type, reports_completed, productive_hours, meeting_hours, is_half_day, errors)
VALUES
(1,'2026-06-01','SETT',95,7.5,0,0,0),
(2,'2026-06-01','TLLS',80,7.5,1,0,2),
(3,'2026-06-01','TAV',60,7.5,0,0,1),
(4,'2026-06-01','SETT',40,4,0,1,3),
(5,'2026-06-01','TAD',55,7.5,0.5,0,0),
(6,'2026-06-01','Auxilis',30,7.5,0,0,1),
(7,'2026-06-01','SETT',110,7.5,0,0,0),
(8,'2026-06-01','TLLS',70,7.5,1.5,0,2),
(9,'2026-06-01','Telematics',25,7.5,0,0,0),
(10,'2026-06-01','DSC',35,7.5,0,0,1);

select * from daily_activity

INSERT INTO daily_activity 
(agent_id, activity_date, report_type, reports_completed, productive_hours, meeting_hours, is_half_day, errors)
VALUES
(1,'2026-06-02','SETT',100,7.5,0,0,0),
(2,'2026-06-02','TLLS',75,7.5,0.5,0,1),
(3,'2026-06-02','TAV',65,7.5,0,0,2),
(4,'2026-06-02','SETT',45,4,0,1,2),
(5,'2026-06-02','TAD',50,7.5,1,0,1),
(6,'2026-06-02','Auxilis',28,7.5,0,0,0),
(7,'2026-06-02','SETT',105,7.5,0,0,0),
(8,'2026-06-02','TLLS',72,7.5,1,0,1),
(9,'2026-06-02','Telematics',27,7.5,0,0,0),
(10,'2026-06-02','DSC',33,7.5,0,0,1);


--Find adjusted hours

select agent_id, activity_date, 
       report_type, reports_completed, 
	   productive_hours, meeting_hours, is_half_day,
	   iif(is_half_day = 1, 4, productive_hours - meeting_hours) adjusted_hours
	   from daily_activity


--Find RPH

select   agent_id,
    activity_date,
    report_type,
    reports_completed,
	case when is_half_day = 1 then 4
	else productive_hours - meeting_hours
	end as adjusted_hours,
	round(reports_completed *1.0 / nullif(case when is_half_day = 1 then 4
	else productive_hours - meeting_hours
	end ,0),2) as RPH
	from daily_activity


--Find daily weighted average RPH

select *,
      case when daily_RPH >= 14 then 'Good Performer'
	       when daily_RPH >= 12 then 'Average Performer'
		   else 'Low Performer' end as Performance
from (select agent_id, activity_date,
       ROUND(
	         sum(reports_completed) * 1.00 /
			     sum(case when is_half_day = 1 then 4 
				    else productive_hours - meeting_hours end),2) as daily_RPH
			from daily_activity
			group by agent_id, activity_date) t


--Weekly RPH per agent

select *,
       case when weekly_RPH > = 14 then 'Meets Target'
	        when weekly_RPH > = 12 then 'Close to Target'
			else 'Below Target'
			end as Performance
from (select agent_id,
       DATEPART(week, activity_date) as week_no,
	   ROUND(
	         sum(reports_completed)*1.0 / 
			    sum(case when is_half_day = 1 then 4
				   else productive_hours - meeting_hours end),2) as weekly_RPH
		from daily_activity
		group by agent_id,
       DATEPART(week, activity_date)) t


-- Monthly RPH + Errors

select*,
       case when monthly_RPH >= 14 then 'Meets Target'
	       when monthly_RPH >= 12 then 'Close To Target'
		   else 'Needs Improvement'
		   end as Performance
from (select agent_id,
       FORMAT(activity_date, 'yyyy-MM') as month,
	   ROUND(
	         sum(reports_completed)*1.0/
			     sum(case when is_half_day = 1 then 4
				    else productive_hours - meeting_hours end ),2) as monthly_RPH,
			sum(errors) as total_errors
from daily_activity
group by agent_id,
       FORMAT(activity_date, 'yyyy-MM')) t


--Final Step : Final agent performance view

create view final_agent_performance as
select d.agent_id,
       a.agent_name,
	   a.team_lead,
	   d.activity_date,

	   DATEPART(week, d.activity_date) as week_no,
	   FORMAT(d.activity_date, 'yyyy-MM') as month,

	   sum(reports_completed) as Total_reports,
	   sum(
	       case when d.is_half_day = 1 then 4
		   else d.productive_hours - d.meeting_hours end) as total_hours,

	   ROUND(
	          nullif(sum(d.reports_completed)*1.0/
			           sum(case when d.is_half_day = 1 then 4
		   else d.productive_hours - d.meeting_hours end),0),2) as RPH,

        sum(d.errors) as total_errors,

		ROUND((sum(errors)*1.0/
		       nullif(sum(d.reports_completed),0)),4) as error_rate,

        CASE 
        WHEN SUM(d.reports_completed) * 1.0 /
             SUM(CASE WHEN d.is_half_day = 1 THEN 4 ELSE d.productive_hours - d.meeting_hours END) >= 14 
        THEN 'Meets Target'
        WHEN SUM(d.reports_completed) * 1.0 /
             SUM(CASE WHEN d.is_half_day = 1 THEN 4 ELSE d.productive_hours - d.meeting_hours END) >= 12 
        THEN 'Close to Target'
        ELSE 'Needs Improvement'
    END AS performance

	FROM daily_activity d
JOIN agents a 
    ON d.agent_id = a.agent_id
	
GROUP BY 
    d.agent_id,
    a.agent_name,
    a.team_lead,
    d.activity_date;



SELECT * FROM final_agent_performance;
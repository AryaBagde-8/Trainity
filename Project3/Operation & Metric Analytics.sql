CREATE DATABASE Project3;
USE Project3;

-- Case Study 1 - Job Data Analysis 

SELECT * FROM job_data;
desc job_data;

-- Changing datatype of ds coloumn (text - datetime)

ALTER TABLE job_data ADD COLUMN temp_ds datetime;
UPDATE job_data SET temp_ds = STR_TO_DATE(ds, '%m/%d/%Y');
ALTER TABLE job_data DROP COLUMN ds;
ALTER TABLE job_data CHANGE COLUMN temp_ds ds datetime;

-- Tasks
/* 1. Jobs Reviewed Over Time: Write an SQL query to calculate the number of jobs reviewed per hour for each day 
in November 2020*/

SELECT DATE(ds) AS review_date,
       HOUR(ds) AS review_hour,
       COUNT(job_id) AS jobs_reviewed
FROM job_data
WHERE DATE(ds) BETWEEN '2020-11-01' AND '2020-11-30'
GROUP BY review_date, review_hour
ORDER BY review_date, review_hour;

/* 2. Throughput Analysis: Write an SQL query to calculate the 7-day rolling average of throughput. Additionally, explain whether you prefer using the daily metric or the 7-day rolling average for throughput, and why. */

 WITH daily_throughput AS (
    SELECT DATE(ds) AS event_date,
        COUNT(*) AS total_events,
        COUNT(*) * 1.0 / (24 * 60 * 60) AS events_per_second
    FROM job_data
    GROUP BY DATE(ds)),
rolling_avg AS (
    SELECT event_date,
        events_per_second,
        AVG(events_per_second)
        OVER (ORDER BY event_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_throughput
    FROM daily_throughput)
SELECT 
    event_date, events_per_second, rolling_avg_throughput
FROM rolling_avg
ORDER BY event_date;

/* 3. Language Share Analysis: Write an SQL query to calculate the percentage share of each language over the last 30 days.*/

WITH recent_jobs AS (
    SELECT language,
        COUNT(*) AS job_count
    FROM job_data
    WHERE DATE(ds) >= DATE_SUB('2020-12-01', INTERVAL 30 DAY) 
    GROUP BY language
),
total_jobs AS (
    SELECT SUM(job_count) AS total_job_count
    FROM recent_jobs
)
SELECT 
    language, job_count,
    ROUND((job_count * 100.0) / total_job_count, 2) AS language_share_percentage
FROM recent_jobs 
CROSS JOIN total_jobs 
ORDER BY language_share_percentage DESC;

/* 4. Duplicate Rows Detection: Write an SQL query to display duplicate rows from the job_data table.*/

-- Detecting Duplicate rows across all column

SELECT ds, job_id, actor_id, event, language, time_spent, org,
    COUNT(*) AS duplicate_rows
FROM job_data
GROUP BY ds, job_id, actor_id, event, language, time_spent, org
HAVING COUNT(*) > 1
ORDER BY duplicate_rows DESC;

-- Detecting Partial Duplicates

SELECT job_id, actor_id,
    COUNT(*) AS duplicate_rows
FROM job_data
GROUP BY job_id, actor_id
HAVING COUNT(*) > 1
ORDER BY duplicate_rows DESC;

SELECT ds, time_spent, COUNT(*)
FROM job_data
GROUP BY ds, time_spent
HAVING COUNT(*) > 1;

-- Case Study 2 - Investigating Metric Spike
-- Table 1 - Users

CREATE TABLE users(
user_id	int,
created_at varchar(100),
company_id int,
language varchar(50),
activated_at varchar(100),
state varchar(50));

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users.csv"
INTO TABLE users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM users;

-- Changing datatype of created_at coloumn (text - datetime)

ALTER TABLE users ADD COLUMN temp_created_at datetime;
UPDATE users SET temp_created_at = STR_TO_DATE(created_at, '%d-%m-%Y %H:%i');
ALTER TABLE users DROP COLUMN created_at;
ALTER TABLE users CHANGE COLUMN temp_created_at created_at datetime;

-- Changing datatype of activated_at coloumn (text - datetime)

ALTER TABLE users ADD COLUMN temp_activated_at datetime;
UPDATE users SET temp_activated_at = STR_TO_DATE(activated_at, '%d-%m-%Y %H:%i');
ALTER TABLE users DROP COLUMN activated_at;
ALTER TABLE users CHANGE COLUMN temp_activated_at activated_at datetime;

desc users;

-- Table 2 - Events
CREATE TABLE events(
user_id int, 	
occurred_at varchar(100),	
event_type varchar(50),
event_name varchar(100),
location varchar(50),
device varchar(50),
user_type int);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/events.csv"
INTO TABLE events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM events;

-- Changing datatype of occurred_at coloumn (text - datetime)

ALTER TABLE events ADD COLUMN temp_occurred_at datetime;
UPDATE events SET temp_occurred_at = STR_TO_DATE(occurred_at, '%d-%m-%Y %H:%i');
ALTER TABLE events DROP COLUMN occurred_at;
ALTER TABLE events CHANGE COLUMN temp_occurred_at occured_at datetime;
ALTER TABLE events CHANGE COLUMN occured_at occurred_at  datetime;

desc events;

-- Table 3 - Email_Events

CREATE TABLE email_events(
user_id int,
occurred_at	varchar(50),
action varchar(100),
user_type int
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/email_events.csv"
INTO TABLE email_events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM email_events;

-- Changing datatype of occurred_at coloumn (text - datetime)

ALTER TABLE email_events ADD COLUMN temp_occurred_at datetime;
UPDATE email_events SET temp_occurred_at = STR_TO_DATE(occurred_at, '%d-%m-%Y %H:%i');
ALTER TABLE email_events DROP COLUMN occurred_at;
ALTER TABLE email_events CHANGE COLUMN temp_occurred_at occured_at datetime;
ALTER TABLE email_events CHANGE COLUMN occured_at occurred_at datetime;

desc email_events;

-- Tasks 
/* 1. Weekly User Engagement: Write an SQL query to calculate the weekly user engagement.*/

SELECT COUNT(DISTINCT user_id) AS user_count,
EXTRACT(WEEK FROM occurred_at) AS weekly_engagement
FROM events
GROUP BY weekly_engagement;

/* 2. User Growth Analysis:  Write an SQL query to calculate the user growth for the product.*/

SELECT year_num, weekly_engagement, active_user, SUM(active_user)
OVER( ORDER BY year_num, weekly_engagement ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sum
FROM
(SELECT COUNT(DISTINCT user_id) AS active_user,
EXTRACT(WEEK FROM activated_at) AS weekly_engagement,
EXTRACT(YEAR FROM activated_at) AS year_num
FROM users
WHERE activated_at IS NOT NULL
GROUP BY weekly_engagement, year_num) AS user_growth;

/* 3. Weekly Retention Analysis: Write an SQL query to calculate the weekly retention of users based on their 
sign-up cohort.*/

WITH cohort AS (
    SELECT user_id,
        EXTRACT(YEAR FROM created_at) AS cohort_year,
        EXTRACT(WEEK FROM created_at) AS cohort_week
    FROM users),
weekly_activity AS (
    SELECT user_id,
        EXTRACT(YEAR FROM occurred_at) AS activity_year,
        EXTRACT(WEEK FROM occurred_at) AS activity_week
    FROM events),
retention AS (
    SELECT c.cohort_year, c.cohort_week,
        wa.activity_year, wa.activity_week,
        COUNT(DISTINCT wa.user_id) AS retained_users
    FROM cohort c
    JOIN weekly_activity wa
    ON c.user_id = wa.user_id
    GROUP BY c.cohort_year, c.cohort_week, wa.activity_year, wa.activity_week),
weekly_retention AS (
    SELECT 
        cohort_year,cohort_week,
        activity_year,activity_week,
        retained_users,
        activity_week - cohort_week AS week_number
    FROM retention
    WHERE 
        activity_year = cohort_year 
        AND activity_week >= cohort_week)
SELECT 
    cohort_year, cohort_week,
    week_number, retained_users
FROM weekly_retention
ORDER BY cohort_year, cohort_week, week_number;

/* 4. Weekly Engagement Per Device: Write an SQL query to calculate the weekly engagement per device.*/

SELECT 
    device,
    EXTRACT(YEAR FROM occurred_at) AS year,
    EXTRACT(WEEK FROM occurred_at) AS week,
    COUNT(DISTINCT user_id) AS active_user
FROM
    events
WHERE
    event_type = 'engagement'
GROUP BY device , year , week
ORDER BY device , year , week;

/* 5. Email Engagement Analysis: Write an SQL query to calculate the email engagement metrics.*/

SELECT 
    action, COUNT(*) AS total_events
FROM
    email_events
GROUP BY action;

SELECT
100.0 * SUM(CASE WHEN email_category='email_open' then 1 else 0 end)
/ SUM(CASE WHEN email_category='email_sent' then 1 else 0 end) AS open_rate,
100.0 * SUM(CASE WHEN email_category='email_click' then 1 else 0 end)
/ SUM(CASE WHEN email_category='email_sent' then 1 else 0 end) AS click_rate
FROM
(
SELECT *,
CASE
	WHEN action IN('sent_weekly_digest', 'sent_reengagement_email') THEN 'email_sent'
    WHEN action IN('email_open') THEN 'email_open'
    WHEN action IN('email_clickthrough') THEN 'email_click'
END AS email_category
FROM email_events
) AS email_metrics;
  
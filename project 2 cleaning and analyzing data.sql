-- Cleaning our data: make the email coulun in employee table look like this: first_name.last_name@ndogowater.gov
/* - selecting the employee_name column
- replacing the space with a full stop
- make it lowercase
- and stitch it all together*/
SELECT
LOWER(replace(employee_name," ",".")) -- first 2 steps
FROM md_water_services.employee;
SELECT
CONCAT(
LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov') AS new_email -- add it all together
FROM
employee;

UPDATE
employee
SET
email=CONCAT(
LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov');

-- Trim the space in the phone number so the length will be 12 rather than 13
select
length(trim(phone_number))
FROM 
 md_water_services.employee;
 
 -- Honouring the workers: 1-Use the employee table to count how many of our employees live in each town.
SELECT town_name,COUNT(town_name)  AS NUM_OF_EMPLOYEE_IN_TOWN
FROM md_water_services.employee
group by town_name
order by COUNT(town_name) DESC;
 
-- 2_send out an email or message congratulating the top 3 field surveyors.
SELECT VIS.assigned_employee_id,COUNT(VIS.assigned_employee_id) AS num_of_survey,employee_name,email,phone_number 
FROM md_water_services.visits AS VIS
JOIN md_water_services.employee AS EMP
ON VIS.assigned_employee_id=EMP.assigned_employee_id
group by assigned_employee_id
order by COUNT(assigned_employee_id) DESC
LIMIT 3;

-- Analysing locations:  
/*1. Create a result set showing:
• province_name
• town_name
• An aggregated count of records for each town (consider naming this records_per_town).
• Ensure your data is grouped by both province_name and town_name.
2. Order your results primarily by province_name. Within each province, further sort the towns by their record counts in descending order.*/
SELECT province_name,town_name,COUNT(town_name)  records_per_town
FROM md_water_services.location
group by province_name,town_name
order by  province_name,records_per_town desc;

-- the number of records for each location type
SELECT location_type,COUNT(location_type) as records_per_location
FROM md_water_services.location
group by location_type
order by  records_per_location desc;

/* Diving into the sources: 1. How many people did we survey in total?
2. How many wells, taps and rivers are there?
3. How many people share particular types of water sources on average?
4. How many people are getting water from each type of source?*/

-- 1. How many people did we survey in total?
SELECT SUM(number_of_people_served) AS total_people_num
FROM md_water_services.water_source;
-- 2. How many wells, taps and rivers are there?
SELECT * 
FROM water_source;
SELECT type_of_water_source,count(type_of_water_source) num_per_source_type
FROM md_water_services.water_source
group by type_of_water_source
order by  num_per_source_type desc;
-- 3. How many people share particular types of water sources on average?
SELECT type_of_water_source,round(avg(number_of_people_served)) avg_num_of_prople_per_source_type
FROM md_water_services.water_source
group by type_of_water_source
order by avg_num_of_prople_per_source_type   desc;
--  How many people are getting water from each type of source?
SELECT type_of_water_source,sum(number_of_people_served) num_of_prople_per_source_type 
FROM md_water_services.water_source
group by type_of_water_source
order by num_of_prople_per_source_type   desc;
-- How many people are getting water from each type of source by percentage?
WITH total_people as (
	SELECT SUM(number_of_people_served) as total_people
    FROM md_water_services.water_source
    ),
source_type as(
	SELECT type_of_water_source,sum(number_of_people_served) as  num_of_prople_per_source_type 
FROM md_water_services.water_source
group by type_of_water_source
order by num_of_prople_per_source_type   desc
)
SELECT 
	st.type_of_water_source, st.num_of_prople_per_source_type ,
     round((st.num_of_prople_per_source_type/tp.total_people)*100) as percentage
 FROM source_type AS st
 CROSS JOIN  total_people tp;
 
 -- Start of a solution: use a window function on the total people served column, converting it into a rank.
  SELECT 
    type_of_water_source,
    SUM(number_of_people_served) AS total_people_served,
    RANK() OVER (ORDER BY SUM(number_of_people_served) DESC) AS rank_sources
FROM 
    md_water_services.water_source
WHERE type_of_water_source <> 'tap_in_home'
GROUP BY 
    type_of_water_source;
    
/* So create a query to do this, and keep these requirements in mind:
1. The sources within each type should be assigned a rank.
2. Limit the results to only improvable sources.
3. Think about how to partition, filter and order the results set.
4. Order the results to see the top of the list.*/
  SELECT 
    source_id,type_of_water_source,
    SUM(number_of_people_served) AS total_people_served,
    RANK() OVER (ORDER BY SUM(number_of_people_served) DESC) AS rank_sources
FROM 
    md_water_services.water_source
WHERE type_of_water_source <> 'tap_in_home'
GROUP BY 
    type_of_water_source,source_id;
    
-- Analysing queues:1. How long did the survey take?
SELECT 
    DATEDIFF(MAX(time_of_record), MIN(time_of_record)) AS days_to_complete
FROM 
    md_water_services.visits;
-- 2. What is the average total queue time for water?
SELECT  ROUND(AVG(nullif(time_in_queue,0))) as avg_queue_time
FROM md_water_services.visits;

-- 3. What is the average queue time on different days?
SELECT DAYNAME(time_of_record) as day_of_week,ROUND(AVG(nullif(time_in_queue,0))) as avg_queue_time
FROM md_water_services.visits
GROUP BY DAYNAME(time_of_record)
ORDER BY avg_queue_time DESC;

-- 4.what time during the day people collect water.
SELECT TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,ROUND(AVG(nullif(time_in_queue,0))) as avg_queue_time
FROM md_water_services.visits
GROUP BY TIME_FORMAT(TIME(time_of_record), '%H:00') 
ORDER BY avg_queue_time DESC;

-- Write a query for average queue times for each hour in each day!
SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
-- Sunday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
ELSE NULL
END
),0) AS Sunday,
-- Monday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
ELSE NULL
END
),0) AS Monday,
-- Tuesday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
ELSE NULL
END
),0) AS Tuesday,
-- Wednesday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
ELSE NULL
END
),0) AS Wednesday,
-- Thursday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
ELSE NULL
END
),0) AS Thursday,
-- Friday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
ELSE NULL
END
),0) AS Friday,
-- Saturday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
ELSE NULL
END
),0) AS saturday
FROM
visits
WHERE
time_in_queue != 0 -- this excludes other sources with 0 queue times
GROUP BY
hour_of_day
ORDER BY
hour_of_day;
 
 
 
/*Insights
1. Most water sources are rural.
2. 43% of our people are using shared taps. 2000 people often share one tap.
3. 31% of our population has water infrastructure in their homes, but within that group, 45% face non-functional systems due to issues with pipes,
pumps, and reservoirs.
4. 18% of our people are using wells of which, but within that, only 28% are clean..
5. Our citizens often face long wait times for water, averaging more than 120 minutes.
6. In terms of queues:
- Queues are very long on Saturdays.
- Queues are longer in the mornings and evenings.
- Wednesdays and Sundays have the shortest queues.*/
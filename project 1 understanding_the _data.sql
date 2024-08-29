-- To see tables in the md_water_services 
 show tables;
 -- Dive into the water sources:in the water_source to find all the unique types of water sources
 SELECT DISTINCT
	type_of_water_source
 FROM  md_water_services.water_source;
 
 -- Unpack the visits to water sources: Which type of water sources take more than 8 hours to queue
 SELECT 
	VIS.source_id,time_in_queue,type_of_water_source,number_of_people_served
FROM md_water_services.visits AS VIS
INNER JOIN md_water_services.water_source AS SOUR
ON VIS.source_id=SOUR.source_id
WHERE time_in_queue > 480
LIMIT 10;

/* Assess the quality of water sources: write a query to find records where the subject_quality_score is 10 -- only 
looking for home taps -- and where the source
was visited a second time.*/
SELECT
	QUALITY.record_id,QUALITY.visit_count,SOUR.type_of_water_source
FROM md_water_services.water_quality AS QUALITY
JOIN md_water_services.visits AS VIS
ON VIS.record_id=QUALITY.record_id
JOIN md_water_services.water_source AS SOUR
ON VIS.source_id=SOUR.source_id
WHERE subjective_quality_score=10
AND QUALITY.visit_count =2;

-- Investigate pollution issues: write a query that checks if the results is Clean but the biological column is > 0.01.
SELECT
	*
FROM md_water_services.well_pollution
WHERE results="Clean"
and biological > 0.01
and description like "Clean%";

/*Looking at the results we can see two different descriptions that we need to fix:
1. All records that mistakenly have Clean Bacteria: E. coli should updated to Bacteria: E. coli
2. All records that mistakenly have Clean Bacteria: Giardia Lamblia should updated to Bacteria: Giardia Lamblia*/

-- Before proceeding make a copy to test if it work or not before updating
CREATE TABLE
md_water_services.well_pollution_copy
AS (
SELECT
*
FROM
md_water_services.well_pollution
);
-- Case 1a
SET SQL_SAFE_UPDATES = 0;
UPDATE
well_pollution_copy
SET
description = 'Bacteria: E. coli'
WHERE
description = 'Clean Bacteria: E. coli';
-- Case 1b
UPDATE
well_pollution_copy
SET
description='Bacteria: Giardia Lamblia'
where
description= 'Clean Bacteria: Giardia Lamblia';
 UPDATE
well_pollution_copy
SET
results = 'Contaminated: Biological'
WHERE
biological > 0.01 AND results = 'Clean'; 
-- test the result 
 SELECT
*
FROM
well_pollution_copy
WHERE
description LIKE "Clean_%"
OR (results = "Clean" AND biological > 0.01);
 
 




-- the result is 0 so apply the changes to the well_pollutuin table
-- Case 1a
SET SQL_SAFE_UPDATES = 0;
UPDATE
well_pollution
SET
description = 'Bacteria: E. coli'
WHERE
description = 'Clean Bacteria: E. coli';
-- Case 1b
UPDATE
well_pollution
SET
description = 'Bacteria: Giardia Lamblia'
WHERE
description = 'Clean Bacteria: Giardia Lamblia'  ;
 UPDATE
well_pollution
SET
results = 'Contaminated: Biological'
WHERE
biological > 0.01 AND results = 'Clean'; 
-- To test the query, The result should be zero rows
SELECT
*
FROM
well_pollution
WHERE
description LIKE "Clean_%"
OR (results = "Clean" AND biological > 0.01);



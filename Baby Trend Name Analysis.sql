USE babyname_db;
/*Project: Baby Name Trend Analysis

Objective 1: The most popular names have changed over time, and identify the names that have jumped 
the most in terms of popularity
*/
-- Girl name
SELECT Name,
	   SUM(Births) AS num_of_babies
FROM names
WHERE Gender = "F"
GROUP BY Name
ORDER BY num_of_babies DESC
LIMIT 1;

-- How "Jessica" name have changed in popularity rankings over the year
WITH girl_popularity_name AS (
	SELECT Year, Name, 
    SUM(Births) AS num_of_babies, 
    ROW_NUMBER() OVER(
		PARTITION BY Year 
        ORDER BY SUM(Births) DESC) AS name_rank
	FROM names
	WHERE Gender = 'F'
	GROUP BY Year, Name
)
SELECT * 
FROM girl_popularity_name
WHERE Name = 'Jessica';

-- Male
SELECT Name,
	   SUM(Births) AS num_of_babies
FROM names
WHERE Gender = "M"
GROUP BY Name
ORDER BY num_of_babies DESC
LIMIT 1;    

-- How "Michael" name have changed in popularity rankings over the year
WITH boy_popularity_name AS (
	SELECT Year, Name,
		   SUM(Births) AS num_of_babies,
           ROW_NUMBER() OVER (
				PARTITION BY Year
                ORDER BY SUM(Births) DESC
		    ) AS name_rank
	FROM names
    WHERE Gender = 'M'
    GROUP BY Year, Name
)
SELECT *
FROM boy_popularity_name
WHERE Name = 'Michael';

-- Name that have the biggest jumps in popularity from 1980 to 2009
WITH name_1980 AS (
	SELECT Year, Name,
		   SUM(Births) AS num_of_babies,
           ROW_NUMBER() OVER (
				PARTITION BY Year
                ORDER BY SUM(Births) DESC
			) AS popular_name
	FROM names
	WHERE Year = 1980
    GROUP BY Year, Name
),
name_2009 AS (
	SELECT Year, Name,
           SUM(Births) AS num_of_babies,
           ROW_NUMBER() OVER (
				PARTITION BY Year
                ORDER BY SUM(Births) DESC
			) AS popular_name
	FROM names
    WHERE Year = 2009
    GROUP BY Year, Name
)
SELECT t1.Year, t1.Name, t1.popular_name,
	   t2.Year, t2.Name, t2.popular_name,
       CAST(t2.popular_name AS SIGNED) - CAST(t1.popular_name AS SIGNED) AS diff
FROM name_1980 AS t1
INNER JOIN name_2009 AS t2
ON t1.Name = t2.Name
ORDER BY diff;

/*Objective 2: Top 3 girl names, Top 3 boy names for each year and for each decade */
WITH gender_ranking AS (
	SELECT Year, Name, Gender,
		   SUM(Births) AS num_of_babies,
           ROW_NUMBER() OVER (
				PARTITION BY Year, Gender
                ORDER BY SUM(Births) DESC
			) AS popular_rank
	FROM names
    GROUP BY Year, Name, Gender
    ORDER BY Year, SUM(Births) DESC
)
SELECT Year, Name, Gender, popular_rank
FROM gender_ranking
WHERE popular_rank IN (1,2,3) AND Gender = 'F';
-- Boys name: Replace Gender with M
SELECT Year, Name, Gender, popular_rank
FROM gender_ranking
WHERE popular_rank IN (1,2,3) AND Gender = 'M';

-- For each decade
SELECT * FROM (
	WITH decade_ranking AS (
		SELECT CASE
			WHEN Year BETWEEN 1980 AND 1990 THEN '80s'
            WHEN Year BETWEEN 1990 AND 1999 THEN '90s'
            WHEN Year BETWEEN 2000 AND 2010 THEN '2000'
            ELSE 'No Year Found'
		END AS Decade,
			   Name, Gender,
               SUM(Births) AS num_of_babies
        FROM names
        GROUP BY Decade, Name, Gender
        ORDER BY Decade, SUM(Births) DESC
)
		SELECT Decade, Name, Gender, num_of_babies,
			ROW_NUMBER() OVER (
				PARTITION BY Decade, Gender
				ORDER BY num_of_babies DESC
			) AS popular_rank
		FROM decade_ranking
) AS top_three
WHERE popular_rank IN (1,2,3) AND Gender = 'M'
ORDER BY Decade;

/*Objective 3: Number of babies born in each region, Top 3 girl names and Top 3 boy names within each region */
SELECT * FROM regions;
SELECT * FROM final_regions;
DROP TABLE IF EXISTS final_regions;
CREATE TEMPORARY TABLE final_regions
SELECT State,
	   CASE WHEN Region = 'New England' THEN 'New England'
       ELSE Region
       END AS final_region
FROM regions
UNION
SELECT 'MI' AS State, 'Midwest' AS Region;

SELECT COUNT(DISTINCT final_region) FROM final_regions; -- 6 region
SELECT DISTINCT State FROM final_regions WHERE final_region = 'Midwest';-- check MI in Midwest region or No

SELECT 
	DISTINCT names.state, 
    final_regions.final_region
FROM names 
	LEFT JOIN final_regions
		ON final_regions.state = names.state
; -- check MI by join both table

SELECT 
	final_regions.final_region,
	SUM(Names.Births) AS num_of_babies
FROM final_regions 
	INNER JOIN names
		ON final_regions.state = names.state
GROUP BY final_region
ORDER BY SUM(Names.Births) DESC;
-- Top 3 girl, boy names by region
WITH name_by_region AS (
	SELECT final_region, Name, Gender,
		   SUM(names.Births) AS num_of_babies
	FROM names
    INNER JOIN final_regions ON names.State = final_regions.State
    GROUP BY final_region, Name, Gender
    ORDER BY SUM(names.Births) DESC
),
region_gender_popularity AS (
	SELECT final_region, Name, Gender,
		   ROW_NUMBER() OVER (
				PARTITION BY final_region, Gender
                ORDER BY num_of_babies DESC
			) AS gender_popularity
	FROM name_by_region
)
SELECT * FROM region_gender_popularity
WHERE gender_popularity IN (1,2,3) AND Gender = 'F'; -- Replace with 'M' to see boy names

/*Objective 4: The most popular androgynous names, the shortest and longest names, 
and the state with the highest percent of babies named "Chris"
*/
-- Top 10 androgynous names (both female and male gender)
SELECT Name,
	   COUNT(DISTINCT Gender) AS gender,
       SUM(Births) AS num_of_babies
FROM names
GROUP BY Name
HAVING gender > 1
ORDER BY SUM(Births) DESC
LIMIT 10;

-- The shortest and longest name
SELECT Name,
	   SUM(Births) AS num_of_babies,
       DENSE_RANK() OVER (ORDER BY SUM(Births) DESC) AS length_rank
FROM names
WHERE LENGTH(Name) = 
(SELECT MIN(LENGTH(Name))
FROM names)
GROUP BY Name;
-- Longest name
SELECT Name,
	   SUM(Births) AS num_of_babies,
       DENSE_RANK() OVER(ORDER BY SUM(Births) DESC) AS length_rank
FROM names
WHERE LENGTH(Name) =
(SELECT MAX(LENGTH(Name))
FROM names)
GROUP BY Name;

-- Percent of babies named "Chris"
-- Step 1: Count the total Chris name in each state
WITH chris_name AS (
	SELECT State,
		   SUM(Births) AS num_of_chris
	FROM names
    WHERE Name = 'Chris'
    GROUP BY State
),
-- Step 2: Count the total names in each state
total_name AS (
	SELECT State,
		   SUM(Births) AS num_of_babies
	FROM names
    GROUP BY State
)
-- Step 3: Find percentage (number of Chris name divided by total names)
SELECT total_name.State,
	   (num_of_chris/num_of_babies)*100 AS pct_of_chris_name
FROM total_name
INNER JOIN chris_name
ON total_name.State = chris_name.State
ORDER BY pct_of_chris_name DESC;
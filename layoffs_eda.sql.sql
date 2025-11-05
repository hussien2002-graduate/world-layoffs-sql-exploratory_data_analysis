-- =============================================================================
-- EDA: Explore layoffs data for trends, outliers, and top contributors
-- Source table used throughout: world_layoffs.layoffs_staging2
-- NOTE: One query references world_layoffs.layoffs_staging (without the "2").
--       Leaving it as-is per your request (no code changes).
-- =============================================================================


-- ----------------------------------------------------------------------------- 
-- 0) QUICK SCAN OF THE TABLE
-- Purpose: sanity-check columns and a few sample rows
-- -----------------------------------------------------------------------------
SELECT * 
FROM world_layoffs.layoffs_staging2;



-- ----------------------------------------------------------------------------- 
-- 1) BASIC RANGE CHECKS
-- Purpose: get a feel for magnitudes (max layoffs; min/max % laid off)
-- -----------------------------------------------------------------------------

-- Max total layoffs observed (single record)
SELECT MAX(total_laid_off)
FROM world_layoffs.layoffs_staging2;

-- Min/Max percentage laid off (ignoring NULLs)
SELECT MAX(percentage_laid_off), MIN(percentage_laid_off)
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off IS NOT NULL;



-- ----------------------------------------------------------------------------- 
-- 2) 100% LAYOFF EVENTS
-- Purpose: find records where the company effectively shut down (percentage=1)
-- -----------------------------------------------------------------------------

-- All companies with percentage_laid_off = 1 (i.e., 100%)
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1;

-- Same cohort, ordered by funds raised to see scale of companies impacted
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;



-- ----------------------------------------------------------------------------- 
-- 3) TOP CONTRIBUTORS (GROUP BY AGGREGATIONS)
-- Purpose: identify largest layoffs by company, location, country, year, industry, stage
-- NOTE: The first query uses world_layoffs.layoffs_staging (no "2") exactly as provided.
-- -----------------------------------------------------------------------------

-- 3a) Companies with the biggest single-day layoff (TOP 5 by a single record)
SELECT company, total_laid_off
FROM world_layoffs.layoffs_staging
ORDER BY 2 DESC
LIMIT 5;

-- 3b) Companies with the most total layoffs (all time in dataset)
SELECT company, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;

-- 3c) Locations with the most total layoffs
SELECT location, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;

-- 3d) Countries with the most total layoffs
SELECT country, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- 3e) Yearly totals (chronological to see trend)
SELECT YEAR(date), SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 ASC;

-- 3f) Industries with the most total layoffs
SELECT industry, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- 3g) Company stage with the most total layoffs
SELECT stage, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;



-- ----------------------------------------------------------------------------- 
-- 4) HARDER ANALYSIS: TOP COMPANIES PER YEAR
-- Purpose: rank companies within each year by total layoffs, then keep Top 3
-- Approach: CTE (company-year sums) + window function (DENSE_RANK)
-- -----------------------------------------------------------------------------
WITH Company_Year AS 
(
  SELECT 
    company, 
    YEAR(date) AS years, 
    SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
),
Company_Year_Rank AS 
(
  SELECT 
    company, 
    years, 
    total_laid_off, 
    DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT 
  company, 
  years, 
  total_laid_off, 
  ranking
FROM Company_Year_Rank
WHERE ranking <= 3
  AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;



-- ----------------------------------------------------------------------------- 
-- 5) TIME SERIES: MONTHLY TOTALS & ROLLING CUMULATIVE
-- Purpose: monthly aggregation and an ever-increasing total to show trend shape
-- NOTE: SUBSTRING(date,1,7) implies "date" may be TEXT 'YYYY-MM-DD'. Left as-is.
-- -----------------------------------------------------------------------------

-- 5a) Monthly totals (YYYY-MM)
SELECT 
  SUBSTRING(date,1,7) AS dates, 
  SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC;

-- 5b) Rolling (cumulative) monthly total using a CTE
WITH DATE_CTE AS 
(
  SELECT 
    SUBSTRING(date,1,7) AS dates, 
    SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY dates
  ORDER BY dates ASC
)
SELECT 
  dates, 
  SUM(total_laid_off) OVER (ORDER BY dates ASC) AS rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;

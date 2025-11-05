# world-layoffs-sql-exploratory_data_analysis
This project performs an exploratory data analysis (EDA) on the global layoffs dataset to uncover patterns, trends, and insights about workforce reductions across industries, companies, and countries.
The goal is to understand the scale, distribution, and evolution of layoffs using SQL-based data exploration techniques.

Project Overview

The dataset contains reported layoffs from companies worldwide

This analysis focuses on identifying:
The largest layoffs recorded in the dataset.
Companies that experienced 100% workforce reductions (closures).
Layoff totals by company, country, industry, and funding stage.
Yearly and monthly trends in layoffs.
A rolling cumulative total of layoffs over time.
Each query was designed to build a deeper understanding of how layoffs evolved over time and which sectors were most affected.

Database & Table
All analysis is performed on the table:
world_layoffs.layoffs_staging2


Key columns used:
company
location
country
industry
stage
date
total_laid_off
percentage_laid_off
funds_raised_millions

Main SQL Steps
1. Initial Exploration

Checked data shape and magnitude:

SELECT * FROM world_layoffs.layoffs_staging2;
SELECT MAX(total_laid_off), MAX(percentage_laid_off) FROM world_layoffs.layoffs_staging2;

2. Extreme Cases

Identified companies that had 100% layoffs (went out of business):

SELECT * 
FROM world_layoffs.layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

3. Aggregations

Grouped totals by company, location, country, year, industry, and stage to reveal concentration patterns:

SELECT country, SUM(total_laid_off)
FROM world_layoffs.layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

4. Rankings by Year

Used CTEs and the DENSE_RANK() window function to find the top 3 companies per year with the highest layoffs:

WITH Company_Year AS (
  SELECT company, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(date)
),
Company_Year_Rank AS (
  SELECT company, years, total_laid_off,
         DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT * FROM Company_Year_Rank WHERE ranking <= 3;

5. Rolling Monthly Totals

Built a rolling cumulative view of layoffs over time:

WITH DATE_CTE AS (
  SELECT SUBSTRING(date,1,7) AS dates, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY dates
)
SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) AS rolling_total_layoffs
FROM DATE_CTE;

Insights Gained

Layoffs peaked in certain years (especially 2022) across major tech and startup sectors.
Several companies raised millions in funding yet still closed, showing volatility in the startup ecosystem.
The United States and technology hubs like San Francisco and London dominate layoff counts.
Early-stage and growth-stage companies saw the highest percentage-based layoffs.
A clear rolling upward trend shows that layoffs accelerated during the later years of the dataset.

Key SQL Concepts Demonstrated

Exploratory analysis using aggregate and window functions
Data ranking and filtering using CTEs
Monthly trend analysis and rolling cumulative totals
Identifying edge cases and outliers with logical filters

Next Steps
Build a Power BI or Tableau dashboard using this cleaned data.
Compare layoffs by sector to stock market trends.
Extend analysis with additional features such as company size or employee count.

Author
Hussien Abdelhamid
Mechatronics Engineer | Data Analytics Enthusiast

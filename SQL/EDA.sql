-- View the cleaned COVID deaths table (only actual countries, not aggregates like 'World')
SELECT * 
FROM coviddeaths 
WHERE continent IS NOT NULL 
ORDER BY location, date;

-- Preview the COVID vaccination data
SELECT * 
FROM covidvacc 
ORDER BY location, date;


-- Select essential columns to analyze spread and impact
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY location, date;


-- Change data types from string (VARCHAR) to FLOAT for calculations
ALTER TABLE coviddeaths MODIFY COLUMN total_deaths FLOAT;
ALTER TABLE coviddeaths MODIFY COLUMN new_deaths FLOAT;


-- Casting as signed integer (positive & negative numbers)
SELECT CAST(total_deaths AS SIGNED) FROM coviddeaths;

-- Casting as unsigned integer (only positive numbers)
SELECT CAST(total_deaths AS UNSIGNED) FROM coviddeaths;


-- CTE to calculate death percentage globally per country
WITH CTE_COVID_DEATHS AS (
  SELECT location,
         SUM(total_cases) AS total_cases_,
         SUM(total_deaths) AS total_deaths_,
         (SUM(total_deaths) / SUM(total_cases)) * 100 AS death_percentage
  FROM coviddeaths
  WHERE continent IS NOT NULL
  GROUP BY location
)

-- Find the country with highest death percentage
SELECT location, death_percentage
FROM CTE_COVID_DEATHS
WHERE death_percentage = (
  SELECT MAX(death_percentage) FROM CTE_COVID_DEATHS
);


-- Average death rate across all countries
SELECT AVG((total_deaths / total_cases) * 100) AS avg_death_percentage
FROM coviddeaths
WHERE continent IS NOT NULL 
  AND total_cases IS NOT NULL 
  AND total_deaths IS NOT NULL;


-- India's death percentage over time
SELECT location, date, total_cases, total_deaths,
       (total_deaths / total_cases) * 100 AS death_percentage
FROM coviddeaths
WHERE continent IS NOT NULL
  AND total_deaths IS NOT NULL
  AND location = 'India';

-- India: percentage of population infected
SELECT location, date, population, total_cases,
       (total_cases / population) * 100 AS percentage_of_population
FROM coviddeaths
WHERE continent IS NOT NULL
  AND total_deaths IS NOT NULL
  AND location = 'India'
ORDER BY total_cases DESC;

-- Maximum cases recorded on a single day in India
SELECT MAX(total_cases) FROM coviddeaths WHERE location = 'India';


SELECT date, total_cases
FROM coviddeaths
WHERE location = 'India'
ORDER BY total_cases DESC
LIMIT 1;


-- Countries with highest number of cases (and what % of their population got infected)
SELECT location, population,
       MAX(total_cases) AS highest_infection_count,
       MAX((total_cases / population)) * 100 AS percent_population
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY highest_infection_count DESC;



-- For continents (or aggregates like World), since continent is NULL
SELECT location, MAX(total_deaths) AS total_death_count
FROM coviddeaths
WHERE continent IS NULL AND location NOT IN ('World', 'International')
GROUP BY location
ORDER BY total_death_count DESC;


SELECT location,
       MAX(total_deaths / population) * 100 AS death_count_per_population
FROM coviddeaths
WHERE continent IS NULL
  AND location NOT IN ('World', 'International')
GROUP BY location
ORDER BY death_count_per_population DESC;

-- This shows cumulative new cases and deaths per country per day
SELECT location, date,
       SUM(new_cases) AS total_cases,
       SUM(new_deaths) AS total_deaths
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location, date
ORDER BY location, date;

-- Find the first date when deaths were reported in Afghanistan
SELECT location, date,
       SUM(new_cases) AS total_cases,
       SUM(new_deaths) AS total_deaths
FROM coviddeaths
WHERE continent IS NOT NULL
  AND location = 'Afghanistan'
GROUP BY location, date
HAVING SUM(new_deaths) != 0
ORDER BY date
LIMIT 1;


-- Join deaths & vaccinations data to calculate vaccination percentage
SELECT cd.continent, cd.location, cd.date, cd.population,
       (CAST(cv.new_vaccinations AS UNSIGNED) / cd.population) * 100 AS new_vacc_percentage
FROM coviddeaths cd
JOIN covidvacc cv ON cd.date = cv.date AND cd.location = cv.location
WHERE cd.continent IS NOT NULL
ORDER BY cd.continent, new_vacc_percentage DESC;


-- Rolling sum of vaccinations per country
CREATE OR REPLACE VIEW percent_population AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
       SUM(CAST(cv.new_vaccinations AS UNSIGNED))
         OVER (PARTITION BY cd.location ORDER BY cd.date)
         AS rolling_people_vaccinated
FROM coviddeaths cd
JOIN covidvacc cv ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;


SELECT *, 
       (rolling_people_vaccinated / population) * 100 AS percent_vaccinated
FROM percent_population
ORDER BY location, date;


-- Create and populate a temp table to allow for filtering, plotting, etc.
CREATE TEMPORARY TABLE percent_population_temp (
  continent VARCHAR(50),
  location VARCHAR(50),
  date DATE,
  population INT,
  new_vaccinations INT,
  rolling_people_vaccinated BIGINT
);

INSERT INTO percent_population_temp
SELECT cd.continent, cd.location, cd.date, cd.population,
       CAST(cv.new_vaccinations AS UNSIGNED),
       SUM(CAST(cv.new_vaccinations AS UNSIGNED))
         OVER (PARTITION BY cd.location ORDER BY cd.date) AS rolling_people_vaccinated
FROM coviddeaths cd
JOIN covidvacc cv ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, cd.date;

-- View the final result
SELECT * FROM percent_population_temp;


SELECT location, date, new_cases
FROM coviddeaths
WHERE new_cases IS NOT NULL
ORDER BY new_cases DESC
LIMIT 10;

SELECT location,
       (total_recovered / total_cases) * 100 AS recovery_rate
FROM coviddeaths
WHERE total_cases IS NOT NULL AND total_recovered IS NOT NULL
ORDER BY recovery_rate DESC;

SELECT date, new_vaccinations
FROM covidvacc
WHERE location = 'India'
ORDER BY date;

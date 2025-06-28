-- COVID-19 Data Exploration Project (MySQL Version)
-- Skills Used: Joins, CTEs, Temp Tables, Window Functions, Aggregate Functions, Views, Type Conversions

-- 1. View cleaned COVID deaths data (excluding null continents, i.e., only countries)
SELECT * 
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY location, date;


-- 2. Selecting essential columns to start with
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM coviddeaths
WHERE continent IS NOT NULL
ORDER BY location, date;


-- 3. Total Cases vs Total Deaths
-- Calculates the likelihood of dying if infected, specific to a country (e.g., United States)
SELECT location, date, total_cases, total_deaths,
       (total_deaths / NULLIF(total_cases, 0)) * 100 AS death_percentage
FROM coviddeaths
WHERE location LIKE '%states%'
  AND continent IS NOT NULL
ORDER BY location, date;


-- 4. Total Cases vs Population
-- Shows what percentage of the population has been infected
SELECT location, date, population, total_cases,
       (total_cases / NULLIF(population, 0)) * 100 AS percent_population_infected
FROM coviddeaths
ORDER BY location, date;


-- 5. Countries with Highest Infection Rates relative to population
SELECT location, population,
       MAX(total_cases) AS highest_infection_count,
       MAX((total_cases / NULLIF(population, 0))) * 100 AS percent_population_infected
FROM coviddeaths
GROUP BY location, population
ORDER BY percent_population_infected DESC;


-- 6. Countries with the Highest Death Count (raw numbers)
SELECT location,
       MAX(CAST(total_deaths AS UNSIGNED)) AS total_death_count
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;


-- 7. Breakdown by Continent: Total Deaths
SELECT continent,
       MAX(CAST(total_deaths AS UNSIGNED)) AS total_death_count
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;


-- 8. Global Summary: Total Cases, Total Deaths, Global Death Percentage
SELECT 
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths,
    (SUM(CAST(new_deaths AS UNSIGNED)) / NULLIF(SUM(new_cases), 0)) * 100 AS global_death_percentage
FROM coviddeaths
WHERE continent IS NOT NULL;


-- 9. Rolling Vaccinations by Country
-- Using a window function to show the running total of people vaccinated
SELECT 
    cd.continent, cd.location, cd.date, cd.population,
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS UNSIGNED)) 
        OVER (PARTITION BY cd.location ORDER BY cd.date) AS rolling_people_vaccinated
FROM coviddeaths cd
JOIN covidvaccinations cv
  ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, cd.date;


-- 10. CTE to calculate percent of population vaccinated (rolling)
WITH pop_vs_vac AS (
  SELECT 
      cd.continent, cd.location, cd.date, cd.population,
      cv.new_vaccinations,
      SUM(CAST(cv.new_vaccinations AS UNSIGNED)) 
          OVER (PARTITION BY cd.location ORDER BY cd.date) AS rolling_people_vaccinated
  FROM coviddeaths cd
  JOIN covidvaccinations cv
    ON cd.location = cv.location AND cd.date = cv.date
  WHERE cd.continent IS NOT NULL
)
SELECT *,
       (rolling_people_vaccinated / NULLIF(population, 0)) * 100 AS percent_vaccinated
FROM pop_vs_vac;


-- 11. Temp Table for calculating vaccination % per country
-- Temp tables are session-specific and allow for easier reuse in reporting
DROP TEMPORARY TABLE IF EXISTS percent_population_vaccinated;

CREATE TEMPORARY TABLE percent_population_vaccinated (
  continent VARCHAR(255),
  location VARCHAR(255),
  date DATE,
  population BIGINT,
  new_vaccinations BIGINT,
  rolling_people_vaccinated BIGINT
);

-- Inserting data into temp table
INSERT INTO percent_population_vaccinated
SELECT 
    cd.continent, cd.location, cd.date, cd.population,
    CAST(cv.new_vaccinations AS UNSIGNED),
    SUM(CAST(cv.new_vaccinations AS UNSIGNED)) 
        OVER (PARTITION BY cd.location ORDER BY cd.date) AS rolling_people_vaccinated
FROM coviddeaths cd
JOIN covidvaccinations cv
  ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;

-- Viewing results from the temp table with % vaccinated
SELECT *,
       (rolling_people_vaccinated / NULLIF(population, 0)) * 100 AS percent_vaccinated
FROM percent_population_vaccinated;


-- 12. Creating a reusable view for percent vaccinated over time
-- Views are useful for BI tools like Power BI / Tableau
CREATE OR REPLACE VIEW percent_population_vaccinated_view AS
SELECT 
    cd.continent, cd.location, cd.date, cd.population,
    cv.new_vaccinations,
    SUM(CAST(cv.new_vaccinations AS UNSIGNED)) 
        OVER (PARTITION BY cd.location ORDER BY cd.date) AS rolling_people_vaccinated
FROM coviddeaths cd
JOIN covidvaccinations cv
  ON cd.location = cv.location AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;

SELECT *
FROM CovidDataAnalysis..CovidDeaths
ORDER BY 3,4; -- this means order my column 3, column 4

SELECT *
FROM CovidDataAnalysis..CovidVaccinations
ORDER BY 3,4;

SELECT *
FROM CovidDataAnalysis..CovidDeaths
WHERE location = 'China'
ORDER BY 4;

-- Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDataAnalysis..CovidDeaths
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid-19
SELECT location, date, total_cases, total_deaths, CAST((total_deaths/total_cases)*100 AS DECIMAL(10,2)) AS Death_Percentage
FROM CovidDataAnalysis..CovidDeaths
ORDER BY 1,2;

-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid-19
SELECT location, date, population, total_cases, CAST((total_cases/population)*100 AS DECIMAL(10,2)) AS Infection_Rate
FROM CovidDataAnalysis..CovidDeaths
WHERE location = 'Australia'
ORDER BY 1,2;

-- Looking at Countries with Highest Infection Rate compared to population
-- Shows the infection rate of each country
SELECT location, population, MAX(total_cases) as total_cases_to_date, MAX((total_cases/population))*100 AS Infection_Rate
FROM CovidDataAnalysis..CovidDeaths
GROUP BY location, population -- group rows with same values
ORDER BY Infection_Rate DESC

-- Showing Countries with Highest Death Counts 
SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_counts
FROM CovidDataAnalysis..CovidDeaths
WHERE continent IS NOT NULL -- get rid of continents
GROUP BY location
ORDER BY total_death_counts DESC

-- Death Counts by continents
SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_counts
FROM CovidDataAnalysis..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_counts DESC

-- Death rates vs total cases for different countries
SELECT location, MAX(total_cases) AS Case_count, MAX(total_deaths) AS death_count, 
CAST((MAX(total_deaths)/MAX(total_cases))*100 AS DECIMAL(10,2)) AS Death_Rate_Per_Case
FROM CovidDataAnalysis..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Death_Rate_Per_Case DESC

-- Global Numbers New Cases and New Deaths Each Day
SELECT CAST(date AS DATE) AS time, SUM(CAST(new_cases AS INT)) AS new_cases, SUM(CAST(new_deaths AS INT)) AS new_deaths, 
CAST(SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DECIMAL(10,2)) AS death_percentage -- can use CTE
FROM CovidDataAnalysis..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

-- Global Numbers Total 
SELECT CAST(date AS DATE) AS time, SUM(CAST(total_cases AS INT)) AS total_cases, SUM(CAST(total_deaths AS INT)) AS total_deaths, 
CAST(SUM(CAST(total_deaths AS INT))/SUM(total_cases)*100 AS DECIMAL(10,2)) AS death_percentage
FROM CovidDataAnalysis..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1

-- Join two tables
-- Looking at Total Population vs Vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS total_vaccinated -- to use total_vaccinated in other calculations, a CTE or TEMP TABLE can be used, examples below
FROM CovidDataAnalysis..CovidDeaths dea -- set table name as dea
JOIN CovidDataAnalysis..CovidVaccinations vac -- set table name as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
AND vac.new_vaccinations IS NOT NULL
ORDER BY 2,3


-- USE CTE:common_table_expression
WITH POPvsVAC (continent, location, date, population, new_vaccination, total_vaccinated) 
AS (
SELECT dea.continent, dea.location, CONVERT(date,dea.date), dea.population, vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS total_vaccinated
FROM CovidDataAnalysis..CovidDeaths dea -- set table name as dea
JOIN CovidDataAnalysis..CovidVaccinations vac -- set table name as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
AND vac.new_vaccinations IS NOT NULL
)
SELECT *, CONVERT(DECIMAL(10,3),(total_vaccinated/population)*100) AS vac_rate
FROM POPvsVAC
ORDER BY 2,3

-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated ( -- #table means temporary  table
	continent NVARCHAR(255),
	location NVARCHAR(255), 
	date DATE, 
	population NUMERIC, 
	new_vaccination NUMERIC, 
	total_vaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, CONVERT(date,dea.date), dea.population, vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS total_vaccinated
FROM CovidDataAnalysis..CovidDeaths dea -- set table name as dea
JOIN CovidDataAnalysis..CovidVaccinations vac -- set table name as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
AND vac.new_vaccinations IS NOT NULL

SELECT *, CONVERT(DECIMAL(10,3),(total_vaccinated/population)*100) AS vac_rate
FROM #PercentPopulationVaccinated
ORDER BY 2,3
-- vac_rate could over 100% as new_vaccination did not specify whether it was 1st or 2nd jab


-- Creating View to store data for later visualisation
DROP VIEW IF EXISTS PercentPopulationVaccinated
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS total_vaccinated
FROM CovidDataAnalysis..CovidDeaths dea -- set table name as dea
JOIN CovidDataAnalysis..CovidVaccinations vac -- set table name as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
AND vac.new_vaccinations IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated
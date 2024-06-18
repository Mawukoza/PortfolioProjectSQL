SELECT * 
FROM covid_vaccinations
LIMIT 100;

SELECT * 
FROM covid_deaths
LIMIT 100;

-- Total Cases vs Total Deaths
-- Percentage of deaths from covid
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	ROUND((total_deaths * 1.0 / total_cases) * 100, 5) AS death_percentage 
FROM covid_deaths
WHERE location = 'Ghana'
AND continent IS NOT NULL
ORDER BY location, date;


-- Total Cases vs Population
-- Percentage of population that contracted covid
SELECT 
	location, 
	date, 
	total_cases, 
	population, 
	(total_cases * 1.0 / population) * 100 AS covid_percentage 
FROM covid_deaths
-- WHERE location = 'Ghana'
WHERE continent IS NOT NULL
ORDER BY location, date;


-- Countries with Highest Infection Rate compared to Population
SELECT 
	location,   
	population,
	MAX(total_cases) AS highest_infection_count,
	MAX(total_cases * 1.0 / population) * 100 AS percent_population_infected
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC;


-- Showing countries with highest fatalities
SELECT location, MAX(total_deaths) AS highest_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
HAVING MAX(total_deaths) IS NOT NULL
ORDER BY highest_death_count DESC;


-- Continents with the highest death count
SELECT location, MAX(total_deaths) AS highest_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
HAVING MAX(total_deaths) IS NOT NULL
ORDER BY highest_death_count DESC;


-- Global numbers
SELECT
	date,
	SUM(new_cases) AS total_new_cases, 
	SUM(new_deaths) AS total_new_deaths, 
	SUM(total_deaths) AS total_global_deaths
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
HAVING SUM(total_deaths) IS NOT NULL
ORDER BY total_new_cases DESC;


-- Global percentage deaths
SELECT
	date,
	SUM(new_cases) AS total_cases, 
	SUM(new_deaths) AS total_deaths,
	ROUND(
	CASE
		WHEN SUM(new_cases) = 0 THEN  0
		ELSE (SUM(new_deaths)/SUM(new_cases)) * 100 
	END, 2
	) AS total_global_deaths_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
HAVING SUM(total_deaths) IS NOT NULL
ORDER BY total_cases DESC;


-- Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_tests,
	SUM(vac.new_tests) OVER (PARTITION BY dea.location ORDER BY dea.date) AS people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac USING (iso_code, continent, location, date)
WHERE new_tests IS NOT NULL
ORDER BY 2, 3;


-- Use CTEs(Common Table Expressions)
WITH pop_vs_vac (continent, location, date, population, new_tests, people_vaccinated) 
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_tests,
	SUM(vac.new_tests) OVER (PARTITION BY dea.location ORDER BY dea.date) AS people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac USING (iso_code, continent, location, date)
WHERE new_tests IS NOT NULL
)
SELECT *, (people_vaccinated/population) * 100 AS percent_vaccinated
FROM pop_vs_vac;


-- Temp Table
DROP TABLE IF EXISTS percent_population_vaccinated;

CREATE TEMP TABLE percent_population_vaccinated (
	continent VARCHAR(50),
	location VARCHAR(100),
	date DATE,
	population BIGINT,
	new_tests BIGINT,
	people_vaccinated INT
);

INSERT INTO percent_population_vaccinated (continent, location, date, population, new_tests, people_vaccinated)
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_tests,
	SUM(vac.new_tests) OVER (PARTITION BY dea.location ORDER BY dea.date) AS people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac USING (iso_code, continent, location, date)
WHERE vac.new_tests IS NOT NULL;

ALTER TABLE percent_population_vaccinated
ADD COLUMN percent_vaccinated FLOAT;  

UPDATE percent_population_vaccinated
SET percent_vaccinated = (people_vaccinated::FLOAT / population) * 100;

SELECT *
FROM percent_population_vaccinated;


-- Creating View to Store Data for later visualizations
CREATE VIEW percent_population_vaccinated AS
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_tests,
	SUM(vac.new_tests) OVER (PARTITION BY dea.location ORDER BY dea.date) AS people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac USING (iso_code, continent, location, date)
WHERE vac.new_tests IS NOT NULL;
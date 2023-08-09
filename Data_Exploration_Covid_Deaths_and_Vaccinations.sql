--SELECT Location, date, total_cases, new_cases,total_deaths,population
--FROM CovidDeaths
--WHERE POPULATION IS NOT NULL and location = 'Peru'
--order by 1,2

-- Looking at total cases vs total deaths in perú
-- Shows likelihood of dying if you contract covid in Perú
SELECT Location, date, total_cases,total_deaths,ROUND((CAST(total_deaths AS decimal) /CAST(total_cases AS decimal) )*100,4) as DeathPercentage
FROM CovidDeaths
WHERE POPULATION IS NOT NULL and location = 'Peru'
order by 1,2

-- Looking at total cases vs Population in perú
--Show what percentage of the Population got covid
SELECT Location, date, total_cases,Population,ROUND((CAST(total_cases AS decimal)/Population )*100,4) as PercentageOfPopulationInfected
FROM CovidDeaths
WHERE POPULATION IS NOT NULL and location = 'Cyprus'
order by 1,2

--Looking at countries with highest Infection Rate compared with Population
SELECT Location,Population,MAX(CAST(total_cases AS int)),MAX(ROUND((CAST(total_cases AS decimal)/Population )*100,4)) as MaxPercentageOfPopulationInfected
FROM CovidDeaths
GROUP BY Location,Population
ORDER BY MaxPercentageOfPopulationInfected DESC

--Showing countries with higtest Death Count per Population
SELECT continent,MAX(CAST(total_deaths AS int)) AS TotalDeaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeaths DESC


--WORLD NUMBERS
SELECT date , 
SUM(CAST(new_cases AS int)) AS total_cases ,
SUM(CAST(new_deaths AS int)) as total_deaths,
CASE 
	WHEN SUM(CAST(new_cases AS int)) = 0 OR SUM(CAST(new_cases AS int)) IS NULL THEN 0
    ELSE SUM(CAST(new_deaths AS decimal)) / SUM(CAST(new_cases AS decimal)) * 100      
END AS death_percentage
FROM CovidDeaths
WHERE POPULATION IS NOT NULL
GROUP BY date
order by 1,2

--Looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER(PARTITION BY dea.location  ORDER BY dea.location, dea.date) as total_amount_of_vaccination
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location=vac.location 
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
AND  dea.population IS NOT NULL
ORDER BY 2,3

--Creamos un CTE:
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccionations, Total_amount_of_vaccination)
AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER(PARTITION BY dea.location  ORDER BY dea.location, dea.date) as total_amount_of_vaccination
	FROM CovidDeaths dea
	JOIN CovidVaccinations vac
		ON dea.location=vac.location 
		AND dea.date=vac.date
	WHERE dea.continent IS NOT NULL
	AND  dea.population IS NOT NULL
)
SELECT * , (Total_amount_of_vaccination/Population)*100
FROM PopvsVac
ORDER BY 2,3

--Hacemos lo mismo pero creando una tabla temporal

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
total_amount_of_vaccination numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER(PARTITION BY dea.location  ORDER BY dea.location, dea.date) as total_amount_of_vaccination
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location=vac.location 
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
AND  dea.population IS NOT NULL

SELECT * , (Total_amount_of_vaccination/Population)*100
FROM #PercentPopulationVaccinated
ORDER BY 2,3


--Creating view to store data for later visualizations
CREATE VIEW V_PopulationVaccinated 
AS SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER(PARTITION BY dea.location  ORDER BY dea.location, dea.date) as total_amount_of_vaccination
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location=vac.location 
	AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
AND  dea.population IS NOT NULL;


/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/



SELECT * FROM PortfolioProject..CovidDeaths 
where continent is not null 
Order by 3, 4



-- Select data that I'm going to be using.

SELECT Location, date, total_cases, new_cases,total_deaths, population 
FROM PortfolioProject..CovidDeaths 
where continent is not null 
ORDER BY 1, 2



-- Total Cases vs. Total Deaths in the US
-- Shows likelihood of dying if you contract covid in the US

SELECT Location, date, total_cases, total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 as DeathPercentage
FROM PortfolioProject..CovidDeaths 
Where location like '%states%' and total_cases is not null
ORDER BY 1, 2


-- Total Cases vs. Total Deaths in Japan
-- Shows likelihood of dying if you contract covid in Japan

SELECT Location, date, total_cases, total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 as DeathPercentage
FROM PortfolioProject..CovidDeaths 
Where location = 'Japan' and total_cases is not null
ORDER BY 1, 2



-- Looking at Total Cases vs Population

-- Shows what percentage of population got covid in the US

SELECT Location, date, population, total_cases, 
(total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths 
Where location like '%states%' and total_cases is not null
ORDER BY 1, 2


-- Shows what percentage of population got covid in Japan

SELECT Location, date, population, total_cases, 
(total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths 
Where location like '%Japan%' and total_cases is not null
ORDER BY 1, 2



-- Countries with Highest Infection Rate Compared to Populatoin

SELECT Location, population, MAX(total_cases) as TotalInfectionCount, 
MAX((total_cases/population)*100) as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths 
where continent is not null
Group by Location, population
ORDER BY PercentPopulationInfected desc


-- Infection Rate Compared to Populatoin (US vs. Japan)

SELECT Location, population, MAX(total_cases) as TotalInfectionCount, 
MAX((total_cases/population)*100) as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths 
where population is not null and Location in ('United States', 'Japan')
Group by Location, population
ORDER BY PercentPopulationInfected desc



-- Countries with Death Count Compared to Population

SELECT Location, population, MAX(cast(total_deaths as float)) as TotalDeathCount, 
Max(cast(total_deaths as float)/population*100) as DeathRate
FROM PortfolioProject..CovidDeaths 
Where continent is not null
Group by Location, population
ORDER BY DeathRate desc


-- Death Count Compared to Population (US vs. Japan)

SELECT Location, population, MAX(cast(total_deaths as float)) as TotalDeathCount, 
Max(cast(total_deaths as float)/population*100) as DeathRate
FROM PortfolioProject..CovidDeaths 
Where population is not null and Location in ('United States', 'Japan')
Group by Location, population
ORDER BY DeathRate desc



-- Global Numbers on Each Date

SELECT date, SUM(new_cases) as total_cases, 
SUM(CAST(new_deaths as float)) as total_deaths,
SUM(CAST(new_deaths as float))/SUM(new_cases)*100 as DeathRate
FROM PortfolioProject..CovidDeaths 
where continent is not null
group by date
ORDER BY 1, 2


-- Total Global Numbers 

SELECT SUM(new_cases) as total_cases, 
SUM(CAST(new_deaths as float)) as total_deaths,
SUM(CAST(new_deaths as float))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths 
where continent is not null
-- group by date
ORDER BY 1, 2 



-- Total Population vs. Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(float, vac.new_vaccinations)) 
over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/dea.population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null and population is not null
order by 2, 3


-- Shows percentage of population that has recieved at least one Covid vaccine
-- Using CTE to perform calculation on Partition By in previous query

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float, vac.new_vaccinations)) 
over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/dea.population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null and population is not null
-- order by 2, 3
)

select *, (RollingPeopleVaccinated/population)*100 as VaccinationRate
from PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE if exists #PercentPopulationVaccinated

create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(float, vac.new_vaccinations)) 
over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/dea.population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null and population is not null
-- order by 2, 3

select *, (RollingPeopleVaccinated/population)*100 as VaccinationRate
from #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float, vac.new_vaccinations)) 
over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/dea.population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null and population is not null
-- order by 2, 3

select * from PercentPopulationVaccinated
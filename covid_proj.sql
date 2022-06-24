
--Checagem geral dos dados

select *
from [COVID-DS]..['owid-covid-deaths']
where continent is not null
order by location,date

select *
from [COVID-DS]..['owid-covid-vac']
where continent is not null
order by location, date



--Total de casos por total de mortes
--Mostra a chance de morte no país caso se contraia o virus

select location, date,total_cases,total_deaths,(total_deaths/total_cases)*100 as death_percentage
from [COVID-DS]..['owid-covid-deaths']
where location = 'Brazil'
and continent is not null
order by location, date



--Total de casos por população
--Mostra a porcentagem da população infectada por covid

select location, date, population, total_cases, (total_cases/population)*100 as percent_population_infected
from [COVID-DS]..['owid-covid-deaths']
where location = 'Brazil'
order by 1,2



--Países com a maior taxa de infecção por população

select location, population, max(total_cases) as highest_infection_count, round(max((total_cases/population))*100, 2) as percent_population_infected
from [COVID-DS]..['owid-covid-deaths']
group by location, population
order by percent_population_infected desc



--Países com maior contagem de mortes por população

select location, max(cast(total_deaths as int)) as total_death_count
from [COVID-DS]..['owid-covid-deaths']
where continent is not null and continent != ''
group by location
order by total_death_count desc



--Continentes com a maior contagem de mortes por população

select continent, max(cast(total_deaths as int)) as total_death_count
from [COVID-DS]..['owid-covid-deaths']
where continent is not null and continent != ''
group by continent
order by total_death_count desc



--Separando mortes por renda ao redor do mundo

select location, max(cast(total_deaths as int)) as total_death_count
from [COVID-DS]..['owid-covid-deaths']
where continent is not null and location like '%income%'
group by location
order by total_death_count desc



--Dados globais

select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
from [COVID-DS]..['owid-covid-deaths']
where continent is not null
order by 1,2



--População total por vacinação
--Mostra a porcentagem da população que recebeu pelo menos uma dose da vacina

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from [COVID-DS]..['owid-covid-deaths'] dea
join [COVID-DS]..['owid-covid-vac'] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
	  and dea.location = 'Brazil'
order by 2,3



--Usando CTE para realizar cálculo em 'partition by' feito na requisição anterior

with pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date)
as rolling_people_vaccinated
from [COVID-DS]..['owid-covid-deaths'] dea
join [COVID-DS]..['owid-covid-vac'] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
	  and dea.location = 'Brazil'
)
select *,round((rolling_people_vaccinated/population)*100, 2) as percent_vaccinated
from pop_vs_vac



--Utilizando tabela temporária para realizar cáculo no 'partition by' da requisição anterior

drop table if exists #percet_population_vaccinated
create table #percet_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations nvarchar(255),
rolling_people_vaccinated numeric
)

insert into #percet_population_vaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from [COVID-DS]..['owid-covid-deaths'] dea
join [COVID-DS]..['owid-covid-vac'] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
	  and dea.location = 'Brazil'

select *,cast((rolling_people_vaccinated/population)*100 as decimal(5,2))
as percent_vaccinated
from #percet_population_vaccinated



--Criando uma vizualização para guardar dados para vizualizações posteriores

create view percent_population_vaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by dea.location, dea.date) as rolling_people_vaccinated
from [COVID-DS]..['owid-covid-deaths'] dea
join [COVID-DS]..['owid-covid-vac'] vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
	  and dea.location = 'Brazil'
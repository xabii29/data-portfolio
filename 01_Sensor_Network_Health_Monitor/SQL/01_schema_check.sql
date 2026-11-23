/*Consultas para analizar la calidad, cantidad y tipos de datos del dataset correspondiente a la calidad de aire,
adicionalmente se selecciona un tipo de lectura y sus respectivas tablas horaria y diaria*/

-- Script para listar las tablas del dataset
SELECT *
FROM `bigquery-public-data.epa_historical_air_quality.INFORMATION_SCHEMA.TABLES`;

--Script para categorizar las tablas del dataset
SELECT 
  IFNULL(table_name, 'TOTAL') AS tabla,
  COUNTIF(table_name LIKE "%daily%") AS daily, 
  COUNTIF(table_name LIKE "%hourly%") AS hourly, 
  COUNTIF(table_name NOT LIKE "%hourly%" AND table_name NOT LIKE "%daily%") AS distinta,
  COUNT(*) AS total
FROM `bigquery-public-data.epa_historical_air_quality.INFORMATION_SCHEMA.TABLES`
GROUP BY ROLLUP(table_name)
ORDER BY tabla;

--tabla seleccionada "co_hourly_summary"
--Script para consultar las columnas
SELECT column_name, data_type
FROM `bigquery-public-data.epa_historical_air_quality.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = "co_hourly_summary"; --WHERE table_name = "co_daily_summary"; 

--Consulta acotada al 1 porciento (190MB) para verificar tipos de datos, al 100 porciento se cargan 21.13 GB aproximadamente 
--100 millones de filas
SELECT *
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary` TABLESAMPLE system(1 percent);

--Consulta para ubicar el año mas viejo y el mas reciente
SELECT state_name, MAX(date_local) AS reciente, MIN(date_local) AS vieja
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name = "Texas"
GROUP BY state_name;

--Consulta para verificar granularidad, con esas columnas se puede identificar un unico registro por hora, por dia, por monitor, 
--por zona, por county y por estado
SELECT *
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name = "Texas"
ORDER BY state_code, county_code, site_num, poc, date_local, time_local;

--Consulta para medir la temporalidad de los registros
SELECT state_name, date_trunc(date_local,month) AS mes, COUNT(poc) AS registros
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name = "Texas" and date_local between "2021-01-01" and "2024-12-31"
GROUP BY state_name, mes 
ORDER BY mes;

--Consulta para comparar los registros de New York y Texas
WITH filtrado AS(
  SELECT state_name, date_trunc(date_local,year) AS anual, CONCAT(COUNTy_code,' ',site_num,' ',poc) AS code_poc, COUNT(poc) AS registros
  FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
  WHERE state_name in ("Texas","New York") and date_local between "2021-01-01" and "2022-12-31"
  GROUP BY state_name,site_num, anual, COUNTy_code, poc
)
SELECT state_name, anual, COUNT(distinct code_poc) AS monitores, sum(registros) AS registros
FROM filtrado
GROUP BY state_name, anual
ORDER BY monitores;

--Consulta para ver si existen registros duplicados
WITH codigo AS(
  SELECT CONCAT(COUNTy_code,' ',site_num,' ',poc,' ',date_local,' ',time_local) AS code_poc
  FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
  WHERE state_name in ("Texas") and date_local between "2021-01-01" and "2021-12-31"
)
SELECT COUNT(code_poc) AS duplicados
from codigo
group by code_poc
having COUNT(*) > 1;

--Consulta para saber si hay qualifiers, los rangos de mdl y si existen valores de incertidumbre
SELECT qualifier, mdl, uncertainty
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name in ("Texas") and date_local between "2021-01-01" and "2022-12-31"
GROUP BY qualifier, mdl, uncertainty;

--Consulta para contar registros de mdl, qualifier distintos a null, incertidumbre distintos a null
SELECT COUNT(qualifier), COUNT(mdl), COUNT(uncertainty)
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name in ("Texas") and date_local between "2021-01-01" and "2022-12-31"
GROUP BY qualifier, mdl, uncertainty;

--Consulta para saber cuantos meses de registros existen en el año 2021
SELECT state_name, date_trunc(date_local,year) AS anual, COUNT(distinct date_trunc(date_local,month)) AS meses
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name = "Texas" and date_local between "2021-01-01" and "2021-12-31"
GROUP BY state_name, anual
ORDER BY anual, state_name;



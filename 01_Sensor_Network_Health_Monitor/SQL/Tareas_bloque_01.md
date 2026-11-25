# Bloque 1

## Tarea 1

La primer tarea consiste en analizar el dataset, elegir las tablas a evaluar y entender su contenido para evaluar su utilidad y el rango de investigacion.

```sql
/*Script para categorizar las tablas del dataset*/

SELECT 
  IFNULL(table_name, 'TOTAL') AS tabla,
  COUNTIF(table_name LIKE "%daily%") AS daily, 
  COUNTIF(table_name LIKE "%hourly%") AS hourly, 
  COUNTIF(table_name NOT LIKE "%hourly%" AND table_name NOT LIKE "%daily%") AS distinta,
  COUNT(*) AS total
FROM `bigquery-public-data.epa_historical_air_quality.INFORMATION_SCHEMA.TABLES`
GROUP BY ROLLUP(table_name)
ORDER BY tabla;

```

Resultado

|tabla|daily|hourly|distinta|total|
|---|:---:|:---:|:---:|:---:|
|Total|16|15|1|32|
|air_quality_annual_summary|0|0|1|1|
|co_daily_summary|1|0|0|1|
|co_hourly_summary|0|1|0|1|
|hap_daily_summary|1|0|0|1|
|hap_hourly_summary|0|1|0|1|
|lead_daily_summary|1|0|0|1|
|no2_daily_summary|1|0|0|1|
|no2_hourly_summary|0|1|0|1|
|nonoxnoy_daily_summary|1|0|0|1|
|nonoxnoy_hourly_summary|0|1|0|1|
|o3_daily_summary|1|0|0|1|
|o3_hourly_summary|0|1|0|1|
|pm10_daily_summary|1|0|0|1|
|pm10_hourly_summary|0|1|0|1|
|pm25_frm_daily_summary|1|0|0|1|
|pm25_frm_hourly_summary|0|1|0|1|
|pm25_nonfrm_daily_summary|1|0|0|1|
|pm25_nonfrm_hourly_summary|0|1|0|1|
|pm25_speciation_daily_summary|1|0|0|1|
|pm25_speciation_hourly_summary|0|1|0|1|
|pressure_daily_summary|1|0|0|1|
|pressure_hourly_summary|0|1|0|1|
|rh_and_dp_daily_summary|1|0|0|1|
|rh_and_dp_hourly_summary|0|1|0|1|
|so2_daily_summary|1|0|0|1|
|so2_hourly_summary|0|1|0|1|
|temperature_daily_summary|1|0|0|1|
|temperature_hourly_summary|0|1|0|1|
|voc_daily_summary|1|0|0|1|
|voc_hourly_summary|0|1|0|1|
|wind_daily_summary|1|0|0|1|
|wind_hourly_summary|0|1|0|1|

La tabla distinta es una unica tabla de resumen de calidad del aire anual. Para todos las demas tablas: existen 16 diarias y 15 por hora. La unica que no tiene *hourly* es la de *lead*, la cual es una tabla diaria unica. Todos los demas parametros del dataset contienen una tabla horario y diaria.

## Tarea 2

Se eligió la tabla de CO (monoxido de carbono), bajo el supuesto de que es un compuesto generalmente asociado a la quema de combustibles.

La tabla *co_hourly_summary* es la tabla que contiene los registros por hora, la tabla *co_daily_summary* contiene los registros por día.

Con la tabla *hourly* puedo ver donde hay fallas o que lecturas de los sensores no se reportaron o cuentan con medidas erroneas. Con la tabla *daily* puedo ver el resumen de las medidas y comparar datos ya procesados con agregaciones.

## Tarea 3

Granularidad: state_code, county_code, site_num, poc, date_local, time_local (o date_gmt, time_gmt). Con esos podemos obtener un unico registro.

Se agrega ademas a la lista de columnas: latitude, longitude, units of measurement, mdl, uncertainty, qualifier y county_name

Lista completa de columnas tabla *daily*:

|column_name|data_type|
|---|---|
|state_code|STRING|
|county_code|STRING|
|site_num|STRING|
|parameter_code|INT64|
|poc|INT64|
|latitude|FLOAT64|
|longitude|FLOAT64|
|datum|STRING|
|parameter_name|STRING|
|sample_duration|STRING|
|pollutant_standard|STRING|
|date_local|DATE|
|units_of_measure|STRING|
|event_type|STRING|
|observation_count|INT64|
|observation_percent|FLOAT64|
|arithmetic_mean|FLOAT64|
|first_max_value|FLOAT64|
|first_max_hour|INT64|
|aqi|INT64|
|method_code|INT64|
|method_name|STRING|
|local_site_name|STRING|
|address|STRING|
|state_name|STRING|
|county_name|STRING|
|city_name|STRING|
|cbsa_name|STRING|
|date_of_last_change|DATE|

Lista completa de columnas tabla *hourly*:

|column_name|data_type|
|---|---|
|state_code|STRING|
|county_code|STRING|
|site_num|STRING|
|parameter_code|INT64|
|poc|INT64|
|latitude|FLOAT64|
|longitude|FLOAT64|
|datum|STRING|
|parameter_name|STRING|
|date_local|DATE|
|time_local|STRING|
|date_gmt|DATE|
|time_gmt|STRING|
|sample_measurement|FLOAT64|
|units_of_measure|STRING|
|mdl|FLOAT64|
|uncertainty|FLOAT64|
|qualifier|STRING|
|method_type|STRING|
|method_code|STRING|
|method_name|STRING|
|state_name|STRING|
|county_name|STRING|
|date_of_last_change|DATE|

## Tarea 4

Si elijo menos columnas baja la carga de datos desde BigQuery.

Con el comando **TABLESAMPLE system (1 percent)** puedo reducir la carga de datos para verificar columnas tipo de datos antes de cargar todo una tabla con miles o millones de filas.

Con solo una columna seleccionada se carga 3.56 MB. Con SELECT * 189.83 MB.

De acuerdo con **INFORMATION_SCHEMA** ninguna columna esta clusterizada ni particionada.

## Tarea 5

Para el estado de Texas, hay datos disponibles desde 1990-01-01 hasta 2022-03-01. Vamos a trabajar con los datos del **2021**, los cuales tienen datos anuales completos.

Los datos obtenidos en las consultas muestran que a partir del 2022 unicamente se realizan tomas de datos en ciertos perdiodos del año por lo que queremos corroborar el comportamiento anual y no solo por periodos.

Estamos investigando los datos de monoxido de carbono, veremos si en ciertas temporadas del año se muestran cambios en las tendencias e intentaremos observar si tienen alguna correlacion con algun fenomeno natural, con una temporada productiva, o si hay lecturas fuera de rango, para evaluar la existencia de algun evento desencadenante y su causa.

Las columnas de calidad sirven para señalar directamente la existencia de anomalias por eventos: incendios, intermitencias energeticas o solo marcar que los datos no son de un dia normal.

mdl sirve como el cambio minimo posible detectable por el monitor, mdl puede ser de 0.02 o 0.5 ppm.

El total de la incertidumbre asociada a cada monitor: para la consulta en esta tabla de CO todos los datos son **NULL** en el año seleccionado.

Qualifiers puede marcar valores fuera de rango: excepcional event, null, natural events, calidad. Tanto para Texas como para New York, estos aparecen como completos como **NULL** en el año seleccionado.

```sql
/*01_schema_check
  -Analizar el dataset
  -Listar tablas
  -Evaluar columnas de las posibles tablas
  -Relizar investigacion previa
  -Hacer supuestos*/

-- 01 Script para listar las tablas del dataset
SELECT *
FROM `bigquery-public-data.epa_historical_air_quality.INFORMATION_SCHEMA.TABLES`

-- 02 Script para categorizar las tablas del dataset

SELECT 
COUNTIF(table_name like "%daily%") as daily,
COUNTIF(table_name like "%hourly%") as hourly,
COUNTIF(table_name NOT like "%hourly%" AND table_name not like "%daily%" )as distinta,
COUNT(*) as total
FROM `bigquery-public-data.epa_historical_air_quality.INFORMATION_SCHEMA.TABLES`;

--La tabla seleccionada fue "co_hourly_summary"

-- 03 Script para consultar las columnas

SELECT column_name, data_type
FROM `bigquery-public-data.epa_historical_air_quality.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = "co_hourly_summary"; /*WHERE table_name = "co_daily_summary"; */

/* 04 Consulta acotada al 1 porciento (190MB) para verificar tipos de datos, al 100 porciento se cargan 21.13 GB aproximadamente 
100 millones de filas*/

SELECT *
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`;

-- 05 Consulta para ubicar el año mas viejo y el mas reciente

SELECT state_name, MAX(date_local) as reciente, MIN(date_local) as vieja
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name = "Texas"
GROUP BY state_name;

-- 06 Consulta para ver cuantos sensores hay en texas y registros totales 2021 por sitio

SELECT state_name, county_code, site_num, count(distinct poc) as qtn_sensores, count(poc) as registros
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name = "Texas" and date_local between "2021-01-01" and "2021-12-31"
GROUP BY state_name, county_code, site_num, poc;
```

Resultado Texas

| state_name | county_code | site_num | qtn_sensores | registros |
| --- | :---: | :---: | :---: | :---: |
| Texas | 141 | 0044 | 1 | 2537 |
| Texas | 201 | 1052 | 1 | 2838 |
| Texas | 309 | 1037 | 1 | 1195 |
| Texas | 029 | 1069 | 1 | 2814 |
| Texas | 439 | 1053 | 1 | 2788 |
| Texas | 453 | 1068 | 1 | 2830 |
| Texas | 201 | 1035 | 1 | 2021 |
| Texas | 113 | 0069 | 1 | 1932 |
| Texas | 141 | 1021 | 1 | 2117 |
| Texas | 201 | 1039 | 1 | 2583 |
| Texas | 479 | 0016 | 1 | 2643 |

```sql
-- 07 Consulta para ver monitores de new york
SELECT state_name, county_code, site_num, count(poc) as registros, count(distinct poc) as qtn_sensores
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name = "New York" and date_local between "2021-01-01" and "2021-12-31"
GROUP BY state_name, county_code, site_num, poc;
```

Resultado New York

| state_name | county_code | site_num | registros | qtn_sensores |
| --- | :---: | :---: | :---: | :---: |
| New York | 029 | 0023 | 3961 | 1 |
| New York | 081 | 0124 | 3753 | 1 |
| New York | 101 | 0003 | 3691 | 1 |
| New York | 055 | 1007 | 4292 | 1 |
| New York | 029 | 0005 | 4275 | 1 |
| New York | 103 | 0044 | 3736 | 1 |
| New York | 055 | 0015 | 4268 | 1 |
| New York | 061 | 0135 | 4273 | 1 |
| New York | 005 | 0133 | 4214 | 1 |

```sql
-- 08 Consulta para medir la temporalidad de los registros
SELECT state_name, date_trunc(date_local,month) as mes, count(poc) as registros
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name = "Texas" and date_local between "2020-01-01" and "2023-12-31"
GROUP BY state_name, mes 
ORDER BY mes;
```

|state_name|mes|registros|
|---|---|:---:|
|Texas|2024-01-01|7681|
|Texas|2024-02-01|6550|
|Texas|2024-03-01|6482|
|Texas|2024-04-01|2766|
|Texas|2021-01-01|7607|
|Texas|2021-02-01|6932|
|Texas|2021-03-01|7076|
|Texas|2021-04-01|4683|
|Texas|2022-01-01|7218|
|Texas|2022-02-01|6531|
|Texas|2022-03-01|5783|

```sql
-- 09 Monitores y registros disponibles
WITH filtrado as(
SELECT state_name, date_trunc(date_local,year) as anual, CONCAT(county_code,' ',site_num,' ',poc) as code_poc, count(poc) as registros
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name in ("Texas","New York") and date_local between "2021-01-01" and "2022-12-31"
GROUP BY state_name,site_num, anual, county_code, poc
)
SELECT state_name, anual, count(distinct code_poc) as monitores, sum(registros) as registros
FROM filtrado
GROUP BY state_name, anual
ORDER BY monitores;
```

|state_name|anual|monitores|registros|
|---|---|:---:|:---:|
|New York|2021-01-01|9|36463|
|New York|2022-01-01|10|27149|
|Texas|2022-01-01|10|19532|
|Texas|2021-01-01|11|26298|

```sql
-- 10 Check por duplicados
with codigo as(
SELECT CONCAT(county_code,' ',site_num,' ',poc,' ',date_local,' ',time_local) as code_poc
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name in ("Texas") and date_local between "2021-01-01" and "2022-12-31"
)
SELECT count(code_poc) as duplicados
from codigo
group by code_poc
having count(*) > 1
```

"No hay duplicados"

```sql
-- 11 Verificar posibles datos de qualifier, mdl y uncertainty
SELECT qualifier, mdl, uncertainty
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name in ("Texas") and date_local between "2021-01-01" and "2022-12-31"
GROUP BY qualifier, mdl, uncertainty
```

|qualifier|mdl|uncertainty|
|:---:|:---:|:---:|
|null|0.5|null|
|null|0.02|null|

```sql
-- 12 contar cuantos registros hay por tipo de valor de mld, qualifier, y uncertainty
SELECT count(qualifier), count(mdl), count(uncertainty)
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name in ("Texas") and date_local between "2021-01-01" and "2022-12-31"
GROUP BY qualifier, mdl, uncertainty
```

|qualifier|mdl|uncertainty|
|:---:|:---:|:---:|
|0|32384|0|
|0|13446|0|

```sql
-- 13 Contar los meses con registros
SELECT state_name, date_trunc(date_local,year) as anual, count(distinct date_trunc(date_local,month)) as meses
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name = "Texas" and date_local between "2021-01-01" and "2021-12-31"
GROUP BY state_name, anual
ORDER BY anual, state_name;
```

|state_name|anual|meses|
|:---:|:---:|:---:|
|Texas|2021-01-01|12|
|Texas|2022-01-01|4|

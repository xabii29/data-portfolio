# Bloque 2

## Descripcion

El bloque 2 consiste en analizar y ver las posibilidades de trabajo con la tabla **texas_co_hourly_2021** del dataset **bigquery-public-data.epa_historical_air_quality.**

Esta primer consulta se realiza para cargar una sola vez la tabla y trabajar directamente con las consultas y no estar releyendo la informacion. En caso de querer seleccionar nuevas columnas debe cambiarse el ```CREATE TABLE IF EXISTS``` por ```CREATE OR REPLACE TABLE```

```sql
-- 01 Guardar tabla texas_co_hourly_2021, se procesan 8.29 GB
CREATE TABLE IF NOT EXISTS `Texas_CO_2021.texas_co_hourly_2021` AS(
SELECT state_code, county_code, site_num, poc, date_local, time_local, 
sample_measurement, units_of_measure, mdl, uncertainty, qualifier, 
CONCAT(state_code,' ', county_code, ' ', site_num, ' ', poc) as monitor_code, 
datetime(CONCAT(date_local, 'T',time_local,':00')) as hour,
latitude, longitude, county_name
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name = "Texas" and date_local between "2021-01-01" and "2021-12-31");
```

La segunda consulta nos permite crear un calendario, en el que se genera un array anual de los dias y horas que deberian existir de registros. En total se generan **365*12=4,380** filas.

```sql
-- 02 Crear tabla calendario
CREATE TABLE IF NOT EXISTS `Texas_CO_2021.calendar_hourly_2021` AS(
  SELECT DATETIME(fecha_hora) as fecha_hora
  FROM UNNEST(
    GENERATE_TIMESTAMP_ARRAY("2021-01-01 00:00:00", "2021-12-31 23:00:00", INTERVAL 1 HOUR)
  )  as fecha_hora
);
```

Esta tercer consulta nos permite evaluar los datos de identificacion para cada monitor

```sql
-- 03 Dimension monitores
SELECT DISTINCT 
  monitor_code, state_code, county_code, site_num, poc, 
  county_name, latitude, longitude
FROM `Texas_CO_2021.texas_co_hourly_2021`
ORDER BY monitor_code;
```

Con la siguiente consulta corroboramos cuantos registros totales existen. En total tenemos 8,760.

```sql
-- 04 Registros
SELECT c.*, r.hour, count(r.hour) as conteo
FROM `Texas_CO_2021.calendar_hourly_2021` as c
LEFT JOIN `Texas_CO_2021.texas_co_hourly_2021` as r
ON c.fecha_hora = r.hour
GROUP BY c.fecha_hora, r.hour
ORDER BY c.fecha_hora asc;
```

La consulta 05 nos indica cuantos registros faltan por monitor, por mes. La consulta 06 cuantos faltan por dia.

```sql
-- 05 Sin registro mes
WITH filtrado AS( 
  SELECT distinct monitor_code
  FROM `Texas_CO_2021.texas_co_hourly_2021`
), combinaciones as(
  SELECT f.monitor_code, cal.fecha_hora
  FROM filtrado as f
  CROSS JOIN  `Texas_CO_2021.calendar_hourly_2021` as cal
), nulos as (
SELECT c.monitor_code, c.fecha_hora, f.hour
FROM combinaciones as c
LEFT JOIN `Texas_CO_2021.texas_co_hourly_2021` as f
ON c.fecha_hora = f.hour and f.monitor_code = c.monitor_code
WHERE hour is NULL
)
SELECT monitor_code, DATE_TRUNC(fecha_hora, MONTH) as mes,count(*) AS nulos
FROM nulos
GROUP BY monitor_code, mes
ORDER BY monitor_code, mes
;

-- 06 Sin registro dia
WITH filtrado AS( 
  SELECT distinct monitor_code
  FROM `Texas_CO_2021.texas_co_hourly_2021`
), combinaciones as(
  SELECT f.monitor_code, cal.fecha_hora
  FROM filtrado as f
  CROSS JOIN  `Texas_CO_2021.calendar_hourly_2021` as cal
), nulos as (
SELECT c.monitor_code, c.fecha_hora, f.hour
FROM combinaciones as c
LEFT JOIN `Texas_CO_2021.texas_co_hourly_2021` as f
ON c.fecha_hora = f.hour and f.monitor_code = c.monitor_code
WHERE hour is NULL
)
SELECT monitor_code, DATE_TRUNC(fecha_hora, DAY) as dia,count(*) AS nulos
FROM nulos
GROUP BY monitor_code, dia
ORDER BY monitor_code, dia
;
```

La consulta 07 nos muestra el cruce entre el calendario y los registros que si existen, por dia.

```sql
-- 07 Registro bien
WITH monitores AS (
  SELECT DISTINCT monitor_code
  FROM `Texas_CO_2021.texas_co_hourly_2021`
),
por_dia AS (
  SELECT 
    TIMESTAMP_TRUNC(fecha_hora, DAY) AS dia,
    COUNT(*) AS esperadas
  FROM `Texas_CO_2021.calendar_hourly_2021`
  GROUP BY dia
),
cuadricula_base AS (
  SELECT 
    m.monitor_code,
    d.dia,
    d.esperadas
  FROM monitores AS m
  CROSS JOIN por_dia AS d
),
esp_rec AS (
  SELECT 
    monitor_code, 
    TIMESTAMP_TRUNC(date_local, DAY) AS dia, 
    COUNT(*) AS recibidas
  FROM `Texas_CO_2021.texas_co_hourly_2021`
  GROUP BY monitor_code, dia
)
SELECT 
  cb.monitor_code,
  cb.dia AS local_date,
  FORMAT_DATE('%A',cb.dia) as day_name,
  cb.esperadas,
  COALESCE(e.recibidas, 0) AS recibidas,
  ROUND(SAFE_DIVIDE(COALESCE(e.recibidas, 0) * 100, cb.esperadas), 2) AS pct_completition
FROM cuadricula_base AS cb
LEFT JOIN esp_rec AS e
  ON cb.monitor_code = e.monitor_code AND cb.dia = e.dia
order by monitor_code, local_date
;
```

Muestra:

|fila|monitor_code|local_date|day_name|esperadas|recibidas|pct_completition|
|---|---|---|---|:---:|:---:|:---:|
|1|48 029 1069 1|2021-01-01T00:00:00|Friday|24|24|100.0|
|2|48 029 1069 1|2021-01-02T00:00:00|Saturday|24|23|95.8|
|3|48 029 1069 1|2021-01-03T00:00:00|Sunday|24|23|95.83|
|4|48 029 1069 1|2021-01-04T00:00:00|Monday|24|24|100.0|

```sql
-- 08 Registro comprobacion
WITH monitores AS (
  SELECT DISTINCT monitor_code
  FROM `Texas_CO_2021.texas_co_hourly_2021`
),
por_dia AS (
  SELECT 
    TIMESTAMP_TRUNC(fecha_hora, DAY) AS dia,
    COUNT(*) AS esperadas
  FROM `Texas_CO_2021.calendar_hourly_2021`
  GROUP BY dia
),
cuadricula_base AS (
  SELECT 
    m.monitor_code,
    d.dia,
    d.esperadas
  FROM monitores AS m
  CROSS JOIN por_dia AS d
),
esp_rec AS (
  SELECT 
    monitor_code, 
    TIMESTAMP_TRUNC(date_local, DAY) AS dia, 
    COUNT(*) AS recibidas
  FROM `Texas_CO_2021.texas_co_hourly_2021`
  GROUP BY monitor_code, dia
), final as(
SELECT 
  cb.monitor_code,
  cb.dia AS local_date,
  FORMAT_DATE('%A',cb.dia) as day_name,
  cb.esperadas,
  COALESCE(e.recibidas, 0) AS recibidas,
  ROUND(SAFE_DIVIDE(COALESCE(e.recibidas, 0) * 100, cb.esperadas), 2) AS pct_completition
FROM cuadricula_base AS cb
LEFT JOIN esp_rec AS e
  ON cb.monitor_code = e.monitor_code AND cb.dia = e.dia
)
SELECT COUNT(*) as filas_cuadricula,
SUM(recibidas) as registros_totales,
MAX(recibidas) as max_recibidas,
MAX(pct_completition) as max_pct_completition
FROM final;
```

|filas_cuadricula|registros_totales|max_recibidas|max_pct_completition|
|:---:|:---:|:---:|:---:|
|4380|93208|24|100.0|

La consulta 09 muestra algunas medidas de las muestras.

```sql
-- 09 sample_measure
WITH filtrado AS(
SELECT CONCAT(state_code,' ', county_code, ' ', site_num, ' ', poc) as monitor_code,
DATETIME(CONCAT(date_local, 'T',time_local,':00')) as hour,
sample_measurement, mdl
FROM `Texas_CO_2021.texas_co_hourly_2021`
), medidas AS (
  SELECT monitor_code, 
  MIN(sample_measurement) as min_sm,
  MAX(sample_measurement) as max_sm,
  ROUND(AVG(sample_measurement),2) as avg_sm,
  COUNTIF(sample_measurement < 0) as negatives,
  COUNT(sample_measurement) as totales,
  mdl
  FROM filtrado
  GROUP BY monitor_code, mdl
)
SELECT *
FROM medidas
ORDER BY mdl, monitor_code;
```

La consulta 10 muestra los monitores con consultas negativas y la fecha en que ocurrieron.

```sql
-- 10 Seleccion de monitores y fechas donde hubo medidas negativas
SELECT monitor_code, hour, sample_measurement
FROM `Texas_CO_2021.texas_co_hourly_2021`
WHERE sample_measurement < 0;

--Primer y ultimo registro por monitor
SELECT distinct monitor_code, min(date_local) as first_date, max(date_local) as last_date
FROM `Texas_CO_2021.texas_co_hourly_2021`
;
```

La consulta 11 muestra los periodos que si contienen registros, la consulta 12 muestra los periodos que no contienen registros por mes y los rankea de peor a mejor.

```sql
-- 11 Periodos con registros
SELECT monitor_code, MIN(date_local) as start_date,MAX(date_local) as end_day, count(*) as dias
FROM (SELECT distinct monitor_code, date_local, 
    DATE_SUB(date_local, INTERVAL (dense_rank()OVER(partition by monitor_code order by date_local)) DAY) as isla
    FROM `Texas_CO_2021.texas_co_hourly_2021`)
group by monitor_code, isla
;

-- 12 Periodos sin registros rankeados
WITH islas as(
SELECT monitor_code, MIN(date_local) as start_date,MAX(date_local) as end_day, count(*) as dias
FROM (SELECT distinct monitor_code, date_local, 
    DATE_SUB(date_local, INTERVAL (dense_rank()OVER(partition by monitor_code order by date_local)) DAY) as isla
    FROM `Texas_CO_2021.texas_co_hourly_2021`)
group by monitor_code, isla
),
brechas as(
  SELECT monitor_code,
  DATE_ADD(end_day, INTERVAL 1 day) as gap_start,
  DATE_SUB(COALESCE(LEAD(start_date)OVER(partition by monitor_code order by start_date),"2022-01-01"), interval 1 day) as gap_end
  FROM islas
), results as(
SELECT monitor_code, gap_start, gap_end, date_diff(gap_end,gap_start,day)+1 as dias
FROM brechas
GROUP BY monitor_code, gap_start, gap_end
)
SELECT *, rank()OVER(order by dias desc) as TOP
FROM results
ORDER BY dias desc
LIMIT 5
;
```

La siguientes consultas muestran algunas estadisticas de las medidas de cada monitor.

```sql
-- 13 Sample measurement stadistics
SELECT monitor_code,mdl,MIN(sample_measurement) as minimo,
MAX(sample_measurement) as maximo,
AVG(sample_measurement) as promedio,
units_of_measure,
count(*) as registros
FROM `Texas_CO_2021.texas_co_hourly_2021`
GROUP BY monitor_code,units_of_measure,mdl;

-- 14 Lecturas
WITH categorias as(
SELECT mdl,sample_measurement, units_of_measure,
CASE WHEN sample_measurement >= 2 THEN "Desde 2"
WHEN sample_measurement BETWEEN 0 and 2 THEN "Entre 0 y 2"
ELSE "Negativo"
END AS rango
FROM `Texas_CO_2021.texas_co_hourly_2021`
)
SELECT mdl, rango,units_of_measure, COUNT(*) as medidas
FROM categorias
GROUP BY mdl,rango, units_of_measure
ORDER BY mdl;
```

Esta consulta muestra los periodos en horas con mayor falta de registros, se puede filtrar por periodos especificos para evitar rankear los dias que evidentemente no tuvieron señal en todo el dia.

```sql
-- 15 Ranking dias de la semana con falta de registros
WITH monitores AS (
  SELECT DISTINCT monitor_code
  FROM `Texas_CO_2021.texas_co_hourly_2021`
),
por_dia AS (
  SELECT 
    TIMESTAMP_TRUNC(fecha_hora, DAY) AS dia,
    COUNT(*) AS esperadas
  FROM `Texas_CO_2021.calendar_hourly_2021`
  GROUP BY dia
),
cuadricula_base AS (
  SELECT 
    m.monitor_code,
    d.dia,
    d.esperadas
  FROM monitores AS m
  CROSS JOIN por_dia AS d
),
esp_rec AS (
  SELECT 
    monitor_code, 
    TIMESTAMP_TRUNC(date_local, DAY) AS dia, 
    COUNT(*) AS recibidas
  FROM `Texas_CO_2021.texas_co_hourly_2021`
  GROUP BY monitor_code, dia
), res as(
SELECT 
  FORMAT_DATE('%A',cb.dia) as day_name,
  SUM(cb.esperadas) as esperadas,
  SUM(COALESCE(e.recibidas, 0)) AS recibidas,
  ROUND(SAFE_DIVIDE(SUM(COALESCE(e.recibidas, 0)) * 100, sum(cb.esperadas)), 2) AS pct_completition
FROM cuadricula_base AS cb
LEFT JOIN esp_rec AS e
  ON cb.monitor_code = e.monitor_code AND cb.dia = e.dia
GROUP BY FORMAT_DATE('%A',cb.dia)
)
SELECT *, rank()over(ORDER BY pct_completition asc) as top_incompletos
FROM res
;
```

```sql
-- Periodos sin registros rankeados
WITH calendario_dias AS (
  SELECT DISTINCT DATE(fecha_hora) AS dia
  FROM `Texas_CO_2021.calendar_hourly_2021`
),
monitores AS (
  SELECT DISTINCT monitor_code
  FROM `Texas_CO_2021.texas_co_hourly_2021`
),
dias_con_datos AS (
  SELECT DISTINCT monitor_code, date_local
  FROM `Texas_CO_2021.texas_co_hourly_2021`
),
dias_faltantes AS (
  SELECT 
    m.monitor_code,
    c.dia,
    DATE_SUB(c.dia, INTERVAL DENSE_RANK() OVER(PARTITION BY m.monitor_code ORDER BY c.dia) DAY) AS isla_vacia
  FROM monitores AS m
  CROSS JOIN calendario_dias AS c
  LEFT JOIN dias_con_datos AS d
    ON m.monitor_code = d.monitor_code AND c.dia = d.date_local
  WHERE d.date_local IS NULL
),
results AS (
  SELECT 
    monitor_code,
    MIN(dia) AS gap_start,
    MAX(dia) AS gap_end,
    COUNT(*) AS dias
  FROM dias_faltantes
  GROUP BY monitor_code, isla_vacia
)
SELECT *, RANK() OVER(ORDER BY dias DESC) AS TOP
FROM results
ORDER BY dias desc
LIMIT 5;

-- Periodos horas sin registro
WITH filtrado AS(
SELECT monitor_code, hour, LAG(hour)OVER(PARTITION BY monitor_code ORDER BY hour) AS registro_anterior
FROM `Texas_CO_2021.texas_co_hourly_2021`
), tiempos AS(
SELECT monitor_code, hour, registro_anterior,
datetime_diff(hour, registro_anterior,HOUR) AS tiempo_entre_registros
FROM filtrado
)
SELECT *,
RANK()OVER(order by tiempo_entre_registros desc) as top
FROM tiempos
WHERE tiempo_entre_registros between 1 and 24
ORDER BY top asc
LIMIT 10;
```

Ultima consulta para ver los monitores y la ubicacion de los que fallaron en la tormenta del 15 de febrero.

```sql
-- 17 Alrededor del 15 Febrero
WITH monitores AS (
  SELECT DISTINCT monitor_code
  FROM `Texas_CO_2021.texas_co_hourly_2021`
),
por_dia AS (
  SELECT 
    TIMESTAMP_TRUNC(fecha_hora, DAY) AS dia,
    COUNT(*) AS esperadas
  FROM `Texas_CO_2021.calendar_hourly_2021`
  GROUP BY dia
),
cuadricula_base AS (
  SELECT 
    m.monitor_code,
    d.dia,
    d.esperadas
  FROM monitores AS m
  CROSS JOIN por_dia AS d
),
esp_rec AS (
  SELECT 
    monitor_code, 
    TIMESTAMP_TRUNC(date_local, DAY) AS dia, 
    COUNT(*) AS recibidas
  FROM `Texas_CO_2021.texas_co_hourly_2021`
  GROUP BY monitor_code, dia
)
SELECT 
  cb.monitor_code,
  cb.dia AS local_date,
  FORMAT_DATE('%A',cb.dia) as day_name,
  cb.esperadas,
  COALESCE(e.recibidas, 0) AS recibidas,
  ROUND(SAFE_DIVIDE(COALESCE(e.recibidas, 0) * 100, cb.esperadas), 2) AS pct_completition
FROM cuadricula_base AS cb
LEFT JOIN esp_rec AS e
  ON cb.monitor_code = e.monitor_code AND cb.dia = e.dia
WHERE cb.dia BETWEEN "2021-02-10" AND "2021-02-20" AND
  ROUND(SAFE_DIVIDE(COALESCE(e.recibidas, 0) * 100, cb.esperadas), 2) < 100
order by monitor_code, local_date
;
```

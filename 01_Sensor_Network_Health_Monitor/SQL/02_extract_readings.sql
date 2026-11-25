--Guardar tabla texas_co_hourly_2021, se procesan 8.29 GB
CREATE TABLE IF NOT EXISTS `Texas_CO_2021.texas_co_hourly_2021` AS(
SELECT state_code, county_code, site_num, poc, date_local, time_local, 
sample_measurement, units_of_measure, mdl, uncertainty, qualifier, 
CONCAT(state_code,' ', county_code, ' ', site_num, ' ', poc) as monitor_code, 
datetime(CONCAT(date_local, 'T',time_local,':00')) as hour,
latitude, longitude, county_name
FROM `bigquery-public-data.epa_historical_air_quality.co_hourly_summary`
WHERE state_name = "Texas" and date_local between "2021-01-01" and "2021-12-31");

--Crear tabla calendario
CREATE TABLE IF NOT EXISTS `Texas_CO_2021.calendar_hourly_2021` AS(
  SELECT DATETIME(fecha_hora) as fecha_hora
  FROM UNNEST(
    GENERATE_TIMESTAMP_ARRAY("2021-01-01 00:00:00", "2021-12-31 23:00:00", INTERVAL 1 HOUR)
  )  as fecha_hora
);

--Dimension monitores
SELECT DISTINCT 
  monitor_code, state_code, county_code, site_num, poc, 
  county_name, latitude, longitude
FROM `Texas_CO_2021.texas_co_hourly_2021`
ORDER BY monitor_code;

--Registros

SELECT c.*, r.hour, count(r.hour) as conteo
FROM `Texas_CO_2021.calendar_hourly_2021` as c
LEFT JOIN `Texas_CO_2021.texas_co_hourly_2021` as r
ON c.fecha_hora = r.hour
GROUP BY c.fecha_hora, r.hour
ORDER BY c.fecha_hora asc;

--POR DIA
WITH esp_rec AS(
  SELECT monitor_code, date_local, count(*) as recibidas
  FROM `Texas_CO_2021.texas_co_hourly_2021`
  GROUP BY monitor_code, date_local
),
por_dia AS(
  SELECT TIMESTAMP_TRUNC(fecha_hora, DAY) AS dia,
  COUNT(*) AS esperadas
  FROM `Texas_CO_2021.calendar_hourly_2021`
  GROUP BY dia
  )
SELECT e.monitor_code, DATE_TRUNC(e.date_local,day) as local_date, d.esperadas, e.recibidas, round(SAFE_DIVIDE(e.recibidas*100,d.esperadas),2) as pct_completition
FROM por_dia as d
LEFT JOIN esp_rec as e
ON d.dia = DATE_TRUNC(e.date_local,day)
GROUP BY monitor_code, local_date, esperadas, recibidas
HAving pct_completition <10
ORDER BY monitor_code, local_date
;

-- POR MES

WITH esp_rec AS(
  SELECT monitor_code, date_local, count(*) as recibidas
  FROM `Texas_CO_2021.texas_co_hourly_2021`
  GROUP BY monitor_code, date_local
),
por_dia AS(
  SELECT TIMESTAMP_TRUNC(fecha_hora, DAY) AS dia,
  COUNT(*) AS esperadas
  FROM `Texas_CO_2021.calendar_hourly_2021`
  GROUP BY dia
  ),
  por_mes AS (
  SELECT TIMESTAMP_TRUNC(dia, MONTH) AS mes,
  SUM(esperadas) AS esperadas_mes
  FROM por_dia
  GROUP BY mes
  )
SELECT e.monitor_code, DATE_TRUNC(e.date_local,MONTH) as local_date, d.esperadas_mes, sum(e.recibidas) as recibidas, round(SAFE_DIVIDE(sum(e.recibidas)*100,d.esperadas_mes),2) as pct_completition
FROM por_mes as d
LEFT JOIN esp_rec as e
ON d.mes = DATE_TRUNC(e.date_local,MONTH)
GROUP BY monitor_code, local_date, esperadas_mes
ORDER BY monitor_code, local_date
;

--- POR Anho
WITH esp_rec AS(
  SELECT monitor_code, date_local, count(*) as recibidas
  FROM `Texas_CO_2021.texas_co_hourly_2021`
  GROUP BY monitor_code, date_local
),
por_dia AS(
  SELECT TIMESTAMP_TRUNC(fecha_hora, DAY) AS dia,
  COUNT(*) AS esperadas
  FROM `Texas_CO_2021.calendar_hourly_2021`
  GROUP BY dia
  ),
  por_mes AS (
  SELECT TIMESTAMP_TRUNC(dia, MONTH) AS mes,
  SUM(esperadas) AS esperadas_mes
  FROM por_dia
  GROUP BY mes
  ),
  anual AS(
  SELECT TIMESTAMP_TRUNC(mes, YEAR) AS anual,
  SUM(esperadas_mes) AS esperadas_anual
  FROM por_mes
  GROUP BY anual
  )
SELECT e.monitor_code, DATE_TRUNC(e.date_local,YEAR) as local_date, d.esperadas_anual, sum(e.recibidas) as recibidas, round(SAFE_DIVIDE(sum(e.recibidas)*100,d.esperadas_anual),2) as pct_completition
FROM anual as d
LEFT JOIN esp_rec as e
ON d.anual = DATE_TRUNC(e.date_local,YEAR)
GROUP BY monitor_code, local_date, esperadas_anual
ORDER BY monitor_code, local_date;


--Sin registro mes
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

--Sin registro dia
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

--registro bien
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

--Registro comprobacion
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

--sample_measure
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

--Seleccion de monitores y fechas donde hubo medidas negativas
SELECT monitor_code, hour, sample_measurement
FROM `Texas_CO_2021.texas_co_hourly_2021`
WHERE sample_measurement < 0;

--Primer y ultimo registro por monitor
SELECT distinct monitor_code, min(date_local) as first_date, max(date_local) as last_date
FROM `Texas_CO_2021.texas_co_hourly_2021`
;

--Periodos con registros
SELECT monitor_code, MIN(date_local) as start_date,MAX(date_local) as end_day, count(*) as dias
FROM (SELECT distinct monitor_code, date_local, 
    DATE_SUB(date_local, INTERVAL (dense_rank()OVER(partition by monitor_code order by date_local)) DAY) as isla
    FROM `Texas_CO_2021.texas_co_hourly_2021`)
group by monitor_code, isla
;

--Periodos sin registros rankeados
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

--Sample measurement stadistics
SELECT monitor_code,mdl,MIN(sample_measurement) as minimo,
MAX(sample_measurement) as maximo,
AVG(sample_measurement) as promedio,
units_of_measure,
count(*) as registros
FROM `Texas_CO_2021.texas_co_hourly_2021`
GROUP BY monitor_code,units_of_measure,mdl;

--Lecturas
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

--Dias de la semana con falta de registros
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

-- huecos horas
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

--15 Febrero
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

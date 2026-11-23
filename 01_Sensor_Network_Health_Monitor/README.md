# Resume

This project is made to resolve .

## Business case

(El escenario es ficticio, los datos son reales.) Eres Data Associate en un equipo que consume datos de una red de sensores ambientales de terceros. Un cliente se queja de que sus reportes tienen huecos y valores raros. Tu gerente te pide un diagnóstico de salud de la red: qué sensores son confiables, cuáles fallan y cuáles hay que excluir antes de entregar datos.

## Business Questions

¿Cuál es la completitud (% de lecturas esperadas vs. recibidas) de cada sensor en el periodo analizado?
¿Dónde están los huecos más largos y cuándo ocurren?
¿Hay duplicados o lecturas inconsistentes?
¿Qué lecturas son outliers o físicamente imposibles?
¿Qué sensores recomendarías excluir, vigilar o aprobar?

## Data

Dataset: bigquery-public-data.epa_historical_air_qualiy.

## Methodology

Plan del proyecto

| Sesión | Fase | Objetivo |
| 1 | SQL | Explorar el esquema y definir el alcance |
| 2 | SQL + Excel | Extraer datos y perfilar calidad |
| 3 | Excel + Power BI | Validación y modelo del dashboard |
| 4 | Power BI + insights | Dashboard y presentación ejecutiva |

## Findings

## Recommendations

## How to

Tareas

Tarea 1: Inventario de tablas.
Consulta el INFORMATION_SCHEMA del dataset y lista sus tablas. Reporta cuántas hay, con qué patrón de nombres y cuáles parecen horarias y cuáles diarias.

Tarea 2: Elegir una tabla candidata.
Busca una tabla horaria de un parámetro con relevancia energética (por ejemplo, temperatura o algún contaminante asociado a combustión). Justifica tu elección en dos líneas.

Tarea 3: Entender el esquema.
Consulta INFORMATION_SCHEMA.COLUMNS de esa tabla y responde:

¿Cuál es la granularidad? ¿Qué combinación de columnas identifica de forma única una lectura?
¿Qué columnas sirven para identificar un sensor y cuáles para el tiempo?
¿Hay columnas de calidad o banderas (flags, método, unidades)? ¿Cuáles?

Tarea 4: Costo antes de ejecutar.
Antes de correr cualquier SELECT sobre la tabla, revisa cuántos bytes va a procesar (el estimador de la consola). Anota cuántos y qué cambia si acotas por fecha, columnas o estado.

Tarea 5: Definir el alcance.
Elige un estado o ciudad y un periodo de 1 a 2 años donde haya suficientes sensores para comparar. Escribe una consulta que cuente sensores y lecturas por año, y úsala para justificar tu elección.

## Decisions and leassons learned

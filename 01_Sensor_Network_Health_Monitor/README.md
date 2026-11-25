# Resume

This project was made to analize the content in a dataset related to air quality data.

## Business case

    (El escenario es ficticio, los datos son reales.) Eres Data Associate en un equipo que consume datos de una red de sensores ambientales de terceros. Un cliente se queja de que sus reportes tienen huecos y valores raros. Tu gerente te pide un diagnóstico de salud de la red: qué sensores son confiables, cuáles fallan y cuáles hay que excluir antes de entregar datos.

    The scenary is fictional, the data is real. You're a Data Associate on a team responsible for analizing data from a third-party enviromental sensor network. The client complains that their reports contain gaps and with unusual readings. Your manager asks for a network health assessment to determine: which sensors are reliable, which ones are failling, and which ones should be excluded before delivering the data.

## Business Questions

¿Cuál es la completitud (% de lecturas esperadas vs. recibidas) de cada sensor en el periodo analizado?
¿Dónde están los huecos más largos y cuándo ocurren?
¿Hay duplicados o lecturas inconsistentes?
¿Qué lecturas son outliers o físicamente imposibles?
¿Qué sensores recomendarías excluir, vigilar o aprobar?

What is the completeness rate (percentage of expected readings vs received readings) for each sensor during the analyzed period?
When do the longest gaps occur, and when do they happend?
Are there any duplicate records or inconsistent readings?
Which readings are outliers or physically impossible?
Which sensors would you recommend excluiding, monitoring or approving?

## Data

Dataset: bigquery-public-data.epa_historical_air_qualiy.

## Methodology

Plan del proyecto

| Sesión | Fase | Objetivo |
| --- | --- | --- |
| 1 | SQL | Explorar el esquema y definir el alcance |
| 2 | SQL + Excel | Extraer datos y perfilar calidad |
| 3 | Excel + Power BI | Validación y modelo del dashboard |
| 4 | Power BI + insights | Dashboard y presentación ejecutiva |

| Session | Phase | Objetive |
| --- | --- | --- |
| 1 | SQL | Explore the schema and define the scope |
| 2 | SQL + Excel | Extract data and assess data quality |
| 3 | Excel + Power BI | Validation and  dashboard modelling |
| 4 | Power BI + insights | Dashboard development and executive presentation |

## How to

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

Del bloque 1 y 2 si que aprendi bastante en cuanto a calidad de la informacion. Anteriormente hubiera ido sobre los datos estadisticos basicos (min, max, avg, etc) y no me hubiera preocupado por los gaps tanto como se realizo en el proyecto. Tambien el manejo de COALESCE cuando existen datos de tipo NULL que necesitan ser tratados como otro tipo de dato para su visualizaicon y comparacion.

Del bloque 1 la leccion mas importante fue empezar a armar una investigacion, elegir con que queria desarrollar mi idea y empezar a describir que podia obtener, con que informacion y el tipo de informacion que estaba extrayendo.

Del bloque 2 mi habilidad para escribir consultas en SQL se vio altamente desafiada, a pesar de entender lo que tenia que lograr, no lograba conectar la informacion entre consultas. Pase de evaluar unicamente la cantidad de registros, acomodarlos por dia, mes y año, a hacer consultas que mostraban los huecos de datos entre registros por horas o por dia.

Conforme avance y vi los tipos de datos, entendi como ejecutar los comandos adecuados para la transformacion efectiva de las fechas, la manipulacion de las funciones tipo LAG y LEAD y el uso del sistema de RANKING para enfatizar datos destacados de ciertas consultas.

Adicionalmente, las preguntas generadas por la IA referentes a investigar sobre que ocurrio en cierta fecha, me llevaron a encontrar informacion clave. No solamente existio un corte en la energia electrica derivado de una tormenta invernal, algunas zonas no tuvieron ese problema dado que existen en una red electrica operada por distintas empresas.

## Findings

## Recommendations

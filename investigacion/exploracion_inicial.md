# Exploración inicial de las fuentes

Fecha de revisión: 2026-09-25.

## Archivos y estructura

- `BD_2020.xlsx` a `BD_2025.xlsx`: seis libros de mediciones. Cada hoja representa una estación y contiene 16 columnas. Las 15 variables de medición son `CO`, `NO`, `NO2`, `NOX`, `O3`, `PM10`, `PM2.5`, `PRS`, `RAINF`, `RH`, `SO2`, `SR`, `TOUT`, `WSR` y `WDR`. La columna temporal se llama `Fecha y hora` en 2020–2024 y `date` en 2025; `readxl` la interpreta como fecha y hora en ambos casos.
- Cobertura de hojas: 13 estaciones en 2020, 14 en 2021 y 15 en cada año de 2022 a 2025. Hay 87 hojas y aproximadamente 754 954 filas de datos en total, contadas a partir de las filas XML de los libros, sin incluir encabezados.
- La hoja `NO3` de 2022 tiene 743 filas de mediciones y empieza en diciembre; las demás hojas suelen cubrir casi todo su año respectivo. El número de filas por sí solo no establece continuidad horaria.
- `Etiquetas.xlsx` tiene las hojas `Variables` y `Banderas`. Describe estaciones, contaminantes, parámetros meteorológicos, unidades y códigos de bandera.
- `ubicacion_estaciones.docx` enumera 15 estaciones con coordenadas y elevaciones, y está titulado como información de 2025.
- `rangos_parametros_SIMA.pdf` presenta rangos de operación por año (2020–2025), un rango del fabricante y notas específicas para algunos parámetros de 2020 y 2021.

## Cuestiones para revisar antes del análisis

- En `Etiquetas.xlsx`, la abreviatura `SE` aparece también en la fila de “Sur”, mientras los libros de datos usan `SUR`. La tabla de estaciones incluye 13 entradas y no enumera `NE3` ni `NO3`. Algunas filas tienen municipio vacío. Se debe cotejar con el documento de ubicaciones antes de integrar una tabla maestra.
- El PDF llama a sus valores “rangos de operación” y “rango del fabricante”; no deben interpretarse como límites normativos de calidad del aire. Los encabezados del PDF (`BP`, `TEMP`, `WS`, `WD`) tampoco coinciden literalmente con los de las bases (`PRS`, `TOUT`, `WSR`, `WDR`). Cualquier equivalencia deberá verificarse y codificarse expresamente.
- La hoja `Variables` contiene notas sobre conversiones y tratamiento de banderas. Se registran como contenido de la fuente; no se aplicó ninguna transformación ni exclusión a las bases originales.
- Faltan comprobaciones de continuidad temporal, duplicados de fecha y estación, valores faltantes, unidades consistentes y valores fuera de rango. Esas revisiones serán parte de la fase analítica.

Los nueve archivos originales se copiaron sin modificaciones. `datos/manifiesto_fuentes.csv` permite comprobar su integridad.

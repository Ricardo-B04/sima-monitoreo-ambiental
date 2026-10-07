# Decisiones y puntos abiertos

Registro de lo que el equipo ha acordado y de lo que sigue pendiente. Se actualiza conforme avanza el análisis.

## Acordado

- Enfoque: combinar tipologías multivariadas diarias (PCA y conglomerados de estaciones y días) con un clasificador de episodios de excedencia de ozono (análisis discriminante principal; regresión logística como comparación).
- Los libros de mediciones se leen sin modificarlos; cualquier limpieza se documenta en código antes de usarse en un informe.

- Periodo de análisis: 2020–2025 (6 libros). No se incorpora el año parcial de 2026; el informe y los documentos de preparación se ajustaron a esto.

## Pendiente de decidir

| Tema | Situación |
|---|---|
| Periodo de modelado | 2020 tiene muchos nulos en gases (NO2, NOX, NO, O3, CO, SO2) y varias estaciones sin sensor. Propuesta: conservarlo en la depuración y fuera de los modelos. |
| Umbral de ozono | El borrador plantea un límite escalonado del máximo diario de la media móvil de 8 h (0.065 ppm en 2022–2023, 0.060 en 2024–2025, 0.051 en 2026). Verificar contra la NOM-020-SSA1-2021 y SINAICA. Los conteos preliminares con 90 ppb (1 h) y 70 ppb (8 h) no deben usarse. |
| Cobertura diaria | Propuesta: un día cuenta para una variable con al menos 75 % de horas válidas. |
| PM2.5 | 17–34 % de nulos en 2022–2025 y casi vacío en NE3 y NO3. Propuesta: fuera de la primera versión. |
| Reglas de limpieza | Centinela -9999 y valores fuera de rango (TOUT, RH, SR, WSR, PRS, RAINF) por definir y cruzar con `rangos_parametros_SIMA.pdf`. |
| Conteo de registros | Difiere del borrador en 2020 (-70), 2021 (-268) y 2024 (-13); en 2022, 2023 y 2025 coincide. Hipótesis sin confirmar: filas vacías en el XML. |
| NOX | No coincide con NO + NO2 en 23 525 registros pese a que el diccionario lo define como su suma. |
| Radiación y humedad inusuales (Etapa 2) | 146 estación-días con `SR_media` > 0.4 kW/m² (90 en NE2-2021, 51 en NO2) y 71 con `RH_media` < 10 %. Pasan los rangos de operación pero parecen falla de sensor; coinciden con los atípicos de Mahalanobis. Consultar con SIMA antes de invalidarlos. |
| Presión por estación (Etapa 2) | En la exploración se usa como anomalía respecto de la media de cada estación; decidir si así entra a PCA y modelos. |
| Validación (Etapa 2) | Propuesta: entrenar 2021–2024 y evaluar 2025, y dejar una estación fuera. |
| Fuentes de apoyo | PIMUS, inventario 2018 y padrón de medio ambiente se citan en el borrador pero no están en el repo. |

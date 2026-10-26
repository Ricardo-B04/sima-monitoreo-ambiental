# Decisiones metodológicas del proyecto SIMA

Registro actualizado al cierre de la Etapa 4. Resume las decisiones que finalmente se aplicaron; las propuestas de las etapas iniciales se distinguen de los análisis realizados.

## Pregunta, alcance y unidad de análisis

El objetivo final es describir las asociaciones del ozono con sus precursores y la meteorología, y evaluar la clasificación de días-estación con excedencia. Se estudian las estaciones SIMA de la Zona Metropolitana de Monterrey. No se interpretan las asociaciones como efectos causales de las emisiones ni se evalúan intervenciones de política ambiental.

La unidad es el **día-estación**. No se definió una agrupación de días consecutivos ni se calcularon métricas por episodio. Los clasificadores usan variables del mismo día; el AR(1) añade respuestas previamente observadas de la misma estación. Se trata de clasificación con datos observados y no de pronóstico anticipado.

## Datos y preparación

| Tema | Decisión final |
| --- | --- |
| Fuentes y periodo | Se limpiaron seis libros horarios de 2020–2025. Se excluyó el séptimo libro, de enero–julio de 2026, por estar incompleto. El modelado usa 2021–2025; 2020 se conserva en la base limpia y en el diagnóstico, pero se excluye de los modelos por su cobertura. |
| Integridad | Los originales no se modifican. Se registran sus huellas y las conversiones y exclusiones en los análisis 01 y 02. Las notas iniciales sobre diferencias de conteo no se interpretan como cambios en los archivos originales. |
| Limpieza | Se convirtieron los valores inválidos en faltantes de acuerdo con los rangos de SIMA y las reglas documentadas en el análisis 02. Se conservaron los extremos físicamente plausibles. No se imputaron datos. |
| Cobertura diaria | La agregación diaria requiere al menos 18 horas válidas. Para el promedio móvil de ocho horas se requieren al menos seis lecturas válidas por ventana y se conservan las ventanas que cruzan medianoche según el cálculo del análisis 02. |
| Respuesta | Máximo diario del promedio móvil de ozono de ocho horas, en ppb (`O3_max8`). |
| Umbrales | Comparación analítica de días con `O3_max8 > 60` y `O3_max8 > 51` ppb. No se mezclan límites de una hora con los de ocho horas ni se presentan estos escenarios fijos como una auditoría normativa anual. |
| Predictores finales | NO y NO₂ transformados con `log(1+x)`, temperatura máxima, radiación y humedad medias, presión media y componentes U y V del viento. Se añaden términos anuales y semianuales en los modelos de concentración y clasificación. |
| Precursores | NOₓ se excluye para evitar repetir la señal de NO y NO₂. Las diferencias observadas frente a la suma NO + NO₂ no se corrigen imponiendo una igualdad a las mediciones. |
| Transformación | `log(1+x)` reduce el contraste entre muchos valores bajos y pocos muy altos, conservando los ceros. Se comparó con el uso de precursores sin logaritmos; la ventaja no fue uniforme. Las curvas se interpretan como asociaciones condicionadas. |
| Casos completos | Los modelos se ajustan con casos completos para los predictores y la respuesta. El complemento final compara la cobertura por año, estación y mes y las características de los casos completos e incompletos. |
| Otras fuentes y variables | PM2.5 no forma parte de los ocho predictores finales. No se analizaron el padrón vehicular, inventarios de emisiones ni mediciones de compuestos orgánicos volátiles para atribuir fuentes concretas. |

La base diaria contiene 32,880 filas de 2020–2025 y 31 columnas. El periodo 2021–2025 reúne 27,390 días-estación; el conjunto completo utilizado en la comparación final de modelos contiene 19,668 casos, con 16,300 hasta 2024 y 3,368 en 2025. Estas cifras corresponden a conjuntos distintos y no deben intercambiarse.

## Técnicas y decisiones sobre los modelos

| Técnica | Aplicación y alcance |
| --- | --- |
| PCA | Describe la estructura de ocho predictores. Se centra por estación y se estandariza con datos de entrenamiento de 2021–2024. Se conservan cuatro componentes, que resumen el 81.02 % de la variación de los predictores; ese porcentaje no es variación explicada del ozono. Se mantiene el PCA original porque excluir los 82 días señalados de su conjunto de entrenamiento cambió poco la estructura. |
| Regresión lineal | Estima la concentración por estación. Se revisan residuos, dependencia, relaciones con predictores y coeficientes. La asimetría marginal del ozono no se usa por sí sola para justificar o rechazar el modelo. |
| GAM | Permite asociaciones no lineales y se compara con la regresión lineal sobre los mismos días de prueba. Sus contribuciones y curvas son descriptivas, no efectos causales. |
| GAMM de CE | Complemento de una estación con errores AR(1). Reduce la dependencia residual, pero no representa una validación para toda la red. La interpretación de variables y la prueba con la regla inicial de calidad se incluyen en la revisión final. La prueba de calidad ampliada se omitió por el tiempo de cálculo. |
| Logística original | Clasifica los umbrales de 60 y 51 ppb con predictores del día e indicadores de estación. Los cortes de probabilidad se eligen en un periodo anterior a la prueba. |
| Logística AR(1) | Modelo binomial con un estado temporal por estación; comparte parámetros de persistencia y dispersión entre estaciones. Estandariza los predictores con el entrenamiento. Para evaluar, calcula la probabilidad antes de incorporar la respuesta del día y actualiza el estado con las respuestas ya observadas. No utiliza estados suavizados que conozcan respuestas futuras. |
| Forma del logit | Se revisa la relación lineal de los predictores continuos en la escala logit mediante curvas cúbicas naturales, comparaciones individuales y una alternativa flexible conjunta. No se confirmó plenamente la linealidad; la alternativa flexible no mejoró de forma uniforme. No se afirma que el AR(1) resuelva este supuesto. |
| Persistencia | Línea base basada en el evento del día calendario anterior. Si falta ese dato, usa la frecuencia de entrenamiento. Se reporta su cobertura. |

Los cambios de la ruta inicial se documentan en el informe. Las comparaciones de medias con T² de Hotelling y MANOVA no se usaron como requisito previo para clasificar. LDA, QDA y conglomerados aparecieron en propuestas iniciales, pero no forman parte de la ruta final aplicada; no se presentan como modelos evaluados ni como resultados fallidos. El PCA se mantuvo como análisis descriptivo y no como entrada de los clasificadores.

## Validación e incertidumbre

- La evaluación principal ajusta hasta 2024 y compara en 2025. Para seleccionar los cortes de clasificación se usa 2024 después de ajustar con 2021–2023; posteriormente se reajusta hasta 2024 y se mantiene el corte al evaluar 2025.
- Se distingue la exactitud balanceada de sensibilidad, precisión y F1. Un mayor número de excedencias detectadas puede aumentar las falsas alarmas; no se declaró un corte universal sin definir el costo de ambos errores.
- El complemento usa cortes temporales crecientes para evaluar 2023, 2024 y 2025 con regresión lineal, GAM y las logísticas original y flexible. No se extendió esa comparación entre años al modelo AR(1).
- La validación al dejar una estación fuera corresponde a la logística sin indicador de estación. Permite clasificar una estación ausente del entrenamiento sin necesitar un coeficiente específico de ese sitio. No demuestra transferencia del AR(1) a una estación nueva.
- Los intervalos del complemento final usan 2,000 remuestreos de bloques móviles de siete y 14 días, manteniendo juntas todas las estaciones. Se conservan predicciones, cortes y parámetros; no se cuantifica la incertidumbre de volver a ajustar los modelos.
- Como 2025 ya se había explorado al decidir ampliaciones, las comparaciones posteriores son exploratorias y no equivalen a una prueba completamente independiente.
- Se conserva el fallo de concentración en NO3 al evaluar 2024 con solo 46 días completos de ajuste. La comparación adicional sin NO3 muestra su influencia y no reemplaza el resultado completo.

## Calidad de radiación, humedad y datos faltantes

Las señales iniciales son `SR_media > 0.4 kW/m²` y `RH_media < 10 %`. Los 82 días corresponden a los casos completos usados en el PCA de entrenamiento, no a todo el periodo. Las mismas reglas señalan 217 días-estación en 2021–2025. La revisión horaria añade una regla distinta, con al menos cinco lecturas válidas entre las 10 y las 16 horas y todas iguales a cero. Esta regla señala 2,383 días-estación y necesita los libros horarios.

Las franjas horarias usan el reloj original del archivo, sin conversión de zona horaria. Los ceros nocturnos se conservan. Las señales no equivalen a fallas confirmadas ni justifican eliminar automáticamente las observaciones o modificar la base diaria.

Se comparan modelos con y sin los días señalados, incluida regresión lineal y clasificación AR(1). La sensibilidad del GAMM solo se completó para la regla inicial. Los cambios en desempeño fueron mixtos, por lo que no se adoptó una exclusión general como solución. Sin los originales, las comparaciones que dependen de la regla horaria no se reproducen con la misma selección de días.

## Conclusiones que se conservan

El GAM redujo el RMSE global de 2025 frente a la regresión lineal, de 13.57 a 12.59 ppb, pero ambos subestimaron el ozono. La ventaja no fue uniforme entre años y estaciones.

La logística AR(1) redujo la autocorrelación residual diaria y mostró una mejora moderada en la clasificación observada. A 60 ppb, la sensibilidad pasó de 83.1 % a 86.1 % y la precisión de 51.5 % a 52.6 %. A 51 ppb, la sensibilidad pasó de 76.1 % a 82.8 %, con precisión de 75.1 % a 74.3 %. Los intervalos por bloques de la diferencia en exactitud balanceada incluyen cero, por lo que no se afirma una superioridad concluyente. Tampoco se considera eliminada toda la dependencia ni alcanzado un límite de desempeño de la logística.

La relevancia de las variables se interpreta por modelo y estación, con atención a la correlación entre predictores. No se suman contribuciones de precursores y temperatura para atribuirles un porcentaje causal del ozono.

## Límites y posibles trabajos posteriores

Quedan sujetos a información externa la confirmación de sensores y fechas de mantenimiento, y el costo que SIMA asignaría a las excedencias omitidas y las falsas alarmas. Una aplicación futura requeriría validación prospectiva y datos disponibles con la anticipación deseada. El estudio de mínimos y la definición de episodios fueron sugerencias de ampliación; no se incorporaron como objetivos realizados ni como requisitos pendientes del análisis entregado.

La implementación está en los cuatro Rmd y en `analisis/complemento_retro_etapa3.R`. Los antecedentes bibliográficos, resultados completos y limitaciones se presentan en `entregables/entregable4/main.tex`. Las notas de `exploracion_inicial.md` se conservan como registro histórico de las primeras revisiones.

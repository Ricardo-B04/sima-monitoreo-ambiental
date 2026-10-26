# Proyecto SIMA: monitoreo ambiental de Nuevo León

Proyecto del Equipo 3 sobre el ozono y sus relaciones con los precursores y la meteorología en las estaciones SIMA de la Zona Metropolitana de Monterrey. Incluye la preparación de datos, los análisis en R y los informes en LaTeX de las etapas 1, 2, 3 y 4.

## Objetivo y alcance final

El proyecto describe las asociaciones entre el ozono, NO, NO₂ y las variables meteorológicas, y evalúa la clasificación de días-estación con excedencia. La limpieza comprende 2020–2025; la exploración y el modelado final se concentran en 2021–2025 por la baja cobertura de 2020. El libro de enero–julio de 2026 se excluyó por ser un año incompleto.

La unidad de análisis es el **día-estación**. La respuesta es el máximo diario del promedio móvil de ozono de ocho horas. Se comparan umbrales fijos de **60 y 51 ppb**, sin interpretar estos escenarios como una evaluación del cumplimiento normativo anual. No se agrupan ni evalúan episodios de varios días consecutivos.

La clasificación usa variables observadas del mismo día; la logística AR(1) añade el historial previo de cada estación. Por tanto, los resultados describen clasificación con datos ya observados, no un pronóstico anticipado. Las relaciones entre variables se interpretan como asociaciones y no como efectos causales.

## Estructura

| Ruta | Contenido |
| --- | --- |
| `datos/originales/` | Libros horarios `BD_2020.xlsx` a `BD_2025.xlsx`, obtenidos por el canal de la clase y no publicados; `Etiquetas.xlsx` contiene el diccionario. El libro parcial de 2026 no es necesario para ejecutar los análisis. |
| `datos/procesados/sima_diaria_estacion.csv` | Base diaria limpia de 2020–2025, con 32,880 filas y 31 columnas. La genera el análisis 02 y permite ejecutar la exploración y los modelos sin repetir la limpieza. |
| `datos/manifiesto_fuentes.csv` | Nombres, tamaños y huellas SHA-256 de las fuentes registradas. |
| `datos/rangos_operacion_SIMA.csv` | Rangos por año y variable, tomados de `referencias/originales/rangos_parametros_SIMA.pdf`. |
| `analisis/01_comprension_datos.Rmd` | Revisión de integridad, cobertura y calidad de los libros originales. |
| `analisis/02_preparacion_datos.Rmd` | Limpieza, agregación diaria y construcción de la base procesada. |
| `analisis/03_exploracion_descriptiva.Rmd` | Descripción de los datos; genera figuras y tablas del Entregable 2. |
| `analisis/04_modelado y evaluación.Rmd` | PCA, regresión lineal, GAM, GAMM de CE, logística y logística AR(1), junto con las comparaciones y validaciones finales. |
| `analisis/complemento_retro_etapa3.R` | Complemento llamado por la sección 13 del análisis 04. Interpreta variables, revisa la forma del logit y amplía la validación temporal, la incertidumbre y la revisión de calidad. Necesita los objetos creados por el Rmd; no se ejecuta por separado. |
| `analisis/salidas/` | HTML, tablas CSV, predicciones, información de sesión y cachés generados localmente. Esta carpeta está ignorada por Git. |
| `entregables/entregable1/`, `entregable2/`, `entregable3/`, `entregable4/` | Informes de las cuatro etapas con `main.tex`, `main.pdf`, imágenes y tablas. El Entregable 3 corresponde al reporte de modelado y evaluación; el 4, al informe final. |
| `R/` | Scripts para ejecutar los análisis, compilar los informes e inventariar las fuentes. |
| `investigacion/` | Notas de exploración y [decisiones metodológicas finales](investigacion/decisiones.md). Las notas iniciales se conservan como antecedentes. |
| `referencias/originales/` | Documentos de ubicación de estaciones y rangos recibidos. |
| `renv.lock` | Versiones de los paquetes de R y sus dependencias. |

## Preparación del entorno

Abrir `sima-monitoreo-ambiental.Rproj` en RStudio o trabajar desde la raíz del repositorio. El entorno registrado usa **R 4.6.1**. Restaurar los paquetes con:

```r
renv::restore(prompt = FALSE)
```

La logística AR(1) necesita `glmmTMB` 1.1.15.2 o posterior. El archivo de dependencias conserva la versión utilizada y también registra los paquetes necesarios para GAM y GAMM. La biblioteca instalada y los cachés no se publican.

Para generar los HTML se necesita Pandoc, incluido en RStudio. Al ejecutar fuera de RStudio, Pandoc debe estar en `PATH` o su carpeta debe indicarse mediante la variable de entorno `RSTUDIO_PANDOC`. Para compilar los informes se necesita una distribución de LaTeX con **XeLaTeX y pdfLaTeX**, como TinyTeX. Los scripts no instalan paquetes ni componentes de LaTeX automáticamente.

## Ejecución de los análisis

Los siguientes comandos se ejecutan en una terminal situada en la raíz del repositorio:

```sh
Rscript R/ejecutar_analisis.R --simular
Rscript R/ejecutar_analisis.R
```

`--simular` muestra lo que se ejecutaría sin ajustar modelos ni escribir resultados. Sin seleccionar documentos, el script ejecuta 01, 02, 03 y 04 en ese orden. Si faltan los libros de 2020–2025, omite 01 y 02 y utiliza la base diaria disponible. También se pueden elegir documentos:

```sh
Rscript R/ejecutar_analisis.R 03
Rscript R/ejecutar_analisis.R 04
Rscript R/ejecutar_analisis.R 03 04 --sin-auditoria-horaria
```

| Análisis | Entrada necesaria | Resultado principal |
| --- | --- | --- |
| 01 | Seis libros horarios de 2020–2025 y manifiesto de fuentes | Diagnóstico de calidad e integridad. |
| 02 | Los mismos libros y rangos de operación | Base diaria limpia. |
| 03 | Base diaria limpia | Descripción, figuras y tablas del Entregable 2. |
| 04 | Base diaria limpia, complemento R y dependencias restauradas | Modelos, validaciones y salidas de las secciones 1–13. La auditoría horaria necesita además los libros de 2021–2025. |

Los HTML se escriben en `analisis/salidas/`. El análisis 04 guarda las comparaciones de las secciones 7–12 en `analisis/salidas/cierre/` y las ampliaciones de la sección 13 en `analisis/salidas/retro_etapa3/`. El análisis 02 vuelve a escribir la base procesada y el 03 vuelve a generar los recursos del Entregable 2.

### Alcance al ejecutar solo con la base diaria

La base diaria permite reproducir la exploración y ajustar los modelos. Sin los libros horarios **no se reproduce la revisión de ceros de radiación durante el día**, ni se obtienen las mismas exclusiones de la regla ampliada de calidad. En ese caso, el código mantiene las señales que se pueden calcular con los datos diarios, pero no añade las señales horarias. El script avisa de esta diferencia; `--sin-auditoria-horaria` también permite omitir esa lectura expresamente.

Los libros originales se conservan sin cambios. La limpieza convierte valores inválidos en faltantes, mantiene los extremos físicamente plausibles y no imputa observaciones. Para los modelos se utilizan casos completos; los análisis finales revisan las diferencias con los casos incompletos.

### Ajustes que requieren más tiempo

El análisis 04 puede tardar bastante por los ajustes AR(1), las comparaciones temporales y los remuestreos. El GAMM original de CE está desactivado en la sección 4 mediante `ejecutar_gamm: false`, pero **la sección 13 lo vuelve a ajustar si no encuentra** `analisis/salidas/retro_etapa3/gamm_original_ce.rds` ni un ajuste ya disponible en memoria. Desactivar aquel parámetro no evita este cálculo del complemento.

Las pruebas de calidad del GAMM usan `gamm_calidad_Inicial.rds` si está disponible. Si falta, se omite esa comparación por defecto. La comparación con la regla ampliada no se completó en el proyecto por su costo de cálculo. La opción `options(sima.reajustar_gamm_calidad = TRUE)` solicita nuevos ajustes de sensibilidad para las reglas sin caché; no es necesaria para la ejecución habitual y puede tardar más de una hora.

Los RDS son cachés regenerables. Sin el ajuste inicial guardado, una ejecución con las opciones habituales no recrea la tabla de sensibilidad del GAMM incluida en el informe. Los CSV conservan las cifras obtenidas, pero no sustituyen los modelos RDS para evitar un nuevo ajuste. Estos archivos están actualmente dentro de la carpeta de salidas ignorada por Git.

## Ruta de análisis final

- **Interdependencia:** PCA de los ocho predictores, centrados por estación y estandarizados con el entrenamiento. Sus componentes describen la estructura de las variables; no se incorporan al clasificador.
- **Concentración de ozono:** regresión lineal y GAM por estación, con un GAMM AR(1) complementario para CE.
- **Clasificación:** logística original y logística con estado temporal AR(1), para 60 y 51 ppb. Se comparan con persistencia del día previo y con una alternativa logística flexible.
- **Validación:** evaluación principal en 2025; cortes temporales adicionales en 2023 y 2024 para los modelos indicados en el informe; prueba en estaciones excluidas para la logística sin indicador de estación. Esta última prueba no evalúa la transferencia del modelo AR(1).
- **Diagnósticos:** dependencia residual, forma de los predictores en el logit, transformación de los precursores, datos faltantes y señales de calidad de radiación y humedad.
- **Incertidumbre:** 2,000 remuestreos en bloques de siete y 14 días en el complemento final, manteniendo juntas las estaciones y las predicciones. Los intervalos no incluyen volver a ajustar los parámetros.

Las decisiones y limitaciones se detallan en `investigacion/decisiones.md` y en el informe final. Como 2025 ya se había explorado, las comparaciones posteriores no se presentan como una prueba completamente independiente.

## Compilación de los informes

```sh
Rscript R/compilar_entregables.R --simular
Rscript R/compilar_entregables.R
Rscript R/compilar_entregables.R entregable4
```

El script busca `entregables/*/main.tex` y lee la indicación `% !TeX program = ...` de cada archivo. Los Entregables 1, 2 y 3 usan XeLaTeX; el 4 usa pdfLaTeX. Si no hay indicación, se utiliza XeLaTeX. También se admite LuaLaTeX cuando esté indicado en el documento. Una carpeta solicitada sin `main.tex` o una compilación fallida producen un error al terminar.

Cada PDF se genera junto a su fuente, como `entregables/entregable4/main.pdf`. Para Overleaf se sube el contenido de esa carpeta con sus imágenes y tablas, se selecciona `main.tex` como documento principal y se usa pdfLaTeX. No es necesario volver a ajustar los modelos para compilar el informe con los recursos incluidos. Las fechas de portada deben mantenerse fijas para conservar la fecha de entrega.

## Recursos del informe y organización

R realiza la limpieza, el análisis estadístico y la generación de resultados. LaTeX organiza el informe y sus tablas y figuras. Durante la elaboración se usó Python para preparar recursos y comprobar cifras y archivos; esos auxiliares todavía deben incorporarse al repositorio para documentar también esa parte del proceso. La compilación del TeX con los recursos incluidos no depende de ellos.

El informe final y su código deben conservar la misma versión. Las tablas CSV y los ajustes necesarios para evitar cálculos largos no se publican automáticamente, porque `analisis/salidas/` está ignorada. Al incorporar resultados finales, conviene guardarlos en una carpeta destinada a esos resultados, separada de los cachés y de los archivos de prueba.

Los libros de mediciones no se distribuyen en este repositorio. Cada integrante debe obtenerlos por el canal autorizado de la clase y colocarlos en `datos/originales/` con los nombres indicados arriba. Las notas de [exploración inicial](investigacion/exploracion_inicial.md) describen las primeras revisiones; las decisiones que finalmente se adoptaron están en el registro metodológico actualizado.

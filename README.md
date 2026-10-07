# Proyecto SIMA: monitoreo ambiental de Nuevo León

Repositorio para el análisis en R de las bases SIMA 2020–2025 y para la elaboración de investigación e informes en LaTeX.

Pregunta de investigación: ¿cómo se relacionan las concentraciones de ozono con sus precursores (NO, NO2, NOx) y con las variables meteorológicas en las estaciones de SIMA entre 2020 y 2025, y qué combinación de estas variables permite explicar y clasificar los episodios de excedencia de ozono?

## Estructura

| Ruta | Contenido |
| --- | --- |
| `datos/originales/` | Carpeta local para los libros de mediciones `BD_2020.xlsx` a `BD_2025.xlsx` (no se publican). Incluye el diccionario `Etiquetas.xlsx`. |
| `datos/procesados/sima_diaria_estacion.csv` | **Base limpia** (una fila por estación-día, 32,880 filas y 31 columnas). La genera `02_preparacion_datos.Rmd`. |
| `datos/manifiesto_fuentes.csv` | Nombres de origen, tamaños y huellas SHA-256 para identificar las fuentes. |
| `datos/rangos_operacion_SIMA.csv` | Rangos de operación por año y parámetro, transcritos de `referencias/originales/rangos_parametros_SIMA.pdf`; los usa la limpieza. |
| `referencias/originales/` | Documento de ubicación de estaciones y PDF de rangos recibidos, sin cambios. |
| `R/` | Script de inventario de las bases originales. |
| `investigacion/` | Notas metodológicas, hallazgos y registro de decisiones ([decisiones.md](investigacion/decisiones.md)). |
| `informes/` | Documentos de trabajo (`01_`, `02_`, `03_*.Rmd`), informes LaTeX de cada entregable (`entregable1/`, `entregable2/`) y `plantilla.tex`. Las salidas compiladas van a `informes/build/` (no se versiona). |

## Orden de ejecución

Todos los comandos se ejecutan desde la raíz del repositorio. Se requiere R 4.6 y una distribución de LaTeX con `latexmk` y XeLaTeX.

| Paso | Archivo | Entrada | Salida | ¿Requiere libros originales? |
| --- | --- | --- | --- | --- |
| 0 | `renv::restore()` | `renv.lock` | Paquetes de R | No |
| 1 | `R/inventario.R` | `datos/originales/` | Inventario en consola | Sí |
| 2 | `informes/01_comprension_datos.Rmd` | `datos/originales/` | Diagnóstico de calidad (HTML) | Sí |
| 3 | `informes/02_preparacion_datos.Rmd` | `datos/originales/`, `datos/rangos_operacion_SIMA.csv` | Limpieza y transformación (HTML) y `datos/procesados/sima_diaria_estacion.csv` | Sí |
| 4 | `informes/entregable1/main.tex` | Cifras de los pasos 2–3 | Entregable 1 (PDF) | No |
| 5 | `informes/03_exploracion_descriptiva.Rmd` | `datos/procesados/sima_diaria_estacion.csv` | Exploración descriptiva (HTML), figuras en `informes/entregable2/img/` y tablas en `informes/entregable2/tablas/` | No |
| 6 | `informes/entregable2/main.tex` | Figuras y tablas del paso 5 | Entregable 2 (PDF) | No |

```sh
Rscript -e 'renv::restore(prompt = FALSE)'

# Pasos 1-3: necesitan los libros originales en datos/originales/
Rscript R/inventario.R
Rscript -e 'rmarkdown::render("informes/01_comprension_datos.Rmd", output_dir = "informes/build")'
Rscript -e 'rmarkdown::render("informes/02_preparacion_datos.Rmd", output_dir = "informes/build")'
latexmk -xelatex -cd -outdir=../build/entregable1 informes/entregable1/main.tex

# Pasos 5-6: se pueden ejecutar sólo con el repositorio (parten de la base limpia .csv)
Rscript -e 'rmarkdown::render("informes/03_exploracion_descriptiva.Rmd", output_dir = "informes/build")'
latexmk -xelatex -cd -outdir=../build/entregable2 informes/entregable2/main.tex
```

`renv.lock` fija las dependencias de R; la biblioteca instalada queda fuera del control de versiones.

Los libros de mediciones no se distribuyen en este repositorio. Cada integrante debe obtenerlos por el canal de la clase y colocarlos en `datos/originales/` con los nombres indicados en `datos/originales/README.md`. Los libros sólo se leen; toda limpieza, conversión o exclusión está explícita en código y documentada en `02_preparacion_datos.Rmd`.

Ver [exploración inicial](investigacion/exploracion_inicial.md) para la cobertura observada y los puntos pendientes.

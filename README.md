# Proyecto SIMA: monitoreo ambiental de Nuevo León

Repositorio para el análisis en R de las bases SIMA 2020–2025 y para la elaboración de investigación e informes en LaTeX.

## Estructura

| Ruta | Contenido |
| --- | --- |
| `datos/originales/` | Carpeta local para los libros de mediciones `BD_2020.xlsx` a `BD_2025.xlsx` (no se publican). Incluye el diccionario `Etiquetas.xlsx`. |
| `datos/manifiesto_fuentes.csv` | Nombres de origen, tamaños y huellas SHA-256 para identificar las fuentes. |
| `datos/rangos_operacion_SIMA.csv` | Rangos de operación por año y parámetro, transcritos de `referencias/originales/rangos_parametros_SIMA.pdf`; los usa la limpieza de `informes/02_preparacion_datos.Rmd`. |
| `referencias/originales/` | Documento de ubicación y PDF de rangos recibidos, sin cambios. |
| `R/` | Código para explorar e importar las bases. |
| `investigacion/` | Notas metodológicas, hallazgos y registro de decisiones ([decisiones.md](investigacion/decisiones.md)). |
| `informes/` | Informes: `entregable1/` (borrador LaTeX del Entregable 1 con `img/` y `tablas/`), `01_comprension_datos.Rmd` (diagnóstico de los datos), `02_preparacion_datos.Rmd` (selección y limpieza) y `plantilla.tex`. |

## Primeros pasos

Desde la raíz del repositorio:

```sh
Rscript -e 'renv::restore(prompt = FALSE)'
Rscript R/inventario.R
latexmk -xelatex -outdir=informes/build informes/plantilla.tex
latexmk -xelatex -cd -outdir=../build/entregable1 informes/entregable1/main.tex
Rscript -e 'rmarkdown::render("informes/01_comprension_datos.Rmd", output_dir = "informes/build")'
```

Se requiere R 4.6 y una distribución de LaTeX con `latexmk` y XeLaTeX. `renv.lock` fija las dependencias de R; la biblioteca instalada queda fuera del control de versiones. La plantilla produce un PDF de ejemplo en `informes/build/`, que también se ignora.

Los libros de mediciones no se distribuyen en este repositorio. Cada integrante debe obtenerlos por el canal de la clase y colocarlos en `datos/originales/` con los nombres indicados en `datos/originales/README.md`. El script de inventario sólo los lee; cualquier limpieza, conversión de unidades o exclusión debe quedar explícita en código y documentada antes de usarse en un informe.

Ver [exploración inicial](investigacion/exploracion_inicial.md) para la cobertura observada y los puntos pendientes.

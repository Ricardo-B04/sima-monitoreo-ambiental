# Proyecto SIMA: monitoreo ambiental de Nuevo León

Repositorio para el análisis en R de las bases SIMA 2020–2025 y para la elaboración de los entregables en LaTeX.

Pregunta de investigación: ¿cómo se relacionan las concentraciones de ozono con sus precursores (NO, NO2, NOx) y con las variables meteorológicas en las estaciones de SIMA entre 2020 y 2025, y qué combinación de estas variables permite explicar y clasificar los episodios de excedencia de ozono?

## Estructura

| Ruta | Contenido |
| --- | --- |
| `datos/originales/` | Carpeta local para los libros de mediciones `BD_2020.xlsx` a `BD_2025.xlsx` (no se publican). Incluye el diccionario `Etiquetas.xlsx`. |
| `datos/procesados/sima_diaria_estacion.csv` | **Base limpia** (una fila por estación-día, 32,880 filas y 31 columnas). La genera `analisis/02_preparacion_datos.Rmd`. |
| `datos/manifiesto_fuentes.csv` | Nombres de origen, tamaños y huellas SHA-256 de las fuentes. |
| `datos/rangos_operacion_SIMA.csv` | Rangos de operación por año y parámetro, transcritos de `referencias/originales/rangos_parametros_SIMA.pdf`. |
| `analisis/` | Documentos de trabajo en R Markdown, numerados en orden de ejecución. Sus HTML se generan en `analisis/salidas/` (no se versiona). |
| `entregables/` | Un subdirectorio por entregable (`entregable1/`, `entregable2/`) con `main.tex`, `img/`, `tablas/` y el **`main.pdf` que se entrega**; además `plantilla.tex`. |
| `R/` | Scripts de ejecución (`ejecutar_analisis.R`, `compilar_entregables.R`) y de inventario de las fuentes. |
| `investigacion/` | Notas metodológicas y registro de decisiones ([decisiones.md](investigacion/decisiones.md)). |
| `referencias/originales/` | Documento de ubicación de estaciones y PDF de rangos recibidos, sin cambios. |

## Orden de ejecución

Todo se ejecuta desde la raíz del repositorio (o abriendo `sima-monitoreo-ambiental.Rproj` en RStudio). Se requiere R 4.6 y una distribución de LaTeX con XeLaTeX.

| Paso | Archivo | Entrada | Salida | ¿Requiere libros originales? |
| --- | --- | --- | --- | --- |
| 0 | `renv::restore()` | `renv.lock` | Paquetes de R | No |
| 1 | `R/inventario.R` | `datos/originales/` | Inventario en consola | Sí |
| 2 | `analisis/01_comprension_datos.Rmd` | `datos/originales/` | Diagnóstico de calidad | Sí |
| 3 | `analisis/02_preparacion_datos.Rmd` | `datos/originales/`, `datos/rangos_operacion_SIMA.csv` | Limpieza, transformación y `datos/procesados/sima_diaria_estacion.csv` | Sí |
| 4 | `analisis/03_exploracion_descriptiva.Rmd` | `datos/procesados/sima_diaria_estacion.csv` | Exploración descriptiva; figuras en `entregables/entregable2/img/` y tablas en `entregables/entregable2/tablas/` | No |
| 5 | `entregables/entregable1/main.tex` | Cifras de los pasos 2–3 | `entregables/entregable1/main.pdf` | No |
| 6 | `entregables/entregable2/main.tex` | Figuras y tablas del paso 4 | `entregables/entregable2/main.pdf` | No |

```sh
Rscript -e 'renv::restore(prompt = FALSE)'
Rscript R/ejecutar_analisis.R       # pasos 1-4 (omite 01 y 02 si faltan los libros originales)
Rscript R/compilar_entregables.R    # pasos 5-6; o: Rscript R/compilar_entregables.R entregable2
```

Sin los libros originales se puede reproducir todo a partir de la base limpia: `ejecutar_analisis.R` corre sólo `03_exploracion_descriptiva.Rmd` y los entregables se compilan igual.

## Reglas para compilar

Para que haya un único PDF por entregable y sea siempre el mismo:

- **Un solo lugar de salida.** Cada PDF se genera junto a su `.tex` (`entregables/<entregable>/main.pdf`) y ése es el que se versiona y se entrega. No se usan carpetas `build/` para LaTeX.
- **Un solo motor: XeLaTeX.** Cada `.tex` empieza con `% !TeX program = XeLaTeX` y el proyecto de RStudio está configurado igual, así que el botón *Compile PDF* y `R/compilar_entregables.R` producen el mismo resultado.
- **Los HTML de análisis van a `analisis/salidas/`.** Los `.Rmd` tienen un `knit:` en su encabezado, de modo que el botón *Knit* de RStudio también escribe ahí.
- **Antes de hacer commit de un entregable**, recompilarlo y revisar que `git status` muestre su `main.pdf` como modificado.
- **Fechas de portada.** Al cerrar un entregable, reemplazar `\today` por la fecha de entrega, para que recompilarlo después no cambie la portada.

`renv.lock` fija las dependencias de R; la biblioteca instalada queda fuera del control de versiones.

Los libros de mediciones no se distribuyen en este repositorio. Cada integrante debe obtenerlos por el canal de la clase y colocarlos en `datos/originales/` con los nombres indicados en `datos/originales/README.md`. Los libros sólo se leen; toda limpieza, conversión o exclusión está explícita en código y documentada en `analisis/02_preparacion_datos.Rmd`.

Ver [exploración inicial](investigacion/exploracion_inicial.md) para la cobertura observada y los puntos pendientes.

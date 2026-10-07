# Ejecuta los documentos de análisis en orden y deja los HTML en analisis/salidas/.
#
# 01 y 02 necesitan los libros originales de SIMA en datos/originales/ (no se
# publican); si no están, se omiten y 03 se ejecuta a partir de la base limpia
# datos/procesados/sima_diaria_estacion.csv, que sí está en el repositorio.
#
# Uso, desde la raíz del repositorio:
#   Rscript R/ejecutar_analisis.R

if (!file.exists("sima-monitoreo-ambiental.Rproj")) {
  stop("Ejecuta este script desde la raíz del repositorio.", call. = FALSE)
}

salidas <- file.path("analisis", "salidas")
originales <- file.path("datos", "originales", sprintf("BD_%d.xlsx", 2020:2025))
hay_originales <- all(file.exists(originales))

documentos <- c("01_comprension_datos.Rmd", "02_preparacion_datos.Rmd", "03_exploracion_descriptiva.Rmd")
requiere_originales <- c(TRUE, TRUE, FALSE)

for (i in seq_along(documentos)) {
  if (requiere_originales[i] && !hay_originales) {
    message("Se omite ", documentos[i], ": faltan los libros originales en datos/originales/.")
    next
  }
  message("Ejecutando ", documentos[i])
  rmarkdown::render(file.path("analisis", documentos[i]), output_dir = salidas,
                    envir = new.env(), quiet = TRUE)
}
message("HTML en ", salidas, "/. Para los PDF: Rscript R/compilar_entregables.R")

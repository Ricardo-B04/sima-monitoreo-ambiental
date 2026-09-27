# Inventario de libros SIMA. Ejecutar desde la raíz del repositorio:
# Rscript R/inventario.R

if (!requireNamespace("readxl", quietly = TRUE)) {
  stop("Falta readxl. Ejecute: Rscript -e 'renv::restore(prompt = FALSE)'")
}

bases <- file.path("datos", "originales", sprintf("BD_%d.xlsx", 2020:2025))
etiquetas <- file.path("datos", "originales", "Etiquetas.xlsx")
archivos <- c(bases, etiquetas)

if (!all(file.exists(archivos))) {
  stop("Faltan archivos de entrada: ", paste(archivos[!file.exists(archivos)], collapse = ", "))
}

columnas_medicion <- c(
  "CO", "NO", "NO2", "NOX", "O3", "PM10", "PM2.5",
  "PRS", "RAINF", "RH", "SO2", "SR", "TOUT", "WSR", "WDR"
)

filas <- list()
for (archivo in bases) {
  anio <- as.integer(sub(".*BD_(\\d{4})\\.xlsx$", "\\1", archivo))
  hojas <- readxl::excel_sheets(archivo)
  for (hoja in hojas) {
    columnas <- names(readxl::read_excel(archivo, sheet = hoja, n_max = 0))
    columna_fecha <- if (anio == 2025L) "date" else "Fecha y hora"
    filas[[length(filas) + 1L]] <- data.frame(
      anio = anio,
      estacion = hoja,
      n_columnas = length(columnas),
      columna_fecha = columnas[1],
      cabecera_esperada = identical(columnas, c(columna_fecha, columnas_medicion))
    )
  }
}

inventario <- do.call(rbind, filas)
print(inventario, row.names = FALSE)
cat("\nHojas por año:\n")
print(table(inventario$anio))
cat("\nHojas de Etiquetas.xlsx: ",
    paste(readxl::excel_sheets(etiquetas), collapse = ", "), "\n", sep = "")

if (!all(inventario$cabecera_esperada)) {
  stop("Una o más hojas tienen columnas distintas a las esperadas.")
}

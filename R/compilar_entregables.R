# Compila entregables/*/main.tex con el motor indicado en cada documento.
# El PDF se escribe junto a su fuente y se eliminan auxiliares de compilación.
# Uso desde la raíz:
#   Rscript R/compilar_entregables.R
#   Rscript R/compilar_entregables.R entregable4
#   Rscript R/compilar_entregables.R entregable1 entregable4 --simular
# --simular muestra los motores y las rutas sin compilar ni escribir archivos.

if (!file.exists("sima-monitoreo-ambiental.Rproj")) {
  stop("Ejecuta este script desde la raíz del repositorio.", call. = FALSE)
}

argumentos <- commandArgs(trailingOnly = TRUE)
simular <- "--simular" %in% argumentos
solicitudes <- unique(argumentos[argumentos != "--simular"])
if (any(!grepl("^[[:alnum:]_-]+$", solicitudes))) {
  stop("Indica nombres de carpetas de entregables/ y, si lo deseas, --simular.", call. = FALSE)
}
carpetas <- if (length(solicitudes)) {
  file.path("entregables", solicitudes)
} else {
  list.dirs("entregables", recursive = FALSE)
}
con_fuente <- file.exists(file.path(carpetas, "main.tex"))
if (length(solicitudes) && any(!con_fuente)) {
  stop("No se encontró main.tex en: ", paste(carpetas[!con_fuente], collapse = ", "), call. = FALSE)
}
carpetas <- carpetas[con_fuente]
if (!length(carpetas)) stop("No se encontró ningún entregables/*/main.tex.", call. = FALSE)

motor_documento <- function(carpeta) {
  encabezado <- readLines(file.path(carpeta, "main.tex"), n = 20L, encoding = "UTF-8", warn = FALSE)
  patron <- "^\\s*%\\s*!TeX\\s+program\\s*=\\s*"
  indicaciones <- grep(patron, encabezado, value = TRUE, ignore.case = TRUE, perl = TRUE)
  if (!length(indicaciones)) return("xelatex") # Compatibilidad con informes previos.
  motores <- unique(tolower(trimws(sub(patron, "", indicaciones, ignore.case = TRUE, perl = TRUE))))
  if (length(motores) != 1L || !motores %in% c("pdflatex", "xelatex", "lualatex")) {
    stop("Indicación de motor inválida o contradictoria en ", file.path(carpeta, "main.tex"), call. = FALSE)
  }
  motores
}
motores <- vapply(carpetas, motor_documento, character(1))
if (!simular && !requireNamespace("tinytex", quietly = TRUE)) {
  stop("Falta tinytex. Restaura los paquetes con renv::restore().", call. = FALSE)
}

compilar <- function(carpeta, motor) {
  anterior <- setwd(carpeta)
  on.exit(setwd(anterior), add = TRUE)
  # Las rutas img/ y tablas/ se resuelven desde la carpeta del informe.
  tinytex::latexmk("main.tex", engine = motor, clean = TRUE, install_packages = FALSE)
}

fallidos <- character()
for (i in seq_along(carpetas)) {
  carpeta <- carpetas[[i]]
  motor <- motores[[i]]
  if (simular) {
    message("[Simulación] ", file.path(carpeta, "main.tex"), " -> ", motor,
            " -> ", file.path(carpeta, "main.pdf"))
    next
  }
  ok <- tryCatch({
    message("Compilando ", carpeta, " con ", motor, ".")
    compilar(carpeta, motor)
    TRUE
  }, error = function(e) {
    message("Error al compilar ", carpeta, ": ", conditionMessage(e))
    FALSE
  })
  if (ok) message("PDF actualizado: ", file.path(carpeta, "main.pdf"))
  else fallidos <- c(fallidos, carpeta)
}
if (length(fallidos)) {
  stop("No se completó la compilación de: ", paste(fallidos, collapse = ", "), call. = FALSE)
}
if (simular) message("Simulación terminada; no se modificaron los informes.")

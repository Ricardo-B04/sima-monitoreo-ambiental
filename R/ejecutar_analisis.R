# Ejecuta los Rmd en orden; escribe los HTML en analisis/salidas/.
# Uso desde la raíz: Rscript R/ejecutar_analisis.R [01 02 03 04] [opciones]
# Sin números se seleccionan los cuatro documentos. Opciones:
#   --simular                Mostrar el plan sin ejecutar ni escribir archivos.
#   --sin-auditoria-horaria   Omitir la lectura horaria del análisis 04.
# 01 y 02 se omiten si faltan los originales. 03 y 04 usan la base limpia.
# 04 llama al complemento de la sección 13 y puede requerir cálculos largos.

if (!file.exists("sima-monitoreo-ambiental.Rproj")) {
  stop("Ejecuta este script desde la raíz del repositorio.", call. = FALSE)
}

argumentos <- commandArgs(trailingOnly = TRUE)
opciones <- c("--simular", "--sin-auditoria-horaria")
solicitudes <- setdiff(argumentos, opciones)
if (any(!solicitudes %in% c("01", "02", "03", "04"))) {
  stop("Usa los números 01, 02, 03 o 04 y las opciones --simular o --sin-auditoria-horaria.",
       call. = FALSE)
}
seleccion <- if (length(solicitudes)) unique(solicitudes) else c("01", "02", "03", "04")
simular <- "--simular" %in% argumentos
sin_auditoria <- "--sin-auditoria-horaria" %in% argumentos
raiz <- normalizePath(".", winslash = "/")
salidas <- file.path(raiz, "analisis", "salidas")
base_limpia <- file.path(raiz, "datos", "procesados", "sima_diaria_estacion.csv")
originales <- file.path(raiz, "datos", "originales", sprintf("BD_%d.xlsx", 2020:2025))
hay_originales <- all(file.exists(originales))
auditar <- !sin_auditoria && all(file.exists(originales[-1L]))

documentos <- c(
  "01" = "01_comprension_datos.Rmd",
  "02" = "02_preparacion_datos.Rmd",
  "03" = "03_exploracion_descriptiva.Rmd",
  "04" = "04_modelado y evaluaci\u00f3n.Rmd"
)
plan <- documentos[names(documentos) %in% seleccion]
omitidos <- names(plan) %in% c("01", "02") & !hay_originales
for (documento in plan[omitidos]) {
  message("Se omite ", documento, ": faltan libros de 2020–2025 en datos/originales/.")
}
plan <- plan[!omitidos]
if (!length(plan)) stop("No hay análisis que puedan ejecutarse con estas entradas.", call. = FALSE)

faltantes <- file.path("analisis", unname(plan))
faltantes <- faltantes[!file.exists(faltantes)]
if (length(faltantes)) stop("Faltan documentos: ", paste(faltantes, collapse = ", "), call. = FALSE)
if (any(names(plan) %in% c("03", "04")) && !file.exists(base_limpia) && !"02" %in% names(plan)) {
  stop("Falta datos/procesados/sima_diaria_estacion.csv. Ejecuta 02 con los originales.", call. = FALSE)
}
if ("04" %in% names(plan)) {
  if (!file.exists("analisis/complemento_retro_etapa3.R")) {
    stop("Falta analisis/complemento_retro_etapa3.R, necesario para la sección 13.", call. = FALSE)
  }
  message("Análisis 04: auditoría horaria ", if (auditar) "activada." else "omitida.")
  if (!auditar) {
    message("Sin auditoría horaria no se reproducen las señales de ceros diurnos ni las mismas exclusiones de calidad ampliada.")
  }
  if (!file.exists(file.path(salidas, "retro_etapa3", "gamm_original_ce.rds"))) {
    message("La sección 13 ajustará el GAMM original de CE si no está disponible; puede tardar unos 40 minutos o más.")
  }
  if (!file.exists(file.path(salidas, "retro_etapa3", "gamm_calidad_Inicial.rds"))) {
    message("Sin el GAMM de calidad inicial guardado, esa comparación se omite salvo que se solicite su reajuste.")
  }
  message("Los ajustes nuevos de sensibilidad del GAMM dependen de options(sima.reajustar_gamm_calidad = TRUE); por defecto están desactivados.")
}

message("Orden: ", paste(names(plan), collapse = " -> "), ". Salida: ", salidas)
if (!simular) {
  if (!requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("Falta rmarkdown. Restaura los paquetes con renv::restore().", call. = FALSE)
  }
  dir.create(salidas, recursive = TRUE, showWarnings = FALSE)
}
for (id in names(plan)) {
  documento <- unname(plan[[id]])
  if (simular) {
    message("[Simulación] ", file.path("analisis", documento))
    next
  }
  message("Ejecutando ", documento)
  # Entorno nuevo por documento; las secciones y el complemento del 04 comparten
  # su entorno. Los demás parámetros se conservan como están en el YAML.
  parametros <- if (id == "04") list(auditar_horarios = auditar) else NULL
  rmarkdown::render(file.path(raiz, "analisis", documento), output_dir = salidas,
                    params = parametros, envir = new.env(parent = globalenv()),
                    encoding = "UTF-8", quiet = TRUE)
}
if (simular) {
  message("Simulación terminada; no se ejecutaron análisis ni se escribieron resultados.")
} else {
  message("Análisis terminados. HTML en ", salidas, "/.")
  message("Para los PDF: Rscript R/compilar_entregables.R")
}

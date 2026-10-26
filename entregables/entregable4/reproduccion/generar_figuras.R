# Regenera las dos figuras de comparación del informe final, sin ajustar modelos.
# Desde la raíz del repositorio:
#   Rscript entregables/entregable4/reproduccion/generar_figuras.R
# Antes debe haberse ejecutado el análisis 04, incluida su sección 13.
# Entradas (se generan localmente; no es necesario publicarlas en Git):
#   datos/procesados/sima_diaria_estacion.csv
#   analisis/salidas/retro_etapa3/predicciones_concentraciones_2025.csv
#   analisis/salidas/cierre/ar1_dependencia.csv
# Salidas: entregables/entregable4/img/gam_rmse.pdf y ar1_dependencia.pdf.
# La gráfica del logit está dibujada en main.tex y no necesita este script.
# Opciones para otras ubicaciones: --raiz <repositorio> --salida <carpeta_informe>.

buscar_raiz <- function(inicio) {
  ruta <- normalizePath(inicio, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(ruta, "sima-monitoreo-ambiental.Rproj"))) return(ruta)
    padre <- dirname(ruta)
    if (identical(padre, ruta)) return(NULL)
    ruta <- padre
  }
}

generar_figuras <- function(argumentos = commandArgs(trailingOnly = TRUE)) {
  opciones <- list()
  while (length(argumentos)) {
    nombre <- argumentos[[1]]
    if (nombre == "--ayuda") {
      cat("Uso: Rscript entregables/entregable4/reproduccion/generar_figuras.R",
          "[--raiz repositorio] [--salida carpeta_informe]\n")
      return(invisible(NULL))
    }
    if (!nombre %in% c("--raiz", "--salida") || length(argumentos) < 2L ||
        startsWith(argumentos[[2]], "--")) {
      stop("Opciones: --raiz <repositorio> y --salida <carpeta_informe>.", call. = FALSE)
    }
    opciones[[nombre]] <- argumentos[[2]]
    argumentos <- argumentos[-c(1L, 2L)]
  }

  if (!is.null(opciones[["--raiz"]])) {
    raiz <- normalizePath(opciones[["--raiz"]], winslash = "/", mustWork = TRUE)
    if (!file.exists(file.path(raiz, "sima-monitoreo-ambiental.Rproj"))) {
      stop("La carpeta indicada no es la raíz del proyecto SIMA.", call. = FALSE)
    }
  } else {
    # Permite ejecutar desde la raíz o una subcarpeta, y mediante la ruta
    # completa del script desde otra carpeta. No contiene rutas personales.
    origen <- grep("^--file=", commandArgs(), value = TRUE)
    inicios <- c(getwd(), if (length(origen)) dirname(sub("^--file=", "", origen[[1]])))
    raices <- Filter(Negate(is.null), lapply(unique(inicios), buscar_raiz))
    if (!length(raices)) stop("No se encontró el proyecto. Usa --raiz <repositorio>.", call. = FALSE)
    raiz <- raices[[1]]
  }
  destino <- if (is.null(opciones[["--salida"]])) {
    file.path(raiz, "entregables", "entregable4")
  } else opciones[["--salida"]]

  archivos <- c(
    base = file.path(raiz, "datos/procesados/sima_diaria_estacion.csv"),
    concentraciones = file.path(raiz, "analisis/salidas/retro_etapa3/predicciones_concentraciones_2025.csv"),
    dependencia = file.path(raiz, "analisis/salidas/cierre/ar1_dependencia.csv")
  )
  faltantes <- archivos[!file.exists(archivos)]
  if (length(faltantes)) {
    stop("Faltan entradas:\n", paste(faltantes, collapse = "\n"),
         "\nGenera las salidas con Rscript R/ejecutar_analisis.R 04 (incluida la sección 13).",
         "\nEste script no ajusta modelos ni crea resultados de ejemplo.", call. = FALSE)
  }
  paquetes <- c("ggplot2", "dplyr", "tidyr")
  faltan_paquetes <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
  if (length(faltan_paquetes)) {
    stop("Faltan paquetes: ", paste(faltan_paquetes, collapse = ", "),
         ". Ejecuta renv::restore().", call. = FALSE)
  }
  suppressPackageStartupMessages({
    library(ggplot2)
    library(dplyr)
    library(tidyr)
  })
  leer <- function(nombre) read.csv(archivos[[nombre]], check.names = FALSE, fileEncoding = "UTF-8")
  comprobar_columnas <- function(datos, columnas, nombre) {
    faltan <- setdiff(columnas, names(datos))
    if (length(faltan)) stop("Faltan columnas en ", nombre, ": ", paste(faltan, collapse = ", "), call. = FALSE)
  }

  # Misma selección de entrenamiento que la sección 2 del análisis 04.
  # Solo se calcula la referencia mensual; las predicciones lineales y GAM
  # ya están guardadas por la sección 13 y no se vuelven a ajustar.
  base <- leer("base")
  variables <- c("log_NO_media", "log_NO2_media", "TOUT_max", "SR_media",
                 "RH_media", "PRS_media", "U_media", "V_media", "doy_sin", "doy_cos")
  comprobar_columnas(base, c("estacion", "dia", "anio", "O3_max8", variables), "base diaria")
  base$dia <- as.Date(base$dia)
  if (anyNA(base$dia) || anyDuplicated(base[c("estacion", "dia")])) {
    stop("La base contiene fechas inválidas o días-estación duplicados.", call. = FALSE)
  }
  base$doy_sin2 <- 2 * base$doy_sin * base$doy_cos
  base$doy_cos2 <- base$doy_cos^2 - base$doy_sin^2
  completas <- complete.cases(base[c("O3_max8", variables, "doy_sin2", "doy_cos2")])
  entrenamiento <- base[base$anio %in% 2021:2024 & completas, ]
  prueba <- base[base$anio == 2025 & completas, ]
  if (!nrow(entrenamiento) || !nrow(prueba)) stop("No hay casos completos para comparar.", call. = FALSE)
  referencia <- entrenamiento |>
    mutate(mes_eval = as.integer(format(dia, "%m"))) |>
    group_by(estacion, mes_eval) |>
    summarise(estimado_referencia = mean(O3_max8), .groups = "drop")

  pc <- leer("concentraciones")
  comprobar_columnas(pc, c("estacion", "dia", "O3_max8", "estimado_gam", "estimado_lineal"), "predicciones de concentración")
  pc$dia <- as.Date(pc$dia)
  if (anyNA(pc$dia) || anyDuplicated(pc[c("estacion", "dia")])) {
    stop("Las predicciones contienen fechas inválidas o duplicados.", call. = FALSE)
  }
  clave <- function(d) paste(d$estacion, d$dia, sep = "|")
  if (!setequal(clave(pc), clave(prueba))) {
    stop("Las predicciones no corresponden a los mismos casos completos de 2025 de la base diaria.", call. = FALSE)
  }
  observados <- prueba$O3_max8[match(clave(pc), clave(prueba))]
  if (anyNA(pc$O3_max8) || any(abs(pc$O3_max8 - observados) > 1e-8)) {
    stop("La respuesta de las predicciones no coincide con la base diaria.", call. = FALSE)
  }
  pc <- pc |>
    mutate(mes_eval = as.integer(format(dia, "%m"))) |>
    left_join(referencia, by = c("estacion", "mes_eval"))
  predictores <- c("estimado_referencia", "estimado_lineal", "estimado_gam")
  if (any(!is.finite(as.matrix(pc[predictores])))) stop("Hay predicciones faltantes o no finitas.", call. = FALSE)
  etiquetas <- c("Referencia mensual", "Regresi\u00f3n lineal", "GAM")
  gam <- pc |>
    pivot_longer(all_of(predictores), names_to = "modelo", values_to = "estimado") |>
    group_by(estacion, modelo) |>
    summarise(RMSE = sqrt(mean((estimado - O3_max8)^2)), .groups = "drop") |>
    mutate(modelo = etiquetas[match(modelo, predictores)], RMSE = round(RMSE, 3)) |>
    pivot_wider(names_from = modelo, values_from = RMSE)
  gam$estacion <- factor(gam$estacion, levels = rev(gam$estacion[order(gam$GAM)]))
  g <- gam |> pivot_longer(all_of(etiquetas), names_to = "modelo", values_to = "RMSE")
  g$modelo <- factor(g$modelo, levels = etiquetas)

  dep <- leer("dependencia")
  comprobar_columnas(dep, c("anio", "rezago", "umbral", "estacion", "modelo", "correlacion"), "dependencia AR(1)")
  dep <- dep |> filter(anio == 2025, rezago == 1, umbral %in% c(60, 51), modelo %in% c("Original", "AR1"))
  if (!nrow(dep) || anyNA(dep[c("estacion", "modelo", "umbral", "correlacion")]) ||
      any(!is.finite(dep$correlacion)) || any(abs(dep$correlacion) > 1) ||
      anyDuplicated(dep[c("estacion", "modelo", "umbral")])) {
    stop("La tabla de dependencia no contiene comparaciones válidas de 2025 a un día.", call. = FALSE)
  }
  pares <- table(dep$estacion, dep$umbral, dep$modelo)
  if (!setequal(dep$umbral, c(60, 51)) || !setequal(dep$modelo, c("Original", "AR1")) || any(pares != 1L)) {
    stop("Faltan comparaciones por estación, modelo o umbral en la tabla de dependencia.", call. = FALSE)
  }
  dep$umbral <- factor(dep$umbral, levels = c(60, 51), labels = c("Excedencia > 60 ppb", "Excedencia > 51 ppb"))
  dep$modelo <- factor(dep$modelo, levels = c("Original", "AR1"), labels = c("Log\u00edstica", "Log\u00edstica AR(1)"))
  dep$estacion <- factor(dep$estacion, levels = rev(sort(unique(dep$estacion))))

  # Mismo diseño, colores y dimensiones que las figuras del informe.
  tema <- theme_minimal(base_size = 11, base_family = "sans") +
    theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
          legend.position = "top", legend.title = element_blank(),
          plot.title = element_text(face = "bold", size = 12),
          strip.text = element_text(face = "bold", colour = "#17486A"),
          plot.margin = margin(8, 12, 6, 8))
  figura_gam <- ggplot(g, aes(RMSE, estacion, colour = modelo, shape = modelo)) +
    geom_line(aes(group = estacion), colour = "#D5DEE4", linewidth = .6) +
    geom_point(size = 2.8, stroke = 1) +
    scale_colour_manual(values = c("#9AA8B2", "#D98D35", "#247BA0")) +
    scale_shape_manual(values = c(1, 17, 16)) +
    labs(x = "RMSE en 2025 (ppb)", y = NULL) + tema
  figura_dep <- ggplot(dep, aes(correlacion, estacion, colour = modelo, shape = modelo)) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "#A2ABB3", linewidth = .4) +
    geom_line(aes(group = estacion), colour = "#CCD7DF", linewidth = .65) +
    geom_point(size = 2.3) + facet_wrap(~ umbral, nrow = 1) +
    scale_colour_manual(values = c("#929DA5", "#247BA0")) +
    scale_shape_manual(values = c(1, 16)) +
    labs(x = "Correlaci\u00f3n de residuos de Pearson a un d\u00eda", y = NULL) + tema

  imagenes <- file.path(destino, "img")
  dir.create(imagenes, recursive = TRUE, showWarnings = FALSE)
  dispositivo <- if (capabilities("cairo")) grDevices::cairo_pdf else grDevices::pdf
  ggsave(file.path(imagenes, "gam_rmse.pdf"), figura_gam, width = 7, height = 3.7, device = dispositivo)
  ggsave(file.path(imagenes, "ar1_dependencia.pdf"), figura_dep, width = 7, height = 3.3, device = dispositivo)
  message("Figuras generadas en ", normalizePath(imagenes, winslash = "/"))
  invisible(list(gam = gam, dependencia = dep))
}

generar_figuras()

# Compila los informes LaTeX de entregables/ con XeLaTeX.
#
# El PDF se escribe junto a su main.tex (entregables/<carpeta>/main.pdf), igual
# que el botón "Compile PDF" de RStudio, y los archivos auxiliares se eliminan.
# Ese main.pdf es el que se versiona y se entrega.
#
# Uso, desde la raíz del repositorio:
#   Rscript R/compilar_entregables.R                # todos los entregables
#   Rscript R/compilar_entregables.R entregable2    # sólo uno

if (!file.exists("sima-monitoreo-ambiental.Rproj")) {
  stop("Ejecuta este script desde la raíz del repositorio.", call. = FALSE)
}

args <- commandArgs(trailingOnly = TRUE)
carpetas <- if (length(args) > 0) {
  file.path("entregables", args)
} else {
  list.dirs("entregables", recursive = FALSE)
}
carpetas <- carpetas[file.exists(file.path(carpetas, "main.tex"))]
if (length(carpetas) == 0) stop("No se encontró ningún entregables/*/main.tex.", call. = FALSE)

for (d in carpetas) {
  raiz <- setwd(d)
  ok <- tryCatch({
    # Las rutas relativas del .tex (img/, tablas/) se resuelven desde su carpeta
    tinytex::latexmk("main.tex", engine = "xelatex", clean = TRUE, install_packages = FALSE)
    TRUE
  }, error = function(e) {
    message("Error al compilar ", d, ": ", conditionMessage(e))
    FALSE
  }, finally = setwd(raiz))
  if (ok) message("PDF actualizado: ", file.path(d, "main.pdf"))
}

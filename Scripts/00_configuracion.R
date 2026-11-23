# ============================================================
# 00. CONFIGURACIÓN GENERAL DEL PROYECTO
# Tesis: desarrollo y descarbonización en América Latina, 2000-2021.
# RUTA ADAPTADA AL EQUIPO: Descargas/tesis-descarbonizacion-america-latina.
# Usa el nombre real de las carpetas: Datos, Originales, Resultados, Scripts.
# No instala paquetes ni redefine los resultados.
# ============================================================

# La ruta se obtiene de USERPROFILE, no depende del directorio de RStudio.
# Ejemplo: C:/Users/nicop/Downloads/tesis-descarbonizacion-america-latina
usuario_windows <- Sys.getenv("USERPROFILE")
if (!nzchar(usuario_windows)) stop("Este paquete está configurado para Windows (USERPROFILE no disponible).")
raiz <- file.path(usuario_windows, "Downloads", "tesis-descarbonizacion-america-latina")
if (!file.exists(file.path(raiz, "Scripts", "00_configuracion.R"))) {
  stop("No se encontró la carpeta del proyecto en: ", raiz,
       "\nVerifica que el ZIP se haya extraído dentro de Descargas/tesis-descarbonizacion-america-latina.")
}
raiz <- normalizePath(raiz, winslash = "/", mustWork = TRUE)

paquetes <- c("readr", "readxl", "dplyr", "tidyr", "stringr", "ggplot2",
              "plm", "lmtest", "flextable", "officer")
faltantes <- paquetes[!vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)]
if (length(faltantes)) {
  stop("Faltan paquetes: ", paste(faltantes, collapse = ", "),
       ". Ejecute: install.packages(c(",
       paste(sprintf('"%s"', faltantes), collapse = ", "), "))")
}

carpeta_scripts <- file.path(raiz, "Scripts")
carpeta_datos <- file.path(raiz, "Datos", "Originales")
carpeta_procesados <- file.path(raiz, "Datos", "Procesados")
carpeta_tablas <- file.path(raiz, "Resultados", "Tablas")
carpeta_graficos <- file.path(raiz, "Resultados", "Graficos")
if (!dir.exists(carpeta_datos)) {
  stop("No existe la carpeta de datos originales: ", carpeta_datos)
}
for (dir in c(carpeta_procesados, carpeta_tablas, carpeta_graficos))
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)

# Si Windows muestra nombres truncados o una descarga tiene un sufijo
# diferente, localizar por el código estable del indicador (sin escoger al azar).
archivo_original <- function(nombre) {
  directo <- file.path(carpeta_datos, nombre)
  if (file.exists(directo)) return(directo)
  archivos <- list.files(carpeta_datos, full.names = TRUE)
  extension <- tolower(tools::file_ext(nombre))
  prefijo <- if (startsWith(nombre, "API_")) {
    sub("_DS2_en_csv_v2_.*$", "", nombre)
  } else if (startsWith(nombre, "UNE_DEAP_SEX_AGE_RT_A-")) {
    "UNE_DEAP_SEX_AGE_RT_A-"
  } else {
    tools::file_path_sans_ext(nombre)
  }
  candidatos <- archivos[tolower(tools::file_ext(archivos)) == extension &
    startsWith(tolower(basename(archivos)), tolower(prefijo))]
  if (length(candidatos) != 1L) {
    stop("No pude identificar de forma única el archivo original: ", nombre,
         "\nCarpeta revisada: ", carpeta_datos,
         "\nCoincidencias: ", length(candidatos),
         "\nSi hay dos versiones de un indicador, deja solo la que utilizaste en la tesis.")
  }
  cat("Archivo identificado para ", nombre, ": ", basename(candidatos), "\n", sep = "")
  candidatos[[1]]
}

# El CSV de gobernanza puede llevar un nombre UUID (como en la captura),
# en lugar del nombre Data.csv. Se identifica por columnas WGI oficiales.
archivo_wgi <- function() {
  candidatos <- list.files(carpeta_datos, pattern = "\\.csv$", full.names = TRUE,
                           ignore.case = TRUE)
  es_wgi <- vapply(candidatos, function(ruta) {
    cabecera <- tryCatch(names(utils::read.csv(ruta, nrows = 1L,
                         check.names = FALSE, fileEncoding = "UTF-8-BOM")),
                        error = function(e) character())
    all(c("Country Code", "Series Code") %in% trimws(cabecera))
  }, logical(1))
  hallados <- candidatos[es_wgi]
  if (length(hallados) != 1L) {
    stop("No se pudo identificar un único CSV de WGI en Datos/Originales.",
         "\nDebe tener las columnas 'Country Code' y 'Series Code'.",
         "\nArchivos compatibles encontrados: ", length(hallados),
         "\nNo se modificarán los datos del panel principal.")
  }
  cat("Base WGI identificada: ", basename(hallados), "\n", sep = "")
  hallados[[1]]
}
archivo_panel <- file.path(carpeta_procesados, "base_panel.csv")
archivo_modelos <- file.path(carpeta_procesados, "base_modelos.csv")

leer_panel <- function() {
  if (!file.exists(archivo_panel)) stop("Ejecute primero Scripts/01_preparacion_datos.R")
  readr::read_csv(archivo_panel, show_col_types = FALSE)
}
leer_muestra <- function() {
  if (!file.exists(archivo_modelos)) stop("Ejecute primero Scripts/01_preparacion_datos.R")
  readr::read_csv(archivo_modelos, show_col_types = FALSE)
}

# MISMO CRITERIO DE LAS TABLAS Y ANEXOS DE LA TESIS:
# plm within por país + indicadores de año; VCOV HC1 Arellano,
# agrupación por país; p calculado con t y gl residuales.
# ADVERTENCIA: NO es una corrección para 15 conglomerados pequeños.
vcov_robusta <- function(modelo) {
  plm::vcovHC(modelo, method = "arellano", type = "HC1", cluster = "group")
}
extraer_robusto <- function(modelo) {
  b <- stats::coef(modelo)
  ee <- sqrt(diag(vcov_robusta(modelo)))[names(b)]
  estadistico <- b / ee
  gl <- stats::df.residual(modelo)
  if (!is.finite(gl) || gl <= 0) stop("Grados de libertad inválidos")
  p <- 2 * stats::pt(abs(estadistico), df = gl, lower.tail = FALSE)
  data.frame(termino = names(b), coeficiente = unname(b),
             error_estandar = unname(ee), estadistico_t = unname(estadistico),
             gl = gl, valor_p = unname(p), row.names = NULL)
}
estrellas <- function(p) {
  ifelse(is.na(p), "", ifelse(p < .001, "***", ifelse(p < .01, "**",
                                               ifelse(p < .05, "*", ""))))
}

# Preparación estadística compartida: exactamente los filtros y centros
# globales que aparecen en los anexos originales A.1, A.2 y A.3.
preparar_base_modelos <- function(base_panel) {
  columnas <- c("country", "year", "co2_pc", "renovables", "pib_pc",
                "apertura", "urbanizacion", "anos_democracia", "desempleo", "gini")
  if (length(setdiff(columnas, names(base_panel)))) {
    stop("Faltan variables: ", paste(setdiff(columnas, names(base_panel)), collapse = ", "))
  }
  if (any(base_panel$pib_pc <= 0, na.rm = TRUE)) stop("PIB per cápita no positivo")
  datos <- base_panel |>
    dplyr::mutate(log_pib = log(pib_pc)) |>
    dplyr::filter(stats::complete.cases(dplyr::pick(
      co2_pc, renovables, log_pib, apertura, urbanizacion,
      anos_democracia, desempleo, gini))) |>
    dplyr::mutate(log_pib_c = log_pib - mean(log_pib),
                  apertura_c = apertura - mean(apertura),
                  urbanizacion_c = urbanizacion - mean(urbanizacion),
                  democracia_c = anos_democracia - mean(anos_democracia),
                  desempleo_c = desempleo - mean(desempleo),
                  gini_c = gini - mean(gini)) |>
    dplyr::arrange(country, year)
  if (anyDuplicated(datos[c("country", "year")])) stop("country-year repetidos")
  if (nrow(datos) != 263L || dplyr::n_distinct(datos$country) != 15L)
    warning("Muestra distinta de la tesis: ", nrow(datos), " filas, ",
            dplyr::n_distinct(datos$country), " países (esperado: 263 y 15).")
  datos
}

# Modelo individual FE + factor(year) equivale a efectos fijos país y año;
# no emplear efecto='twoways' adicional, porque duplicaría dummies anuales.
estimar_fe <- function(df, y, variables) {
  ff <- stats::reformulate(c(variables, "factor(year)"), response = y)
  plm::plm(ff, data = plm::pdata.frame(df, index = c("country", "year")),
           model = "within", effect = "individual")
}

# Exportar tabla en Word, sin alterar los cálculos subyacentes.
guardar_tabla_word <- function(tabla, titulo, nota, ruta, tamaño = 9) {
  ft <- flextable::flextable(tabla)
  ft <- flextable::theme_booktabs(ft)
  ft <- flextable::fontsize(ft, size = tamaño, part = "all")
  ft <- flextable::autofit(ft)
  doc <- officer::read_docx()
  doc <- officer::body_add_par(doc, titulo, style = "heading 2")
  doc <- flextable::body_add_flextable(doc, ft)
  doc <- officer::body_add_par(doc, nota, style = "Normal")
  print(doc, target = ruta)
  invisible(ruta)
}

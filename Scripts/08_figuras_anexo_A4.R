# ============================================================
# 08. FIGURAS A.1-A.4: SENSIBILIDAD POR EXCLUSION DE PAISES
# ------------------------------------------------------------
# Reproduce a partir de las estimaciones del script 07 las
# cuatro figuras de sensibilidad incluidas en la tesis.
# No reestima modelos, no modifica coeficientes y no importa
# imagenes del documento de tesis.
#
# Diseno: intervalos de confianza horizontales al 95%,
# lineas verticales para el cero y el coeficiente original,
# paises en orden alfabetico y facetas por coeficiente.
# ============================================================
source(file.path(Sys.getenv("USERPROFILE"), "Downloads",
                 "tesis-descarbonizacion-america-latina", "Scripts",
                 "00_configuracion.R"), encoding = "UTF-8")

ruta_estimaciones <- file.path(carpeta_tablas, "anexo_A4", "A4_resultados_completos.csv")
if (!file.exists(ruta_estimaciones)) {
  stop("Falta A4_resultados_completos.csv: ejecute primero 07_anexo_A4_sensibilidad.R")
}
resultados <- readr::read_csv(ruta_estimaciones, show_col_types = FALSE)
columnas <- c("termino", "dependiente", "modelo", "pais_excluido",
              "coeficiente", "error_estandar", "gl")
if (length(setdiff(columnas, names(resultados))) > 0) {
  stop("Faltan columnas de las estimaciones de sensibilidad: ",
       paste(setdiff(columnas, names(resultados)), collapse = ", "))
}

# Se emplean los mismos cuantiles t residuales que las tablas de la tesis.
# Esto NO representa una correccion adicional para pocos conglomerados.
resultados <- resultados |>
  dplyr::mutate(
    ic_inferior = coeficiente - stats::qt(.975, df = gl) * error_estandar,
    ic_superior = coeficiente + stats::qt(.975, df = gl) * error_estandar
  )

variables_en_orden <- c(
  "log_pib_c", "apertura_c", "urbanizacion_c", "desempleo_c",
  "gini_c", "urbanizacion_c:democracia_c"
)
etiquetas <- c(
  "PIB per cápita (log)", "Apertura comercial", "Urbanización",
  "Desempleo", "Índice de Gini", "Urbanización × democracia"
)
names(etiquetas) <- variables_en_orden

# La tabla original tiene 15 paises; ninguna observacion es generada a mano.
paises <- sort(unique(as.character(resultados$pais_excluido)))
paises <- setdiff(paises, "Ninguno")
if (length(paises) != 15L) {
  stop("Se esperaban 15 países en la sensibilidad; se encontraron ", length(paises))
}

# Validar que los puntos de referencia son efectivamente los coeficientes
# originales M6 y M7 de los modelos principales, sin exclusiones.
ruta_principales <- file.path(carpeta_tablas, "coeficientes_principales_completos.csv")
if (!file.exists(ruta_principales)) {
  stop("Falta coeficientes_principales_completos.csv: ejecute 03_modelos_principales.R")
}
principales <- readr::read_csv(ruta_principales, show_col_types = FALSE)
referencias <- resultados |>
  dplyr::filter(pais_excluido == "Ninguno") |>
  dplyr::inner_join(principales,
    by = c("dependiente", "modelo", "termino"),
    suffix = c("_loco", "_principal"))
if (any(abs(referencias$coeficiente_loco - referencias$coeficiente_principal) > 1e-9)) {
  stop("Los coeficientes originales de sensibilidad no coinciden con los modelos principales")
}

# M6: cinco covariables, M7: las mismas mas la interaccion.
# Los paneles NO incluyen los indicadores de ano ni la variable
# democracia sola; esas covariables si permanecen en las regresiones.
configuraciones <- list(
  list(numero = "A.1", dv = "co2_pc", modelo = "M6",
       titulo = "Análisis de sensibilidad: CO2 - M6", variables = variables_en_orden[1:5]),
  list(numero = "A.2", dv = "co2_pc", modelo = "M7",
       titulo = "Análisis de sensibilidad: CO2 - M7", variables = variables_en_orden),
  list(numero = "A.3", dv = "renovables", modelo = "M6",
       titulo = "Análisis de sensibilidad: Renovables - M6", variables = variables_en_orden[1:5]),
  list(numero = "A.4", dv = "renovables", modelo = "M7",
       titulo = "Análisis de sensibilidad: Renovables - M7", variables = variables_en_orden)
)

for (cfg in configuraciones) {
  puntos <- resultados |>
    dplyr::filter(dependiente == cfg$dv,
                  modelo == cfg$modelo,
                  pais_excluido != "Ninguno",
                  termino %in% cfg$variables)
  referencia <- resultados |>
    dplyr::filter(dependiente == cfg$dv,
                  modelo == cfg$modelo,
                  pais_excluido == "Ninguno",
                  termino %in% cfg$variables) |>
    dplyr::select(termino, coef_original = coeficiente)

  # Comprobaciones de integridad de las 15 exclusiones por coeficiente.
  conteos <- table(puntos$termino)
  if (nrow(puntos) != 15L * length(cfg$variables) ||
      any(conteos != 15L) || nrow(referencia) != length(cfg$variables) ||
      anyDuplicated(puntos[c("termino", "pais_excluido")])) {
    stop("Faltan o sobran observaciones en la Figura ", cfg$numero)
  }

  puntos <- puntos |>
    dplyr::mutate(
      variable = factor(termino, levels = cfg$variables,
                        labels = unname(etiquetas[cfg$variables])),
      pais = factor(pais_excluido, levels = rev(paises))
    )
  referencia <- referencia |>
    dplyr::mutate(variable = factor(termino, levels = cfg$variables,
                                     labels = unname(etiquetas[cfg$variables])))

  # Geometria segun las figuras de la tesis: dos columnas, facetas con
  # escalas horizontales propias, barra horizontal, punto de estimacion,
  # cero gris discontinuo y linea de referencia azul punteada.
  grafico <- ggplot2::ggplot(puntos, ggplot2::aes(y = pais, x = coeficiente)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey60",
                        linetype = "dashed", linewidth = 0.4) +
    ggplot2::geom_vline(data = referencia,
      ggplot2::aes(xintercept = coef_original), inherit.aes = FALSE,
      colour = "#1F567B", linetype = "dotted", linewidth = 0.65) +
    ggplot2::geom_segment(ggplot2::aes(x = ic_inferior, xend = ic_superior,
                       yend = pais), colour = "#1F567B", linewidth = 0.38) +
    ggplot2::geom_point(colour = "#1F567B", size = 1.65) +
    ggplot2::facet_wrap(~ variable, ncol = 2, scales = "free_x") +
    ggplot2::labs(
      title = cfg$titulo,
      subtitle = "Exclusión sucesiva de países | Intervalos de confianza al 95%",
      x = "Coeficiente estimado", y = "País excluido",
      caption = paste("Línea punteada azul: coeficiente del modelo original.",
                      "Línea gris discontinua: valor cero.")) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      plot.subtitle = ggplot2::element_text(size = 10, colour = "grey30"),
      strip.background = ggplot2::element_rect(fill = "grey94", colour = NA),
      strip.text = ggplot2::element_text(face = "bold", colour = "black", size = 10),
      panel.grid.major = ggplot2::element_line(colour = "grey87", linewidth = 0.35),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(colour = "black"),
      axis.text.x = ggplot2::element_text(colour = "black"),
      axis.title = ggplot2::element_text(size = 11),
      panel.spacing = grid::unit(1.3, "lines"),
      plot.caption = ggplot2::element_text(hjust = 1, colour = "grey35", size = 8),
      plot.margin = ggplot2::margin(8, 12, 8, 8)
    )

  ruta_figura <- file.path(carpeta_graficos, paste0("figura_", cfg$numero, "_sensibilidad.png"))
  ggplot2::ggsave(ruta_figura, plot = grafico,
                  width = 13.51, height = 11.43, units = "in", dpi = 100,
                  bg = "white")
  cat("Figura ", cfg$numero, " generada desde R: ", ruta_figura, "\n", sep = "")
}
cat("Cuatro figuras generadas a partir de los coeficientes LOCO originales.\n")

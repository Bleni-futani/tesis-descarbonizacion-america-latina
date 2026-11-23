# ============================================================
# 09. FIGURA 3: EFECTO MARGINAL DE LA URBANIZACION
# ------------------------------------------------------------
# Reconstruye la figura de moderacion urbanizacion x trayectoria
# democratica para renovables a partir del MODELO M7 real.
# Los intervalos se calculan con el metodo delta y la misma
# matriz de covarianza HC1 agrupada por pais de las regresiones.
# No utiliza imagenes extraidas del documento Word.
# ============================================================
source(file.path(Sys.getenv("USERPROFILE"), "Downloads",
                 "tesis-descarbonizacion-america-latina", "Scripts",
                 "00_configuracion.R"), encoding = "UTF-8")

base_modelos <- leer_muestra()
variables_m7 <- c("log_pib_c", "apertura_c", "urbanizacion_c", "democracia_c",
                  "desempleo_c", "gini_c", "urbanizacion_c:democracia_c")
modelo <- estimar_fe(base_modelos, "renovables", variables_m7)
coeficientes <- stats::coef(modelo)
matriz_v <- vcov_robusta(modelo)
termino_urb <- "urbanizacion_c"
termino_int <- "urbanizacion_c:democracia_c"
if (!(termino_int %in% names(coeficientes))) {
  termino_int <- "democracia_c:urbanizacion_c"
}
if (!all(c(termino_urb, termino_int) %in% names(coeficientes))) {
  stop("No se encontraron los terminos de urbanizacion e interaccion en M7")
}

# Comprobar que el M7 recien estimado coincide con las salidas originales.
ruta_principales <- file.path(carpeta_tablas, "coeficientes_principales_completos.csv")
if (!file.exists(ruta_principales)) {
  stop("Ejecute primero 03_modelos_principales.R")
}
principales <- readr::read_csv(ruta_principales, show_col_types = FALSE)
ref <- principales |>
  dplyr::filter(dependiente == "renovables", modelo == "M7", termino %in% c(termino_urb, termino_int))
if (nrow(ref) != 2L || any(abs(coeficientes[ref$termino] - ref$coeficiente) > 1e-9)) {
  stop("Los coeficientes de moderacion no coinciden con el M7 principal")
}

# Como democracia_c = anos_democracia - media(anos_democracia),
# d(renovables)/d(urbanizacion) = beta_urb + beta_inter * (edad - media).
media_democracia <- mean(base_modelos$anos_democracia)
edades <- seq(min(base_modelos$anos_democracia),
             max(base_modelos$anos_democracia), by = 1)
centrados <- edades - media_democracia
beta <- as.numeric(coeficientes[c(termino_urb, termino_int)])
V <- as.matrix(matriz_v[c(termino_urb, termino_int),
                       c(termino_urb, termino_int), drop = FALSE])
X <- cbind(1, centrados)
efecto <- as.numeric(X %*% beta)
# Error estandar robusto por metodo delta: sqrt(x' V x).
se <- sqrt(pmax(0, rowSums((X %*% V) * X)))
q95 <- stats::qt(0.975, df = stats::df.residual(modelo))
figura_datos <- data.frame(
  anos_democracia = edades, efecto_marginal = efecto,
  error_estandar = se, ic_inferior = efecto - q95 * se,
  ic_superior = efecto + q95 * se
)

# Comprobacion sustantiva: pendiente de la linea igual al coeficiente
# de interaccion reportado en M7, no un dato escrito manualmente.
pendiente_observada <- diff(figura_datos$efecto_marginal)[1]
if (!isTRUE(all.equal(unname(pendiente_observada),
                      unname(coeficientes[[termino_int]]), tolerance = 1e-10))) {
  stop("La pendiente del efecto marginal no coincide con el coeficiente M7")
}
readr::write_csv(figura_datos,
                 file.path(carpeta_tablas, "figura_3_datos_moderacion.csv"))

# ============================================================
# ESTILO DE LA FIGURA 3
# ------------------------------------------------------------
# La figura insertada en la tesis se presenta sobre fondo blanco,
# con grilla gris claro y una banda de confianza gris tenue.
# Estos cambios son exclusivamente graficos. Los coeficientes,
# la varianza robusta HC1, el metodo delta y el CSV no se alteran.
# ============================================================
grafico <- ggplot2::ggplot(
  figura_datos, ggplot2::aes(x = anos_democracia, y = efecto_marginal)) +
  ggplot2::geom_ribbon(
    ggplot2::aes(ymin = ic_inferior, ymax = ic_superior),
    fill = "grey20", alpha = 0.20) +
  ggplot2::geom_hline(yintercept = 0, linetype = "dashed",
                      colour = "black", linewidth = 0.55) +
  ggplot2::geom_line(colour = "black", linewidth = 1.15) +
  ggplot2::scale_x_continuous(breaks = c(0, 20, 40, 60)) +
  ggplot2::labs(
    title = "Efecto de la urbanización sobre la participación de energías renovables",
    subtitle = "Según años de trayectoria democrática",
    x = "Años de trayectoria democrática",
    y = "Efecto marginal de la urbanización") +
  ggplot2::theme_minimal(base_size = 17) +
  ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold", size = 22),
    plot.subtitle = ggplot2::element_text(size = 17),
    axis.title = ggplot2::element_text(size = 17),
    axis.text = ggplot2::element_text(size = 13),
    panel.grid.major = ggplot2::element_line(colour = "grey92", linewidth = 0.6),
    panel.grid.minor = ggplot2::element_blank(),
    plot.background = ggplot2::element_rect(fill = "white", colour = NA),
    panel.background = ggplot2::element_rect(fill = "white", colour = NA),
    plot.margin = ggplot2::margin(10, 10, 10, 10)
  )

ruta_figura <- file.path(carpeta_graficos, "figura_3_moderacion.png")
ggplot2::ggsave(ruta_figura, plot = grafico,
                width = 13.5, height = 8.44, units = "in", dpi = 100,
                bg = "white")
cat("Figura 3 generada desde R: ", ruta_figura, "\n", sep = "")
cat("M7: coef. interaccion = ", format(coeficientes[[termino_int]], digits = 8),
    ", media trayectoria democratica = ", format(media_democracia, digits = 8), "\n", sep = "")

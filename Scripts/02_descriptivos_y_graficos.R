# ============================================================
# 02. ESTADÍSTICOS DESCRIPTIVOS Y FIGURAS 1-2
# NUEVA TABLA para metodología: N, media, DE, mínimo y máximo.
# Una tabla para el panel disponible (N variable por variable) y otra
# para los 263 casos completos usados en los modelos.
# Los gráficos usan las MISMAS capas, etiquetas, escalas y exportación
# del código original pegado por el autor; solamente cambia la ruta.
# ============================================================
source(file.path(Sys.getenv("USERPROFILE"), "Downloads", "tesis-descarbonizacion-america-latina", "Scripts", "00_configuracion.R"), encoding = "UTF-8")
base_panel <- leer_panel()
base_modelos <- leer_muestra()

# 1. TABLA DESCRIPTIVA DE VARIABLES UTILIZADAS EN LA TESIS.
variables <- c(co2_pc = "Emisiones de CO₂ per cápita (t/persona)",
               renovables = "Energías renovables (% consumo final)",
               log_pib = "PIB per cápita PPP (log)",
               apertura = "Apertura comercial (% PIB)",
               urbanizacion = "Urbanización (% población)",
               anos_democracia = "Trayectoria democrática (años)",
               desempleo = "Desempleo (%)",
               gini = "Índice de Gini")

hacer_descriptivos <- function(df) {
  do.call(rbind, lapply(names(variables), function(nm) {
    x <- as.numeric(df[[nm]])
    x <- x[is.finite(x)]
    data.frame(Variable = unname(variables[[nm]]),
               N = length(x),
               Media = if (length(x)) mean(x) else NA_real_,
               DE = if (length(x) > 1) stats::sd(x) else NA_real_,
               Minimo = if (length(x)) min(x) else NA_real_,
               Maximo = if (length(x)) max(x) else NA_real_)
  }))
}
tabla_total <- hacer_descriptivos(base_panel)
tabla_muestra <- hacer_descriptivos(base_modelos)

# Datos precisos en CSV (sin redondeo); Word con dos decimales para lectura.
readr::write_csv(tabla_total, file.path(carpeta_tablas, "tabla_descriptivos_panel_general.csv"))
readr::write_csv(tabla_muestra, file.path(carpeta_tablas, "tabla_descriptivos_muestra_modelos.csv"))
redondear <- function(d) {
  for (nm in c("Media", "DE", "Minimo", "Maximo")) d[[nm]] <- sprintf("%.2f", d[[nm]])
  names(d)[names(d) == "Minimo"] <- "Mín."
  names(d)[names(d) == "Maximo"] <- "Máx."
  d
}
guardar_tabla_word(redondear(tabla_total), "Tabla descriptiva. Indicadores del panel 2000-2021",
  paste("Nota: N corresponde a observaciones país-año no faltantes por variable.",
        "DE: desviación estándar muestral. El panel contiene hasta 330 país-años.",
        "El PIB se presenta en logaritmo, igual que en los modelos."),
  file.path(carpeta_tablas, "tabla_descriptivos_panel_general.docx"), tamaño = 9)
guardar_tabla_word(redondear(tabla_muestra), "Tabla descriptiva. Muestra común de regresión",
  "Nota: Estadísticos de las mismas observaciones completas usadas en las regresiones (esperado: 263).",
  file.path(carpeta_tablas, "tabla_descriptivos_muestra_modelos.docx"), tamaño = 9)
print(tabla_total)
cat("Descriptivos generados: tabla general y tabla de muestra común.\n")

# 2. CORRELACIÓN ORIGINAL DE PEARSON (pares completos).
correlacion <- stats::cor.test(base_panel$co2_pc, base_panel$renovables,
                               use = "complete.obs", method = "pearson")
print(correlacion)
writeLines(capture.output(print(correlacion)),
           file.path(carpeta_tablas, "correlacion_co2_renovables.txt"))

# 3. GRÁFICO DESCRIPTIVO CO₂: código visual original, sin rediseño.
grafico_co2 <- ggplot2::ggplot(base_panel,
                              ggplot2::aes(x = year, y = co2_pc)) +
  ggplot2::geom_line(color = "black", linewidth = 0.7, na.rm = TRUE) +
  ggplot2::geom_point(color = "black", size = 1.2, na.rm = TRUE) +
  ggplot2::geom_text(
    data = subset(base_panel, year %in% c(2000, 2005, 2010, 2015, 2020)),
    ggplot2::aes(x = year, y = co2_pc, label = sprintf("%.1f", co2_pc)),
    size = 2.5, vjust = -0.8, color = "black", na.rm = TRUE) +
  ggplot2::facet_wrap(~country, ncol = 3) +
  ggplot2::scale_x_continuous(breaks = c(2000, 2005, 2010, 2015, 2020)) +
  ggplot2::scale_y_continuous(
    breaks = seq(0.5, 5, by = 0.5), minor_breaks = NULL,
    expand = ggplot2::expansion(mult = c(0.03, 0.10))) +
  ggplot2::labs(
    title = expression("Trayectorias de emisiones de CO"[2] * " per cápita"),
    subtitle = "Países de América Latina, 2000–2021", x = "Año",
    y = expression("Emisiones de CO"[2] * " (toneladas per cápita)")) +
  ggplot2::theme_classic(base_size = 11) +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = "white", color = NA),
    panel.background = ggplot2::element_rect(fill = "white", color = NA),
    panel.grid.major.y = ggplot2::element_line(color = "grey85", linewidth = 0.35),
    panel.grid.major.x = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    strip.background = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(size = 10.5, face = "bold", color = "black"),
    plot.title = ggplot2::element_text(size = 15, face = "bold", color = "black",
                                       margin = ggplot2::margin(b = 4)),
    plot.subtitle = ggplot2::element_text(size = 11, color = "black",
                                          margin = ggplot2::margin(b = 12)),
    axis.title = ggplot2::element_text(size = 10.5, color = "black"),
    axis.text = ggplot2::element_text(size = 8, color = "black"),
    panel.spacing = grid::unit(0.9, "lines"),
    plot.margin = ggplot2::margin(15, 15, 15, 15))
print(grafico_co2)
ggplot2::ggsave(file.path(carpeta_graficos, "trayectorias_co2_tesis.png"),
                plot = grafico_co2, width = 10, height = 8, units = "in",
                dpi = 600, bg = "white")

# 4. GRÁFICO RENOVABLES: código visual original, sin rediseño.
grafico_renovables <- ggplot2::ggplot(base_panel,
                                ggplot2::aes(x = year, y = renovables)) +
  ggplot2::geom_line(color = "black", linewidth = 0.7, na.rm = TRUE) +
  ggplot2::geom_point(color = "black", size = 1.2, na.rm = TRUE) +
  ggplot2::geom_text(
    data = subset(base_panel, year %in% c(2000, 2005, 2010, 2015, 2020)),
    ggplot2::aes(x = year, y = renovables, label = sprintf("%.1f%%", renovables)),
    size = 2.5, vjust = -0.8, color = "black", na.rm = TRUE) +
  ggplot2::facet_wrap(~country, ncol = 3) +
  ggplot2::scale_x_continuous(breaks = c(2000, 2005, 2010, 2015, 2020)) +
  ggplot2::scale_y_continuous(
    breaks = seq(0, 80, by = 10), limits = c(0, 80), minor_breaks = NULL,
    labels = function(x) paste0(x, "%"),
    expand = ggplot2::expansion(mult = c(0, 0.03))) +
  ggplot2::labs(
    title = "Trayectorias del consumo de energías renovables",
    subtitle = "Países de América Latina, 2000–2021", x = "Año",
    y = "Energías renovables (% del consumo final de energía)") +
  ggplot2::theme_classic(base_size = 11) +
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = "white", color = NA),
    panel.background = ggplot2::element_rect(fill = "white", color = NA),
    panel.grid.major.y = ggplot2::element_line(color = "grey85", linewidth = 0.35),
    panel.grid.major.x = ggplot2::element_blank(),
    panel.grid.minor = ggplot2::element_blank(),
    strip.background = ggplot2::element_blank(),
    strip.text = ggplot2::element_text(size = 10.5, face = "bold", color = "black"),
    plot.title = ggplot2::element_text(size = 15, face = "bold", color = "black",
                                       margin = ggplot2::margin(b = 4)),
    plot.subtitle = ggplot2::element_text(size = 11, color = "black",
                                          margin = ggplot2::margin(b = 12)),
    axis.title = ggplot2::element_text(size = 10.5, color = "black"),
    axis.text = ggplot2::element_text(size = 8, color = "black"),
    panel.spacing = grid::unit(0.9, "lines"),
    plot.margin = ggplot2::margin(15, 15, 15, 15))
print(grafico_renovables)
ggplot2::ggsave(file.path(carpeta_graficos, "trayectorias_renovables_tesis.png"),
                plot = grafico_renovables, width = 10, height = 8, units = "in",
                dpi = 600, bg = "white")
cat("Figuras 1 y 2 guardadas a 600 dpi.\n")

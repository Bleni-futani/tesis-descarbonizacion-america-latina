# ============================================================
# 04. ANEXO A.1: FE / RE / WITHIN-BETWEEN / HAUSMAN
# Se reproducen M6, la muestra común y las dummies anuales de los
# códigos del anexo originales (sin modificaciones a la estimación).
# Excepción: se uniforman rutas y exportación; funciones comunes en 00.
# ============================================================
source(file.path(Sys.getenv("USERPROFILE"), "Downloads", "tesis-descarbonizacion-america-latina", "Scripts", "00_configuracion.R"), encoding = "UTF-8")
base_modelos <- leer_muestra()
carpeta <- file.path(carpeta_tablas, "anexo_A1")
dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)
variables <- c("log_pib_c", "apertura_c", "urbanizacion_c", "democracia_c",
               "desempleo_c", "gini_c")

# Desviación de la media de cada país y promedio de cada país:
# descomposición within-between, distinta del centrado global previo.
for (v in variables) {
  media_pais <- ave(base_modelos[[v]], base_modelos$country,
                    FUN = function(z) mean(z, na.rm = TRUE))
  base_modelos[[paste0(v, "_w")]] <- base_modelos[[v]] - media_pais
  base_modelos[[paste0(v, "_b")]] <- media_pais
}
pdata <- plm::pdata.frame(base_modelos, index = c("country", "year"))
ff_m6 <- function(y) stats::reformulate(c(variables, "factor(year)"), response = y)
ff_wb <- function(y) stats::reformulate(
  c(paste0(variables, "_w"), paste0(variables, "_b"), "factor(year)"), response = y)

ajustar <- function(y) list(
  fe = plm::plm(ff_m6(y), pdata, model = "within", effect = "individual"),
  re = plm::plm(ff_m6(y), pdata, model = "random", effect = "individual", random.method = "walhus"),
  wb = plm::plm(ff_wb(y), pdata, model = "random", effect = "individual", random.method = "walhus"))
modelos_co2 <- ajustar("co2_pc")
modelos_ren <- ajustar("renovables")

nombres <- c("PIB per cápita (log)", "Apertura comercial", "Urbanización",
             "Años de democracia", "Desempleo", "Índice de Gini")
formatear <- function(d, terminos) {
  i <- match(terminos, d$termino)
  if (anyNA(i)) stop("No se encontraron términos en tabla A1")
  d <- d[i, , drop = FALSE]
  paste0(sprintf("%.3f", d$coeficiente), estrellas(d$valor_p), "\n(",
         sprintf("%.3f", d$error_estandar), ")")
}
crear_tabla <- function(ms) {
  fe <- extraer_robusto(ms$fe); re <- extraer_robusto(ms$re)
  wb <- extraer_robusto(ms$wb)
  data.frame(Variable = nombres, FE = formatear(fe, variables),
             RE = formatear(re, variables),
             `WB within` = formatear(wb, paste0(variables, "_w")),
             `WB between` = formatear(wb, paste0(variables, "_b")),
             check.names = FALSE)
}
tabla_co2 <- crear_tabla(modelos_co2)
tabla_ren <- crear_tabla(modelos_ren)

# Hausman convencional: con dummies anuales y auxiliar sin ellas.
hausman_fila <- function(y, temporal) {
  f <- if (temporal) ff_m6(y) else stats::reformulate(variables, response = y)
  fe <- plm::plm(f, pdata, model = "within", effect = "individual")
  re <- plm::plm(f, pdata, model = "random", effect = "individual", random.method = "walhus")
  h <- plm::phtest(fe, re)
  data.frame(Variable = ifelse(y == "co2_pc", "CO₂ per cápita", "Energías renovables"),
             Especificacion = ifelse(temporal, "Con efectos temporales", "Auxiliar sin efectos temporales"),
             Chi_cuadrado = round(unname(h$statistic), 4), gl = unname(h$parameter),
             p = signif(unname(h$p.value), 5))
}
tabla_hausman <- dplyr::bind_rows(
  hausman_fila("co2_pc", TRUE), hausman_fila("co2_pc", FALSE),
  hausman_fila("renovables", TRUE), hausman_fila("renovables", FALSE))

nota_modelos <- paste("Nota. Coeficientes y errores estándar robustos agrupados por país entre paréntesis.",
 "Todos los modelos incorporan indicadores anuales y la misma muestra.",
 "WB within: desviaciones respecto de la media del país; WB between: promedios nacionales.",
 "* p < 0,05; ** p < 0,01; *** p < 0,001.",
 "Valores p obtenidos mediante t con grados de libertad residuales, sin corrección especial para 15 grupos.")
nota_hausman <- paste("Nota. Prueba convencional de Hausman, no robusta a correlación intrapaís.",
                      "Las pruebas auxiliares no incluyen indicadores anuales.")

for (a in list(list(tabla_co2, "Tabla A.1. Comparación de modelos: CO₂ per cápita", nota_modelos, "tabla_A1_co2"),
               list(tabla_ren, "Tabla A.2. Comparación de modelos: energías renovables", nota_modelos, "tabla_A2_renovables"),
               list(tabla_hausman, "Tabla A.3. Pruebas de Hausman", nota_hausman, "tabla_A3_hausman"))) {
  df <- a[[1]]; titulo <- a[[2]]; nota <- a[[3]]; nombre <- a[[4]]
  readr::write_csv(df, file.path(carpeta, paste0(nombre, ".csv")))
  guardar_tabla_word(df, titulo, nota, file.path(carpeta, paste0(nombre, ".docx")))
}
detalle <- dplyr::bind_rows(lapply(
  list(CO2_FE = modelos_co2$fe, CO2_RE = modelos_co2$re, CO2_WB = modelos_co2$wb,
       REN_FE = modelos_ren$fe, REN_RE = modelos_ren$re, REN_WB = modelos_ren$wb),
  extraer_robusto), .id = "modelo")
readr::write_csv(detalle, file.path(carpeta, "coeficientes_completos_A1.csv"))
cat("Tablas A.1, A.2 y A.3 guardadas en", carpeta, "\n")

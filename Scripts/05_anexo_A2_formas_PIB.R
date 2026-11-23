# ============================================================
# 05. ANEXO A.2: FORMAS FUNCIONALES DEL PIB PER CÁPITA
# M6 con PIB en niveles (miles), logaritmo o término cuadrático.
# Centrado global, FE país/año, misma muestra y errores HC1.
# El punto de giro se expresa nuevamente en dólares internacionales.
# ============================================================
source(file.path(Sys.getenv("USERPROFILE"), "Downloads", "tesis-descarbonizacion-america-latina", "Scripts", "00_configuracion.R"), encoding = "UTF-8")
base_modelos <- leer_muestra()
carpeta <- file.path(carpeta_tablas, "anexo_A2")
dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)
base_a2 <- base_modelos |>
  dplyr::mutate(pib_miles = pib_pc / 1000,
                pib_miles_c = pib_miles - mean(pib_miles),
                pib_miles_c2 = pib_miles_c^2)
controles <- c("apertura_c", "urbanizacion_c", "democracia_c", "desempleo_c", "gini_c")

estimar <- function(y) list(
  Lineal = estimar_fe(base_a2, y, c("pib_miles_c", controles)),
  Logaritmica = estimar_fe(base_a2, y, c("log_pib_c", controles)),
  Cuadratica = estimar_fe(base_a2, y, c("pib_miles_c", "pib_miles_c2", controles)))
modelos <- list(CO2 = estimar("co2_pc"), Renovables = estimar("renovables"))

etiquetas <- c(pib_miles_c = "PIB per cápita (miles, centrado)",
  pib_miles_c2 = "PIB per cápita (miles, centrado)²",
  log_pib_c = "PIB per cápita (log)", apertura_c = "Apertura comercial",
  urbanizacion_c = "Urbanización", democracia_c = "Años de democracia",
  desempleo_c = "Desempleo", gini_c = "Índice de Gini")

hacer_tabla <- function(lista) {
  res <- data.frame(Variable = unname(etiquetas), check.names = FALSE)
  for (nm in names(lista)) {
    d <- extraer_robusto(lista[[nm]])
    i <- match(names(etiquetas), d$termino)
    valores <- rep("", length(i))
    ok <- !is.na(i)
    valores[ok] <- paste0(sprintf("%.3f", d$coeficiente[i[ok]]),
                         estrellas(d$valor_p[i[ok]]), "\n(",
                         sprintf("%.3f", d$error_estandar[i[ok]]), ")")
    res[[nm]] <- valores
  }
  r2 <- vapply(lista, function(m) as.numeric(summary(m)$r.squared["rsq"]), numeric(1))
  rmse <- vapply(lista, function(m) sqrt(mean(as.numeric(stats::residuals(m))^2)), numeric(1))
  res[nrow(res) + 1, ] <- c("Observaciones", as.character(vapply(lista, stats::nobs, numeric(1))))
  res[nrow(res) + 1, ] <- c("R² within", sprintf("%.3f", r2))
  res[nrow(res) + 1, ] <- c("RMSE residual", sprintf("%.3f", rmse))
  res
}

# Resumen diagnóstico A.6; misma fórmula del punto de giro del original.
diagnostico <- function(lista, dependiente) {
  dplyr::bind_rows(lapply(names(lista), function(nm) {
    modelo <- lista[[nm]]
    d <- extraer_robusto(modelo)
    fila2 <- d[d$termino == "pib_miles_c2", , drop = FALSE]
    giro <- NA_real_; en_rango <- NA
    if (nrow(fila2) == 1L) {
      b1 <- stats::coef(modelo)["pib_miles_c"]
      b2 <- stats::coef(modelo)["pib_miles_c2"]
      if (is.finite(b2) && b2 != 0) {
        giro <- as.numeric((-b1 / (2 * b2) + mean(base_a2$pib_miles)) * 1000)
        en_rango <- giro >= min(base_a2$pib_pc) && giro <= max(base_a2$pib_pc)
      }
    }
    data.frame(Dependiente = dependiente, Forma = nm, N = stats::nobs(modelo),
               R2_within = as.numeric(summary(modelo)$r.squared["rsq"]),
               RMSE_residual = sqrt(mean(as.numeric(stats::residuals(modelo))^2)),
               coef_cuadratico = if (nrow(fila2)) fila2$coeficiente else NA_real_,
               p_cuadratico = if (nrow(fila2)) fila2$valor_p else NA_real_,
               PIB_punto_giro = giro, giro_en_rango_muestral = en_rango)
  }))
}

nota <- paste("Nota. Modelos de efectos fijos por país y año, con errores estándar HC1 agrupados por país.",
              "* p < 0,05; ** p < 0,01; *** p < 0,001.",
              "PIB en niveles: miles de dólares internacionales, centrados respecto de su media.",
              "El logaritmo también se centra respecto de su media.",
              "Valores p con t y grados de libertad residuales.")
for (dv in names(modelos)) {
  numero <- if (dv == "CO2") "A4" else "A5"
  tabla <- hacer_tabla(modelos[[dv]])
  readr::write_csv(tabla, file.path(carpeta, paste0("tabla_", numero, ".csv")))
  guardar_tabla_word(tabla, paste0("Tabla A.", ifelse(dv == "CO2", "4", "5"),
                                 ". Formas funcionales del PIB: ", dv), nota,
                    file.path(carpeta, paste0("tabla_", numero, ".docx")))
}
detalle <- dplyr::bind_rows(lapply(names(modelos), function(dv) {
  dplyr::bind_rows(lapply(names(modelos[[dv]]), function(forma) {
    cbind(Dependiente = dv, Forma = forma, extraer_robusto(modelos[[dv]][[forma]]))
  }))
}))
readr::write_csv(detalle, file.path(carpeta, "coeficientes_completos_A2.csv"))
resumen <- dplyr::bind_rows(diagnostico(modelos$CO2, "CO2"),
                             diagnostico(modelos$Renovables, "Renovables"))
readr::write_csv(resumen, file.path(carpeta, "tabla_A6_diagnosticos.csv"))
resumen_imp <- resumen
for (nm in c("R2_within", "RMSE_residual")) resumen_imp[[nm]] <- round(resumen_imp[[nm]], 3)
for (nm in c("coef_cuadratico", "p_cuadratico")) resumen_imp[[nm]] <- round(resumen_imp[[nm]], 4)
resumen_imp$PIB_punto_giro <- round(resumen_imp$PIB_punto_giro, 0)
guardar_tabla_word(resumen_imp, "Tabla A.6. Diagnósticos de formas funcionales",
  "Nota. El punto de giro se calcula solo para el modelo cuadrático; su posición dentro del rango muestral no demuestra una curva de Kuznets.",
  file.path(carpeta, "tabla_A6_diagnosticos.docx"))

# Exploración original adicional: casos con PIB >= 24.201 (si procede).
casos_giro <- base_a2 |>
  dplyr::filter(pib_pc >= 24201) |>
  dplyr::group_by(country) |>
  dplyr::summarise(observaciones = dplyr::n(), primer_anio = min(year),
                   ultimo_anio = max(year), .groups = "drop") |>
  dplyr::arrange(dplyr::desc(observaciones))
readr::write_csv(casos_giro, file.path(carpeta, "exploracion_pib_24201.csv"))
cat("Tablas A.4, A.5 y A.6 guardadas en", carpeta, "\n")

# ============================================================
# 07. ANEXO A.4: EXCLUSIÓN SUCESIVA DE PAÍSES (LOCO)
# La misma base_modelos, efectos fijos país y año, y errores HC1
# agrupados por país que los modelos de resultados principales.
# Produce tablas con todas las estimaciones, cambios de signo y
# significancia, y datos para graficar la sensibilidad.
# El rótulo antiguo H5 se corrige a H4, sin alterar cálculos.
# ============================================================
source(file.path(Sys.getenv("USERPROFILE"), "Downloads", "tesis-descarbonizacion-america-latina", "Scripts", "00_configuracion.R"), encoding = "UTF-8")
datos <- as.data.frame(leer_muestra())
paises <- sort(unique(as.character(datos$country)))
carpeta <- file.path(carpeta_tablas, "anexo_A4")
dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)
cat("Países incluidos:", length(paises), "\n")
print(paises)

# Exactamente las covariables de M6 y la interacción H4 para M7.
variables_m6 <- c("log_pib_c", "apertura_c", "urbanizacion_c", "democracia_c",
                  "desempleo_c", "gini_c")
estimar_modelo <- function(base, dependiente, modelo) {
  vars <- if (modelo == "M7") c(variables_m6, "urbanizacion_c:democracia_c") else variables_m6
  ajuste <- estimar_fe(base, dependiente, vars)
  resultado <- extraer_robusto(ajuste)
  resultado$dependiente <- dependiente
  resultado$modelo <- modelo
  resultado
}

# Modelo original + 15 repeticiones excluyendo cada país, para dos DV
# y dos especificaciones. El centrado se mantiene desde base_modelos,
# IGUAL al código original: no se recalcula al excluir un país.
resultados <- list(); contador <- 1L
for (pais_excluido in c("Ninguno", paises)) {
  base_actual <- if (pais_excluido == "Ninguno") datos else
    dplyr::filter(datos, country != pais_excluido)
  for (dv in c("co2_pc", "renovables")) {
    for (modelo in c("M6", "M7")) {
      fila <- estimar_modelo(base_actual, dv, modelo)
      fila$pais_excluido <- pais_excluido
      resultados[[contador]] <- fila
      contador <- contador + 1L
    }
  }
  cat("Completado:", pais_excluido, "\n")
}
resultados_completos <- dplyr::bind_rows(resultados)

# Seis asociaciones originalmente seleccionadas para sensibilidad.
variables_interes <- data.frame(
  dependiente = c("co2_pc", "co2_pc", "renovables", "renovables", "renovables", "renovables"),
  modelo = c("M6", "M6", "M6", "M6", "M6", "M7"),
  termino = c("log_pib_c", "desempleo_c", "apertura_c", "urbanizacion_c",
              "gini_c", "urbanizacion_c:democracia_c"),
  resultado = c("PIB - CO2", "Desempleo - CO2", "Apertura - Renovables",
                "Urbanización - Renovables", "Gini - Renovables", "Interacción H4 - Renovables"))
sensibilidad <- dplyr::inner_join(resultados_completos, variables_interes,
                                 by = c("dependiente", "modelo", "termino")) |>
  dplyr::mutate(significativo = !is.na(valor_p) & valor_p < 0.05,
                signo = sign(coeficiente))
original <- sensibilidad |>
  dplyr::filter(pais_excluido == "Ninguno") |>
  dplyr::select(resultado, coef_original = coeficiente, p_original = valor_p,
                significativo_original = significativo, signo_original = signo)
comparacion <- sensibilidad |>
  dplyr::filter(pais_excluido != "Ninguno") |>
  dplyr::left_join(original, by = "resultado") |>
  dplyr::mutate(
    pierde_significancia = significativo_original & !significativo,
    gana_significancia = !significativo_original & significativo,
    cambia_signo = signo != signo_original,
    cambio_porcentual = ifelse(coef_original != 0,
                              100 * (coeficiente - coef_original) / abs(coef_original), NA_real_))

tabla_cambios <- comparacion |>
  dplyr::filter(pierde_significancia | gana_significancia | cambia_signo) |>
  dplyr::mutate(cambio = dplyr::case_when(
    pierde_significancia ~ "Pierde significancia",
    gana_significancia ~ "Gana significancia",
    cambia_signo ~ "Cambia de signo")) |>
  dplyr::transmute(`País excluido` = pais_excluido,
                   `Resultado evaluado` = resultado,
                   Cambio = cambio,
                   `Coeficiente original` = round(coef_original, 3),
                   `Coeficiente sin país` = round(coeficiente, 3),
                   `Valor p original` = round(p_original, 4),
                   `Valor p sin país` = round(valor_p, 4)) |>
  dplyr::arrange(`País excluido`, `Resultado evaluado`)
resumen_paises <- comparacion |>
  dplyr::group_by(pais_excluido) |>
  dplyr::summarise(pierden_significancia = sum(pierde_significancia),
                   ganan_significancia = sum(gana_significancia),
                   cambian_signo = sum(cambia_signo), .groups = "drop") |>
  dplyr::arrange(dplyr::desc(pierden_significancia))
sensibilidad_H4 <- comparacion |>
  dplyr::filter(resultado == "Interacción H4 - Renovables") |>
  dplyr::select(pais_excluido, coeficiente, error_estandar, valor_p,
                significativo, pierde_significancia, cambia_signo)

readr::write_csv(tabla_cambios, file.path(carpeta, "A4_paises_con_cambios.csv"))
readr::write_csv(resumen_paises, file.path(carpeta, "A4_resumen_paises.csv"))
readr::write_csv(sensibilidad_H4, file.path(carpeta, "A4_sensibilidad_H4.csv"))
readr::write_csv(resultados_completos, file.path(carpeta, "A4_resultados_completos.csv"))
readr::write_csv(comparacion, file.path(carpeta, "A4_datos_para_figuras.csv"))
cat("Cambios de significancia o signo:\n"); print(tabla_cambios, row.names = FALSE)
cat("Resumen por país:\n"); print(resumen_paises, row.names = FALSE)
cat("Archivos A.4 guardados en", carpeta, "\n")

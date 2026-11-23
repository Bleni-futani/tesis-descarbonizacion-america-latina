# ============================================================
# 03. REGRESIONES M1-M7: TABLAS 1 Y 2 DE LA TESIS
# Muestra común 263 observaciones; FE país y año.
# Preparación e inferencia idénticas a los anexos originales.
# M7: interacción urbanización × trayectoria democrática (H4).
# No se incluyen R² en las tablas principales definitivas.
# ============================================================
source(file.path(Sys.getenv("USERPROFILE"), "Downloads", "tesis-descarbonizacion-america-latina", "Scripts", "00_configuracion.R"), encoding = "UTF-8")
base_modelos <- leer_muestra()
if (nrow(base_modelos) != 263L) warning("La muestra no tiene las 263 observaciones esperadas")

variables <- c("log_pib_c", "apertura_c", "urbanizacion_c", "democracia_c",
               "desempleo_c", "gini_c")
variables_por_modelo <- list(
  M1 = variables[1], M2 = variables[1:2], M3 = variables[1:3],
  M4 = variables[1:4], M5 = variables[1:5], M6 = variables[1:6],
  M7 = c(variables, "urbanizacion_c:democracia_c"))

todos_los_modelos <- list()
todos_los_resultados <- list()
for (dv in c("co2_pc", "renovables")) {
  for (id in names(variables_por_modelo)) {
    modelo <- estimar_fe(base_modelos, dv, variables_por_modelo[[id]])
    nombre <- paste(dv, id, sep = "_")
    todos_los_modelos[[nombre]] <- modelo
    salida <- extraer_robusto(modelo)
    salida$dependiente <- dv
    salida$modelo <- id
    salida$n <- stats::nobs(modelo)
    todos_los_resultados[[nombre]] <- salida
  }
}
coeficientes <- dplyr::bind_rows(todos_los_resultados)
readr::write_csv(coeficientes, file.path(carpeta_tablas,
                                        "coeficientes_principales_completos.csv"))
saveRDS(todos_los_modelos, file.path(carpeta_procesados, "modelos_principales.rds"))

etiquetas <- c(log_pib_c = "PIB per cápita (log)",
               apertura_c = "Apertura comercial", urbanizacion_c = "Urbanización",
               democracia_c = "Años de democracia", desempleo_c = "Desempleo",
               gini_c = "Gini", 
               `urbanizacion_c:democracia_c` = "Urbanización × Democracia")

# Filas de coeficiente y error estándar separadas, como en el Word;
# salida de Word sin R², con 263 en todos los modelos.
construir_tabla <- function(dv) {
  d <- coeficientes[coeficientes$dependiente == dv, , drop = FALSE]
  filas <- list()
  for (v in names(etiquetas)) {
    fila1 <- data.frame(Variable = unname(etiquetas[[v]]), check.names = FALSE)
    fila2 <- data.frame(Variable = "", check.names = FALSE)
    for (id in paste0("M", 1:7)) {
      k <- which(d$modelo == id & d$termino == v)
      fila1[[id]] <- if (length(k) == 1) paste0(sprintf("%.3f", d$coeficiente[k]),
                                                  estrellas(d$valor_p[k])) else ""
      fila2[[id]] <- if (length(k) == 1) paste0("(", sprintf("%.3f", d$error_estandar[k]), ")") else ""
    }
    filas <- c(filas, list(fila1, fila2))
  }
  tab <- dplyr::bind_rows(filas)
  observaciones <- data.frame(Variable = "Num.Obs.", check.names = FALSE)
  for (id in paste0("M", 1:7)) observaciones[[id]] <- as.character(stats::nobs(
    todos_los_modelos[[paste(dv, id, sep = "_")]]))
  dplyr::bind_rows(tab, observaciones)
}
nota <- paste(
  "Nota. Todos los modelos incluyen efectos fijos por país y año.",
  "Errores estándar HC1 robustos, agrupados por país, entre paréntesis.",
  "* p < 0,05; ** p < 0,01; *** p < 0,001.",
  "Los valores p siguen la distribución t con grados de libertad residuales;",
  "no se aplica una corrección especial por 15 conglomerados.")

dir.create(file.path(carpeta_tablas, "resultados_principales"), recursive = TRUE,
           showWarnings = FALSE)
for (dv in c("co2_pc", "renovables")) {
  num <- if (dv == "co2_pc") 1 else 2
  titulo <- if (dv == "co2_pc")
    "Tabla 1. Modelos de efectos fijos para emisiones de CO₂ per cápita" else
    "Tabla 2. Modelos de efectos fijos para participación de energías renovables"
  tabla <- construir_tabla(dv)
  readr::write_csv(tabla, file.path(carpeta_tablas, "resultados_principales",
                                           paste0("tabla_", num, ".csv")))
  guardar_tabla_word(tabla, titulo, nota,
                    file.path(carpeta_tablas, "resultados_principales",
                              paste0("tabla_", num, ".docx")), tamaño = 9)
  cat("\n", titulo, "\n")
  print(tabla, row.names = FALSE)
}

# Valores que figuran en las Tablas 1 y 2 del Word (56 pares),
# incluidos en el propio script para no necesitar archivos en Documentación.
# La validación se realiza sobre valores publicados redondeados a 3 decimales.
esperado <- utils::read.csv(text = paste(c(
  "dependiente,modelo,termino,referencia_coeficiente,referencia_ee,referencia_estrellas",
  "co2_pc,M1,log_pib_c,0.702,0.407,",
  "co2_pc,M2,log_pib_c,0.912,0.376,*",
  "co2_pc,M3,log_pib_c,0.965,0.351,**",
  "co2_pc,M4,log_pib_c,0.997,0.365,**",
  "co2_pc,M5,log_pib_c,0.835,0.411,*",
  "co2_pc,M6,log_pib_c,0.822,0.397,*",
  "co2_pc,M7,log_pib_c,0.82,0.404,*",
  "co2_pc,M2,apertura_c,0.004,0.003,",
  "co2_pc,M3,apertura_c,0.003,0.003,",
  "co2_pc,M4,apertura_c,0.004,0.003,",
  "co2_pc,M5,apertura_c,0.003,0.003,",
  "co2_pc,M6,apertura_c,0.003,0.003,",
  "co2_pc,M7,apertura_c,0.003,0.003,",
  "co2_pc,M3,urbanizacion_c,-0.022,0.015,",
  "co2_pc,M4,urbanizacion_c,-0.023,0.015,",
  "co2_pc,M5,urbanizacion_c,-0.014,0.017,",
  "co2_pc,M6,urbanizacion_c,-0.015,0.016,",
  "co2_pc,M7,urbanizacion_c,-0.015,0.016,",
  "co2_pc,M4,democracia_c,-0.004,0.003,",
  "co2_pc,M5,democracia_c,-0.003,0.003,",
  "co2_pc,M6,democracia_c,-0.001,0.003,",
  "co2_pc,M7,democracia_c,-0.001,0.003,",
  "co2_pc,M5,desempleo_c,-0.028,0.011,*",
  "co2_pc,M6,desempleo_c,-0.022,0.01,*",
  "co2_pc,M7,desempleo_c,-0.022,0.009,*",
  "co2_pc,M6,gini_c,-0.016,0.01,",
  "co2_pc,M7,gini_c,-0.016,0.012,",
  "co2_pc,M7,urbanizacion_c:democracia_c,0.0,0.0,",
  "renovables,M1,log_pib_c,-2.872,7.256,",
  "renovables,M2,log_pib_c,-6.033,9.549,",
  "renovables,M3,log_pib_c,-4.477,9.143,",
  "renovables,M4,log_pib_c,-5.384,9.234,",
  "renovables,M5,log_pib_c,-7.663,6.6,",
  "renovables,M6,log_pib_c,-7.054,5.182,",
  "renovables,M7,log_pib_c,-11.123,4.199,**",
  "renovables,M2,apertura_c,-0.06,0.064,",
  "renovables,M3,apertura_c,-0.079,0.052,",
  "renovables,M4,apertura_c,-0.094,0.053,",
  "renovables,M5,apertura_c,-0.109,0.043,*",
  "renovables,M6,apertura_c,-0.106,0.032,**",
  "renovables,M7,apertura_c,-0.124,0.03,***",
  "renovables,M3,urbanizacion_c,-0.656,0.367,",
  "renovables,M4,urbanizacion_c,-0.631,0.354,",
  "renovables,M5,urbanizacion_c,-0.506,0.301,",
  "renovables,M6,urbanizacion_c,-0.467,0.227,*",
  "renovables,M7,urbanizacion_c,-0.463,0.143,**",
  "renovables,M4,democracia_c,0.113,0.044,*",
  "renovables,M5,democracia_c,0.122,0.053,*",
  "renovables,M6,democracia_c,0.033,0.044,",
  "renovables,M7,democracia_c,0.149,0.063,*",
  "renovables,M5,desempleo_c,-0.389,0.525,",
  "renovables,M6,desempleo_c,-0.637,0.449,",
  "renovables,M7,desempleo_c,-0.699,0.355,*",
  "renovables,M6,gini_c,0.726,0.161,***",
  "renovables,M7,gini_c,0.219,0.184,",
  "renovables,M7,urbanizacion_c:democracia_c,0.02,0.008,*"), collapse = "\n"),
  stringsAsFactors = FALSE, check.names = FALSE)
esperado$referencia_estrellas[is.na(esperado$referencia_estrellas)] <- ""

observado <- dplyr::left_join(
  esperado, coeficientes,
  by = c("dependiente", "modelo", "termino")) |>
  dplyr::mutate(
    coincide_coeficiente = !is.na(coeficiente) &
      abs(coeficiente - referencia_coeficiente) < 0.0005,
    coincide_ee = !is.na(error_estandar) &
      abs(error_estandar - referencia_ee) < 0.0005,
    coincide_estrellas = !is.na(valor_p) & estrellas(valor_p) == referencia_estrellas,
    coincide_todo = coincide_coeficiente & coincide_ee & coincide_estrellas)
destino <- file.path(carpeta_tablas, "validacion_con_tesis.csv")
readr::write_csv(observado, destino)
n_fallas <- sum(is.na(observado$coincide_todo) | !observado$coincide_todo)
cat("\nCOMPARACIÓN AUTOMÁTICA CON EL WORD: ", nrow(observado) - n_fallas,
    "/", nrow(observado), " celdas coincidentes.\n", sep = "")
if (n_fallas) {
  print(observado[is.na(observado$coincide_todo) | !observado$coincide_todo,
                 c("dependiente", "modelo", "termino", "referencia_coeficiente",
                   "coeficiente", "referencia_ee", "error_estandar",
                   "referencia_estrellas", "valor_p")])
  warning("Hay diferencias respecto de las tablas publicadas; NO subir a GitHub todavía.")
}

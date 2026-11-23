# ============================================================
# 01. PREPARACIÓN Y CONSOLIDACIÓN DE DATOS
# Fuentes: OWID/Global Carbon Project, Banco Mundial, OIT/ILOSTAT,
# V-Dem/OWID. Panel: 15 países de América Latina, 2000-2021.
# Objetivo: reproducir los nombres, las recodificaciones y el
# emparejamiento país-año del script empírico original.
# En particular, se preserva la regla de recodificación original
# de democracia; este script NO la revisa ni cambia sus resultados.
# ============================================================
source(file.path(Sys.getenv("USERPROFILE"), "Downloads", "tesis-descarbonizacion-america-latina", "Scripts", "00_configuracion.R"), encoding = "UTF-8")

# 1. IMPORTACIÓN: conservar los archivos originales sin modificarlos.
co2 <- readr::read_csv(archivo_original("co-emissions-per-capita.csv"), show_col_types = FALSE)
renov <- readr::read_csv(archivo_original("API_EG.FEC.RNEW.ZS_DS2_en_csv_v2_102971.csv"), skip = 4, show_col_types = FALSE)
pib <- readr::read_csv(archivo_original("API_NY.GDP.PCAP.PP.CD_DS2_en_csv_v2_102948.csv"), skip = 4, show_col_types = FALSE)
apertura <- readr::read_csv(archivo_original("API_NE.TRD.GNFS.ZS_DS2_en_csv_v2_171.csv"), skip = 4, show_col_types = FALSE)
urb <- readr::read_csv(archivo_original("API_SP.URB.TOTL.IN.ZS_DS2_en_csv_v2_33901.csv"), skip = 4, show_col_types = FALSE)
desempleo_ilo <- readxl::read_excel(archivo_original("UNE_DEAP_SEX_AGE_RT_A-20260820T0351.xlsx"))
gini <- readr::read_csv(archivo_original("API_SI.POV.GINI_DS2_en_csv_v2_499.csv"), skip = 4, show_col_types = FALSE)
democracia <- readr::read_csv(archivo_original("age-of-liberal-democracy-row.csv"), show_col_types = FALSE)

# 2. RENOMBRAR CO₂ Y TRANSFORMAR LOS INDICADORES DE BANCO MUNDIAL.
co2 <- co2 |>
  dplyr::rename(country = Entity, year = Year,
                co2_pc = `CO₂ emissions per capita`) |>
  dplyr::select(country, year, co2_pc)

# Equivalente a pivot_longer(... cols = matches('^\\d{4}$'))
# usado independientemente para cada base en el código original.
a_largo <- function(df, variable) {
  df |>
    tidyr::pivot_longer(cols = tidyselect::matches("^\\d{4}$"),
                        names_to = "year", values_to = variable) |>
    dplyr::rename(country = `Country Name`) |>
    dplyr::mutate(year = as.numeric(year),
                  !!variable := as.numeric(.data[[variable]])) |>
    dplyr::select(country, year, tidyselect::all_of(variable))
}
renov <- a_largo(renov, "renovables")
pib <- a_largo(pib, "pib_pc")
apertura <- a_largo(apertura, "apertura")
urb <- a_largo(urb, "urbanizacion")
gini <- a_largo(gini, "gini")

# 3. DESEMPLEO: población total y edad 15+; equivalencia de Bolivia.
desempleo_ilo <- desempleo_ilo |>
  dplyr::filter(sex.label == "Total", classif1.label == "Age (Aggregate bands): 15+") |>
  dplyr::rename(country = ref_area.label, year = time, desempleo = obs_value) |>
  dplyr::select(country, year, desempleo) |>
  dplyr::mutate(year = as.numeric(year),
                country = ifelse(country == "Bolivia, Plurinational State of", "Bolivia", country))

# 4. TRAYECTORIA DEMOCRÁTICA: copia fiel de la condición original.
# Es democrática si la etiqueta contiene 'democracy' O es numérica.
# El contador suma filas consecutivas y se reinicia en una fila clasificada
# como no democrática. El origen es 'Age of liberal democracy'.
democracia <- democracia |>
  dplyr::rename(country = Entity, year = Year) |>
  dplyr::mutate(regimen = stringr::str_squish(as.character(`Age of liberal democracy`)),
                es_democracia = stringr::str_detect(
                  stringr::str_to_lower(regimen), "democracy") |
                  !is.na(suppressWarnings(as.numeric(regimen)))) |>
  dplyr::arrange(country, year) |>
  dplyr::group_by(country) |>
  dplyr::mutate(anos_democracia = {
    contador <- 0
    resultado <- numeric(dplyr::n())
    for (i in seq_len(dplyr::n())) {
      if (es_democracia[i]) {
        contador <- contador + 1
        resultado[i] <- contador
      } else {
        contador <- 0
        resultado[i] <- 0
      }
    }
    resultado
  }) |>
  dplyr::ungroup() |>
  dplyr::select(country, year, anos_democracia)

# 5. DELIMITACIÓN DE PAÍSES Y PERÍODO, IGUAL AL SCRIPT ORIGINAL.
paises <- c("Argentina", "Bolivia", "Brazil", "Chile", "Colombia",
            "Costa Rica", "Dominican Republic", "Ecuador", "El Salvador",
            "Honduras", "Mexico", "Panama", "Paraguay", "Peru", "Uruguay")
filtrar_panel <- function(x) {
  dplyr::filter(x, country %in% paises, year >= 2000, year <= 2021)
}
co2 <- filtrar_panel(co2)
renov <- filtrar_panel(renov)
pib <- filtrar_panel(pib)
apertura <- filtrar_panel(apertura)
urb <- filtrar_panel(urb)
desempleo_ilo <- filtrar_panel(desempleo_ilo)
gini <- filtrar_panel(gini)
democracia <- filtrar_panel(democracia)

# 6. UNIÓN ORIGINAL: CO₂ COMO TABLA ANCLA Y left_join sucesivos.
base_panel <- co2 |>
  dplyr::left_join(renov, by = c("country", "year")) |>
  dplyr::left_join(pib, by = c("country", "year")) |>
  dplyr::left_join(apertura, by = c("country", "year")) |>
  dplyr::left_join(urb, by = c("country", "year")) |>
  dplyr::left_join(desempleo_ilo, by = c("country", "year")) |>
  dplyr::left_join(gini, by = c("country", "year")) |>
  dplyr::left_join(democracia, by = c("country", "year")) |>
  dplyr::mutate(log_pib = log(pib_pc)) |>
  dplyr::arrange(country, year)
if (anyDuplicated(base_panel[c("country", "year")])) stop("Hay claves país-año duplicadas")
base_modelos <- preparar_base_modelos(base_panel)

# 7. REVISAR Y GUARDAR LAS DOS BASES SIN INCORPORAR WGI.
cat("Panel general:", nrow(base_panel), "filas,", dplyr::n_distinct(base_panel$country), "países\n")
cat("Muestra común:", nrow(base_modelos), "filas,", dplyr::n_distinct(base_modelos$country), "países\n")
print(colSums(is.na(base_panel)))
readr::write_csv(base_panel, archivo_panel, na = "")
readr::write_csv(base_modelos, archivo_modelos, na = "")
# La documentación se completará después; por ahora registrar sesión en Resultados.
writeLines(capture.output(utils::sessionInfo()), file.path(raiz, "Resultados", "sessionInfo.txt"))
cat("Bases guardadas en Datos/Procesados/\n")

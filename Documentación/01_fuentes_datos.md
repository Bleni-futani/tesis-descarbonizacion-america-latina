# Fuentes de datos

## Procedencia y unidad de observación

La investigación integra series de Our World in Data, el Banco Mundial, ILOSTAT y V-Dem. La unidad de observación es país-año. El período de estudio comprende 2000–2021 y la selección territorial incluye 15 países de América Latina.

Los nombres listados corresponden a los archivos originales que reconoce el código. La función `archivo_original()` también admite que ciertas descargas tengan sufijos distintos, siempre que pueda identificar una única coincidencia por el código estable del indicador.

| Archivo o identificador | Variable en R | Origen e indicador | Consulta de la fuente |
|---|---|---|---|
| `co-emissions-per-capita.csv` | `co2_pc` | Our World in Data, emisiones de CO₂ per cápita (fuente subyacente: Global Carbon Project) | https://ourworldindata.org/grapher/co-emissions-per-capita |
| `API_EG.FEC.RNEW.ZS_DS2_en_csv_v2_102971.csv` | `renovables` | Banco Mundial, consumo de energía renovable (% del consumo final de energía) | https://data.worldbank.org/indicator/EG.FEC.RNEW.ZS |
| `API_NY.GDP.PCAP.PP.CD_DS2_en_csv_v2_102948.csv` | `pib_pc` | Banco Mundial, PIB per cápita PPP (dólares internacionales corrientes) | https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.CD |
| `API_NE.TRD.GNFS.ZS_DS2_en_csv_v2_171.csv` | `apertura` | Banco Mundial, comercio (% del PIB) | https://data.worldbank.org/indicator/NE.TRD.GNFS.ZS |
| `API_SP.URB.TOTL.IN.ZS_DS2_en_csv_v2_33901.csv` | `urbanizacion` | Banco Mundial, población urbana (% del total) | https://data.worldbank.org/indicator/SP.URB.TOTL.IN.ZS |
| `UNE_DEAP_SEX_AGE_RT_A-20260820T0351.xlsx` | `desempleo` | OIT / ILOSTAT, tasa de desempleo total, población de 15 años y más | https://ilostat.ilo.org/data/ |
| `API_SI.POV.GINI_DS2_en_csv_v2_499.csv` | `gini` | Banco Mundial, índice de Gini | https://data.worldbank.org/indicator/SI.POV.GINI |
| `age-of-liberal-democracy-row.csv` | `anos_democracia` | Our World in Data, serie *Age of liberal democracy*, con datos de V-Dem y recodificación propia | https://ourworldindata.org/grapher/age-of-liberal-democracy-row |
| CSV WGI con columnas `Country Code` y `Series Code` | `gobernanza` | Banco Mundial, *Worldwide Governance Indicators*, efectividad gubernamental (`GOV_WGI_GE.EST`) | https://www.worldbank.org/en/publication/worldwide-governance-indicators |

## Transformaciones

**Datos del Banco Mundial.** Se omiten cuatro filas iniciales de metadatos y se convierte la presentación de años en columnas a una estructura larga `country`–`year`.

**Desempleo.** Se conservan observaciones con `sex.label == "Total"` y `classif1.label == "Age (Aggregate bands): 15+"`. El nombre de Bolivia se armoniza para el emparejamiento entre fuentes.

**Trayectoria democrática.** El script utiliza la serie *Age of liberal democracy* y aplica una recodificación propia para construir `anos_democracia`: identifica como democrática una etiqueta que contiene la palabra `democracy` o un valor interpretable numéricamente, y acumula observaciones consecutivas según esa condición. Esta definición reproduce la regla implementada en el análisis y no debe confundirse automáticamente con la definición original de democracia liberal o electoral de V-Dem.

**Integración del panel.** Se utiliza la serie de CO₂ como tabla base y se incorporan las demás variables mediante uniones por país y año. La efectividad gubernamental WGI **no** se incorpora al panel principal; se integra exclusivamente en las estimaciones adicionales del Anexo A.3.

## Cobertura geográfica

Argentina, Bolivia, Brasil, Chile, Colombia, Costa Rica, República Dominicana, Ecuador, El Salvador, Honduras, México, Panamá, Paraguay, Perú y Uruguay.

Los nombres operativos en R se ajustan a las etiquetas de las bases de origen; por ejemplo, `Brazil`, `Dominican Republic`, `Mexico` y `Peru`.

## Versiones históricas

Los scripts se desarrollaron sobre los archivos descargados para el estudio en 2026. Debido a que las bases públicas pueden actualizarse, una descarga posterior del mismo indicador no necesariamente reproduce exactamente las mismas cifras y observaciones. La especificación empírica y el tratamiento de los datos quedan documentados en los scripts y en los restantes archivos de este repositorio.

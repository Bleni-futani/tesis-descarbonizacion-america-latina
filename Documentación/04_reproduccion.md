# Reproducción computacional

## Entorno de análisis

El procesamiento y las estimaciones están implementados en **R**, con apoyo de RStudio. El proyecto utiliza los paquetes `readr`, `readxl`, `dplyr`, `tidyr`, `stringr`, `ggplot2`, `plm`, `lmtest`, `flextable` y `officer`. Las funciones de `stats`, `utils`, `tools` y `grid` forman parte de R.

```r
install.packages(c(
  "readr", "readxl", "dplyr", "tidyr", "stringr",
  "ggplot2", "plm", "lmtest", "flextable", "officer"
))
```

El archivo `00_configuracion.R` centraliza la verificación de dependencias, los directorios y las funciones compartidas para la muestra, las estimaciones y la exportación.

## Estructura operativa

La versión empleada en el estudio utiliza esta ruta en Windows, construida a partir de `Sys.getenv("USERPROFILE")`:

```text
Downloads/tesis-descarbonizacion-america-latina/
├── Scripts/
├── Datos/
│   ├── Originales/
│   └── Procesados/
├── Resultados/
│   ├── Tablas/
│   └── Graficos/
└── Documentación/
```

Los scripts `01`–`09` importan la configuración desde esa ubicación. La estructura describe el entorno de ejecución efectivamente utilizado; una instalación en otra ubicación requiere adaptar los accesos locales a los archivos, sin cambiar las fórmulas ni los procedimientos estadísticos.

## Orden de ejecución

Los scripts principales están numerados para ejecutarse en la secuencia **01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09**. Cada uno carga `00_configuracion.R`, por lo que no depende de que un script anterior permanezca abierto en la misma sesión de R; los insumos compartidos se almacenan como archivos en `Datos/Procesados/`.

| Script | Entrada principal | Salidas |
|---|---|---|
| `01_preparacion_datos.R` | Datos de origen | `base_panel.csv`, `base_modelos.csv` y `sessionInfo.txt` |
| `02_descriptivos_y_graficos.R` | Bases procesadas | Dos tablas descriptivas en CSV/DOCX, correlación y gráficos de CO₂ y renovables |
| `03_modelos_principales.R` | Muestra común | Tablas 1 y 2, coeficientes detallados y `validacion_con_tesis.csv` |
| `04_anexo_A1_estimadores.R` | Muestra común | Tablas A.1–A.3 y coeficientes comparativos |
| `05_anexo_A2_formas_PIB.R` | Muestra común | Tablas A.4–A.6 y diagnósticos funcionales |
| `06_anexo_A3_especificaciones.R` | Muestra común y WGI | Tabla A.7 (paneles A–D), coeficientes y diagnósticos |
| `07_anexo_A4_sensibilidad.R` | Muestra común | Tablas y CSV de sensibilidad ante exclusión de países |
| `08_figuras_anexo_A4.R` | CSV de sensibilidad del script 07 y coeficientes principales del script 03 | Figuras A.1–A.4 de exclusión sucesiva |
| `09_figura_moderacion.R` | Muestra común y coeficientes principales de M7 | Figura 3 y datos de efectos marginales e intervalos de confianza |

Las figuras son producidas por los scripts de R y no se extraen del documento Word. Los scripts 08 y 09 reconstruyen las visualizaciones a partir de las estimaciones originales. En la Figura 3, el script 09 utiliza un tema de fondo blanco y grilla gris clara para aproximar la apariencia del documento, sin modificar la especificación M7 ni el cálculo de los intervalos de confianza. La igualdad numérica no implica identidad de píxeles entre versiones de R, paquetes o dispositivos gráficos.

## Estadísticos descriptivos

`02_descriptivos_y_graficos.R` conserva **ambas tablas**:

- `Resultados/Tablas/tabla_descriptivos_panel_general.csv` y `tabla_descriptivos_panel_general.docx`: N disponible por variable en el panel general.
- `Resultados/Tablas/tabla_descriptivos_muestra_modelos.csv` y `tabla_descriptivos_muestra_modelos.docx`: N, media, DE, mínimo y máximo sobre la muestra común de 263 observaciones.

La diferencia entre las dos versiones radica exclusivamente en la muestra resumida. Los cálculos estadísticos y las definiciones de las variables son iguales.

## Registro de resultados

El script 03 produce `Resultados/Tablas/validacion_con_tesis.csv`, que compara los valores obtenidos con los coeficientes, errores estándar y asteriscos de las Tablas 1 y 2 de la tesis. La coincidencia se define a la **precisión de los valores publicados**, no a todos los decimales internos.

El script 01 exporta `Resultados/sessionInfo.txt` con información del entorno de R utilizado en la ejecución. Las especificaciones y los productos de los anexos se describen en el [Inventario de resultados](05_inventario_resultados.md).

## Disponibilidad de datos

Los archivos originales se identifican en [Fuentes de datos](01_fuentes_datos.md) y se mantienen separados de los scripts. El archivo `.gitignore` excluye por defecto los originales y los derivados alojados en `Datos/Procesados/` del control de versiones. Dado que los proveedores actualizan periódicamente sus series, la reproducción exacta depende de las versiones históricas efectivamente utilizadas.

# La tensión entre desarrollo y descarbonización en América Latina

### Un análisis comparado de factores socioeconómicos (2000–2021)

Repositorio de códigos, documentación metodológica y resultados derivados de una tesis de **Magíster en Sociología** de la Pontificia Universidad Católica de Chile (2026).

La investigación se desarrolló en el marco del proyecto **FONDECYT de Iniciación N.º 11250489**.

## Descripción de la investigación

La investigación analiza la relación entre el desarrollo económico, la apertura comercial y la urbanización con los procesos de descarbonización en América Latina. Para ello, emplea dos indicadores dependientes estimados por separado: las **emisiones de CO₂ per cápita** y la **participación de energías renovables en el consumo final de energía**.

Se utiliza un panel longitudinal de **15 países latinoamericanos durante 2000–2021** (hasta 330 observaciones país-año). Los modelos estimados sobre la muestra común utilizan **263 observaciones**. Además, se examina si la trayectoria democrática modera la asociación entre urbanización y descarbonización.

El análisis es observacional. Sus coeficientes representan **asociaciones estadísticas y no efectos causales**.

## Datos y estrategia de análisis

Las fuentes incluyen Our World in Data / Global Carbon Project, Banco Mundial, ILOSTAT y V-Dem / Our World in Data. Los indicadores de gobernanza del Banco Mundial (WGI) se emplean únicamente en un análisis adicional de robustez.

Los modelos principales M1–M7 se estiman separadamente para ambas variables dependientes mediante regresiones de panel con **efectos fijos por país y por año**. Las estimaciones utilizan `plm` en R, errores estándar robustos HC1 agrupados por país y valores *p* calculados con una distribución *t* y los grados de libertad residuales del modelo. La interacción entre urbanización y trayectoria democrática se incorpora en M7 (H4).

Los procedimientos y sus alcances se describen en [Metodología y especificaciones](Documentaci%C3%B3n/03_decisiones_metodologicas.md).

## Estructura del repositorio

| Ruta | Contenido |
|---|---|
| `Scripts/` | Scripts numerados de configuración, datos, descriptivos, modelos y anexos |
| `Datos/Originales/` | Archivos originales utilizados como insumos, excluidos del seguimiento de Git mediante `.gitignore` |
| `Datos/Procesados/` | Base armonizada y muestra común de estimación, creadas por el código |
| `Resultados/Tablas/` | Tablas descriptivas, regresiones, comparaciones y diagnósticos |
| `Resultados/Graficos/` | Figuras descriptivas, moderación democrática y sensibilidad generadas mediante R |
| `Documentación/` | Fuentes, diccionario, metodología, reproducción e inventario de resultados |

## Scripts y orden de reproducción

| Secuencia | Script | Análisis |
|---|---|---|
| 00 | `00_configuracion.R` | Rutas, dependencias y funciones compartidas; se carga automáticamente desde los demás scripts |
| 01 | `01_preparacion_datos.R` | Importación de fuentes, construcción del panel y muestra común |
| 02 | `02_descriptivos_y_graficos.R` | Estadísticos descriptivos, correlación y dos gráficos de trayectoria |
| 03 | `03_modelos_principales.R` | Modelos M1–M7 para las dos variables dependientes |
| 04 | `04_anexo_A1_estimadores.R` | Comparación FE, RE, *within-between* y pruebas de Hausman |
| 05 | `05_anexo_A2_formas_PIB.R` | Formas funcionales alternativas del PIB |
| 06 | `06_anexo_A3_especificaciones.R` | Interacciones alternativas y control de gobernanza |
| 07 | `07_anexo_A4_sensibilidad.R` | Análisis de sensibilidad mediante exclusión sucesiva de países |
| 08 | `08_figuras_anexo_A4.R` | Figuras A.1–A.4 de sensibilidad, construidas a partir de los coeficientes del script 07 |
| 09 | `09_figura_moderacion.R` | Figura 3: efecto marginal e intervalos de confianza derivados de M7 |

Los scripts 01–09 constituyen la secuencia de elaboración de resultados; el script 08 utiliza la salida del 07 y el script 09 reproduce el modelo M7 a partir de la muestra común. No se utiliza un archivo de ejecución automática conjunta. El procedimiento informático, los paquetes de R y las características de las rutas se especifican en [Reproducción](Documentaci%C3%B3n/04_reproduccion.md).

## Figuras reproducibles

Las Figuras 1 y 2 se generan en el script 02, la Figura 3 se genera en el script 09 y las Figuras A.1–A.4 se generan en el script 08. Todas las imágenes almacenadas en `Resultados/Graficos/` provienen de salidas de R; no se incorporan imágenes extraídas del documento Word. Los valores y las tendencias de las figuras corresponden a las estimaciones que aparecen en la tesis. El script 09 utiliza un fondo blanco, grilla gris clara y una banda de confianza monocromática para aproximarse a la presentación original de la Figura 3; pequeñas diferencias de tipografía o disposición pueden persistir entre dispositivos y versiones de R/ggplot2.

## Tablas descriptivas

El script `02_descriptivos_y_graficos.R` produce **dos tablas complementarias**, ambas con **N, media, desviación estándar, mínimo y máximo** para las dos variables dependientes y las variables explicativas y de control.

| Tabla | Alcance | Formatos de salida |
|---|---|---|
| Descriptivos del panel general | Todas las observaciones válidas de cada variable; N puede diferir entre filas | `Resultados/Tablas/tabla_descriptivos_panel_general.csv` y `.docx` |
| Descriptivos de la muestra común | Observaciones completas empleadas en las regresiones; N = 263 | `Resultados/Tablas/tabla_descriptivos_muestra_modelos.csv` y `.docx` |

Las dos versiones forman parte de los resultados del procedimiento y mantienen sus definiciones originales. Los valores completos se conservan en CSV; los archivos DOCX presentan las cifras con dos decimales.

## Documentación

- [Fuentes de datos](Documentaci%C3%B3n/01_fuentes_datos.md)
- [Diccionario de variables](Documentaci%C3%B3n/02_diccionario_variables.md)
- [Decisiones metodológicas y alcances](Documentaci%C3%B3n/03_decisiones_metodologicas.md)
- [Reproducción de los análisis](Documentaci%C3%B3n/04_reproduccion.md)
- [Inventario de resultados](Documentaci%C3%B3n/05_inventario_resultados.md)

## Alcances de la reproducibilidad

La organización conserva las transformaciones y convenciones de estimación de la versión final de los análisis. `03_modelos_principales.R` genera un archivo `validacion_con_tesis.csv` que compara coeficientes, errores estándar y símbolos de significancia con los valores publicados **a su precisión de presentación**; esta comparación no equivale a una prueba de igualdad de todos los dígitos internos.

La configuración actualmente utilizada corresponde a Windows y localiza la carpeta del proyecto en `USERPROFILE/Downloads/tesis-descarbonizacion-america-latina`. Por ello, su ejecución en otra ubicación requiere ajustar las rutas de acceso, sin modificar las estimaciones.

Los conjuntos de datos originales se mantienen diferenciados del código y no están incluidos por defecto en el control de versiones. Las fuentes y los nombres de los insumos se describen en la documentación para facilitar su identificación y respetar las condiciones de reutilización de cada proveedor.

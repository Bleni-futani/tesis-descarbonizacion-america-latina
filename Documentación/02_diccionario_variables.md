# Diccionario de variables

La unidad de análisis es **país-año**; el período de referencia es **2000–2021**. El panel contempla 15 países y hasta 330 observaciones; la muestra común de los modelos completos contiene 263.

## Variables principales

| Variable en R | Papel en el análisis | Definición operativa | Escala o unidad |
|---|---|---|---|
| `country` | Identificador | País | Categoría textual |
| `year` | Identificador | Año calendario | Entero |
| `co2_pc` | Dependiente | Emisiones de CO₂ por habitante | Toneladas por persona |
| `renovables` | Dependiente | Consumo de energías renovables respecto del consumo final total de energía | Porcentaje |
| `pib_pc` | Independiente (origen) | PIB per cápita PPP | Dólares internacionales corrientes por habitante |
| `log_pib` | Independiente (transformación) | Logaritmo natural del PIB per cápita PPP | `log(pib_pc)` |
| `apertura` | Independiente | Exportaciones más importaciones de bienes y servicios como porcentaje del PIB | Porcentaje del PIB |
| `urbanizacion` | Independiente | Población urbana como proporción de la población total | Porcentaje |
| `anos_democracia` | Moderadora y covariable | Contador de años consecutivos bajo la regla de recodificación utilizada sobre la serie OWID/V-Dem | Años |
| `desempleo` | Control | Tasa de desempleo, población total de 15 años y más | Porcentaje |
| `gini` | Control | Índice de Gini | Escala original del Banco Mundial |
| `gobernanza` | Robustez (Anexo A.3) | Estimación de efectividad gubernamental WGI | Escala propia del indicador |

## Variables centradas

En la muestra común de regresión se calcula el centrado respecto de la **media global de las observaciones incluidas**:

| Variable derivada | Transformación |
|---|---|
| `log_pib_c` | `log_pib - mean(log_pib)` |
| `apertura_c` | `apertura - mean(apertura)` |
| `urbanizacion_c` | `urbanizacion - mean(urbanizacion)` |
| `democracia_c` | `anos_democracia - mean(anos_democracia)` |
| `desempleo_c` | `desempleo - mean(desempleo)` |
| `gini_c` | `gini - mean(gini)` |

El centrado global no es equivalente a la transformación *within* por país que aplica posteriormente el estimador de efectos fijos.

## Interacción y pruebas adicionales

`urbanizacion_c:democracia_c` representa el término de interacción de M7 y corresponde a la hipótesis H4. En el Anexo A.2 se utilizan `pib_miles = pib_pc / 1000`, `pib_miles_c` y su cuadrado para comparar especificaciones en niveles y cuadráticas. El Anexo A.1 separa componentes *within* (`*_w`, diferencias frente al promedio del país) y *between* (`*_b`, promedio del país). El Anexo A.3 incorpora `gobernanza_c`, centrada sobre su submuestra específica.

## Estadísticos descriptivos

Las dos tablas generadas por `02_descriptivos_y_graficos.R` presentan las mismas ocho variables: `co2_pc`, `renovables`, `log_pib`, `apertura`, `urbanizacion`, `anos_democracia`, `desempleo` y `gini`.

Los estadísticos reportados son el número de observaciones no faltantes (**N**), la **media**, la **desviación estándar muestral (DE)**, el **mínimo** y el **máximo**. Una tabla describe la disponibilidad observada de cada variable en el panel general; la segunda describe la muestra común de las estimaciones principales.

# Estrategia empírica y decisiones metodológicas

## Diseño y selección muestral

El estudio adopta un diseño observacional de datos de panel con **15 países de América Latina** durante **2000–2021**. Se combinan fuentes mediante identificadores de país y año, tomando las observaciones de emisiones de CO₂ per cápita como base de emparejamiento. El período comprende 22 años, con un máximo teórico de **330 país-años**.

Para los modelos principales se utiliza una **muestra común de 263 observaciones**, definida por disponibilidad simultánea de ambas variables dependientes y de PIB per cápita, apertura comercial, urbanización, trayectoria democrática, desempleo y Gini. Esta decisión mantiene constante la composición muestral entre M1 y M7 y entre las dos variables dependientes.

## Modelos principales

Las dos variables dependientes se estiman **por separado**:

1. `co2_pc`: emisiones de CO₂ per cápita.
2. `renovables`: participación de energías renovables en el consumo final energético.

Se utilizan modelos anidados **M1–M6** que introducen sucesivamente el PIB per cápita en logaritmos, la apertura comercial, la urbanización, la trayectoria democrática, el desempleo y el Gini. **M7** agrega la interacción entre urbanización y trayectoria democrática, correspondiente a **H4**.

Las variables explicativas se centran respecto de su media global en la muestra común. Los modelos incluyen **efectos fijos por país** mediante `plm(..., model = "within", effect = "individual")` y **efectos fijos por año** mediante `factor(year)` dentro de la fórmula. Los coeficientes se interpretan como asociaciones condicionales, no como estimaciones de efectos causales.

## Errores estándar e inferencia

La matriz de varianzas-covarianzas se calcula con `plm::vcovHC(modelo, method = "arellano", type = "HC1", cluster = "group")`, agrupando las observaciones por país. Los valores *p* se calculan a partir de la distribución *t* con grados de libertad residuales del modelo. Las tablas utilizan las convenciones `* p < 0,05`, `** p < 0,01` y `*** p < 0,001`.

Esta implementación mantiene el criterio utilizado en los scripts reorganizados, pero **no incluye una corrección inferencial específica para el número reducido de conglomerados (15 países)**. Por ello, la significancia cercana a los umbrales convencionales debe interpretarse con cautela.

## Ejercicios complementarios

### Anexo A.1 — Comparación de estimadores

Se presentan estimaciones de efectos fijos (FE), efectos aleatorios (RE) y una descomposición *within-between* (WB). Se incluyen pruebas de Hausman convencionales, con efectos de año en la especificación principal y una prueba auxiliar sin indicadores temporales. El contraste auxiliar no sustituye a los modelos principales ni constituye una prueba robusta al agrupamiento.

### Anexo A.2 — Formas funcionales del PIB

Se comparan una forma lineal en niveles (PIB expresado en miles), la transformación logarítmica utilizada en el análisis principal y una forma cuadrática del PIB centrado. Los diagnósticos incluyen R² *within*, RMSE y el punto de giro cuando corresponde a la especificación cuadrática. La presencia de un punto de giro dentro del rango muestral no constituye, por sí misma, evidencia de una curva ambiental de Kuznets.

### Anexo A.3 — Especificaciones alternativas

Se estiman la interacción principal urbanización × trayectoria democrática, y por separado interacciones alternativas de democracia con PIB y con apertura comercial. Como análisis adicional se utiliza la efectividad gubernamental del Banco Mundial (WGI) y se comparan M6 y M6 + gobernanza sobre **la misma submuestra con disponibilidad de WGI**. La variable de gobernanza no modifica el panel principal.

### Anexo A.4 — Sensibilidad a países

Se reestiman los modelos M6 y M7 excluyendo sucesivamente uno de los 15 países, para ambas variables dependientes. Se resumen cambios en signo, magnitud y significancia de seis asociaciones seleccionadas. El análisis mantiene la muestra y el centrado originales de las covariables restantes; no se recalculan sus medias tras cada exclusión.

## Interpretación de los indicadores

Las emisiones de CO₂ per cápita y el porcentaje de renovables capturan dimensiones diferentes de la descarbonización; **no forman un índice compuesto**. El indicador de renovables corresponde al consumo final total de energía, no solo a la generación eléctrica, e incorpora las fuentes contabilizadas por la metodología del proveedor. El indicador de emisiones no cubre necesariamente la totalidad de los gases de efecto invernadero.

La variable `anos_democracia` proviene de una **recodificación operacional de la serie *Age of liberal democracy***, descrita en [Fuentes de datos](01_fuentes_datos.md). No se presupone que dicha recodificación tenga idéntico alcance conceptual al de otras medidas de democracia.

## Relación entre código y resultados

El script principal preliminar de trabajo no explicitaba indicadores anuales en M1–M6; la organización final de los análisis aplica efectos fijos por país y año, como se describe en la metodología y en los scripts de los anexos. La rutina `03_modelos_principales.R` conserva una comparación de los coeficientes, errores estándar y niveles de significancia con las tablas de la tesis a la precisión publicada. Los resultados de esa comprobación se exportan a `Resultados/Tablas/validacion_con_tesis.csv`.

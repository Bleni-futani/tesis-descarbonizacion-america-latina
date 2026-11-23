# Inventario de resultados

Este inventario describe **las salidas definidas por los scripts de R**. Las rutas son relativas a la carpeta raíz del proyecto y no implican que los datos originales se encuentren alojados en GitHub.

## Tablas descriptivas y figuras principales

| Archivo | Contenido |
|---|---|
| `Resultados/Tablas/tabla_descriptivos_panel_general.csv` | N, media, DE, mínimo y máximo por variable según disponibilidad del panel |
| `Resultados/Tablas/tabla_descriptivos_panel_general.docx` | Misma tabla, con cifras a dos decimales y nota metodológica |
| `Resultados/Tablas/tabla_descriptivos_muestra_modelos.csv` | Estadísticos sobre la muestra común de regresión (263 casos) |
| `Resultados/Tablas/tabla_descriptivos_muestra_modelos.docx` | Misma tabla, con cifras a dos decimales y nota metodológica |
| `Resultados/Tablas/correlacion_co2_renovables.txt` | Correlación de Pearson y prueba de asociación entre ambas dependientes |
| `Resultados/Graficos/trayectorias_co2_tesis.png` | Trayectorias anuales de CO₂ per cápita por país |
| `Resultados/Graficos/trayectorias_renovables_tesis.png` | Trayectorias anuales del consumo de renovables por país |

Las dos tablas descriptivas se incluyen como **salidas independientes y complementarias**, sin establecer una jerarquía entre ellas.

## Regresiones principales

| Ruta | Contenido |
|---|---|
| `Resultados/Tablas/coeficientes_principales_completos.csv` | Estimaciones detalladas de M1–M7 para ambas variables dependientes |
| `Resultados/Tablas/resultados_principales/tabla_1.csv` y `.docx` | Tabla 1: modelos de CO₂ per cápita |
| `Resultados/Tablas/resultados_principales/tabla_2.csv` y `.docx` | Tabla 2: modelos de energías renovables |
| `Resultados/Tablas/validacion_con_tesis.csv` | Comparación con los valores publicados en las Tablas 1 y 2 |

## Anexos y ejercicios adicionales

| Ruta | Contenido |
|---|---|
| `Resultados/Tablas/anexo_A1/` | Comparaciones FE, RE y WB; Hausman; coeficientes detallados (A.1–A.3) |
| `Resultados/Tablas/anexo_A2/` | Formas funcionales del PIB y diagnósticos (A.4–A.6) |
| `Resultados/Tablas/anexo_A3/` | Especificaciones alternativas, gobernanza y Tabla A.7 con cuatro paneles |
| `Resultados/Tablas/anexo_A4/` | Sensibilidad ante exclusión sucesiva de países, incluyendo `A4_sensibilidad_H4.csv` |
| `Resultados/Graficos/figura_A.1_sensibilidad.png` a `figura_A.4_sensibilidad.png` | Figuras A.1–A.4 de los modelos M6 y M7 por exclusión sucesiva; script 08 |
| `Resultados/Graficos/figura_3_moderacion.png` | Figura 3 de la moderación urbanización × trayectoria democrática; generada por el script 09 sobre fondo blanco |
| `Resultados/Tablas/figura_3_datos_moderacion.csv` | Efectos marginales, errores estándar e intervalos de confianza de la Figura 3 |
| `Resultados/Tablas/anexo_A4/A4_datos_para_figuras.csv` | Datos y diagnósticos de sensibilidad obtenidos del script 07 |

## Archivos técnicos de reproducción

| Archivo | Función |
|---|---|
| `Datos/Procesados/base_panel.csv` | Panel armonizado para las 15 unidades nacionales |
| `Datos/Procesados/base_modelos.csv` | Muestra común de estimación con las variables centradas |
| `Datos/Procesados/modelos_principales.rds` | Objetos de estimación de los modelos principales |
| `Resultados/sessionInfo.txt` | Registro del entorno de ejecución de R |

El archivo `.gitignore` mantiene los datos originales y la base procesada fuera del seguimiento de Git por defecto. Los formatos CSV y DOCX responden a funciones distintas: recuperación de valores numéricos y consulta de tablas formateadas, respectivamente.

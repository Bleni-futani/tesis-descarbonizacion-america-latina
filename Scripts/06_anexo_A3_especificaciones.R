# ANEXO A.3 — Sensibilidad a especificaciones alternativas
# Requisito: ejecutar antes el script principal y disponer de base_modelos.
# No modifica la base principal; WGI se combina solo en este anexo.

source(file.path(Sys.getenv("USERPROFILE"), "Downloads", "tesis-descarbonizacion-america-latina", "Scripts", "00_configuracion.R"), encoding = "UTF-8")
base_modelos <- leer_muestra()
variables_base <- c('country','year','co2_pc','renovables','log_pib_c',
                    'apertura_c','urbanizacion_c','democracia_c','desempleo_c','gini_c')
faltantes <- setdiff(variables_base, names(base_modelos))
if (length(faltantes)) stop('Faltan columnas: ', paste(faltantes, collapse=', '))

carpeta <- file.path(carpeta_tablas, 'anexo_A3')
dir.create(carpeta, showWarnings=FALSE, recursive=TRUE)

# Mantener la misma muestra para todas las comparaciones sin gobernanza.
datos <- as.data.frame(base_modelos)
datos <- datos[complete.cases(datos[,variables_base]),,drop=FALSE]
datos <- datos[order(datos$country,datos$year),,drop=FALSE]
cat('Muestra base:',nrow(datos),'observaciones y',length(unique(datos$country)),'paises.\n')
if (anyDuplicated(datos[c('country','year')])) stop('Hay combinaciones country-year duplicadas.')

# Especificaciones: M6, M7 (H4) y dos interacciones alternativas.
controles <- 'log_pib_c + apertura_c + urbanizacion_c + democracia_c + desempleo_c + gini_c'
especificaciones <- list(
  'M6: sin interaccion' = controles,
  'M7: urbanizacion x democracia (H4)' = paste0(controles,' + urbanizacion_c:democracia_c'),
  'Alternativa: PIB x democracia' = paste0(controles,' + log_pib_c:democracia_c'),
  'Alternativa: apertura x democracia' = paste0(controles,' + apertura_c:democracia_c')
)

# IMPORTAR WGI: efectividad gubernamental (estimacion, escala aprox. -2.5 a 2.5).
# Se abrira una ventana para seleccionar el CSV adjunto desde Descargas.
# No requiere que gobernanza exista previamente en base_modelos.
ruta_wgi <- archivo_wgi()
cat('Archivo WGI:', ruta_wgi, '\n')
wgi_raw <- read.csv(ruta_wgi, check.names=FALSE, stringsAsFactors=FALSE,
                    fileEncoding='UTF-8')
if (!all(c('Country Code','Series Code') %in% names(wgi_raw))) {
  stop('El CSV seleccionado no tiene las columnas Country Code y Series Code.')
}
wgi <- wgi_raw[wgi_raw[['Series Code']]=='GOV_WGI_GE.EST',,drop=FALSE]
if (nrow(wgi)==0) stop('No aparece GOV_WGI_GE.EST (efectividad gubernamental).')
columnas_anio <- grep('^20[0-9]{2} \\[YR20[0-9]{2}\\]$', names(wgi), value=TRUE)
if (!length(columnas_anio)) stop('No se encontraron columnas de anos WGI.')
wgi_largo <- tidyr::pivot_longer(wgi, cols=dplyr::all_of(columnas_anio),
                                 names_to='col_anio',values_to='gobernanza')
wgi_largo$year <- as.integer(substr(wgi_largo$col_anio,1,4))
wgi_largo$gobernanza <- suppressWarnings(as.numeric(wgi_largo$gobernanza))
wgi_largo <- wgi_largo[,c('Country Code','year','gobernanza')]
names(wgi_largo)[1] <- 'codigo'
wgi_largo <- wgi_largo[!duplicated(wgi_largo[c('codigo','year')]),]

# Vincular paises de la tesis con codigos ISO3 de la base WGI.
# Se reconocen nombres en espanol e ingles, con o sin tildes.
normalizar <- function(x) {
  x <- iconv(as.character(x), from='', to='ASCII//TRANSLIT')
  tolower(trimws(x))
}
mapa <- c(
  argentina='ARG', bolivia='BOL', brasil='BRA', brazil='BRA',
  chile='CHL', colombia='COL', 'costa rica'='CRI',
  ecuador='ECU', 'el salvador'='SLV', guatemala='GTM',
  honduras='HND', mexico='MEX', nicaragua='NIC',
  panama='PAN', paraguay='PRY', peru='PER', uruguay='URY',
  'republica dominicana'='DOM', 'dominican republic'='DOM',
  'venezuela'='VEN', 'venezuela, rb'='VEN',
  'bahamas'='BHS', 'bahamas, the'='BHS', barbados='BRB'
)
datos$codigo <- unname(mapa[normalizar(datos$country)])
if (anyNA(datos$codigo)) {
  stop('No se reconocieron estos paises: ',
       paste(unique(datos$country[is.na(datos$codigo)]),collapse=', '))
}
datos <- dplyr::left_join(datos,wgi_largo,by=c('codigo','year'))
cat('Gobernanza WGI importada. Filas con dato:',sum(!is.na(datos$gobernanza)),
    'de',nrow(datos),'\n')
cat('Anos sin dato WGI:',paste(sort(unique(datos$year[is.na(datos$gobernanza)])),collapse=', '),'\n')
variable_gobernanza <- 'gobernanza' 

# Funciones auxiliares
estimar <- function(df, dep, rhs) {
  pd <- plm::pdata.frame(df,index=c('country','year'))
  plm::plm(stats::as.formula(paste(dep,'~',rhs,'+ factor(year)')),
           data=pd, model='within', effect='individual')
}

extraer <- function(modelo, dependiente, especificacion, muestra) {
  vc <- plm::vcovHC(modelo, method='arellano',type='HC1',cluster='group')
  prueba <- lmtest::coeftest(modelo,vcov.=vc)
  data.frame(
    dependiente=dependiente, especificacion=especificacion,
    variable=rownames(prueba), coeficiente=unname(prueba[,1]),
    error_estandar=unname(prueba[,2]), estadistico=unname(prueba[,3]),
    valor_p=unname(prueba[,4]), n=stats::nobs(modelo),
    paises=length(unique(muestra$country)),
    r2_within=unname(summary(modelo)$r.squared['rsq']),
    stringsAsFactors=FALSE, row.names=NULL
  )
}

resultados <- list()
modelos <- list()
for (dep in c('co2_pc','renovables')) {
  for (nombre in names(especificaciones)) {
    modelo <- estimar(datos,dep,especificaciones[[nombre]])
    llave <- paste(dep,nombre,sep=' | ')
    modelos[[llave]] <- modelo
    resultados[[llave]] <- extraer(modelo,dep,nombre,datos)
  }
}

# Gobernanza opcional: comparar M6 y M6+gobernanza en IDENTICA submuestra.
# Es una comparacion adicional, no directamente equiparable a las filas de muestra completa.
if (!is.null(variable_gobernanza)) {
  if (!variable_gobernanza %in% names(datos)) {
    stop('No existe la variable de gobernanza: ',variable_gobernanza)
  }
  if (!is.numeric(datos[[variable_gobernanza]])) {
    stop('La variable de gobernanza debe ser numerica.')
  }
  if (variable_gobernanza %in% variables_base) stop('Gobernanza debe ser una variable adicional.')
  dg <- as.data.frame(datos)
  dg <- dg[complete.cases(dg[,c(variables_base,variable_gobernanza)]),,drop=FALSE]
  dg <- dg[order(dg$country,dg$year),,drop=FALSE]
  if (nrow(dg)<50) stop('Muy pocas observaciones completas para gobernanza.')
  dg$gobernanza_c <- dg[[variable_gobernanza]]-mean(dg[[variable_gobernanza]])
  for (dep in c('co2_pc','renovables')) {
    for (nombre in c('M6: misma submuestra gobernanza','M6 + gobernanza')) {
      rhs <- if (nombre=='M6 + gobernanza') paste(controles,'+ gobernanza_c') else controles
      mod <- estimar(dg,dep,rhs)
      llave <- paste(dep,nombre,sep=' | ')
      modelos[[llave]] <- mod
      resultados[[llave]] <- extraer(mod,dep,nombre,dg)
    }
  }
}

completos <- dplyr::bind_rows(resultados)
utils::write.csv(completos,file.path(carpeta,'coeficientes_completos_A3.csv'),
                 row.names=FALSE,fileEncoding='UTF-8')

# ==============================================================
# TABLA A.7 COMPARATIVA, CUATRO PANELES, CON TODOS LOS COEFICIENTES
# No hace falta seleccionar CSV de resultados ni ejecutar otro script.
# ==============================================================

# Las dummies de ano se mantienen en todos los modelos pero no se
# despliegan individualmente: se indican en la nota para legibilidad.
variables_orden <- c('log_pib_c','apertura_c','urbanizacion_c','democracia_c',
                    'desempleo_c','gini_c','urbanizacion_c:democracia_c',
                    'log_pib_c:democracia_c','apertura_c:democracia_c','gobernanza_c')
etiquetas <- c(
  log_pib_c='PIB per capita (log)',
  apertura_c='Apertura comercial',
  urbanizacion_c='Urbanizacion',
  democracia_c='Anos de democracia',
  desempleo_c='Desempleo',
  gini_c='Indice de Gini',
  'urbanizacion_c:democracia_c'='Urbanizacion x democracia (H4)',
  'log_pib_c:democracia_c'='PIB x democracia',
  'apertura_c:democracia_c'='Apertura x democracia',
  gobernanza_c='Efectividad gubernamental'
)

# Normalizar el orden de terminos de interaccion si plm lo invierte.
normalizar_termino <- function(x) {
  x[x=='democracia_c:urbanizacion_c'] <- 'urbanizacion_c:democracia_c'
  x[x=='democracia_c:log_pib_c'] <- 'log_pib_c:democracia_c'
  x[x=='democracia_c:apertura_c'] <- 'apertura_c:democracia_c'
  x
}

estrellas <- function(p) ifelse(is.na(p),'',ifelse(p<.001,'***',
                       ifelse(p<.01,'**',ifelse(p<.05,'*',''))))
formato <- function(x) sprintf('%.3f',x)
completos$termino <- normalizar_termino(completos$variable)
completos$celda <- paste0(formato(completos$coeficiente),
                          estrellas(completos$valor_p),' (',
                          formato(completos$error_estandar),')')

# Construye una tabla ancha, conservando todos los controles e interacciones.
armar_panel <- function(dep, specs, titulos) {
  sub <- completos[completos$dependiente==dep &
                   completos$especificacion %in% specs &
                   completos$termino %in% variables_orden,,drop=FALSE]
  base <- data.frame(termino=variables_orden, stringsAsFactors=FALSE)
  for (i in seq_along(specs)) {
    z <- sub[sub$especificacion==specs[i],c('termino','celda'),drop=FALSE]
    z <- z[!duplicated(z$termino),,drop=FALSE]
    pos <- match(base$termino,z$termino)
    base[[titulos[i]]] <- ifelse(is.na(pos),'—',z$celda[pos])
  }
  # Solo conservar filas presentes en alguno de los modelos del panel.
  valores <- as.matrix(base[,-1,drop=FALSE])
  base <- base[rowSums(valores!='—')>0,,drop=FALSE]
  base$Variable <- unname(etiquetas[base$termino])
  base <- base[,c('Variable',titulos),drop=FALSE]
  # Anadir diagnosticos por modelo, dentro de la misma tabla.
  info <- unique(completos[completos$dependiente==dep &
                          completos$especificacion %in% specs,
                          c('especificacion','n','paises','r2_within'),drop=FALSE])
  for (nombre in c('Observaciones','Paises','R2 within')) {
    fila <- as.list(rep('—',length(titulos)+1))
    names(fila) <- c('Variable',titulos)
    fila$Variable <- nombre
    for (i in seq_along(specs)) {
      k <- match(specs[i],info$especificacion)
      if (!is.na(k)) {
        fila[[titulos[i]]] <- switch(nombre,
          'Observaciones'=as.character(info$n[k]),
          'Paises'=as.character(info$paises[k]),
          'R2 within'=formato(info$r2_within[k]))
      }
    }
    base <- rbind(base,as.data.frame(fila,stringsAsFactors=FALSE,check.names=FALSE))
  }
  rownames(base) <- NULL
  base
}

spec_full <- c('M6: sin interaccion',
               'M7: urbanizacion x democracia (H4)',
               'Alternativa: PIB x democracia',
               'Alternativa: apertura x democracia')
nombres_full <- c('M6','M7 (H4)','PIB x democracia','Apertura x democracia')
spec_gob <- c('M6: misma submuestra gobernanza','M6 + gobernanza')
nombres_gob <- c('M6 (misma muestra)','M6 + gobernanza')

panel_A <- armar_panel('co2_pc',spec_full,nombres_full)
panel_B <- armar_panel('renovables',spec_full,nombres_full)
panel_C <- armar_panel('co2_pc',spec_gob,nombres_gob)
panel_D <- armar_panel('renovables',spec_gob,nombres_gob)

# Guardar cada panel en CSV, utiles tambien para Excel.
for (nm in c('A','B','C','D')) {
  utils::write.csv(get(paste0('panel_',nm)),
    file.path(carpeta,paste0('tabla_A7_panel_',nm,'.csv')),
    row.names=FALSE,fileEncoding='UTF-8',na='')
}

# Exportacion Word: cada panel con encabezado, tabla y nota final.
crear_flextable <- function(tabla) {
  ft <- flextable::flextable(tabla)
  ft <- flextable::theme_booktabs(ft)
  ft <- flextable::fontsize(ft,size=9,part='all')
  ft <- flextable::bold(ft,part='header')
  ft <- flextable::align(ft,j=2:ncol(tabla),align='center',part='all')
  ft <- flextable::autofit(ft)
  ft <- flextable::set_table_properties(ft,layout='autofit')
  ft
}

doc <- officer::read_docx()
doc <- officer::body_add_par(doc,'Anexo A.3. Especificaciones alternativas',
                             style='heading 1')
doc <- officer::body_add_par(doc,
  'Tabla A.7. Sensibilidad a especificaciones alternativas',style='heading 2')

paneles <- list(
  'Panel A. Emisiones de CO2: interacciones alternativas'=panel_A,
  'Panel B. Participacion de renovables: interacciones alternativas'=panel_B,
  'Panel C. Emisiones de CO2: control de gobernanza'=panel_C,
  'Panel D. Participacion de renovables: control de gobernanza'=panel_D
)
for (nombre in names(paneles)) {
  doc <- officer::body_add_par(doc,nombre,style='heading 3')
  doc <- flextable::body_add_flextable(doc,crear_flextable(paneles[[nombre]]))
  doc <- officer::body_add_par(doc,'',style='Normal')
}
doc <- officer::body_add_par(doc,
  paste0('Nota: todos los modelos incluyen efectos fijos por pais y dummies de ano. ',
  'Coeficientes y errores estandar robustos agrupados por pais entre parentesis. ',
  '* p < 0,05; ** p < 0,01; *** p < 0,001. ',
  'Las interacciones se estiman por separado. ',
  'Los paneles C y D comparan modelos sobre una misma submuestra con datos WGI. ',
  'Las dummies de ano se incluyen en la estimacion, pero no se muestran en la tabla.'),
  style='Normal')
archivo_word <- file.path(carpeta,'tabla_A7_comparativa_completa.docx')
print(doc,target=archivo_word)

# Diagnosticos y detalle de resultados exactos.
diagnosticos <- unique(completos[,c('dependiente','especificacion','n','paises','r2_within')])
utils::write.csv(diagnosticos,file.path(carpeta,'diagnosticos_A3.csv'),
                 row.names=FALSE,fileEncoding='UTF-8')
cat('\n=== DIAGNOSTICOS ===\n')
print(diagnosticos,row.names=FALSE)
cat('\n=== INTERACCIONES Y GOBERNANZA (SIN REDONDEAR) ===\n')
print(completos[completos$termino %in%
                 c('urbanizacion_c:democracia_c','log_pib_c:democracia_c',
                   'apertura_c:democracia_c','gobernanza_c'),
                 c('dependiente','especificacion','termino','coeficiente',
                   'error_estandar','valor_p')],row.names=FALSE)
cat('\nArchivo Word generado:',normalizePath(archivo_word,winslash='/',mustWork=TRUE),'\n')
cat('Carpeta:',normalizePath(carpeta,winslash='/',mustWork=TRUE),'\n')

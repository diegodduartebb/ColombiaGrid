## code to prepare `DATASET` dataset goes here


rm(list = ls())

if(!require(pacman)) install.packages("pacman")
library(pacman)

p_load(dplyr, sf, tidyverse, usethis)
options(scipen = 999)

######################################################################################################################
##### Leer shapefile de los municipios
######################################################################################################################

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

mapa_colombia <- st_read("insumos_shp/MGN_MPIO_POLITICO.shp")

######################################################################################################################
##### Manejo base geografica
######################################################################################################################

# Eliminamos geometría para quedarnos solo con la tabla
mapa_colombia <- st_drop_geometry(mapa_colombia)

# Creamos columnas numéricas para departamento y municipio
mapa_colombia <- mapa_colombia %>%
  mutate(dpto_cod = as.numeric(DPTO_CCDGO),
         muncol   = as.numeric(MPIO_CDPMP))

# Seleccionamos las columnas relevantes
df_muni <- subset(mapa_colombia,
                  select = c(dpto_cod, muncol, DPTO_CNMBR, MPIO_CNMBR))

######################################################################################################################
##### Creación bloque por departamento
######################################################################################################################

generar_bloque_depto <- function(df_municipios_depto) {
  n <- nrow(df_municipios_depto)  # número de municipios

  # dimensiones aproximadas para un bloque "cuadrado"
  ancho <- ceiling(sqrt(n))
  alto  <- ceiling(n / ancho)

  # Creamos un vector con todas las posibles posiciones
  pos_rows <- rep(1:alto, each = ancho)
  pos_cols <- rep(1:ancho, times = alto)

  # Tomamos sólo las primeras n celdas (si sobran)
  pos_rows <- pos_rows[1:n]
  pos_cols <- pos_cols[1:n]

  # Ordenamos los municipios de alguna forma; por ejemplo, alfabéticamente
  df_municipios_depto <- df_municipios_depto %>%
    mutate(
      row = pos_rows,
      col = pos_cols
    )

  return(df_municipios_depto)}

######################################################################################################################
##### Offsets para cada departamento
######################################################################################################################

df_offsets <- data.frame(
  dpto_cod = c(
    5,   # Antioquia
    8,   # Atlántico
    11,  # Bogotá, D.C.
    13,  # Bolívar
    15,  # Boyacá
    17,  # Caldas
    18,  # Caquetá
    19,  # Cauca
    20,  # Cesar
    23,  # Córdoba
    25,  # Cundinamarca
    27,  # Chocó
    41,  # Huila
    44,  # La Guajira
    47,  # Magdalena
    50,  # Meta
    52,  # Nariño
    54,  # Norte de Santander
    63,  # Quindío
    66,  # Risaralda
    68,  # Santander
    70,  # Sucre
    73,  # Tolima
    76,  # Valle del Cauca
    81,  # Arauca
    85,  # Casanare
    86,  # Putumayo
    88,  # San Andrés y Providencia
    91,  # Amazonas
    94,  # Guainía
    95,  # Guaviare
    97,  # Vaupés
    99   # Vichada
  ),
  offset_row = c( ## POSICIÓN Y
    21,  # Antioquia
    6,  # Atlántico
    47,  # Bogotá
    12,  # Bolívar
    23,  # Boyacá
    33,  # Caldas
    54,  # Caquetá
    49,  # Cauca
    7,  # Cesar
    15,  # Córdoba
    35,  # Cundinamarca
    31,  # Chocó
    47,  # Huila
    1,  # La Guajira
    5,  # Magdalena
    49,  # Meta
    56,  # Nariño
    10,  # Norte de Santander
    38,  # Quindío
    33,  # Risaralda
    13,  # Santander
    9,  # Sucre
    39,  # Tolima
    42,  # Valle del Cauca
    28,  # Arauca
    32,  # Casanare
    57,  # Putumayo
    1,  # San Andrés
    59,  # Amazonas
    58,  # Guainía
    56,  # Guaviare
    59,  # Vaupés
    55   # Vichada
  ),
  offset_col = c(  #POSICIÓN X
    16,  # Antioquia
    25,  # Atlántico
    30,  # Bogotá
    25,  # Bolívar
    29,  # Boyacá
    21,  # Caldas
    21,  # Caquetá
    10,  # Cauca
    38,  # Cesar
    17,  # Córdoba
    28,  # Cundinamarca
    9,  # Chocó
    19,  # Huila
    40,  # La Guajira
    31,  # Magdalena
    27,  # Meta
    7,  # Nariño
    44,  # Norte de Santander
    15,  # Quindío
    16,  # Risaralda
    33,  # Santander
    18,  # Sucre
    20,  # Tolima
    11,  # Valle del Cauca
    42,  # Arauca
    42,  # Casanare
    16,  # Putumayo
    1,  # San Andrés
    21,  # Amazonas
    30,  # Guainía
    27,  # Guaviare
    26,  # Vaupés
    30   # Vichada
  )
)

######################################################################################################################
##### Generar layout final
######################################################################################################################

df_final_list <- list()

# Para cada departamento en df_offsets, generamos su bloque y sumamos offset
for (i in seq_len(nrow(df_offsets))) {

  # Tomamos el código del departamento y sus offsets
  this_depto  <- df_offsets$dpto_cod[i]
  off_row     <- df_offsets$offset_row[i]
  off_col     <- df_offsets$offset_col[i]

  # Subconjunto de municipios
  df_sub <- df_muni %>%
    filter(dpto_cod == this_depto)

  # Creamos el bloque local
  bloque_local <- generar_bloque_depto(df_sub)

  # Sumamos los offsets
  bloque_local <- bloque_local %>%
    mutate(
      global_row = row + off_row,
      global_col = col + off_col
    )

  # Guardamos en la lista
  df_final_list[[i]] <- bloque_local
}

# Unimos todo
df_final <- do.call(rbind, df_final_list)


#####
# Cambio de nombre a San andrés
df_final <- df_final %>%
  mutate(DPTO_CNMBR = ifelse(dpto_cod == 88, "SAN ANDRÉS", DPTO_CNMBR))
#####

######################################################################################################################
##### GRAFICO CON ETIQUETAS
######################################################################################################################

# Calculamos el centro (promedio) de cada bloque departamental
df_depto_labels <- df_final %>%
  group_by(dpto_cod, DPTO_CNMBR) %>%
  summarise(
    centro_row = mean(global_row),
    centro_col = mean(global_col),
    .groups = "drop"
  )

######################################################################################################################
##### Exportación para uso permanente
######################################################################################################################

# Renombramos para que sea más fácil de llamar en el paquete
grilla_municipios <- df_final
etiquetas_deptos <- df_depto_labels

saveRDS_safe <- function(object, file) {
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  saveRDS(object, file = file)
  message("Archivo guardado en: ", file)
}

# Esto guarda los datos comprimidos en la carpeta /data del paquete
usethis::use_data(grilla_municipios, etiquetas_deptos, overwrite = TRUE)


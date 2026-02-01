**ColombiaGrid** es un paquete de R diseñado para crear **Tile Grid Maps** (mapas de cuadrículas) de los municipios de Colombia.

A diferencia de los mapas coropléticos tradicionales (geográficos), este tipo de visualización:
1. Evita que los municipios grandes (como los de la Amazonía) dominen visualmente.
2. Permite ver municipios pequeños (como los de Cundinamarca o el Eje Cafetero) con la misma importancia.
3. Es ideal para comparar indicadores de gestión, tasas o categorías.

## Instalación

Puedes instalar la versión de desarrollo desde GitHub usando el paquete `remotes`:

```r
install.packages("remotes")
remotes::install_github("diegodduartebb/ColombiaGrid") ```

## Uso

La función principal es:
```r
colombia_grid()

Para ver la documentación respectiva de la función por favor visualizar:
```r
help("colombia_grid")

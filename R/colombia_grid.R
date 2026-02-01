#' Graficar Grid Map de Colombia (Versión Final Corregida)
#'
#' Genera un mapa de cuadrículas (Tile Grid Map) altamente personalizable.
#' Soporta escalas continuas y discretas, ajuste de tipografías y control total de etiquetas.
#'
#' @param data Dataframe con los datos.
#' @param id_col Columna con el código del municipio.
#' @param value_col Columna con la variable a graficar.
#' @param legend_title Texto para el título de la leyenda (opcional). Si se deja NULL, usa el nombre de value_col.
#' @param scale_type Tipo de escala: "continuous" (gradiente) o "discrete" (categorías).
#' @param colors Vector de colores.
#'   Si scale_type es "continuous", usa c(color_bajo, color_alto).
#'   Si scale_type es "discrete", usa un vector con los colores para cada categoría (o una paleta) c("Bajo"="#8DD3C7", "Medio"="#FFFFB3").
#' @param title Título del gráfico (opcional, NULL para quitar).
#' @param subtitle Subtítulo (opcional).
#' @param caption Fuente o nota al pie (opcional).
#' @param show_labels Lógico. ¿Mostrar etiquetas de departamentos?
#' @param label_size Tamaño de la letra de las etiquetas. Por defecto 1.7.
#' @param label_alpha Transparencia del fondo de las etiquetas (0 a 1).
#' @param label_color Color de la letra de las etiquetas.
#' @param text_family Familia tipográfica para todo el gráfico (ej: "sans", "serif", "Arial").
#' @param border_color Color de la línea de la cuadrícula.
#' @param border_size Grosor de la línea de la cuadrícula (linewidth). Por defecto 0.1.
#' @param na_color Color para datos faltantes (NA).
#'
#' @return Un objeto ggplot.
#' @export
#' @import ggplot2
#' @importFrom dplyr left_join
#' @importFrom rlang .data
colombia_grid <- function(data = NULL,
                          id_col = "muncol",
                          value_col = NULL,
                          legend_title = NULL,
                          scale_type = "continuous",
                          colors = c("#E0F7FA", "#006064"),
                          title = "Mapa de Municipios",
                          subtitle = NULL,
                          caption = NULL,
                          show_labels = TRUE,
                          label_size = 1.7,
                          label_alpha = 0.6,
                          label_color = "black",
                          text_family = "sans",
                          border_color = "white",
                          border_size = 0.1,  # Nuevo parámetro recuperado
                          na_color = "gray95") {

  # 1. Cargar data interna
  df_plot <- ColombiaGrid::grilla_municipios

  # 2. Unión de datos
  if (!is.null(data)) {
    if (is.null(value_col)) stop("Error: Debes especificar 'value_col'.")

    df_plot$muncol_join <- as.numeric(df_plot$muncol)
    data[[id_col]]      <- as.numeric(data[[id_col]])

    df_plot <- dplyr::left_join(df_plot, data, by = c("muncol_join" = id_col))
    df_plot$fill_var <- df_plot[[value_col]]
  } else {
    df_plot$fill_var <- NA
    value_col <- "Sin Data"
  }

  # 3. Base del gráfico
  # CORRECCIÓN AQUÍ: Usamos linewidth en lugar de size para el borde
  p <- ggplot2::ggplot(df_plot, ggplot2::aes(x = .data$global_col,
                                             y = -.data$global_row,
                                             fill = .data$fill_var)) +
    ggplot2::geom_tile(color = border_color, linewidth = border_size) +
    ggplot2::coord_fixed() +
    ggplot2::theme_void(base_family = text_family) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title = if(!is.null(title)) ggplot2::element_text(face = "bold", size = 16, hjust = 0.5) else ggplot2::element_blank(),
      plot.subtitle = ggplot2::element_text(size = 12, hjust = 0.5, color = "gray40"),
      plot.caption = ggplot2::element_text(size = 8, color = "gray60", margin = ggplot2::margin(t = 10))
    )

  # 4. Manejo de Títulos
  titulo_leyenda <- if (!is.null(legend_title)) legend_title else value_col

  labs_list <- list(fill = titulo_leyenda)
  if (!is.null(title)) labs_list$title <- title
  if (!is.null(subtitle)) labs_list$subtitle <- subtitle
  if (!is.null(caption)) labs_list$caption <- caption

  p <- p + do.call(ggplot2::labs, labs_list)

  # 5. Escalas y Colores
  if (scale_type == "continuous") {
    if(length(colors) < 2) colors <- c("#E0F7FA", "#006064")
    p <- p +
      ggplot2::scale_fill_gradient(low = colors[1], high = colors[2], na.value = na_color) +
      ggplot2::guides(fill = ggplot2::guide_colorbar(
        barwidth = 15,
        barheight = 0.5,
        title.position = "top",
        title.hjust = 0.5
      ))

  } else if (scale_type == "discrete") {
    p <- p +
      ggplot2::scale_fill_manual(values = colors, na.value = na_color) +
      ggplot2::guides(fill = ggplot2::guide_legend(
        title.position = "top",
        title.hjust = 0.5,
        nrow = 1
      ))
  }

  # 6. Etiquetas
  if (show_labels) {
    p <- p +
      ggplot2::geom_label(
        data = ColombiaGrid::etiquetas_deptos,
        inherit.aes = FALSE,
        ggplot2::aes(x = .data$centro_col,
                     y = -.data$centro_row,
                     label = .data$DPTO_CNMBR),
        color = label_color,
        fill = "white",
        size = label_size,
        label.size = 0,
        alpha = label_alpha,
        family = text_family,
        fontface = "bold"
      )
  }

  return(p)
}

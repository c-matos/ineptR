#' Get unique values for all dimensions of the indicator
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#'
#' @details
#' If the indicator is not valid, returns a 1x1 tibble with a column named 'value'
#' stating "(PT) O codigo do indicador nao existe. / (EN) The indicator code does not exist."
#' \cr Calling `is_indicator_valid()` before using this function is recommended.
#'
#' @param indicator INE indicator ID as a 7 character string. Example: "0010003".
#' @param lang One of "PT" or "EN". Default is "PT".
#' @return A data frame with dim_num (dimension number), cat_id (dimension description),
#'         categ_cod, categ_dsg (Category description), categ_ord (order in which the category appears in the website),
#'         categ_nivel (hierarchical order) and value_id (id row for this data frame) for the selected indicator.
#' @importFrom magrittr %>%
#' @importFrom rlang .data
#' @export
#'
#' @examples
#' get_dim_values("0010003")
get_dim_values <- function(indicator, lang = "PT") {
  if (is_indicator_valid(indicator)) {
    get_metadata_raw(indicator = indicator, lang = lang) %>%
      magrittr::extract2("Dimensoes") %>%
      magrittr::extract2("Categoria_Dim") %>%
      tibble::as_tibble_col() %>%
      tidyr::unnest_longer(col = .data$value) %>%
      tidyr::unnest(.data$value) %>%
      tidyr::unnest_wider(.data$value) #using .data due to a note appearing in devtools::check()
  } else {
    get_metadata_raw(indicator = indicator, lang = lang) %>%
      magrittr::extract2("Sucesso") %>%  #NB: probably will not work will lang = "EN"
      magrittr::use_series("Falso") %>%
      magrittr::extract2(1) %>%
      magrittr::use_series("Msg") %>%
      tibble::as_tibble()
  }
}

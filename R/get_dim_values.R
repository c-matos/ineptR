#' Get the set of possible values for all dimensions of the indicator
#'
#' @description
#' `r lifecycle::badge('experimental')` \cr
#' Get the set of possible values for all dimensions of the indicator
#'
#'
#' @details
#' If the indicator is not valid, returns "(PT) O codigo do indicador nao existe. / (EN) The indicator code does not exist." \cr
#' Calling `is_indicator_valid()` before using this function is recommended.
#'
#' @param indicator INE indicator ID as a 7 character string. Example: "0010003".
#' @param lang One of "PT" or "EN". Default is "PT".
#' @return A tidy data frame with dim_num (dimension number), cat_id (dimension description),
#'         categ_cod, categ_dsg (Category description), categ_ord (order in which the category appears in the website),
#'         categ_nivel (hierarchical order) and value_id (id row for this data frame) for the selected indicator.
#' @importFrom magrittr %>%
#' @export
#'
#' @examples
#' get_dim_values("0011823")
get_dim_values <- function(indicator, lang = "PT") {
  value <- NULL
  valid_ind <- is_indicator_valid(indicator)

  if (is.null(valid_ind)) {
    return(invisible(NULL))
  }

  if (valid_ind) {

    metadata <- get_metadata_raw(indicator = indicator, lang = lang)

    if (is.null(metadata)) {
      return(invisible(NULL))
    }

    metadata %>%
      magrittr::extract2("Dimensoes") %>%
      magrittr::extract2("Categoria_Dim") %>%
      tibble::as_tibble_col() %>%
      tidyr::unnest_longer(col = value) %>%
      tidyr::unnest(value) %>%
      tidyr::unnest_wider(value)
  } else {
    message("(PT) O c\u00F3digo do indicador n\u00E3o existe. / (EN) The indicator code does not exist.")
    return(invisible(NULL))
  }
}

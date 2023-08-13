#' Get information about the dimensions of a given indicator
#'
#' @description
#' `r lifecycle::badge('experimental')` \cr
#' Get information about the dimensions of a given indicator
#'
#'
#' @details
#' If the indicator is not valid, returns "(PT) O codigo do indicador nao existe. / (EN) The indicator code does not exist." \cr
#' Calling `is_indicator_valid()` before using this function is recommended.
#'
#' @param indicator INE indicator ID as a 7 character string. Example: "0010003".
#' @param lang One of "PT" or "EN". Default is "PT".
#' @return A data frame with dim_num (dimension number), abrv (dimension description) and versao (dimension version) for the selected indicator.
#'         A fourth column 'nota_dsg' is present for some indicators, with additional notes about the dimensions.
#' @importFrom magrittr %>%
#' @importFrom rlang .data
#' @export
#'
#' @examples
#' get_dim_info("0011823", lang = "EN")

get_dim_info <- function(indicator, lang="PT") {
  if (is_indicator_valid(indicator)) {

    metadata <- get_metadata_raw(indicator = indicator, lang = lang)

    if (is.null(metadata)) {
      return(invisible(NULL))
    }

    metadata %>%
      magrittr::extract2("Dimensoes") %>%
      magrittr::extract2("Descricao_Dim") %>%
      tibble::as_tibble_col() %>%
      tidyr::unnest_wider(col = .data$value)
  } else {
    return("(PT) O c\u00F3digo do indicador n\u00E3o existe. / (EN) The indicator code does not exist.")
    # metadata <- get_metadata_raw(indicator = indicator, lang = lang)
    #
    # if (is.null(metadata)) {
    #   return(invisible(NULL))
    # }
    #
    # metadata %>%
    #   magrittr::extract2("Sucesso") %>%
    #   magrittr::use_series("Falso") %>%
    #   magrittr::extract2(1) %>%
    #   magrittr::use_series("Msg")
  }
}

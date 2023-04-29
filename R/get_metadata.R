#' Get indicator metadata
#'
#' @description
#' `r lifecycle::badge('experimental')`
#' `get_metadata()` calls the metadata API.
#'
#' Be aware that this function will still return a value and not throw an error if the indicator does not exist.
#'
#' @param indicator INE indicator ID as a 7 character string. Example: "0010003".
#' @param lang Only "PT" implemented.
#'
#' @return API response body as list.
#'
#' @seealso [ineptR::is_indicator_valid()] can be used to check if the indicator is valid before calling this function.
#'
#' @export
#' @examples
#' get_metadata("0010003")
get_metadata <- function(indicator, lang = "PT") {
  temp_metadata <- get_metadata_raw(indicator = indicator, lang = lang)
  temp_metadata["Dimensoes"] <- NULL
  temp_metadata["Sucesso"] <- NULL
  return(temp_metadata)
}

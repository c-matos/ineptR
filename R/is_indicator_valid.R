#' Check if indicator exists
#'
#' @description
#' `r lifecycle::badge('experimental')` \cr
#' Check if the indicator exists and is callable via the INE API. \cr
#' Indicator ID can be found in the url under the 'indOcorrCod' query parameter when browsing the website. \cr
#' Example: https://www.ine.pt/xportal/xmain?xpid=INE&xpgid=ine_indicadores&indOcorrCod=0010003&contexto=bd&selTab=tab2
#'
#' @param indicator INE indicator ID as a 7 character string. Example: "0010003".
#' @param lang One of "PT" or "EN". Default is "PT".
#'
#' @return TRUE if indicator exists, otherwise FALSE.
#' @export
#'
#' @examples
#' is_indicator_valid("0011823")
is_indicator_valid <- function(indicator, lang="PT") {
  metadata <- get_metadata_raw(indicator = indicator, lang = lang)
  return(!is.null(metadata$Sucesso$Verdadeiro))
}


#' Get data from the INE API
#'
#' @description
#' `r lifecycle::badge('experimental')` \cr
#' Return tidy data frames from Instituto Nacional de Estatística API
#'
#' @details
#' Extraction time can be very high (many hours) for indicators with many dimensions and/or many unique values. E.g. Indicator "0008206 - Deaths by Place of residence, Sex, Age group and Death cause, Annual" will take many hours to extract.
#'
#'
#' @param indicator INE indicator ID as a 7 character string. Example: "0010003".
#' @param lang One of "PT" or "EN". Default is "PT".
#' @param expected.duration If TRUE, prints the expected remaining duration in the console.
#' @param max_cells Integer smaller than or equal to 40000, the maximum number of cells allowed in each API call.
#'                  Default value of 30000
#' @param ... Values for each Dimension of the indicator.
#'            Each parameter should be in the form dimN, with N one of \{1, ..., Nº of dimensions\}.
#'            If one of the dimensions is not included, output includes all values for that dimension.
#'
#' @return tidy data frame for the given indicator.
#'
#' @importFrom magrittr %T>%
#' @importFrom utils txtProgressBar
#' @importFrom utils setTxtProgressBar
#'
#' @seealso [ineptR::get_dim_values()] can be used to identify the values to be passed to *dimN* parameters, in the variable categ_cod.
#'  See \href{https://c-matos.github.io/ineptR/articles/use_cases.html}{this vignette} for further clarification on how to obtain only a subset of the data.
#'
#' @export
#'
#' @examples
#' #A simple example. Returns the complete dataset.
#' get_ine_data("0011823")
#' # A more complex example. Returns a subset of the dataset.
#' \donttest{
#' get_ine_data("0008206", dim1 = "S7A1996", dim2 = c("11","111"),
#'              dim4 = c(1,19), dim5 = "TLES")
#' }
get_ine_data <- function(indicator, lang="PT", expected.duration=FALSE, max_cells = 30000, ...) {
  . <- dim_1 <- NULL
  #get the urls
  myurls <- get_api_urls(indicator, max_cells, ...)

  if (is.null(myurls)) {
    return(invisible(NULL))
  }

  #TODO:
  ## Print the number of records extracted in each call

  #start counters to estimate extraction duration
  if (expected.duration) {
    progressr::handlers(global = T)
    progressr::handlers("cli")
    p <- progressr::progressor(along = myurls)
  }

  #!!!!!!!
  ret_data <- myurls %>%
    tibble::as_tibble() %>%
    dplyr::mutate(id = dplyr::row_number()) %>%
    purrr::pmap_dfr(function(...) {
      current <- tibble::tibble(...) # do stuff and access content from current row with "current"

        if (expected.duration) {
          p(sprintf("Extracting %g", current$id))
        }

      e <- new.env()
      req <- current$value %>%
        purrr::map(~httr2::request(base_url = .x) %>%
                     httr2::req_user_agent("ineptR (https://c-matos.github.io/ineptR/)") %>%
                     httr2::req_error(is_error = ~FALSE))

      resp <- req %>% purrr::map(gracefully_fail)

      if (is.null(resp)) {
        return(invisible(NULL))
      }

      resp[[1]] %>%
        httr2::resp_body_json() %>%
        magrittr::extract2(1) %>%
        magrittr::use_series("Dados") %T>%
        {assign("temp_dim1", names(.), envir = e)} %>%
        magrittr::extract2(1) %>%
        purrr::map_dfr(data.frame) %>%
        dplyr::mutate(dim_1 = e$temp_dim1)
    }) %>%
    dplyr::relocate(dim_1, .before=1)

  if (expected.duration) {
    progressr::handlers(global = F)
  }
  return(ret_data)
}

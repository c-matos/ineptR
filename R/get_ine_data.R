
#' Get data from the INE API
#'
#' @description
#' `r lifecycle::badge('experimental')` \cr
#' This is the function that actually performs the API call.
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
#'            Each parameter should be in the form DimN, with N one of \{1, ..., Nº of dimensions\}.
#'            If one of the dimensions is not included, output includes all values by default.
#'
#' @return Dataset for the given indicator.
#' @export
#'
#' @examples
#'
#' get_ine_data("0010003") # A simple example
#' get_ine_data("0008206", dim1 = "S7A1996", dim2 = c("11","111"),
#'              dim4 = c(1,19), dim5 = "TLES") # A more complex example
#'
get_ine_data <- function(indicator, lang="PT", expected.duration=FALSE, max_cells = 30000, ...) {
  dim_1 <- NULL
  #get the urls
  myurls <- get_api_urls(indicator, max_cells, ...)

  #TODO:
  ## Print the number of records extracted in each call

  #start counters to estimate extraction duration
  if (expected.duration) {
    start_time <- proc.time()
    sstart_time <- proc.time()
  }

  #!!!!!!!
  ret_data <- myurls %>%
    tibble::as_tibble() %>%
    dplyr::mutate(id = dplyr::row_number()) %>%
    purrr::pmap_dfr(function(...) {
      current <- tibble::tibble(...)

      if (expected.duration) {
        # do stuff and access content from current row with "current"
        print(sprintf("Extracting part %s of %s", current$id, length(myurls)))

        #last_execution_duration <- as.double(proc.time() - start_time)[[3]] # single execution duration

        if (current$id!=1) {
          average_execution_duration <- as.double(((proc.time() - sstart_time)[[3]])/current$id)
        }
        else {
          average_execution_duration <- Inf
          }

        #expected remaining duration
        expected_remaining_duration <- (length(myurls) - current$id) * average_execution_duration
        print(sprintf("Expected remaining duration: %.1f seconds", expected_remaining_duration))
        start_time <<- proc.time() # reset execution counter
      }
      e <- new.env()
      # return
      current$value %>%
        purrr::map_df(~
                 jsonlite::fromJSON(txt = .x, simplifyVector = F) %>%
                 magrittr::extract2(1) %>%
                 magrittr::use_series("Dados") %T>%
                 {assign("temp_dim1", names(.), envir = e)} %>%
                 magrittr::extract2(1) %>%
                 purrr::map_dfr(data.frame) %>%
                 dplyr::mutate(dim_1 = e$temp_dim1))
    }) %>%
    dplyr::relocate(dim_1, .before=1)

  #rm(temp_dim1_01348531)
  #rm(e)
  #total duration
  if (expected.duration) {
    print(sprintf("Total duration: %.1f seconds", as.double(proc.time() - sstart_time)[[3]]))
  }
  return(ret_data)
}

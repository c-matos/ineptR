#' Get raw indicator metadata
#'
#' @description
#' `r lifecycle::badge('experimental')`
#' `get_metadata_raw()` calls the metadata API.
#'
#' Be aware that this function will still return a value and not throw an error if the indicator does not exist.
#'
#' @param indicator INE indicator ID as a 7 character string. Example: "0010003".
#' @param lang Only "PT" implemented.
#'
#' @keywords internal
#' @return API response body as list. Returns NULL with an informative message if no internet connection, timeout or HTTP error.
#'
#' @seealso [ineptR::is_indicator_valid()] can be used to check if the indicator is valid before calling this function.
get_metadata_raw <- function(indicator, lang = "PT") {

  #Move the parameters to a list to splice later
  params <- list(
    varcd = indicator,
    lang = lang
  )
  baseurl <- "https://www.ine.pt/ine/json_indicador/pindicaMeta.jsp"

  #metadata_path <- sprintf("https://www.ine.pt/ine/json_indicador/pindicaMeta.jsp?varcd=%s&lang=%s", indicator, lang)
  #httr2::request(metadata_path) %>% httr2::req_perform() %>% httr2::resp_body_json() %>% magrittr::extract2(1)
  #jsonlite::fromJSON(txt = metadata_path, simplifyVector = F)[[1]] #Fails on macos-latest in R CMD check

  req <- httr2::request(base_url = baseurl) %>%
    httr2::req_url_query(!!!params) %>%
    httr2::req_user_agent("ineptR (https://c-matos.github.io/ineptR/)") %>%
    httr2::req_error(is_error = ~FALSE)  #Return message instead of error

  #Validates no internet connection, timeout errors and HTTP errors
  resp <- gracefully_fail(req)

  if (is.null(resp)) {
    return(invisible(NULL))
  }

  #Select only the desired part of the output
  metadata_raw <- resp %>%
    httr2::resp_body_json() %>%
    magrittr::extract2(1) # {\(x) x[[1]]}() --> equivalent, but compatible with base pipe

  #Return the resp to avoid duplicate calls. This is an internal function
  return(metadata_raw) #list(resp = resp, meta = metadata_raw)
}


#Calculate the number of dimensions in the indicator
#Will be used for validation purposes
calc_num_dims <- function(indicator, lang="PT") {
  metadata <- get_metadata_raw(indicator = indicator, lang = lang)

  if (is.null(metadata)) {
    return(invisible(NULL))
  }

  metadata %>%
    magrittr::use_series("Dimensoes") %>%
    magrittr::extract2(1) %>%
    length()
}

#Calculate the number of unique values in each dimension
calc_dims_length <- function(indicator, lang="PT") {
  dim_num <- NULL

  dim_values <- get_dim_values(indicator)

  if (is.null(dim_values)) {
    return(invisible(NULL))
  }

  dim_values %>%
    dplyr::group_by(dim_num) %>%
    dplyr::tally()
}


#Logic to deal with the limit of 40k cells per API call
get_api_urls <- function(indicator, max_cells=30000, lang="PT", ...) {
  dim_num <- cat_id <- n <- dim_1 <- NULL

  #unpack the ellipsis
  opt <- list(...)
  opt_names <- stringr::str_to_sentence(names(list(...))) #convert parameter names to sentence case
  names(opt) <- opt_names
  opt <- append(opt, values = c(op=2, varcd=indicator, lang=lang))

  #get number of dimensions
  num_dims <- calc_num_dims(indicator) #get number of dimensions

  if (is.null(num_dims)) {
    return(invisible(NULL))
  }

  #Get number of unique values in each dimension
  dims_len <- calc_dims_length(indicator)

  if (is.null(dims_len)) {
    return(invisible(NULL))
  }

  dim_values <- get_dim_values(indicator)

  if (is.null(dim_values)) {
    return(invisible(NULL))
  }


  # ------------------#
  # --- VALIDATION ---#
  # ------------------#

  # Check if parameters are named dimX, with max X being <= num_dims
  if (length(opt) - 3 > num_dims) {
    stop(sprintf("You are trying to extract more dimensions than are available for indicator: %s (%s passed, %s allowed)", indicator, length(opt)-3, num_dims))
  }

  #Check if any parameter is not in the form "dimN" (case insensitive)
  any_wrong_pattern <- !as.logical(prod(stringr::str_detect(opt_names, stringr::regex("^dim\\d$", ignore_case = T))))
  wrong_dimension_names <- opt_names[which(!stringr::str_detect(opt_names, stringr::regex("^dim\\d$", ignore_case = T)))]

  if (any_wrong_pattern) {
    stop(sprintf("All parameters should be in the form 'dimN'. Error at: %s", wrong_dimension_names))
  }

  #Check if user included dim1. If not, loop over all possible dim1 values
  if (!"Dim1" %in% opt_names) {
    my_dim1 <- dim_values %>%
      dplyr::filter(dim_num == 1) %>%
      dplyr::select(cat_id) %>%
      as.list() %>%
      magrittr::set_names("Dim1")
    opt <- append(x = opt, values = my_dim1)
  }

  #TODO
  ## Check if user input results in an extraction < max_rows

  #Get dimensions passed by the user
  user_dims <- opt_names %>%
    purrr::map_chr(~as.character(readr::parse_number(.))) %>%
    as.integer()

  #value to check if user input is already below max_rows
  rows_with_user_input <- dims_len %>%
    dplyr::filter(!dim_num %in% c(1, user_dims)) %>%
    dplyr::summarise(p = prod(n)) %>%
    as.integer()

  if (rows_with_user_input > max_cells) {
    #Calculate extra dimensions that need to be looped over, to ensure <= max_rows are extracted in each API call

    #Remaining dims, excluding dim1 an user specified dims
    remaining_dims <- dims_len %>%
      dplyr::filter(!dims_len$dim_num %in% c(1, user_dims))

    temp_out <- c()
    for (i in as.integer(remaining_dims$dim_num)) {
      mystat <- remaining_dims %>%
        dplyr::filter(!dim_num==i) %>%
        dplyr::summarise(p = prod(n)) %>%
        as.integer()

      temp_out <- c(temp_out, stats::setNames(mystat, i))
    }

    temp_out <- temp_out[temp_out<=max_cells]
    extra_dims_to_loop_over <- c(names(which.max(temp_out)))
    #Now get all the values of the desired dim, and add them to opt
    for (d in extra_dims_to_loop_over) {
      opt <- append(x = opt,
                    values = dim_values %>%
                      dplyr::filter(dim_num == d) %>%
                      dplyr::select(cat_id) %>%
                      as.list() %>%
                      magrittr::set_names(paste0("Dim",d)))
    }
  }

  #Base case, assuming everything is passed correctly
  #Generate urls with the parameters passed by the user, that are stored in opt

  #base ine api url (move to a previous location)
  baseurl <- "https://www.ine.pt/ine/json_indicador/pindica.jsp"

  #create the necessary urls for extraction
  urls <- tidyr::crossing(!!!opt) %>% #!!! is used to evaluate a list of expressions; !! would work for a vector
    purrr::pmap(list) %>%
    purrr::map_chr(~ httr::modify_url(baseurl, query=.x) )

  return(urls)
}


gracefully_fail <- function(request, path = NULL) {
  #Fails gracefully to comply with CRAN policy
  #path is used to save directly to disk. Not being used
  try_GET <- function(request) {
    tryCatch(
      resp <- request %>%
        httr2::req_perform(path = path),
      error = function(e) conditionMessage(e),
      warning = function(w) conditionMessage(w)
    )
  }
  is_response <- function(x) {
    class(x) == "httr2_response"
  }

  # First check internet connection
  if (!curl::has_internet()) {
    message("No internet connection.")
    return(invisible(NULL))
  }
  # Then try for timeout problems
  resp <- try_GET(request)
  if (!is_response(resp)) {
    message(resp)
    return(invisible(NULL))
  }
  # Then stop if status > 400
  if (httr2::resp_status(resp)>=400) {
    message(paste(httr2::resp_status(resp), httr2::resp_status_desc(resp), sep = " - "))
    return(invisible(NULL))
  }
  resp
}

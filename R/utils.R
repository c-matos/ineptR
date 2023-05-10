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
#' @return API response body as list.
#'
#' @seealso [ineptR::is_indicator_valid()] can be used to check if the indicator is valid before calling this function.
get_metadata_raw <- function(indicator, lang = "PT") {
  metadata_path <- sprintf("https://www.ine.pt/ine/json_indicador/pindicaMeta.jsp?varcd=%s&lang=%s", indicator, lang)

  jsonlite::fromJSON(txt = metadata_path, simplifyVector = F)[[1]]
}

#Calculate the number of dimensions in the indicator
#Will be used for validation purposes
calc_num_dims <- function(indicator, lang="PT") {
  get_metadata_raw(indicator = indicator, lang = lang) %>%
    magrittr::use_series("Dimensoes") %>%
    magrittr::extract2(1) %>%
    length()
}

#Calculate the number of unique values in each dimension
calc_dims_length <- function(indicator, lang="PT") {
  get_dim_values(indicator) %>%
    dplyr::group_by(dim_num) %>%
    dplyr::tally()
}


#Might be an internal function, that checks the values the user wants and chooses the best option to loop over them
##Some notes: "dim" url parameter is NOT case sensitive. "dim" order in the url DOES NOT matter
## NB: When dim1 is not passed it assumes the most recent one!!!
get_api_urls <- function(indicator, max_cells=30000, lang="PT", ...) {

  #unpack the ellipsis into a list
  opt <- list(...)
  opt_names <- stringr::str_to_sentence(names(list(...))) #convert parameter names to sentence case
  names(opt) <- opt_names
  opt <- append(opt, values = c(op=2, varcd=indicator, lang=lang))

  #TODO: Convert the dim names to sentence case above, as a precaution. (Is it done? To confirm)

  #get number of dimensions
  num_dims <- calc_num_dims(indicator) #get number of dimensions

  #Get number of unique values in each dimension
  dims_len <- calc_dims_length(indicator)


  # ------------------#
  # --- VALIDATION ---#
  # ------------------#

  # Check if parameters are named dimX, with max X being <= num_dims
  if (length(opt) - 3 > num_dims) {
    stop(sprintf("You are trying to extract more dimensions than are available for indicator: %s (%s passed, %s allowed)", indicator, length(opt)-2, num_dims))
  }

  #Check if any parameter is not in the form "dimN" (case insensitive)
  any_wrong_pattern <- !as.logical(prod(stringr::str_detect(opt_names, stringr::regex("^dim\\d$", ignore_case = T))))
  wrong_dimension_names <- opt_names[which(!stringr::str_detect(opt_names, stringr::regex("^dim\\d$", ignore_case = T)))]

  if (any_wrong_pattern) {
    stop(sprintf("All parameters should be in the form 'dimN'. Error at: %s", wrong_dimension_names))
  }

  #Check if user included dim1. If not, loop over all possible dim1 values
  if (!"Dim1" %in% opt_names) {
    my_dim1 <- get_dim_values(indicator) %>%
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

    #Number of remaining dims.
    #Not bein used. to delete later
    #num_remaining_dims <- nrow(remaining_dims)

    temp_out <- c()
    for (i in as.integer(remaining_dims$dim_num)) {
      mystat <- remaining_dims %>%
        dplyr::filter(!dim_num==i) %>%
        dplyr::summarise(p = prod(n)) %>%
        as.integer()

      temp_out <- c(temp_out, stats::setNames(mystat, i))

      # #store the value in a named vector, with dimname=mystat
      # # ?????
      # if (mystat<=max_cells) {
      #
      # }
    }

    temp_out <- temp_out[temp_out<=max_cells] #Do a check here. If length == 0, then must check for removing 2 dims simultaneously, etc...Maybe not needed, since checked max_cells above.
    # temp_out <- temp_out[temp_out==max(temp_out)]
    # dim_to_loop_over <- names(temp_out) # get the dim to loop over
    extra_dims_to_loop_over <- c(names(which.max(temp_out))) # results of the calculation. Assumes dim1 was dealt with earlier and user_dims are already in opt

    #Now get all the values of the desired dim, and add them to opt
    for (d in extra_dims_to_loop_over) {
      opt <- append(x = opt,
                    values = get_dim_values(indicator) %>%
                      dplyr::filter(dim_num == d) %>%
                      dplyr::select(cat_id) %>%
                      as.list() %>%
                      magrittr::set_names(paste0("Dim",d)))
    }
    #}
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

  #TODO:
  ## What if indicator has 2 dims and user only specifies one?
  ### Maybe i can assume that if only two dims, always less than 40k cells??
  #TODO: TEST THIS ASSUMPTION FOR THE ENTIRE INE CATALOG

}
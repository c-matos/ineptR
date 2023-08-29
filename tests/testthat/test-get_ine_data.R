test_that("Problems return NULL, with a message", {
  suppressMessages({
    expect_message(get_ine_data("invalid_id"),"The indicator code does not exist")
    expect_null(get_ine_data("invalid_id"))
  })
})

test_that("Indicator exists and call succeded", {
  expect_type(get_ine_data("0008206", dim1 = "S7A1996", dim2 = c("11","111"), dim4 = c(1,19), dim5 = "TLES"),"list")
  expect_s3_class(get_ine_data("0011823"),"data.frame")
  expect_named(get_ine_data("0011823"))
  expect_true(all(c('dim_1','geocod','geodsg','valor') %in% names(get_ine_data("0011823")))) #at least these columns must exist
})

test_that("HTTP errors arre downgraded to messages", {
  suppressMessages({
    mock_404 <- function(req) {httr2::response(status_code = 404)}
    mock_503 <- function(req) {httr2::response(status_code = 503)}
    expect_message(httr2::with_mock(mock_404,get_ine_data("0011823")),"404")
    expect_message(httr2::with_mock(mock_503,get_ine_data("0011823")),"503")
  })
})

# test_that("Duration log succeeds", {
#   skip_on_cran()
#   expect_output(get_ine_data("0011823", expected.duration = T),"Output: 1 of")
# })

test_that("User input is correct", {
  expect_error(get_ine_data("0010003", Blah = c("1234"))) #Wrong dimension name
  expect_error(get_ine_data("0010003", dim1 = c("S7A2011"), dim2 = "PT", dim3 = "TLES")) #Impossible number of dimensions
})

test_that("Calculations work for request over the API 40k limit", {
  skip_on_cran()
  expect_gt(nrow(get_ine_data("0008206", dim1 = c("S7A1996"), dim3 = "T", dim5 = "TLES", max_cells = 2000)),5000) #over 40k values returned
  expect_gt(nrow(get_ine_data("0008206", dim1 = c("S7A2020"), dim2 = "PT", dim4 = "T", max_cells = 100)),150) #over 40k values returned
  expect_gt(nrow(get_ine_data("0001001", max_cells = 15)),30) #over 40k values returned
})

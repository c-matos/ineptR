test_that("Problems return NULL, with a message", {
  suppressMessages({
    expect_message(get_dim_values("invalid_id"),"The indicator code does not exist")
    expect_null(get_dim_values("invalid_id"))
  })
})

test_that("Indicator exists and call succeded", {
  expect_type(get_dim_values("0011823"),"list")
  expect_s3_class(get_dim_values("0011823"),"data.frame")
  #expect_named(get_dim_values("0011823"))
  expect_true(all(c('dim_num','cat_id','categ_cod','categ_dsg','categ_ord','categ_nivel','value_id') %in% names(get_dim_values("0011823")))) #at least these columns must exist
})

test_that("HTTP errors arre downgraded to messages", {
  suppressMessages({
    mock_404 <- function(req) {httr2::response(status_code = 404)}
    mock_503 <- function(req) {httr2::response(status_code = 503)}
    expect_message(httr2::with_mock(mock_404,get_dim_values("0011823")),"404")
    expect_message(httr2::with_mock(mock_503,get_dim_values("0011823")),"503")
  })
})

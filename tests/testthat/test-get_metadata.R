test_that("Problems return NULL, with a message", {
  suppressMessages({
    #expect_message(get_metadata("invalid_id"))
    expect_message(get_metadata("invalid_id"),"The indicator code does not exist")
    expect_null(get_metadata("invalid_id"))
  })
})

test_that("Indicator exists and call succeded", {
  expect_type(get_metadata("0010003"),"list")
  #expect_named(get_metadata("0010003"))
  expect_named(get_metadata("0010003"),c('IndicadorCod', 'IndicadorNome', 'Periodic', 'PrimeiroPeriodo', 'UltimoPeriodo', 'UnidadeMedida', 'Potencia10', 'PrecisaoDecimal', 'Lingua', 'DataUltimaAtualizacao', 'DataExtracao'))
})

test_that("HTTP errors arre downgraded to messages", {
  suppressMessages({
    mock_404 <- function(req) {httr2::response(status_code = 404)}
    mock_503 <- function(req) {httr2::response(status_code = 503)}
    expect_message(httr2::with_mock(mock_404,get_metadata("0010003")),"404")
    expect_message(httr2::with_mock(mock_503,get_metadata("0010003")),"503")
  })
})



#Test that:
#FAILS
## no internet returns null with a message
## response>400 returns null with a message
## invalid indicator returns null with a message

#SUCCESS
## returns a list
## check the specific names

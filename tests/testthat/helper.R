
clean_dump <- function() {
  if (exists("last.dump", envir = globalenv())) {
    rm(list = "last.dump", envir = globalenv())
  }
}


get_dump <- function(expr) {
  clean_dump()
  expect_error(
    withCallingHandlers(
      expr,
      error = function(e) { dump_pipes(); FALSE }
    )
  )
  res <- get("last.dump", envir = globalenv())
  clean_dump()
  res
}


`%>%` <- magrittr::`%>%`

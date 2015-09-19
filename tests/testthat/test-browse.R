
context("Detecting whether we can browse at the error")

test_that("primitive functions are detected", {

  f <- function(x, y) if (1) x + y
  dump <- get_dump( 1 %>% f("foo") )
  expect_true(attr(dump, "can_browse"))

  g <- `+`
  dump <- get_dump( 1 %>% g("foo") )
  expect_false(attr(dump, "can_browse"))
})

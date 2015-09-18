
context("Detecting if we are in a pipe")

test_that("we can detect if we are not in a pipe", {

  f <- function(x, y) if (1) x + y

  dump <- get_dump( f(1, "foo") )

  expect_equal(class(dump), "dump.frames")
})

test_that("we can detect if we are in a pipe", {

  f <- function(x, y) if (1) x + y

  dump <- get_dump( 1 %>% f("foo") )

  expect_equal(class(dump), c("dump_pipes", "dump.frames"))
})

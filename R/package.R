
#' Easier Debugging of 'magrittr' Pipes
#'
#' One difficulty of 'magrittr' pipes is that they make debugging harder. If you don't always write correct code, and you use pipes, then you'll find tamper very useful. It is the 'magrittr' specific alternative of the 'recover' function: when used with 'options(error=tamper)', after an error, it displays the whole pipeline, marks the place of the error, and helps saving the temporary results.
#'
#' @docType package
#' @name tamper
NULL

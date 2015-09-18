
#' Investigate a pipe, after an error
#'
#' `tamper` is a function that can be used as an error callback,
#' similarly to `utils::recover`. Tamper is pipe-friendly: it will
#' show you the exact place of the error in the pipe.
#'
#' @section Example:
#'
#' After running the following code:
#' ```r
#' options(error = tamper)
#'
#' f <- function(data) {
#'    data \%>\%
#'      (function(x) force(x)) \%>\%
#'      multiply_by(10) \%>\%
#'      add(10) \%>\%
#'      add("oh no!") \%>\%
#'      subtract(5) \%>\%
#'      divide_by(5)
#' }
#'
#'  1:10 \%>\%
#'    multiply_by(2) \%>\%
#'    f() \%>\%
#'    add(1:10)
#' ```
#' you will see:
#' ```
#' Error in add(., "oh no!") : non-numeric argument to binary operator
#'
#' Enter a pipe stage number, 1 to switch mode, or 0 to exit
#'
#' 1: Show full stack frames
#'
#' 2:    data \%>\%
#' 3:      (function (x)
#'          force(x))(.) \%>\%
#' 4:      multiply_by(., 10) \%>\%
#' 5:      add(., 10) \%>\%
#' 6: ->   add(., "oh no!") \%>\%
#' 7:      subtract(., 5) \%>\%
#' 8:      divide_by(., 5)
#'
#' Selection:
#' ```
#'
#' The problematic pipe stage is marked with an arrow. By pressing 1 (and
#' ENTER) you can switch to a regular stack trace. If you want to save
#' the temporary result from the pipe, choose the number at the arrow.
#' This is the last pipe stage that has started before the error. Then
#' you can save the value of the dot argument to the global environment:
#' ```
#' assign("last_value", value, envir = .GlobalEnv)
#' ```
#'
#' When in non-interactive mode, `tamper` calls `dump_pipes`.
#'
#' @export
#' @family pipe debuggers

tamper <- function() {

  if (.isMethodsDispatchOn()) {
    ## turn off tracing
    tState <- tracingState(FALSE)
    on.exit(tracingState(tState))
  }

  if (! interactive()) {
    try({
      dump_pipes()
      cat(gettext("tamper called non-interactively; frames dumped, use debugger() to view\n"))
    })
    return(NULL)

  } else if (identical(getOption("show.error.messages"), FALSE)) {
    ## from try(silent=TRUE)?
    return(NULL)
  }

  dump <- get_pipe_calls(sys.calls(), sys.frames())

  if (is.na(dump$pipe_call)) {
    ## tracing is handled in recover(), so put it back
    tracingState(tState)
    return(recover())
  }

  ## We return here if there are no frames.
  if (dump$from <= 0L) {
    cat(gettext("No suitable frames for tamper()\n"))
    return()
  }

  pipe_menu(dump)

}

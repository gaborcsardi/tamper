
#' Dump the evaluation environments of a pipelines
#'
#' This function is the equivalent of `utils::dump.frames`,
#' for magrittr pipes.
#'
#' It dumps the calls and the evaluation environments to
#' an object in the global environment (`.GlobalEnv`).
#' It also adds an attribute called `pipes` that contains
#' information about the pipe stages, for easier debugging.
#'
#' @param dumpto The name of the object or file to dump to.
#' @param to.file Whether to dump to a file. If `FALSE`,
#'   then the dump does into an object in the global workspace.
#'
#' @export
#' @family pipe debuggers

dump_pipes <- function(dumpto = "last.dump", to.file = FALSE) {

  err_msg <- geterrmessage()
  pipe_env <- get_pipe_calls(sys.calls(), sys.frames())

  if (is.na(pipe_env$pipe_call)) {
    return(dump.frames(dumpto = dumpto, to.file = to.file))
  }

  last_dump <- pipe_env$frames
  names(last_dump) <- limitedLabels(pipe_env$calls)

  attr(last_dump, "pipes") <- pipe_env

  attr(last_dump, "error.message") <- err_msg
  class(last_dump) <- c("dump_pipes", "dump.frames")

  assign(dumpto, last_dump)
  if (to.file) {
    save(list = dumpto, file = paste(dumpto, "rda", sep = "."))
  } else {
    ge <- paste0("global", "env")
    assign(dumpto, last_dump, envir = do.call(ge, list()))
  }
  invisible()
}

#' Pretty-print a pipeline dump
#'
#' @param x Object created by `dump_pipes`.
#' @param ... Ignored.
#' @return The object being printed, invisibly.
#'
#' @export
#' @method print dump_pipes
#' @family pipe debuggers

print.dump_pipes <- function(x, ...) {
  pipe_env <- attr(x, "pipes")
  err <- attr(x, "error.message")
  attr(x, "pipes") <- NULL
  attr(x, "error.message") <- NULL
  attr(x, "class") <- setdiff(class(x), "dump_pipes")

  cat("Frames --------------------------------------------------\n\n")
  print(x)

  cat("Error ---------------------------------------------------\n\n")
  cat(err, "\n")

  cat("Pipe stages ---------------------------------------------\n\n");
  cat(pipe_env$chr_stages, sep = "\n")
  invisible(x)
}

get_pipe_calls <- function(calls, frames) {

  ## options(error = tamper) produces a call to this function as an object
  calls <- calls[- length(calls)]

  freduce_calls <- get_pipe_stages(calls)
  pipe_call <- get_last_pipe_call(calls)

  ## We are not in a pipe
  if (is.na(pipe_call)) {
    return(list(
      pipe_call = NA
    ))
  }

  freduce_calls <- freduce_calls[ freduce_calls > pipe_call ]

  from <- find_interesting_call(calls)

  ## Get the pieces of the pipe, convert to character for printing
  chr_chain_parts <- chain_parts_to_chr(
    get("chain_parts", envir = sys.frame(pipe_call))
  )

  ## Get the bad pipe stage
  bad_stage <- get_bad_stage(freduce_calls)

  ## Nice printout of pipe stages
  chr_stages <- format_pipe_stages(chr_chain_parts, bad_stage)

  ## Can we get into the errored function?
  can_browse <- can_browse_errored(calls)

  list(
    calls = calls,
    frames = frames,
    freduce_calls = freduce_calls,
    pipe_call = pipe_call,
    from = from,
    chr_stages = chr_stages,
    bad_stage = bad_stage,
    can_browse = can_browse
  )
}

## Decides whether the function with the error is in the
## stack. If the function is a primitive function, then it is
## not in the stack. We just check if the last thing in the
## is a magrittr call.

can_browse_errored <- function(calls) {

  ## This is a very sketchy way to detect if testthat is running.
  ## If it is running, then we are inside withCallingHandlers,
  ## and the last function of the stack is not good, we need to
  ## look a bit further up.
  if (Sys.getenv("R_TESTS") == "") {
    last_call <- tail(calls, 1)[[1]]
  } else {
    last_call <- tail(calls, 3)[[1]]
  }

  ! identical(
    last_call[[1]],
    as.call(quote(function_list[[1L]]))
  )
}

is_freduce_call <- function(x) identical(x[[1L]], quote(freduce))

get_pipe_stages <- function(calls) {
  which(vapply(calls, is_freduce_call, logical(1)))
}

is_pipe <- function (pipe) {
  identical(pipe, quote(`%>%`)) || identical(pipe, quote(`%T>%`)) ||
    identical(pipe, quote(`%<>%`)) || identical(pipe, quote(`%$%`))
}

is_pipe_call <- function(x) is_pipe(x[[1L]])

get_last_pipe_call <- function(calls) {
  res <- tail(which(vapply(calls, is_pipe_call, logical(1))), 1)
  if (length(res)) res else NA_integer_
}

is_trace_call <- function(x) {
  identical(x[[1L]], quote(.doTrace))
}

find_trace_calls <- function(calls) {
  which(vapply(calls, is_trace_call, logical(1)))
}

is_debug_call <- function(x) {
  identical(x[[1L]], quote(tamper)) ||
    identical(x[[1L]], quote(recover)) ||
    identical(x[[1L]], quote(stop)) ||
    identical(x[[1L]], quote(Stop))
}

find_not_debug_calls <- function(calls) {
  which(! vapply(calls, is_debug_call, logical(1)))
}

find_interesting_call <- function(calls) {

  no_calls <- length(calls)

  ## look for a call inserted by trace() (and don't show frames below)
  ## this level.
  trace_calls <- find_trace_calls(calls)
  if (length(trace_calls)) {
    tail(trace_calls) - 1

  } else {
    ## if no trace, look for the first frame from the bottom that is not
    ## stop, recover or tamper
    not_debug <- find_not_debug_calls(calls)
    if (length(not_debug)) {
      tail(not_debug)
    } else {
      0L
    }
  }
}

chain_parts_to_chr <- function(chain_parts) {
  no_pipes <- length(chain_parts$pipes)
  list(
    lhs = paste(deparse(chain_parts$lhs), collapse = "\n    "),
    pipes = vapply(chain_parts$pipes, as.character, ""),
    rhss = vapply(lapply(chain_parts$rhss, deparse),
      paste, "", collapse = "\n         ")
  )
}

get_bad_stage <- function(freduce_calls) {

  ## ---------------------------------------------------------------
  ## We might be more down from the actual error in the pipe chain,
  ## because of promises. For example if `value` is a promise all
  ## along the chain, then we are at the last stage.
  ##
  ## We have no_pipes stages in total, and we have
  ## length(freduce_calls) stages in the stack, these
  ## correspond to the first length(freduce_calls) stages.
  ##
  ##        |--------|--------|--------|--------|--------|
  ## pipes: |   1    |   2    |   3    |   4    |    5   |
  ## stack: |   1    |   2    |   3    |
  ##
  ## Now we find which stage the error corresponds to. We need
  ## to go up in the stack, until we find `value` evaluated.

  ## Checks which stacks are below the error in reality.
  ## If the `value` promise is not evaled, then we are below.
  is_below_error <- substitute(
    inherits(try(value, silent = TRUE), "try-error")
  )

  bad_stage <- length(freduce_calls)
  while (bad_stage > 0 &&
           eval(is_below_error,
                envir = sys.frame(freduce_calls[bad_stage]))) {
    bad_stage <- bad_stage - 1
  }

  bad_stage
}

format_pipe_stages <- function(chr_chain_parts, bad_stage) {
  no_pipes <- length(chr_chain_parts$rhss)
  markers <- rep("  ", no_pipes + 1)
  markers[bad_stage + 1] <- "->"

  paste(
    markers,
    c(chr_chain_parts$lhs, paste0("  ", chr_chain_parts$rhss)),
    c(chr_chain_parts$pipes, "")
  )
}

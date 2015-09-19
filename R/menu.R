
pipe_menu <- function(dump) {

  ## Interactive menu
  pipe_stack <- TRUE

  stacks <- list(
    c("   Switch mode\n", dump$calls),
    c("   Switch mode", "   Take me to the error\n", dump$chr_stages)
  )

  repeat {

    which <- menu(
      stacks[[pipe_stack + 1]],
      title = "\nEnter 0 to exit or choose:"
    )

    if (which == 1) {
      pipe_stack <- ! pipe_stack

    } else if (pipe_stack && which == 2) {
      if (dump$can_browse) {
        evalq(browser(), envir = sys.frame(length(dump$calls)))
      } else {
        cat("\n")
        cat(
          sep = "\n",
          strwrap(paste(
            "The error was in a pipe stage that is a primitive function",
            "that cannot be browsed. This is the pipe stage that called it."
          ))
        )
        cat("\n")
        evalq(
          browser(),
          envir = sys.frame(dump$freduce_calls[dump$bad_stage])
        )
      }

    } else if (pipe_stack && which == 3) {
      evalq(browser(), envir = sys.frame(dump$pipe_call))

    } else if (which > 3 && pipe_stack) {
      which <- which - 3
      evalq(browser(), envir = sys.frame(dump$freduce_calls[which]))

    } else if (which > 1 && ! pipe_stack) {
      which <- which - 1
      evalq(browser(), envir = sys.frame(which))

    } else {
      break
    }
  }

  ## ---------------------------------------------------------------

}

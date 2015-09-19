
pipe_menu <- function(dump) {

  ## Interactive menu
  pipe_stack <- TRUE
  titles <- c("\nEnter a frame number, 1 to switch mode, or 0 to exit  ",
              "\nEnter a pipe stage number, 1 to switch mode, or 0 to exit  ")
  other_text <- c("Show pipe stages\n", "Show full stack frames\n")

  stacks <- list(dump$calls, dump$chr_stages)

  repeat {

    which <- menu(
      c(other_text[pipe_stack + 1], stacks[[pipe_stack + 1]]),
      title = titles[pipe_stack + 1])

    if (which == 1) {
      pipe_stack <- ! pipe_stack

    } else if (pipe_stack && which == 2) {
      evalq(browser(), envir = sys.frame(dump$pipe_call))

    } else if (which > 1 && pipe_stack) {
      which <- which - 2
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

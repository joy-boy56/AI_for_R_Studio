#' RConsoleAI Options
#'
#' Get or set global options for RConsoleAI.
#'
#' @param ... Option names to get, or name-value pairs to set.
#' @return If getting, a list of option values. If setting, invisible NULL.
#' @export
#' @examples
#' rconsoleai_options()
#' rconsoleai_options(provider = "horde")
rconsoleai_options <- function(...) {
  args <- list(...)
  if (length(args) == 0) {
    return(getOption("rconsoleai", list()))
  }
  
  current <- getOption("rconsoleai", list())
  if (length(args) == 1 && is.null(names(args))) {
    # Getting a single option
    return(current[[args[[1]]]])
  }
  
  # Setting options
  new_options <- modifyList(current, args)
  options(rconsoleai = new_options)
  invisible(NULL)
}

#' Reset RConsoleAI Options
#'
#' Reset all RConsoleAI options to their defaults.
#'
#' @export
rconsoleai_reset_options <- function() {
  defaults <- list(
    provider = "auto",
    model = NULL,
    gateway_url = NULL,
    max_tokens = 700,
    timeout = 90,
    history_limit = 50,
    persist_history = TRUE,
    color_output = TRUE,
    system_prompt = "You are RConsoleAI, an expert R programming assistant. Provide clear, accurate, and helpful responses about R programming, statistics, and data analysis. Include executable R code examples when appropriate. Never automatically execute code."
  )
  options(rconsoleai = defaults)
  invisible(NULL)
}

# Initialize defaults on load
.onLoad <- function(libname, pkgname) {
  current <- getOption("rconsoleai", list())
  defaults <- list(
    provider = "auto",
    model = NULL,
    gateway_url = NULL,
    max_tokens = 700,
    timeout = 90,
    history_limit = 50,
    persist_history = TRUE,
    color_output = TRUE,
    system_prompt = "You are RConsoleAI, an expert R programming assistant. Provide clear, accurate, and helpful responses about R programming, statistics, and data analysis. Include executable R code examples when appropriate. Never automatically execute code."
  )
  
  # Only set unset options
  for (name in names(defaults)) {
    if (is.null(current[[name]])) {
      current[[name]] <- defaults[[name]]
    }
  }
  options(rconsoleai = current)
}
#' Null Coalescing Operator
#'
#' Returns the left-hand side if not NULL, otherwise the right-hand side.
#'
#' @param x Left-hand side value
#' @param y Right-hand side fallback value
#' @return x if not NULL, otherwise y
#' @keywords internal
`%||%` <- function(x, y) if (is.null(x)) y else x

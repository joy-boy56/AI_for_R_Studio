#' R Context Helper
#'
#' Safely inspects the R environment for context-aware assistance.
#'
#' @keywords internal
RContextHelper <- R6::R6Class(
  "RContextHelper",
  public = list(
    #' @field include_values Whether to include actual values
    include_values = FALSE,
    #' @field max_vars Maximum variables to include
    max_vars = 50,
    #' @field max_df_rows Maximum data frame rows to summarize
    max_df_rows = 1000,
    
    #' @description Initialize context helper
    #' @param include_values Include variable values
    #' @param max_vars Maximum variables
    initialize = function(include_values = FALSE, max_vars = 50) {
      self$include_values <- include_values
      self$max_vars <- max_vars
    },
    
    #' @description Get environment summary
    #' @param env Environment to inspect (default: .GlobalEnv)
    #' @return List with environment summary
    get_summary = function(env = .GlobalEnv) {
      objs <- ls(envir = env, all.names = FALSE)
      
      if (length(objs) > self$max_vars) {
        objs <- objs[1:self$max_vars]
      }
      
      vars <- list()
      for (name in objs) {
        obj <- get(name, envir = env)
        vars[[name]] <- self$summarize_object(name, obj)
      }
      
      list(
        variable_count = length(objs),
        variables = vars,
        r_version = R.version.string,
        platform = R.version$platform
      )
    },
    
    #' @description Summarize a single object
    #' @param name Object name
    #' @param obj Object
    #' @return Summary list
    summarize_object = function(name, obj) {
      cls <- class(obj)[1]
      summary <- list(
        name = name,
        class = cls,
        type = typeof(obj),
        length = length(obj)
      )
      
      # Add class-specific details
      if (cls == "data.frame" || cls == "tbl_df" || cls == "data.table") {
        summary$rows <- nrow(obj)
        summary$cols <- ncol(obj)
        summary$colnames <- names(obj)
        summary$col_types <- vapply(obj, function(x) class(x)[1], character(1))
        
        if (self$include_values && nrow(obj) > 0) {
          summary$head <- head(obj, 5)
          summary$summary <- summary(obj)
        }
      } else if (cls == "matrix" || cls == "array") {
        summary$dim <- dim(obj)
        summary$dimnames <- dimnames(obj)
      } else if (cls == "list") {
        summary$length <- length(obj)
        summary$names <- names(obj)
      } else if (is.numeric(obj) || is.integer(obj)) {
        summary$range <- range(obj, na.rm = TRUE)
        summary$mean <- mean(obj, na.rm = TRUE)
      } else if (is.character(obj)) {
        summary$length <- length(obj)
        summary$preview <- head(obj, 5)
      } else if (is.function(obj)) {
        summary$args <- names(formals(obj))
      }
      
      if (self$include_values && !cls %in% c("data.frame", "tbl_df", "data.table", "matrix", "array", "function")) {
        summary$value <- obj
      }
      
      summary
    },
    
    #' @description Get dataset summary for rchat_data
    #' @param data Dataset (data frame)
    #' @param name Dataset name
    #' @return Formatted summary string
    format_dataset_summary = function(data, name = "dataset") {
      if (!is.data.frame(data)) {
        return(sprintf("%s: Not a data frame (class: %s)", name, class(data)[1]))
      }
      
      lines <- character()
      lines <- c(lines, sprintf("Dataset: %s", name))
      lines <- c(lines, sprintf("Dimensions: %d rows x %d columns", nrow(data), ncol(data)))
      lines <- c(lines, "Columns:")
      
      for (col in names(data)) {
        x <- data[[col]]
        cls <- class(x)[1]
        na_count <- sum(is.na(x))
        na_pct <- round(100 * na_count / length(x), 1)
        
        col_info <- sprintf("  - %s (%s, %d%% NA)", col, cls, na_pct)
        
        if (is.numeric(x) || is.integer(x)) {
          rng <- range(x, na.rm = TRUE)
          col_info <- paste0(col_info, sprintf(", range: [%.2f, %.2f], mean: %.2f", 
                                               rng[1], rng[2], mean(x, na.rm = TRUE)))
        } else if (is.factor(x) || is.character(x)) {
          unique_vals <- length(unique(x))
          col_info <- paste0(col_info, sprintf(", unique: %d", unique_vals))
          if (unique_vals <= 10) {
            vals <- head(sort(table(x), decreasing = TRUE), 5)
            col_info <- paste0(col_info, ", top: ", paste(names(vals), collapse = ", "))
          }
        }
        
        lines <- c(lines, col_info)
      }
      
      paste(lines, collapse = "\n")
    },
    
    #' @description Format environment summary for prompt
    #' @param env Environment to inspect
    #' @return Formatted string
    format_for_prompt = function(env = .GlobalEnv) {
      summary <- self$get_summary(env)
      
      lines <- character()
      lines <- c(lines, sprintf("R Environment Summary (%d variables):", summary$variable_count))
      lines <- c(lines, sprintf("R Version: %s", summary$r_version))
      lines <- c(lines, "")
      
      for (name in names(summary$variables)) {
        v <- summary$variables[[name]]
        line <- sprintf("  %s: %s", name, v$class)
        
        if (v$class %in% c("data.frame", "tbl_df", "data.table")) {
          line <- paste0(line, sprintf(" [%dx%d]", v$rows, v$cols))
        } else if (v$class %in% c("matrix", "array")) {
          line <- paste0(line, sprintf(" [%s]", paste(v$dim, collapse = "x")))
        } else if (is.numeric(v$length)) {
          line <- paste0(line, sprintf(" (len=%d)", v$length))
        }
        
        lines <- c(lines, line)
      }
      
      paste(lines, collapse = "\n")
    }
  )
)

#' Get R Environment Context
#'
#' Safely get a summary of the current R environment for AI context.
#' Requires explicit user consent before including data values.
#'
#' @param include_values Whether to include actual data values (requires consent)
#' @param max_vars Maximum variables to include
#' @return Formatted context string
#' @export
#' @examples
#' \dontrun{
#' # Get metadata only (safe)
#' get_r_context()
#' 
#' # Get with values (requires consent)
#' get_r_context(include_values = TRUE)
#' }
get_r_context <- function(include_values = FALSE, max_vars = 50) {
  helper <- RContextHelper$new(include_values = include_values, max_vars = max_vars)
  helper$format_for_prompt()
}

#' Format Dataset for AI Context
#'
#' @param data Data frame
#' @param name Dataset name
#' @return Formatted summary
#' @export
format_dataset_context <- function(data, name = "dataset") {
  helper <- RContextHelper$new()
  helper$format_dataset_summary(data, name)
}
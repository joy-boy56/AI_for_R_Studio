#' Provider Base Class
#'
#' Abstract base class for AI providers.
#'
#' @keywords internal
ProviderBase <- R6::R6Class(
  "ProviderBase",
  public = list(
    #' @field name Provider name
    name = NULL,
    #' @field models Cached model list
    models = NULL,
    #' @field models_cached_at Cache timestamp
    models_cached_at = NULL,
    #' @field cache_ttl Cache time-to-live in seconds
    cache_ttl = 300,
    
    #' @description Initialize provider
    #' @param name Provider name
    initialize = function(name) {
      self$name <- name
    },
    
    #' @description Get available models
    #' @param force_refresh Force refresh of model cache
    #' @return List of models
    get_models = function(force_refresh = FALSE) {
      if (!force_refresh && !is.null(self$models) && 
          !is.null(self$models_cached_at) &&
          (Sys.time() - self$models_cached_at) < self$cache_ttl) {
        return(self$models)
      }
      self$models <- self$fetch_models()
      self$models_cached_at <- Sys.time()
      self$models
    },
    
    #' @description Fetch models from provider (must be implemented by subclass)
    #' @return List of models
    fetch_models = function() {
      stop("fetch_models() must be implemented by subclass")
    },
    
    #' @description Send chat completion request
    #' @param messages List of message objects with role and content
    #' @param model Model name
    #' @param max_tokens Maximum tokens
    #' @param temperature Temperature
    #' @param stream Whether to stream (not all providers support)
    #' @return Response object
    chat = function(messages, model, max_tokens = 700, temperature = 0.7, stream = FALSE) {
      stop("chat() must be implemented by subclass")
    },
    
    #' @description Check if provider is available
    #' @return Logical
    is_available = function() {
      tryCatch({
        models <- self$get_models()
        length(models) > 0
      }, error = function(e) FALSE)
    },
    
    #' @description Get provider info
    #' @return List with provider info
    get_info = function() {
      list(
        name = self$name,
        available = self$is_available(),
        models = self$get_models()
      )
    }
  )
)

#' Provider Error Conditions
#'
#' S3 condition classes for provider errors. Use these with stop() to signal
#' provider-specific errors that can be caught with tryCatch().
#'
#' @param message Error message
#' @param provider Provider name
#' @return A condition object
#' @keywords internal
ProviderError <- function(message, provider = NULL) {
  structure(
    list(message = message, provider = provider),
    class = c("ProviderError", "error", "condition")
  )
}

#' Timeout Error
#' @param message Error message
#' @param provider Provider name
#' @keywords internal
TimeoutError <- function(message, provider = NULL) {
  structure(
    list(message = message, provider = provider),
    class = c("TimeoutError", "ProviderError", "error", "condition")
  )
}

#' Rate Limit Error
#' @param message Error message
#' @param provider Provider name
#' @keywords internal
RateLimitError <- function(message, provider = NULL) {
  structure(
    list(message = message, provider = provider),
    class = c("RateLimitError", "ProviderError", "error", "condition")
  )
}

#' Authentication Error
#' @param message Error message
#' @param provider Provider name
#' @keywords internal
AuthenticationError <- function(message, provider = NULL) {
  structure(
    list(message = message, provider = provider),
    class = c("AuthenticationError", "ProviderError", "error", "condition")
  )
}

#' Model Not Found Error
#' @param message Error message
#' @param provider Provider name
#' @keywords internal
ModelNotFoundError <- function(message, provider = NULL) {
  structure(
    list(message = message, provider = provider),
    class = c("ModelNotFoundError", "ProviderError", "error", "condition")
  )
}

#' Provider Unavailable Error
#' @param message Error message
#' @param provider Provider name
#' @keywords internal
ProviderUnavailableError <- function(message, provider = NULL) {
  structure(
    list(message = message, provider = provider),
    class = c("ProviderUnavailableError", "ProviderError", "error", "condition")
  )
}
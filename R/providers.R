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

#' Provider Errors
#' @keywords internal
ProviderError <- R6::R6Class(
  "ProviderError",
  inherit = Error,
  public = list(
    provider = NULL,
    initialize = function(message, provider = NULL) {
      self$provider <- provider
      super$initialize(message)
    }
  )
)

#' Timeout Error
#' @keywords internal
TimeoutError <- R6::R6Class(
  "TimeoutError",
  inherit = ProviderError
)

#' Rate Limit Error
#' @keywords internal
RateLimitError <- R6::R6Class(
  "RateLimitError",
  inherit = ProviderError
)

#' Authentication Error
#' @keywords internal
AuthenticationError <- R6::R6Class(
  "AuthenticationError",
  inherit = ProviderError
)

#' Model Not Found Error
#' @keywords internal
ModelNotFoundError <- R6::R6Class(
  "ModelNotFoundError",
  inherit = ProviderError
)

#' Provider Unavailable Error
#' @keywords internal
ProviderUnavailableError <- R6::R6Class(
  "ProviderUnavailableError",
  inherit = ProviderError
)
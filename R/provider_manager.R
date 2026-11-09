#' Provider Manager
#'
#' Manages AI provider selection and switching.
#'
#' @keywords internal
ProviderManager <- R6::R6Class(
  "ProviderManager",
  public = list(
    #' @field providers List of provider instances
    providers = list(),
    #' @field current_provider_name Current provider name
    current_provider_name = "auto",
    #' @field current_model Current model name
    current_model = NULL,
    
    #' @description Initialize provider manager
    initialize = function() {
      self$register_provider(AIHordeProvider$new())
      self$register_provider(NVIDIAProvider$new())
      self$register_provider(GatewayProvider$new())
    },
    
    #' @description Register a provider
    #' @param provider Provider instance
    register_provider = function(provider) {
      self$providers[[provider$name]] <- provider
    },
    
    #' @description Get provider by name
    #' @param name Provider name
    #' @return Provider instance or NULL
    get_provider = function(name) {
      self$providers[[name]]
    },
    
    #' @description List all registered providers
    #' @return Character vector of provider names
    list_providers = function() {
      names(self$providers)
    },
    
    #' @description Set current provider
    #' @param name Provider name ("horde", "nvidia", "gateway", "auto")
    set_provider = function(name) {
      valid <- c("auto", "horde", "nvidia", "gateway")
      if (!name %in% valid) {
        stop(sprintf("Invalid provider: %s. Valid: %s", name, paste(valid, collapse = ", ")))
      }
      self$current_provider_name <- name
      rconsoleai_options(provider = name)
    },
    
    #' @description Get current provider name
    #' @return Provider name
    get_current_provider_name = function() {
      self$current_provider_name
    },
    
    #' @description Resolve provider (handles "auto")
    #' @return Provider instance
    resolve_provider = function() {
      name <- self$current_provider_name
      
      if (name == "auto") {
        # Try NVIDIA first if credentials are available
        nvidia <- self$providers[["nvidia"]]
        if (!is.null(nvidia) && nvidia$has_credentials() && nvidia$is_available()) {
          return(nvidia)
        }
        # Try gateway if configured and available
        gateway <- self$providers[["gateway"]]
        if (!is.null(gateway$gateway_url) && gateway$is_available()) {
          return(gateway)
        }
        # Fall back to AI Horde
        horde <- self$providers[["horde"]]
        if (horde$is_available()) {
          return(horde)
        }
        stop(ProviderUnavailableError$new("No providers available"))
      }
      
      provider <- self$providers[[name]]
      if (is.null(provider)) {
        stop(ProviderError$new(sprintf("Provider not found: %s", name)))
      }
      
      if (!provider$is_available()) {
        if (name == "nvidia") {
          stop(ProviderUnavailableError$new(
            "NVIDIA provider unavailable. Check NVIDIA_API_KEY is set and model is accessible.",
            provider = "nvidia"
          ))
        }
        stop(ProviderUnavailableError$new(sprintf("Provider unavailable: %s", name)))
      }
      
      provider
    },
    
    #' @description Set current model
    #' @param model Model name
    set_model = function(model) {
      self$current_model <- model
      rconsoleai_options(model = model)
    },
    
    #' @description Get current model
    #' @return Model name or NULL
    get_model = function() {
      self$current_model %||% rconsoleai_options("model")
    },
    
    #' @description Get available models from all providers
    #' @return Combined model list
    get_all_models = function() {
      all_models <- list()
      for (name in names(self$providers)) {
        provider <- self$providers[[name]]
        tryCatch({
          models <- provider$get_models()
          for (m in models) {
            m$provider <- name
            all_models <- c(all_models, list(m))
          }
        }, error = function(e) {
          # Silently skip unavailable providers
        })
      }
      all_models
    },
    
    #' @description Get provider status for display
    #' @return Status info list
    get_status = function() {
      list(
        current_provider = self$current_provider_name,
        current_model = self$get_model(),
        providers = lapply(self$providers, function(p) p$get_info())
      )
    }
  )
)

# Global provider manager instance (stored in function attribute to avoid namespace locking)
get_provider_manager <- function() {
  if (is.null(attr(get_provider_manager, "instance"))) {
    attr(get_provider_manager, "instance") <- ProviderManager$new()
  }
  attr(get_provider_manager, "instance")
}

#' List Available Providers
#'
#' @return Character vector of provider names
#' @export
list_providers <- function() {
  get_provider_manager()$list_providers()
}

#' Get Provider Instance
#'
#' @param name Provider name
#' @return Provider instance or NULL
#' @export
get_provider <- function(name) {
  get_provider_manager()$get_provider(name)
}

#' Set Current Provider
#'
#' @param name Provider name ("horde", "nvidia", "gateway", "auto")
#' @export
set_provider <- function(name) {
  get_provider_manager()$set_provider(name)
}

`%||%` <- function(x, y) if (is.null(x)) y else x
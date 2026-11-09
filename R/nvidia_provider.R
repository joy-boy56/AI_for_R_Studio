#' NVIDIA Nemotron Provider
#'
#' Direct provider for NVIDIA Nemotron models using the official
#' OpenAI-compatible API endpoint.
#' https://docs.api.nvidia.com/nim/
#'
#' @keywords internal
NVIDIAProvider <- R6::R6Class(
  "NVIDIAProvider",
  inherit = ProviderBase,
  public = list(
    #' @field base_url API base URL
    base_url = "https://integrate.api.nvidia.com/v1",
    #' @field default_model Default model to use
    default_model = "nvidia/nemotron-3.5-lightning-30b-a3b",
    
    #' @description Initialize NVIDIA provider
    initialize = function() {
      super$initialize("nvidia")
    },
    
    #' @description Get API key from environment or keyring
    #' @return API key string or NULL
    get_api_key = function() {
      # Try keyring first
      key <- tryCatch({
        if (requireNamespace("keyring", quietly = TRUE)) {
          keyring::key_get("rconsoleai", "NVIDIA_API_KEY")
        }
      }, error = function(e) NULL)
      
      if (!is.null(key) && nchar(key) > 0) {
        return(key)
      }
      
      # Fall back to environment variable
      env_key <- Sys.getenv("NVIDIA_API_KEY")
      if (nchar(env_key) > 0) {
        return(env_key)
      }
      
      NULL
    },
    
    #' @description Check if API key is available
    #' @return Logical
    has_credentials = function() {
      !is.null(self$get_api_key())
    },
    
    #' @description Fetch available models from NVIDIA
    #' @return List of model info
    fetch_models = function() {
      api_key <- self$get_api_key()
      if (is.null(api_key)) {
        # No credentials - return empty so is_available() is FALSE
        return(list())
      }
      
      req <- httr2::request(self$base_url) |>
        httr2::req_url_path_append("models") |>
        httr2::req_headers(
          "Content-Type" = "application/json",
          "Authorization" = paste("Bearer", api_key)
        ) |>
        httr2::req_timeout(30) |>
        httr2::req_error(is_error = function(resp) FALSE)
      
      resp <- httr2::req_perform(req)
      status <- httr2::resp_status(resp)
      
      # On auth failure or any non-200, return empty list (not a fallback model)
      # so is_available() correctly reports FALSE
      if (status != 200) {
        return(list())
      }
      
      data <- httr2::resp_body_json(resp)
      
      # Parse model list
      raw_models <- data$data %||% data
      if (!is.list(raw_models)) {
        return(list())
      }
      
      # Filter for chat-capable models
      chat_models <- Filter(function(m) {
        id <- m$id %||% m$name %||% ""
        grepl("nemotron|llama|mistral|mixtral|qwen|deepseek", tolower(id))
      }, raw_models)
      
      lapply(chat_models, function(m) {
        list(
          id = m$id,
          name = m$id,
          provider = "nvidia",
          owned_by = m$owned_by %||% "nvidia"
        )
      })
    },
    
    #' @description Send chat completion request to NVIDIA
    #' @param messages List of message objects
    #' @param model Model name
    #' @param max_tokens Maximum tokens
    #' @param temperature Temperature
    #' @param stream Whether to stream (SSE)
    #' @return Response text
    chat = function(messages, model = NULL, max_tokens = 700, temperature = 0.7, stream = FALSE) {
      api_key <- self$get_api_key()
      if (is.null(api_key)) {
        stop(AuthenticationError(
          "NVIDIA API key not found. Set NVIDIA_API_KEY environment variable or use keyring.",
          provider = "nvidia"
        ))
      }
      
      # Use default model if not specified
      if (is.null(model)) {
        model <- self$default_model
      }
      
      payload <- list(
        model = model,
        messages = messages,
        max_tokens = max_tokens,
        temperature = temperature,
        stream = stream,
        top_p = 0.9
      )
      
      req <- httr2::request(self$base_url) |>
        httr2::req_url_path_append("chat/completions") |>
        httr2::req_headers(
          "Content-Type" = "application/json",
          "Authorization" = paste("Bearer", api_key)
        ) |>
        httr2::req_body_json(payload) |>
        httr2::req_timeout(rconsoleai_options("timeout")) |>
        httr2::req_error(is_error = function(resp) FALSE)
      
      if (stream) {
        return(self$chat_stream(req))
      }
      
      resp <- httr2::req_perform(req)
      status <- httr2::resp_status(resp)
      
      # Handle HTTP errors
      if (status == 400) {
        body <- httr2::resp_body_string(resp)
        stop(ProviderError(
          sprintf("Bad request: %s", body),
          provider = "nvidia"
        ))
      }
      if (status == 401) {
        stop(AuthenticationError(
          "Invalid NVIDIA API key. Check your credentials.",
          provider = "nvidia"
        ))
      }
      if (status == 403) {
        stop(ProviderError(
          "Access forbidden. Your API key may not have access to this model.",
          provider = "nvidia"
        ))
      }
      if (status == 404) {
        stop(ModelNotFoundError(
          sprintf("Model not found: %s", model),
          provider = "nvidia"
        ))
      }
      if (status == 429) {
        stop(RateLimitError(
          "Rate limit exceeded. Please wait before retrying.",
          provider = "nvidia"
        ))
      }
      if (status >= 500) {
        stop(ProviderError(
          sprintf("NVIDIA server error: %d", status),
          provider = "nvidia"
        ))
      }
      if (status != 200) {
        body <- httr2::resp_body_string(resp)
        stop(ProviderError(
          sprintf("NVIDIA API error: %d - %s", status, body),
          provider = "nvidia"
        ))
      }
      
      # Parse response
      data <- httr2::resp_body_json(resp)
      
      if (!is.null(data$choices) && length(data$choices) > 0) {
        choice <- data$choices[[1]]
        if (!is.null(choice$message$content)) {
          return(choice$message$content)
        }
        if (!is.null(choice$text)) {
          return(choice$text)
        }
      }
      
      stop(ProviderError("No response content from NVIDIA", provider = "nvidia"))
    },
    
    #' @description Stream chat completion via Server-Sent Events
    #' @param req Prepared httr2 request
    #' @return Streamed response (not yet implemented - returns error)
    chat_stream = function(req) {
      # Streaming not yet implemented - would require SSE parsing
      stop("Streaming not yet implemented for NVIDIA provider")
    },
    
    #' @description Check if provider is available (valid key + API reachable)
    #' @return Logical
    is_available = function() {
      api_key <- self$get_api_key()
      if (is.null(api_key) || nchar(api_key) == 0) return(FALSE)
      
      tryCatch({
        # Make a direct API call to verify the key works
        req <- httr2::request(self$base_url) |>
          httr2::req_url_path_append("models") |>
          httr2::req_headers(
            "Authorization" = paste("Bearer", api_key)
          ) |>
          httr2::req_timeout(10) |>
          httr2::req_error(is_error = function(resp) FALSE)
        
        resp <- httr2::req_perform(req)
        httr2::resp_status(resp) == 200
      }, error = function(e) FALSE)
    },
    
    #' @description Test connection to NVIDIA API
    #' @return List with status and message
    test_connection = function() {
      api_key <- self$get_api_key()
      if (is.null(api_key)) {
        return(list(success = FALSE, message = "No API key configured"))
      }
      
      tryCatch({
        req <- httr2::request(self$base_url) |>
          httr2::req_url_path_append("models") |>
          httr2::req_headers(
            "Authorization" = paste("Bearer", api_key)
          ) |>
          httr2::req_timeout(10) |>
          httr2::req_error(is_error = function(resp) FALSE)
        
        resp <- httr2::req_perform(req)
        status <- httr2::resp_status(resp)
        
        if (status == 200) {
          data <- httr2::resp_body_json(resp)
          model_count <- length(data$data %||% data %||% list())
          list(success = TRUE, message = sprintf("Connected. %d models available.", model_count))
        } else if (status == 401) {
          list(success = FALSE, message = "Invalid API key")
        } else {
          list(success = FALSE, message = sprintf("Connection failed: HTTP %d", status))
        }
      }, error = function(e) {
        list(success = FALSE, message = sprintf("Connection error: %s", e$message))
      })
    }
  )
)

#' Gateway Provider
#'
#' Provider for the secure RConsoleAI backend (Cloudflare Workers).
#' This provider communicates with the backend gateway which handles
#' authenticated provider access (NVIDIA, OpenAI-compatible, etc.)
#'
#' @keywords internal
GatewayProvider <- R6::R6Class(
  "GatewayProvider",
  inherit = ProviderBase,
  public = list(
    #' @field gateway_url Backend gateway URL
    gateway_url = NULL,
    #' @field api_key Optional API key for gateway (if required)
    api_key = NULL,
    
    #' @description Initialize gateway provider
    #' @param gateway_url Gateway URL (defaults to option)
    #' @param api_key Optional API key
    initialize = function(gateway_url = NULL, api_key = NULL) {
      super$initialize("gateway")
      self$gateway_url <- gateway_url %||% rconsoleai_options("gateway_url")
      self$api_key <- api_key
    },
    
    #' @description Fetch available models from gateway
    #' @return List of model info
    fetch_models = function() {
      if (is.null(self$gateway_url)) {
        return(list())
      }
      
      req <- httr2::request(self$gateway_url) %>%
        httr2::req_url_path_append("models") %>%
        httr2::req_headers("Content-Type" = "application/json") %>%
        httr2::req_timeout(30) %>%
        httr2::req_error(is_error = function(resp) FALSE)
      
      if (!is.null(self$api_key)) {
        req <- httr2::req_headers(req, "Authorization" = paste("Bearer", self$api_key))
      }
      
      resp <- httr2::req_perform(req)
      
      if (httr2::resp_status(resp) != 200) {
        return(list())
      }
      
      data <- httr2::resp_body_json(resp)
      data$models %||% list()
    },
    
    #' @description Send chat completion request to gateway
    #' @param messages List of message objects
    #' @param model Model name
    #' @param max_tokens Maximum tokens
    #' @param temperature Temperature
    #' @param stream Whether to stream
    #' @return Response text
    chat = function(messages, model = NULL, max_tokens = 700, temperature = 0.7, stream = FALSE) {
      if (is.null(self$gateway_url)) {
        stop(ProviderUnavailableError$new("Gateway URL not configured", provider = "gateway"))
      }
      
      payload <- list(
        messages = messages,
        model = model,
        max_tokens = max_tokens,
        temperature = temperature,
        stream = stream
      )
      
      req <- httr2::request(self$gateway_url) %>%
        httr2::req_url_path_append("chat") %>%
        httr2::req_headers("Content-Type" = "application/json") %>%
        httr2::req_body_json(payload) %>%
        httr2::req_timeout(rconsoleai_options("timeout")) %>%
        httr2::req_error(is_error = function(resp) FALSE)
      
      if (!is.null(self$api_key)) {
        req <- httr2::req_headers(req, "Authorization" = paste("Bearer", self$api_key))
      }
      
      resp <- httr2::req_perform(req)
      
      status <- httr2::resp_status(resp)
      
      if (status == 429) {
        stop(RateLimitError$new("Gateway rate limit exceeded", provider = "gateway"))
      }
      if (status == 401) {
        stop(AuthenticationError$new("Gateway authentication failed", provider = "gateway"))
      }
      if (status == 404) {
        stop(ModelNotFoundError$new("Model not found on gateway", provider = "gateway"))
      }
      if (status != 200) {
        body <- httr2::resp_body_string(resp)
        stop(ProviderError$new(
          sprintf("Gateway request failed: %d - %s", status, body),
          provider = "gateway"
        ))
      }
      
      data <- httr2::resp_body_json(resp)
      
      # Handle both streaming and non-streaming responses
      if (stream) {
        # For streaming, we'd need to handle SSE - return the raw response for now
        return(data)
      }
      
      # Extract response text
      if (!is.null(data$choices) && length(data$choices) > 0) {
        choice <- data$choices[[1]]
        if (!is.null(choice$message$content)) {
          return(choice$message$content)
        }
        if (!is.null(choice$text)) {
          return(choice$text)
        }
      }
      
      if (!is.null(data$content)) {
        return(data$content)
      }
      
      stop(ProviderError$new("No response content from gateway", provider = "gateway"))
    },
    
    #' @description Check if gateway is available
    #' @return Logical
    is_available = function() {
      if (is.null(self$gateway_url)) return(FALSE)
      
      tryCatch({
        req <- httr2::request(self$gateway_url) %>%
          httr2::req_url_path_append("health") %>%
          httr2::req_timeout(10) %>%
          httr2::req_error(is_error = function(resp) FALSE)
        
        resp <- httr2::req_perform(req)
        httr2::resp_status(resp) == 200
      }, error = function(e) FALSE)
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
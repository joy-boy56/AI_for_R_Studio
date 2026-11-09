#' AI Horde Provider
#'
#' Provider for AI Horde - a free, distributed AI inference network.
#' https://aihorde.net/api/
#'
#' @keywords internal
AIHordeProvider <- R6::R6Class(
  "AIHordeProvider",
  inherit = ProviderBase,
  public = list(
    #' @field base_url API base URL
    base_url = "https://aihorde.net/api/v2",
    #' @field client_id Client identifier for anonymous access
    client_id = "RConsoleAI",
    
    #' @description Initialize AI Horde provider
    initialize = function() {
      super$initialize("horde")
    },
    
    #' @description Fetch available models from AI Horde
    #' @return List of model info
    fetch_models = function() {
      req <- httr2::request(self$base_url) %>%
        httr2::req_url_path_append("status/models") %>%
        httr2::req_headers(
          "Content-Type" = "application/json",
          "User-Agent" = self$client_id
        ) %>%
        httr2::req_timeout(30) %>%
        httr2::req_error(is_error = function(resp) FALSE)
      
      resp <- httr2::req_perform(req)
      
      if (httr2::resp_status(resp) != 200) {
        stop(ProviderError$new(
          sprintf("AI Horde models request failed: %d", httr2::resp_status(resp)),
          provider = "horde"
        ))
      }
      
      data <- httr2::resp_body_json(resp)
      
      # Filter for text generation models with available workers
      models <- data
      if (is.list(models) && length(models) > 0) {
        # Keep models that have workers available
        models <- Filter(function(m) {
          isTRUE(m$count > 0) || (is.list(m$workers) && length(m$workers) > 0)
        }, models)
      }
      
      # Sort by worker count descending
      models <- models[order(-sapply(models, function(m) m$count %||% 0))]
      
      models
    },
    
    #' @description Submit async generation request to AI Horde
    #' @param payload Request payload
    #' @return Job UUID
    submit_generation = function(payload) {
      req <- httr2::request(self$base_url) %>%
        httr2::req_url_path_append("generate/async") %>%
        httr2::req_headers(
          "Content-Type" = "application/json",
          "User-Agent" = self$client_id,
          "apikey" = "0000000000"  # Anonymous access
        ) %>%
        httr2::req_body_json(payload) %>%
        httr2::req_timeout(60) %>%
        httr2::req_error(is_error = function(resp) FALSE)
      
      resp <- httr2::req_perform(req)
      
      if (httr2::resp_status(resp) == 429) {
        stop(RateLimitError$new("AI Horde rate limit exceeded", provider = "horde"))
      }
      if (httr2::resp_status(resp) == 401) {
        stop(AuthenticationError$new("AI Horde authentication failed", provider = "horde"))
      }
      if (httr2::resp_status(resp) != 200 && httr2::resp_status(resp) != 202) {
        body <- httr2::resp_body_string(resp)
        stop(ProviderError$new(
          sprintf("AI Horde generation submit failed: %d - %s", httr2::resp_status(resp), body),
          provider = "horde"
        ))
      }
      
      data <- httr2::resp_body_json(resp)
      data$id
    },
    
    #' @description Check job status
    #' @param job_id Job UUID
    #' @return Job status data
    check_status = function(job_id) {
      req <- httr2::request(self$base_url) %>%
        httr2::req_url_path_append("generate/check") %>%
        httr2::req_url_query(id = job_id) %>%
        httr2::req_headers(
          "User-Agent" = self$client_id
        ) %>%
        httr2::req_timeout(30) %>%
        httr2::req_error(is_error = function(resp) FALSE)
      
      resp <- httr2::req_perform(req)
      
      if (httr2::resp_status(resp) != 200) {
        stop(ProviderError$new(
          sprintf("AI Horde status check failed: %d", httr2::resp_status(resp)),
          provider = "horde"
        ))
      }
      
      httr2::resp_body_json(resp)
    },
    
    #' @description Wait for job completion with polling
    #' @param job_id Job UUID
    #' @param max_wait Maximum wait time in seconds
    #' @param poll_interval Poll interval in seconds
    #' @return Completed job result
    wait_for_completion = function(job_id, max_wait = 300, poll_interval = 3) {
      start_time <- Sys.time()
      
      while (TRUE) {
        elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
        if (elapsed > max_wait) {
          stop(TimeoutError$new(
            sprintf("AI Horde generation timed out after %d seconds", max_wait),
            provider = "horde"
          ))
        }
        
        status <- self$check_status(job_id)
        
        if (isTRUE(status$done)) {
          if (!is.null(status$faulted) && isTRUE(status$faulted)) {
            stop(ProviderError$new(
              sprintf("AI Horde generation faulted: %s", status$message %||% "Unknown error"),
              provider = "horde"
            ))
          }
          return(status)
        }
        
        # Show progress
        if (!is.null(status$wait_time)) {
          wait_msg <- sprintf("Queue position: %s, estimated wait: %ds", 
                            status$queue_position %||% "unknown", 
                            status$wait_time %||% 0)
          message(wait_msg)
        }
        
        Sys.sleep(poll_interval)
      }
    },
    
    #' @description Send chat completion request
    #' @param messages List of message objects
    #' @param model Model name (NULL for auto)
    #' @param max_tokens Maximum tokens
    #' @param temperature Temperature
    #' @param stream Not supported for AI Horde
    #' @return Response text
    chat = function(messages, model = NULL, max_tokens = 700, temperature = 0.7, stream = FALSE) {
      # Get models if not specified
      if (is.null(model)) {
        models <- self$get_models()
        if (length(models) == 0) {
          stop(ProviderUnavailableError$new("No AI Horde models available", provider = "horde"))
        }
        # Pick first available model
        model <- models[[1]]$name
      }
      
      # Convert messages to prompt format
      prompt <- self$messages_to_prompt(messages)
      
      payload <- list(
        prompt = prompt,
        params = list(
          max_new_tokens = max_tokens,
          temperature = temperature,
          top_p = 0.9,
          repetition_penalty = 1.1,
          do_sample = TRUE
        ),
        models = list(model),
        trusted_workers = FALSE,
        shared = TRUE,
        r2 = TRUE
      )
      
      job_id <- self$submit_generation(payload)
      result <- self$wait_for_completion(job_id, max_wait = rconsoleai_options("timeout"))
      
      # Extract generated text
      if (!is.null(result$generations) && length(result$generations) > 0) {
        gen <- result$generations[[1]]
        if (!is.null(gen$text)) {
          return(gen$text)
        }
      }
      
      stop(ProviderError$new("No generation returned from AI Horde", provider = "horde"))
    },
    
    #' @description Convert messages to prompt string
    #' @param messages List of message objects
    #' @return Prompt string
    messages_to_prompt = function(messages) {
      prompt_parts <- character()
      
      for (msg in messages) {
        role <- msg$role %||% "user"
        content <- msg$content %||% ""
        
        if (role == "system") {
          prompt_parts <- c(prompt_parts, sprintf("<|system|>\n%s", content))
        } else if (role == "user") {
          prompt_parts <- c(prompt_parts, sprintf("<|user|>\n%s", content))
        } else if (role == "assistant") {
          prompt_parts <- c(prompt_parts, sprintf("<|assistant|>\n%s", content))
        }
      }
      
      prompt_parts <- c(prompt_parts, "<|assistant|>\n")
      paste(prompt_parts, collapse = "\n\n")
    },
    
    #' @description Get model info by name
    #' @param model_name Model name
    #' @return Model info or NULL
    get_model_info = function(model_name) {
      models <- self$get_models()
      for (m in models) {
        if (identical(m$name, model_name)) return(m)
      }
      NULL
    }
  )
)

# Null coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x
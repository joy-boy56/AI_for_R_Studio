#' Conversation Class
#'
#' Manages chat conversation history and state.
#'
#' @export
Conversation <- R6::R6Class(
  "Conversation",
  public = list(
    #' @field messages List of message objects
    messages = list(),
    #' @field system_prompt System prompt
    system_prompt = NULL,
    #' @field max_history Maximum messages to keep
    max_history = 50,
    #' @field persist Whether to persist to disk
    persist = TRUE,
    #' @field file_path Path for persistence
    file_path = NULL,
    #' @field created_at Creation timestamp
    created_at = NULL,
    #' @field updated_at Last update timestamp
    updated_at = NULL,
    
    #' @description Initialize conversation
    #' @param system_prompt Initial system prompt
    #' @param max_history Maximum history length
    #' @param persist Whether to persist
    #' @param file_path Persistence file path
    initialize = function(system_prompt = NULL, max_history = 50, persist = TRUE, file_path = NULL) {
      self$system_prompt <- system_prompt %||% rconsoleai_options("system_prompt")
      self$max_history <- max_history
      self$persist <- persist
      self$file_path <- file_path %||% file.path(tempdir(), "rconsoleai_conversation.rds")
      self$created_at <- Sys.time()
      self$updated_at <- Sys.time()
      
      if (self$persist && file.exists(self$file_path)) {
        self$load()
      }
    },
    
    #' @description Add a message to conversation
    #' @param role Message role (user, assistant, system)
    #' @param content Message content
    add_message = function(role, content) {
      msg <- list(
        role = role,
        content = content,
        timestamp = Sys.time()
      )
      self$messages <- c(self$messages, list(msg))
      self$trim_history()
      self$updated_at <- Sys.time()
      if (self$persist) self$save()
    },
    
    #' @description Get messages for API (excludes timestamps)
    #' @param include_system Whether to include system prompt
    #' @return List of messages for API
    get_api_messages = function(include_system = TRUE) {
      msgs <- list()
      if (include_system && !is.null(self$system_prompt) && nchar(self$system_prompt) > 0) {
        msgs <- c(msgs, list(list(role = "system", content = self$system_prompt)))
      }
      for (msg in self$messages) {
        msgs <- c(msgs, list(list(role = msg$role, content = msg$content)))
      }
      msgs
    },
    
    #' @description Trim history to max length
    trim_history = function() {
      if (length(self$messages) > self$max_history) {
        # Keep system prompt if present, then trim
        keep <- self$max_history
        self$messages <- tail(self$messages, keep)
      }
    },
    
    #' @description Clear conversation history
    clear = function() {
      self$messages <- list()
      self$updated_at <- Sys.time()
      if (self$persist) self$save()
    },
    
    #' @description Save conversation to disk
    save = function() {
      data <- list(
        messages = self$messages,
        system_prompt = self$system_prompt,
        max_history = self$max_history,
        created_at = self$created_at,
        updated_at = self$updated_at
      )
      saveRDS(data, self$file_path)
    },
    
    #' @description Load conversation from disk
    load = function() {
      data <- readRDS(self$file_path)
      self$messages <- data$messages %||% list()
      self$system_prompt <- data$system_prompt %||% rconsoleai_options("system_prompt")
      self$max_history <- data$max_history %||% 50
      self$created_at <- data$created_at %||% Sys.time()
      self$updated_at <- data$updated_at %||% Sys.time()
    },
    
    #' @description Export conversation as list
    #' @return Conversation data
    export = function() {
      list(
        messages = self$messages,
        system_prompt = self$system_prompt,
        created_at = self$created_at,
        updated_at = self$updated_at
      )
    },
    
    #' @description Import conversation from list
    #' @param data Conversation data
    import = function(data) {
      self$messages <- data$messages %||% list()
      self$system_prompt <- data$system_prompt %||% rconsoleai_options("system_prompt")
      self$created_at <- data$created_at %||% Sys.time()
      self$updated_at <- Sys.time()
      if (self$persist) self$save()
    },
    
    #' @description Get last user message
    #' @return Last user message content or NULL
    get_last_user_message = function() {
      for (msg in rev(self$messages)) {
        if (msg$role == "user") return(msg$content)
      }
      NULL
    },
    
    #' @description Get message count
    #' @return Number of messages
    length = function() {
      length(self$messages)
    },
    
    #' @description Print conversation summary
    print = function() {
      cat(sprintf("Conversation: %d messages, created %s\n", 
                  length(self$messages), format(self$created_at)))
      cat(sprintf("System prompt: %s\n", 
                  ifelse(is.null(self$system_prompt), "none", 
                         substr(self$system_prompt, 1, 50))))
    }
  )
)

`%||%` <- function(x, y) if (is.null(x)) y else x
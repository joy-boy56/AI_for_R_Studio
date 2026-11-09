#' RConsoleAI Chat Interface
#'
#' Main chat interface for RConsoleAI. Provides interactive chat sessions
#' and single-prompt queries.
#'
#' @param prompt Optional single prompt. If NULL, starts interactive session.
#' @param provider Provider to use ("horde", "gateway", "auto")
#' @param model Model name (NULL for auto)
#' @param system_prompt Custom system prompt
#' @param max_tokens Maximum response tokens
#' @param temperature Sampling temperature
#' @param conversation Conversation object (for continuing sessions)
#' @return Invisible conversation object or response string
#' @export
#' @examples
#' \dontrun{
#' # Interactive session
#' rchat()
#' 
#' # Single prompt
#' rchat("Explain the pnorm function in R.")
#' 
#' # With specific provider
#' rchat("Hello", provider = "horde")
#' }
rchat <- function(prompt = NULL,
                  provider = NULL,
                  model = NULL,
                  system_prompt = NULL,
                  max_tokens = NULL,
                  temperature = 0.7,
                  conversation = NULL) {
  
  pm <- get_provider_manager()
  
  # Set provider if specified
  if (!is.null(provider)) {
    pm$set_provider(provider)
  }
  
  # Set model if specified
  if (!is.null(model)) {
    pm$set_model(model)
  }
  
  # Resolve provider
  selected_provider <- pm$resolve_provider()
  
  # Create or use conversation
  if (is.null(conversation)) {
    conversation <- Conversation$new(
      system_prompt = system_prompt,
      max_history = rconsoleai_options("history_limit"),
      persist = rconsoleai_options("persist_history")
    )
  } else if (!is.null(system_prompt)) {
    conversation$system_prompt <- system_prompt
  }
  
  # If single prompt, process and return
  if (!is.null(prompt)) {
    return(process_single_prompt(prompt, selected_provider, conversation, 
                                 max_tokens, temperature))
  }
  
  # Interactive session
  run_interactive_session(selected_provider, conversation, max_tokens, temperature)
}

#' Process a single prompt and return response
#' @keywords internal
process_single_prompt <- function(prompt, provider, conversation, max_tokens, temperature) {
  conversation$add_message("user", prompt)
  
  # Show progress
  cat("RConsoleAI: ")
  if (rconsoleai_options("color_output")) {
    cat("\033[32m")  # Green
  }
  
  tryCatch({
    messages <- conversation$get_api_messages()
    
    response <- provider$chat(
      messages = messages,
      model = pm$get_model(),
      max_tokens = max_tokens %||% rconsoleai_options("max_tokens"),
      temperature = temperature
    )
    
    conversation$add_message("assistant", response)
    
    if (rconsoleai_options("color_output")) {
      cat("\033[0m")  # Reset
    }
    cat(response, "\n")
    
    invisible(response)
  }, error = function(e) {
    if (rconsoleai_options("color_output")) {
      cat("\033[0m")  # Reset
    }
    cat("\nError: ", e$message, "\n", sep = "")
    invisible(NULL)
  })
}

#' Run interactive chat session
#' @keywords internal
run_interactive_session <- function(provider, conversation, max_tokens, temperature) {
  print_banner(provider)
  
  repeat {
    cat("\nYou: ")
    flush.console()
    
    input <- readLines(n = 1)
    
    if (length(input) == 0) next  # Empty input
    
    input <- trimws(input)
    
    # Handle slash commands
    if (startsWith(input, "/")) {
      result <- handle_slash_command(input, provider, conversation, max_tokens, temperature)
      if (identical(result, "exit")) break
      next
    }
    
    # Skip empty messages
    if (nchar(input) == 0) next
    
    # Process user message
    conversation$add_message("user", input)
    
    cat("RConsoleAI: ")
    if (rconsoleai_options("color_output")) {
      cat("\033[32m")
    }
    
    tryCatch({
      messages <- conversation$get_api_messages()
      
      response <- provider$chat(
        messages = messages,
        model = pm$get_model(),
        max_tokens = max_tokens %||% rconsoleai_options("max_tokens"),
        temperature = temperature
      )
      
      conversation$add_message("assistant", response)
      
      if (rconsoleai_options("color_output")) {
        cat("\033[0m")
      }
      cat(response, "\n")
      
    }, error = function(e) {
      if (rconsoleai_options("color_output")) {
        cat("\033[0m")
      }
      cat("\nError: ", e$message, "\n", sep = "")
    })
  }
  
  cat("\nGoodbye!\n")
  invisible(conversation)
}

#' Print startup banner
#' @keywords internal
print_banner <- function(provider) {
  cat("\n")
  cat("========================================\n")
  cat("          RConsoleAI\n")
  cat("      Your AI Programming Assistant\n")
  cat("========================================\n\n")
  
  cat("Provider: ", toupper(provider$name), "\n", sep = "")
  
  model_name <- pm$get_model()
  if (!is.null(model_name)) {
    cat("Model: ", model_name, "\n", sep = "")
  } else {
    cat("Model: Automatically selected\n")
  }
  
  if (provider$is_available()) {
    cat("Status: Connected\n")
  } else {
    cat("Status: \033[31mDisconnected\033[0m\n")
  }
  
  cat("\nType /help for commands.\n")
  cat("Type /exit to quit.\n")
}

#' Handle slash commands
#' @keywords internal
handle_slash_command <- function(input, provider, conversation, max_tokens, temperature) {
  parts <- strsplit(input, " ")[[1]]
  cmd <- tolower(parts[1])
  args <- parts[-1]
  
  switch(cmd,
    "/help" = print_help(),
    "/exit" = return("exit"),
    "/quit" = return("exit"),
    "/clear" = {
      conversation$clear()
      cat("Conversation cleared.\n")
    },
    "/models" = list_models(provider),
    "/model" = handle_model_command(args, provider),
    "/provider" = handle_provider_command(args),
    "/system" = handle_system_command(args, conversation),
    "/status" = print_status(provider, conversation),
    "/retry" = handle_retry(conversation, provider, max_tokens, temperature),
    "/save" = handle_save(args, conversation),
    "/load" = handle_load(args, conversation),
    "/history" = print_history(conversation),
    "/context" = print_context(),
    {
      cat("Unknown command: ", cmd, "\n", sep = "")
      cat("Type /help for available commands.\n")
    }
  )
  
  invisible(NULL)
}

#' Print help
#' @keywords internal
print_help <- function() {
  cat("\nAvailable Commands:\n")
  cat("  /help              Show this help\n")
  cat("  /exit, /quit       End chat session\n")
  cat("  /clear             Clear conversation history\n")
  cat("  /models            List available models\n")
  cat("  /model             Show current model\n")
  cat("  /model NAME        Change model\n")
  cat("  /provider          Show current provider\n")
  cat("  /provider horde    Select AI Horde\n")
  cat("  /provider gateway  Select secure backend\n")
  cat("  /provider auto     Enable auto selection\n")
  cat("  /system            Show system prompt\n")
  cat("  /system TEXT       Update system prompt\n")
  cat("  /status            Show connection and usage info\n")
  cat("  /retry             Retry previous request\n")
  cat("  /save [file]       Save conversation to file\n")
  cat("  /load [file]       Load conversation from file\n")
  cat("  /history           Show conversation history\n")
  cat("  /context           Show R environment context\n")
  cat("\n")
}

#' List available models
#' @keywords internal
list_models <- function(provider) {
  cat("\nFetching models...\n")
  models <- tryCatch(provider$get_models(), error = function(e) NULL)
  
  if (is.null(models) || length(models) == 0) {
    cat("No models available.\n")
    return()
  }
  
  cat("\nAvailable Models:\n")
  for (i, m in enumerate(models)) {
    name <- m$name %||% m$id %||% "unknown"
    workers <- m$count %||% length(m$workers %||% list())
    current <- ""
    if (!is.null(pm$get_model()) && identical(pm$get_model(), name)) {
      current <- " \033[32m(current)\033[0m"
    }
    cat(sprintf("  %d. %s (%d workers)%s\n", i, name, workers, current))
  }
  cat("\nUse /model NAME to select.\n")
}

#' Handle model command
#' @keywords internal
handle_model_command <- function(args, provider) {
  if (length(args) == 0) {
    model <- pm$get_model()
    if (is.null(model)) {
      cat("Current model: Auto-selected\n")
    } else {
      cat("Current model: ", model, "\n", sep = "")
    }
    return()
  }
  
  model_name <- paste(args, collapse = " ")
  models <- provider$get_models()
  
  # Find matching model
  found <- FALSE
  for (m in models) {
    if (identical(m$name %||% m$id, model_name)) {
      found <- TRUE
      break
    }
  }
  
  if (!found) {
    cat("Model not found: ", model_name, "\n", sep = "")
    cat("Use /models to see available models.\n")
    return()
  }
  
  pm$set_model(model_name)
  cat("Model set to: ", model_name, "\n", sep = "")
}

#' Handle provider command
#' @keywords internal
handle_provider_command <- function(args) {
  pm <- get_provider_manager()
  
  if (length(args) == 0) {
    cat("Current provider: ", pm$get_current_provider_name(), "\n", sep = "")
    return()
  }
  
  provider_name <- tolower(args[1])
  valid <- c("horde", "gateway", "auto")
  
  if (!provider_name %in% valid) {
    cat("Invalid provider: ", provider_name, "\n", sep = "")
    cat("Valid: ", paste(valid, collapse = ", "), "\n", sep = "")
    return()
  }
  
  pm$set_provider(provider_name)
  cat("Provider set to: ", provider_name, "\n", sep = "")
  
  # Verify availability
  new_provider <- tryCatch(pm$resolve_provider(), error = function(e) NULL)
  if (is.null(new_provider) || !new_provider$is_available()) {
    cat("Warning: Provider may not be available.\n")
  }
}

#' Handle system prompt command
#' @keywords internal
handle_system_command <- function(args, conversation) {
  if (length(args) == 0) {
    cat("Current system prompt:\n")
    cat(conversation$system_prompt %||% "(none)", "\n")
    return()
  }
  
  new_prompt <- paste(args, collapse = " ")
  conversation$system_prompt <- new_prompt
  rconsoleai_options(system_prompt = new_prompt)
  cat("System prompt updated.\n")
}

#' Print status
#' @keywords internal
print_status <- function(provider, conversation) {
  cat("\n--- RConsoleAI Status ---\n")
  cat("Provider: ", toupper(provider$name), "\n", sep = "")
  cat("Model: ", pm$get_model() %||% "auto", "\n", sep = "")
  cat("Available: ", ifelse(provider$is_available(), "Yes", "No"), "\n", sep = "")
  cat("Messages in conversation: ", length(conversation), "\n", sep = "")
  cat("History limit: ", rconsoleai_options("history_limit"), "\n", sep = "")
  cat("Persist history: ", rconsoleai_options("persist_history"), "\n", sep = "")
  cat("Max tokens: ", rconsoleai_options("max_tokens"), "\n", sep = "")
  cat("Timeout: ", rconsoleai_options("timeout"), "s\n", sep = "")
  cat("Gateway URL: ", rconsoleai_options("gateway_url") %||% "not set", "\n", sep = "")
  cat("-------------------------\n")
}

#' Handle retry
#' @keywords internal
handle_retry <- function(conversation, provider, max_tokens, temperature) {
  last_user <- conversation$get_last_user_message()
  if (is.null(last_user)) {
    cat("No previous message to retry.\n")
    return()
  }
  
  # Remove last assistant message if exists
  if (length(conversation$messages) > 0) {
    last_idx <- length(conversation$messages)
    if (conversation$messages[[last_idx]]$role == "assistant") {
      conversation$messages <- conversation$messages[-last_idx]
    }
  }
  
  cat("Retrying: ", last_user, "\n", sep = "")
  process_single_prompt(last_user, provider, conversation, max_tokens, temperature)
}

#' Handle save
#' @keywords internal
handle_save <- function(args, conversation) {
  file <- if (length(args) > 0) args[1] else "rconsoleai_conversation.rds"
  conversation$file_path <- normalizePath(file, mustWork = FALSE)
  conversation$save()
  cat("Conversation saved to: ", file, "\n", sep = "")
}

#' Handle load
#' @keywords internal
handle_load <- function(args, conversation) {
  file <- if (length(args) > 0) args[1] else "rconsoleai_conversation.rds"
  if (!file.exists(file)) {
    cat("File not found: ", file, "\n", sep = "")
    return()
  }
  conversation$file_path <- normalizePath(file)
  conversation$load()
  cat("Conversation loaded from: ", file, "\n", sep = "")
  cat("Messages: ", length(conversation), "\n", sep = "")
}

#' Print conversation history
#' @keywords internal
print_history <- function(conversation) {
  if (length(conversation$messages) == 0) {
    cat("No messages in history.\n")
    return()
  }
  
  cat("\n--- Conversation History ---\n")
  for (i, msg in enumerate(conversation$messages)) {
    role <- toupper(msg$role)
    content <- substr(msg$content, 1, 100)
    if (nchar(msg$content) > 100) content <- paste0(content, "...")
    cat(sprintf("%d. [%s] %s\n", i, role, content))
  }
  cat("----------------------------\n")
}

#' Print R context
#' @keywords internal
print_context <- function() {
  cat("\n--- R Environment Context ---\n")
  cat(get_r_context(), "\n")
  cat("-----------------------------\n")
}

#' Set or get chat provider
#'
#' @param provider Provider name ("horde", "gateway", "auto")
#' @return Current provider name (invisible)
#' @export
rchat_provider <- function(provider = NULL) {
  pm <- get_provider_manager()
  if (!is.null(provider)) {
    pm$set_provider(provider)
  }
  invisible(pm$get_current_provider_name())
}

#' Configure RConsoleAI
#'
#' @param provider Default provider
#' @param model Default model
#' @param gateway_url Backend gateway URL
#' @param max_tokens Maximum tokens per response
#' @param timeout Request timeout in seconds
#' @param history_limit Maximum conversation history
#' @param persist_history Whether to persist history
#' @param color_output Whether to use colored output
#' @param system_prompt Default system prompt
#' @export
rchat_config <- function(provider = NULL, model = NULL, gateway_url = NULL,
                         max_tokens = NULL, timeout = NULL,
                         history_limit = NULL, persist_history = NULL,
                         color_output = NULL, system_prompt = NULL) {
  args <- list(
    provider = provider,
    model = model,
    gateway_url = gateway_url,
    max_tokens = max_tokens,
    timeout = timeout,
    history_limit = history_limit,
    persist_history = persist_history,
    color_output = color_output,
    system_prompt = system_prompt
  )
  
  # Remove NULL values
  args <- args[!vapply(args, is.null, logical(1))]
  
  if (length(args) == 0) {
    # Show current config
    opts <- rconsoleai_options()
    cat("Current RConsoleAI Configuration:\n")
    for (name in names(opts)) {
      val <- opts[[name]]
      if (is.null(val)) val <- "NULL"
      cat(sprintf("  %s: %s\n", name, val))
    }
    return(invisible(opts))
  }
  
  # Apply provider change immediately
  if (!is.null(provider)) {
    rchat_provider(provider)
  }
  
  # Apply gateway URL to gateway provider
  if (!is.null(gateway_url)) {
    gateway <- get_provider("gateway")
    if (!is.null(gateway)) {
      gateway$gateway_url <- gateway_url
    }
  }
  
  # Set options
  do.call(rconsoleai_options, args)
  
  cat("Configuration updated.\n")
  invisible(rconsoleai_options())
}

#' List available models
#'
#' @param provider Provider name (NULL for current)
#' @return List of models
#' @export
rchat_models <- function(provider = NULL) {
  pm <- get_provider_manager()
  
  if (!is.null(provider)) {
    p <- pm$get_provider(provider)
    if (is.null(p)) {
      stop("Provider not found: ", provider)
    }
    return(p$get_models())
  }
  
  # Current provider
  current <- pm$resolve_provider()
  current$get_models()
}

#' Show conversation history
#'
#' @param conversation Conversation object (NULL for current)
#' @export
rchat_history <- function(conversation = NULL) {
  if (is.null(conversation)) {
    cat("No conversation provided. Use rchat() to start a session.\n")
    return()
  }
  print_history(conversation)
}

#' Clear conversation history
#'
#' @param conversation Conversation object
#' @export
rchat_clear <- function(conversation) {
  if (is.null(conversation)) {
    cat("No conversation provided.\n")
    return()
  }
  conversation$clear()
  cat("Conversation cleared.\n")
  invisible(conversation)
}

#' Save conversation to file
#'
#' @param conversation Conversation object
#' @param file File path
#' @export
rchat_save <- function(conversation, file = "rconsoleai_conversation.rds") {
  if (is.null(conversation)) {
    stop("No conversation provided")
  }
  conversation$file_path <- normalizePath(file, mustWork = FALSE)
  conversation$save()
  cat("Saved to: ", file, "\n", sep = "")
  invisible(conversation)
}

#' Load conversation from file
#'
#' @param file File path
#' @return Conversation object
#' @export
rchat_load <- function(file = "rconsoleai_conversation.rds") {
  if (!file.exists(file)) {
    stop("File not found: ", file)
  }
  conv <- Conversation$new(file_path = normalizePath(file))
  conv$load()
  cat("Loaded from: ", file, " (", length(conv), " messages)\n", sep = "")
  conv
}

#' Show status
#'
#' @export
rchat_status <- function() {
  pm <- get_provider_manager()
  provider <- tryCatch(pm$resolve_provider(), error = function(e) NULL)
  print_status(provider, Conversation$new())
}

#' Get or set system prompt
#'
#' @param prompt New system prompt (NULL to get current)
#' @return Current system prompt
#' @export
rchat_system_prompt <- function(prompt = NULL) {
  opts <- rconsoleai_options()
  if (is.null(prompt)) {
    return(opts$system_prompt)
  }
  rconsoleai_options(system_prompt = prompt)
  cat("System prompt updated.\n")
  invisible(prompt)
}

# Helper: enumerate for loop with index
enumerate <- function(x) {
  if (length(x) == 0) return(integer(0))
  seq_along(x)
}

`%||%` <- function(x, y) if (is.null(x)) y else x
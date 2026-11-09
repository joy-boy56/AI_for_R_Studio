#' Personal Credential Management
#'
#' Functions for managing personal API keys using the operating system
#' credential manager (via keyring package) or environment variables.
#'
#' @name rchat-credentials
#' @keywords internal
NULL

#' Set Personal API Key
#'
#' Stores an API key securely using the system credential manager (keyring)
#' or provides instructions for environment variable setup.
#'
#' @param provider Provider name ("nvidia")
#' @param key API key string (if NULL, will prompt interactively)
#' @return Invisible TRUE on success
#' @export
#' @examples
#' \dontrun{
#' # Set NVIDIA API key (will prompt if key not provided)
#' rchat_set_key("nvidia")
#' 
#' # Set key directly (less secure - visible in history)
#' rchat_set_key("nvidia", "your-api-key-here")
#' }
rchat_set_key <- function(provider = c("nvidia"), key = NULL) {
  provider <- match.arg(provider)
  
  key_name <- switch(provider,
    nvidia = "NVIDIA_API_KEY"
  )
  
  if (is.null(key)) {
    # Interactive prompt
    cat(sprintf("Enter your %s API key (input hidden): ", toupper(provider)))
    key <- readline(prompt = "")
    if (is.null(key) || nchar(trimws(key)) == 0) {
      stop("No key provided")
    }
    key <- trimws(key)
  }
  
  # Try to use keyring
  keyring_available <- requireNamespace("keyring", quietly = TRUE)
  
  if (keyring_available) {
    tryCatch({
      keyring::key_set_with_value("rconsoleai", key_name, key)
      cat(sprintf("%s key stored securely in system credential manager.\n", toupper(provider)))
      return(invisible(TRUE))
    }, error = function(e) {
      cat("Warning: Could not store in credential manager: ", e$message, "\n", sep = "")
      cat("Falling back to environment variable method.\n")
    })
  } else {
    cat("Note: Install 'keyring' package for secure credential storage.\n")
  }
  
  # Fallback: provide instructions for .Renviron
  cat(sprintf("\nTo persist this key, add to your ~/.Renviron:\n"))
  cat(sprintf("%s=\"%s\"\n", key_name, key))
  cat("\nThen restart R for changes to take effect.\n")
  
  # Set for current session
  do.call(Sys.setenv, stats::setNames(list(key), key_name))
  cat("Key set for current session.\n")
  
  invisible(TRUE)
}

#' Remove Personal API Key
#'
#' Removes a stored API key from the system credential manager.
#'
#' @param provider Provider name ("nvidia")
#' @return Invisible TRUE on success
#' @export
#' @examples
#' \dontrun{
#' rchat_remove_key("nvidia")
#' }
rchat_remove_key <- function(provider = c("nvidia")) {
  provider <- match.arg(provider)
  
  key_name <- switch(provider,
    nvidia = "NVIDIA_API_KEY"
  )
  
  # Try keyring first
  keyring_available <- requireNamespace("keyring", quietly = TRUE)
  
  if (keyring_available) {
    tryCatch({
      keyring::key_delete("rconsoleai", key_name)
      cat(sprintf("%s key removed from credential manager.\n", toupper(provider)))
      return(invisible(TRUE))
    }, error = function(e) {
      cat("Note: Key not found in credential manager or could not be removed.\n")
    })
  }
  
  # Also unset environment variable for current session
  Sys.unsetenv(key_name)
  cat("Key unset for current session.\n")
  
  cat(sprintf("\nAlso remove %s from your ~/.Renviron if present.\n", key_name))
  
  invisible(TRUE)
}

#' Test Provider Connection
#'
#' Tests the connection to a provider using current credentials.
#'
#' @param provider Provider name ("nvidia", "horde", "gateway")
#' @return List with success status and message
#' @export
#' @examples
#' \dontrun{
#' rchat_test_connection("nvidia")
#' rchat_test_connection("horde")
#' rchat_test_connection("gateway")
#' }
rchat_test_connection <- function(provider = c("nvidia", "horde", "gateway")) {
  provider <- match.arg(provider)
  
  pm <- get_provider_manager()
  
  # For explicit provider test, temporarily set and resolve
  old_provider <- pm$get_current_provider_name()
  on.exit(pm$set_provider(old_provider), add = TRUE)
  
  if (provider == "nvidia") {
    # Create temporary NVIDIA provider to test
    nvidia <- NVIDIAProvider$new()
    return(nvidia$test_connection())
  }
  
  # For other providers, use the manager
  pm$set_provider(provider)
  p <- tryCatch(pm$resolve_provider(), error = function(e) NULL)
  
  if (is.null(p)) {
    return(list(success = FALSE, message = sprintf("Provider '%s' not available", provider)))
  }
  
  available <- p$is_available()
  if (available) {
    list(success = TRUE, message = sprintf("%s provider is available", toupper(provider)))
  } else {
    list(success = FALSE, message = sprintf("%s provider is not available", toupper(provider)))
  }
}

#' Show Credential Status
#'
#' Displays which credentials are configured without revealing them.
#'
#' @return Invisible NULL
#' @export
#' @examples
#' \dontrun{
#' rchat_credential_status()
#' }
rchat_credential_status <- function() {
  cat("--- Credential Status ---\n")
  
  # NVIDIA
  nvidia_key <- NULL
  keyring_available <- requireNamespace("keyring", quietly = TRUE)
  
  if (keyring_available) {
    nvidia_key <- tryCatch({
      keyring::key_get("rconsoleai", "NVIDIA_API_KEY")
    }, error = function(e) NULL)
  }
  
  if (is.null(nvidia_key) || nchar(nvidia_key) == 0) {
    nvidia_key <- Sys.getenv("NVIDIA_API_KEY")
  }
  
  cat(sprintf("NVIDIA API Key: %s\n", 
              if (!is.null(nvidia_key) && nchar(nvidia_key) > 0) 
                "Configured (via keyring or env)" 
              else 
                "Not set"))
  
  # Gateway
  gateway_url <- rconsoleai_options("gateway_url")
  cat(sprintf("Gateway URL: %s\n", 
              if (!is.null(gateway_url) && nchar(gateway_url) > 0) 
                gateway_url 
              else 
                "Not set"))
  
  cat("------------------------\n")
  invisible(NULL)
}

#' Configure .Renviron for Windows
#'
#' Opens or creates the user's .Renviron file for editing.
#'
#' @return Invisible path to .Renviron
#' @export
#' @examples
#' \dontrun{
#' rchat_edit_renviron()
#' }
rchat_edit_renviron <- function() {
  renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")
  
  if (!file.exists(renviron_path)) {
    file.create(renviron_path)
    cat("Created new .Renviron at: ", renviron_path, "\n", sep = "")
  }
  
  if (.Platform$OS.type == "windows") {
    shell.exec(renviron_path)
  } else {
    file.edit(renviron_path)
  }
  
  cat("Add your API keys in the format:\n")
  cat("NVIDIA_API_KEY=\"your-key-here\"\n")
  cat("\nRestart R after saving.\n")
  
  invisible(renviron_path)
}
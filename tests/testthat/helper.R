# Helper functions for testing

# Mock AI Horde API responses
mock_horde_models <- function() {
  list(
    list(name = "test-model-1", count = 5, workers = list(list(id = "w1"))),
    list(name = "test-model-2", count = 3, workers = list(list(id = "w2")))
  )
}

mock_horde_submit <- function() {
  list(id = "test-job-uuid-123")
}

mock_horde_status_done <- function() {
  list(
    done = TRUE,
    faulted = FALSE,
    generations = list(list(text = "This is a test response from AI Horde."))
  )
}

mock_horde_status_pending <- function() {
  list(done = FALSE, wait_time = 10, queue_position = 1)
}

# Mock gateway responses
mock_gateway_models <- function() {
  list(models = list(
    list(name = "nvidia/nemotron-3-ultra", provider = "nvidia"),
    list(name = "gpt-3.5-turbo", provider = "openai-compatible")
  ))
}

mock_gateway_chat <- function() {
  list(choices = list(list(message = list(content = "Test response from gateway."))))
}

# Test fixtures
test_conversation <- function() {
  Conversation$new(
    system_prompt = "Test system prompt",
    max_history = 10,
    persist = FALSE
  )
}

# Skip tests if no internet
skip_if_offline <- function() {
  if (!curl::has_internet()) {
    skip("No internet connection")
  }
}

# Skip tests if R is not available
skip_if_no_r <- function() {
  if (Sys.which("R") == "") {
    skip("R not available")
  }
}
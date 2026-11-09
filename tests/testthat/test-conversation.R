# Tests for conversation.R

test_that("Conversation initializes with defaults", {
  conv <- Conversation$new(persist = FALSE)
  
  expect_equal(length(conv), 0)
  expect_false(is.null(conv$system_prompt))
  expect_equal(conv$max_history, 50)
  expect_false(conv$persist)
})

test_that("Conversation adds messages", {
  conv <- Conversation$new(persist = FALSE)
  conv$add_message("user", "Hello")
  conv$add_message("assistant", "Hi there!")
  
  expect_equal(length(conv), 2)
  expect_equal(conv$messages[[1]]$role, "user")
  expect_equal(conv$messages[[1]]$content, "Hello")
  expect_equal(conv$messages[[2]]$role, "assistant")
})

test_that("Conversation trims history", {
  conv <- Conversation$new(max_history = 3, persist = FALSE)
  
  for (i in 1:5) {
    conv$add_message("user", paste("Message", i))
  }
  
  expect_equal(length(conv), 3)
  expect_equal(conv$messages[[1]]$content, "Message 3")
  expect_equal(conv$messages[[3]]$content, "Message 5")
})

test_that("Conversation get_api_messages includes system prompt", {
  conv <- Conversation$new(system_prompt = "You are helpful", persist = FALSE)
  conv$add_message("user", "Hello")
  
  msgs <- conv$get_api_messages()
  
  expect_equal(length(msgs), 2)
  expect_equal(msgs[[1]]$role, "system")
  expect_equal(msgs[[1]]$content, "You are helpful")
  expect_equal(msgs[[2]]$role, "user")
})

test_that("Conversation clear removes all messages", {
  conv <- Conversation$new(persist = FALSE)
  conv$add_message("user", "Hello")
  conv$add_message("assistant", "Hi")
  conv$clear()
  
  expect_equal(length(conv), 0)
})

test_that("Conversation export and import work", {
  conv1 <- Conversation$new(system_prompt = "Test", persist = FALSE)
  conv1$add_message("user", "Hello")
  conv1$add_message("assistant", "Hi")
  
  data <- conv1$export()
  
  conv2 <- Conversation$new(persist = FALSE)
  conv2$import(data)
  
  expect_equal(length(conv2), 2)
  expect_equal(conv2$system_prompt, "Test")
})

test_that("Conversation get_last_user_message works", {
  conv <- Conversation$new(persist = FALSE)
  conv$add_message("user", "First")
  conv$add_message("assistant", "Response")
  conv$add_message("user", "Second")
  
  last <- conv$get_last_user_message()
  expect_equal(last, "Second")
})
# Tests for rchat.R

test_that("rchat_provider gets and sets provider", {
  # Save current
  old_provider <- rchat_provider()
  
  rchat_provider("horde")
  expect_equal(rchat_provider(), "horde")
  
  rchat_provider("gateway")
  expect_equal(rchat_provider(), "gateway")
  
  rchat_provider("auto")
  expect_equal(rchat_provider(), "auto")
  
  # Restore
  rchat_provider(old_provider)
})

test_that("rchat_config shows current config", {
  opts <- rchat_config()
  expect_type(opts, "list")
  expect_true("provider" %in% names(opts))
  expect_true("max_tokens" %in% names(opts))
})

test_that("rchat_config sets values", {
  old_max_tokens <- rconsoleai_options("max_tokens")
  
  rchat_config(max_tokens = 500)
  expect_equal(rconsoleai_options("max_tokens"), 500)
  
  rchat_config(max_tokens = old_max_tokens)
})

test_that("rchat_status runs without error", {
  # Should not error
  expect_silent(rchat_status())
})

test_that("rchat_system_prompt gets and sets", {
  old_prompt <- rchat_system_prompt()
  
  rchat_system_prompt("Test prompt")
  expect_equal(rchat_system_prompt(), "Test prompt")
  
  rchat_system_prompt(old_prompt)
})

test_that("rchat_models returns list for horde", {
  skip_if_offline()
  models <- rchat_models("horde")
  expect_type(models, "list")
})

test_that("slash command helpers work", {
  # Test print_help doesn't error
  expect_output(print_help(), "Available Commands")
  
  # Test print_status doesn't error
  conv <- Conversation$new(persist = FALSE)
  pm <- get_provider_manager()
  provider <- pm$get_provider("horde")
  expect_silent(print_status(provider, conv))
})
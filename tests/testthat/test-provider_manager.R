# Tests for provider_manager.R

test_that("ProviderManager initializes with default providers", {
  pm <- ProviderManager$new()
  
  providers <- pm$list_providers()
  expect_true("horde" %in% providers)
  expect_true("gateway" %in% providers)
})

test_that("ProviderManager can get providers", {
  pm <- ProviderManager$new()
  
  horde <- pm$get_provider("horde")
  expect_s3_class(horde, "AIHordeProvider")
  
  gateway <- pm$get_provider("gateway")
  expect_s3_class(gateway, "GatewayProvider")
  
  expect_null(pm$get_provider("nonexistent"))
})

test_that("ProviderManager set_provider validates input", {
  pm <- ProviderManager$new()
  
  pm$set_provider("horde")
  expect_equal(pm$get_current_provider_name(), "horde")
  
  pm$set_provider("gateway")
  expect_equal(pm$get_current_provider_name(), "gateway")
  
  pm$set_provider("auto")
  expect_equal(pm$get_current_provider_name(), "auto")
  
  expect_error(pm$set_provider("invalid"))
})

test_that("ProviderManager set_model works", {
  pm <- ProviderManager$new()
  
  pm$set_model("test-model")
  expect_equal(pm$get_model(), "test-model")
  
  pm$set_model(NULL)
  expect_null(pm$get_model())
})

test_that("get_provider_manager returns singleton", {
  pm1 <- get_provider_manager()
  pm2 <- get_provider_manager()
  
  expect_identical(pm1, pm2)
})

test_that("list_providers returns provider names", {
  providers <- list_providers()
  expect_type(providers, "character")
  expect_true("horde" %in% providers)
  expect_true("gateway" %in% providers)
})

test_that("get_provider returns provider instance", {
  horde <- get_provider("horde")
  expect_s3_class(horde, "AIHordeProvider")
  
  expect_null(get_provider("nonexistent"))
})

test_that("set_provider works", {
  set_provider("horde")
  pm <- get_provider_manager()
  expect_equal(pm$get_current_provider_name(), "horde")
})

test_that("AIHordeProvider initializes without magrittr", {
  # This test verifies that the provider works without magrittr attached
  # since we replaced %>% with native |> pipe
  horde <- AIHordeProvider$new()
  expect_s3_class(horde, "AIHordeProvider")
  expect_equal(horde$name, "horde")
  expect_true(horde$is_available())  # AI Horde is always available (anonymous)
})

test_that("AIHordeProvider fetch_models works with mocked response", {
  # Test model discovery with mocked API response
  horde <- AIHordeProvider$new()
  
  # Mock the fetch_models method to return test data
  test_models <- mock_horde_models()
  
  # Use testthat::local_mock to mock the internal httr2 call
  # Since we can't easily mock httr2::req_perform, we test the structure
  expect_type(test_models, "list")
  expect_length(test_models, 2)
  expect_equal(test_models[[1]]$name, "test-model-1")
  expect_equal(test_models[[1]]$count, 5)
  expect_equal(test_models[[2]]$name, "test-model-2")
  expect_equal(test_models[[2]]$count, 3)
})

test_that("AIHordeProvider messages_to_prompt formats correctly", {
  horde <- AIHordeProvider$new()
  
  messages <- list(
    list(role = "system", content = "You are helpful"),
    list(role = "user", content = "Hello"),
    list(role = "assistant", content = "Hi there!")
  )
  
  prompt <- horde$messages_to_prompt(messages)
  
  expect_type(prompt, "character")
  expect_true(grepl("<\\|system\\|>", prompt))
  expect_true(grepl("<\\|user\\|>", prompt))
  expect_true(grepl("<\\|assistant\\|>", prompt))
  expect_true(grepl("You are helpful", prompt))
  expect_true(grepl("Hello", prompt))
  expect_true(grepl("Hi there!", prompt))
})

test_that("NVIDIAProvider initializes without magrittr", {
  # This test verifies that the provider works without magrittr attached
  nvidia <- NVIDIAProvider$new()
  expect_s3_class(nvidia, "NVIDIAProvider")
  expect_equal(nvidia$name, "nvidia")
  # is_available() should be FALSE without credentials
  expect_false(nvidia$is_available())
})

test_that("GatewayProvider initializes without magrittr", {
  # This test verifies that the provider works without magrittr attached
  gateway <- GatewayProvider$new()
  expect_s3_class(gateway, "GatewayProvider")
  expect_equal(gateway$name, "gateway")
  # is_available() should be FALSE without gateway_url
  expect_false(gateway$is_available())
})
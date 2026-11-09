# Tests for providers.R

test_that("ProviderError classes can be instantiated", {
  err <- ProviderError$new("Test error", provider = "test")
  expect_s3_class(err, "ProviderError")
  expect_equal(err$provider, "test")
  expect_equal(err$message, "Test error")
})

test_that("TimeoutError inherits from ProviderError", {
  err <- TimeoutError$new("Timeout", provider = "test")
  expect_s3_class(err, "TimeoutError")
  expect_s3_class(err, "ProviderError")
})

test_that("RateLimitError inherits from ProviderError", {
  err <- RateLimitError$new("Rate limited", provider = "test")
  expect_s3_class(err, "RateLimitError")
})

test_that("AuthenticationError inherits from ProviderError", {
  err <- AuthenticationError$new("Auth failed", provider = "test")
  expect_s3_class(err, "AuthenticationError")
})

test_that("ModelNotFoundError inherits from ProviderError", {
  err <- ModelNotFoundError$new("Model not found", provider = "test")
  expect_s3_class(err, "ModelNotFoundError")
})

test_that("ProviderUnavailableError inherits from ProviderError", {
  err <- ProviderUnavailableError$new("Unavailable", provider = "test")
  expect_s3_class(err, "ProviderUnavailableError")
})
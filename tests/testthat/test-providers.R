# Tests for providers.R

test_that("ProviderError condition can be created", {
  err <- ProviderError("Test error", provider = "test")
  expect_s3_class(err, "ProviderError")
  expect_s3_class(err, "error")
  expect_s3_class(err, "condition")
  expect_equal(err$provider, "test")
  expect_equal(err$message, "Test error")
})

test_that("TimeoutError inherits from ProviderError", {
  err <- TimeoutError("Timeout", provider = "test")
  expect_s3_class(err, "TimeoutError")
  expect_s3_class(err, "ProviderError")
})

test_that("RateLimitError inherits from ProviderError", {
  err <- RateLimitError("Rate limited", provider = "test")
  expect_s3_class(err, "RateLimitError")
  expect_s3_class(err, "ProviderError")
})

test_that("AuthenticationError inherits from ProviderError", {
  err <- AuthenticationError("Auth failed", provider = "test")
  expect_s3_class(err, "AuthenticationError")
  expect_s3_class(err, "ProviderError")
})

test_that("ModelNotFoundError inherits from ProviderError", {
  err <- ModelNotFoundError("Model not found", provider = "test")
  expect_s3_class(err, "ModelNotFoundError")
  expect_s3_class(err, "ProviderError")
})

test_that("ProviderUnavailableError inherits from ProviderError", {
  err <- ProviderUnavailableError("Unavailable", provider = "test")
  expect_s3_class(err, "ProviderUnavailableError")
  expect_s3_class(err, "ProviderError")
})

test_that("Provider errors can be caught with tryCatch", {
  expect_error(stop(ProviderError("test")), class = "ProviderError")
  expect_error(stop(TimeoutError("test")), class = "TimeoutError")
  expect_error(stop(RateLimitError("test")), class = "RateLimitError")
  expect_error(stop(AuthenticationError("test")), class = "AuthenticationError")
  expect_error(stop(ModelNotFoundError("test")), class = "ModelNotFoundError")
  expect_error(stop(ProviderUnavailableError("test")), class = "ProviderUnavailableError")
})

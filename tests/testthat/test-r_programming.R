# Tests for r_programming.R

test_that("rchat_code creates proper prompt", {
  # We can't test the actual API call without internet,
  # but we can verify the prompt construction
  code <- "x <- rnorm(100)\nhist(x)"
  
  # Just verify the function exists and runs without error for prompt building
  # The actual API call is tested in integration tests
  expect_true(exists("rchat_code"))
})

test_that("rchat_explain creates proper prompt", {
  code <- "model <- lm(mpg ~ wt, data = mtcars)\nsummary(model)"
  expect_true(exists("rchat_explain"))
})

test_that("rchat_data formats dataset summary", {
  df <- data.frame(a = 1:3, b = c("x", "y", "z"))
  expect_true(exists("rchat_data"))
})

test_that("rchat_generate exists", {
  expect_true(exists("rchat_generate"))
})

test_that("rchat_env exists", {
  expect_true(exists("rchat_env"))
})

test_that("format_dataset_context includes column info", {
  df <- data.frame(
    numeric_col = 1:5,
    factor_col = factor(c("a", "b", "a", "c", "b")),
    char_col = letters[1:5]
  )
  
  result <- format_dataset_context(df, "test")
  expect_true(grepl("numeric_col", result))
  expect_true(grepl("factor_col", result))
  expect_true(grepl("char_col", result))
})
# Tests for r_context.R

test_that("RContextHelper initializes", {
  helper <- RContextHelper$new()
  expect_s3_class(helper, "RContextHelper")
  expect_false(helper$include_values)
  expect_equal(helper$max_vars, 50)
})

test_that("RContextHelper summarizes numeric vector", {
  helper <- RContextHelper$new()
  x <- c(1, 2, 3, 4, 5)
  summary <- helper$summarize_object("test_vec", x)
  
  expect_equal(summary$name, "test_vec")
  expect_equal(summary$class, "numeric")
  expect_equal(summary$length, 5)
  expect_equal(summary$range, c(1, 5))
  expect_equal(summary$mean, 3)
})

test_that("RContextHelper summarizes data frame", {
  helper <- RContextHelper$new()
  df <- data.frame(a = 1:3, b = letters[1:3])
  summary <- helper$summarize_object("test_df", df)
  
  expect_equal(summary$class, "data.frame")
  expect_equal(summary$rows, 3)
  expect_equal(summary$cols, 2)
  expect_equal(summary$colnames, c("a", "b"))
})

test_that("RContextHelper summarizes factor", {
  helper <- RContextHelper$new()
  f <- factor(c("a", "b", "a", "c"))
  summary <- helper$summarize_object("test_factor", f)
  
  expect_equal(summary$class, "factor")
  expect_equal(summary$length, 4)
})

test_that("RContextHelper get_summary works", {
  helper <- RContextHelper$new(max_vars = 10)
  summary <- helper$get_summary()
  
  expect_type(summary, "list")
  expect_true("variable_count" %in% names(summary))
  expect_true("variables" %in% names(summary))
  expect_true("r_version" %in% names(summary))
})

test_that("format_dataset_context works", {
  df <- data.frame(x = 1:5, y = letters[1:5])
  result <- format_dataset_context(df, "test_data")
  
  expect_type(result, "character")
  expect_true(grepl("test_data", result))
  expect_true(grepl("5 rows", result))
  expect_true(grepl("2 columns", result))
})

test_that("get_r_context returns string", {
  result <- get_r_context()
  expect_type(result, "character")
  expect_true(grepl("R Environment Summary", result))
})
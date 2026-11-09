# Tests for options.R

test_that("rconsoleai_options returns defaults when empty", {
  rconsoleai_reset_options()
  opts <- rconsoleai_options()
  
  expect_type(opts, "list")
  expect_equal(opts$provider, "auto")
  expect_equal(opts$max_tokens, 700)
  expect_equal(opts$timeout, 90)
  expect_equal(opts$history_limit, 50)
  expect_true(opts$persist_history)
  expect_true(opts$color_output)
})

test_that("rconsoleai_options can get and set values", {
  rconsoleai_options(test_option = "test_value")
  expect_equal(rconsoleai_options("test_option"), "test_value")
  
  rconsoleai_options(test_option = "new_value")
  expect_equal(rconsoleai_options("test_option"), "new_value")
})

test_that("rconsoleai_reset_options restores defaults", {
  rconsoleai_options(provider = "horde", max_tokens = 100)
  rconsoleai_reset_options()
  
  opts <- rconsoleai_options()
  expect_equal(opts$provider, "auto")
  expect_equal(opts$max_tokens, 700)
})
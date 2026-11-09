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
test_that("select_best_model selects by MSPE", {
  gt_obj <- make_mock_gt_object(n_times = 5)
  models <- build_model_specs(c("linear", "quadratic"))

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = c(1, 2),
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  best <- select_best_model(cv_result, criterion = "mspe")

  expect_type(best, "character")
  expect_length(best, 1)
  expect_true(best %in% names(models))

  # Should match cv_result$best_model
  expect_equal(best, cv_result$best_model)
})

test_that("select_best_model validates input", {
  expect_error(
    select_best_model(list(), criterion = "mspe"),
    "must be a cv_extrapolate object"
  )
})

test_that("select_best_model requires coverage for coverage criterion", {
  gt_obj <- make_mock_gt_object(n_times = 5)
  models <- build_model_specs("linear")

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 6,
    compute_coverage = FALSE  # No coverage
  )

  expect_error(
    select_best_model(cv_result, criterion = "coverage"),
    "requires coverage to be computed"
  )
})

test_that("select_best_model coverage criterion works", {
  gt_obj <- make_mock_gt_object(n = 100, n_times = 5)
  models <- build_model_specs(c("linear", "quadratic"))

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = c(1, 2),
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = TRUE
  )

  best <- select_best_model(cv_result, criterion = "coverage", tolerance = 0.2)

  expect_type(best, "character")
  expect_length(best, 1)
  expect_true(best %in% names(models))
})

test_that("select_best_model combined criterion works", {
  gt_obj <- make_mock_gt_object(n = 100, n_times = 5)
  models <- build_model_specs(c("linear", "quadratic"))

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = c(1, 2),
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = TRUE
  )

  best <- select_best_model(cv_result, criterion = "combined")

  expect_type(best, "character")
  expect_length(best, 1)
  expect_true(best %in% names(models))
})

test_that("select_best_model handles custom target_coverage", {
  gt_obj <- make_mock_gt_object(n = 100, n_times = 5)
  models <- build_model_specs("linear")

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 6,
    compute_coverage = TRUE,
    level = 0.90
  )

  best <- select_best_model(cv_result, criterion = "coverage", target_coverage = 0.90)

  expect_type(best, "character")
})

test_that("select_best_model validates target_coverage", {
  gt_obj <- make_mock_gt_object(n = 100, n_times = 5)
  models <- build_model_specs("linear")

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 6,
    compute_coverage = TRUE
  )

  expect_error(
    select_best_model(cv_result, criterion = "coverage", target_coverage = 1.5),
    "must be in \\(0, 1\\)"
  )
})

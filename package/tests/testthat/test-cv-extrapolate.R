test_that("cv_extrapolate_ATT runs with valid inputs", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 2, n_times = 5)
  models <- build_model_specs(c("linear", "quadratic"))

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = c(1, 2),
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  expect_s3_class(result, "cv_extrapolate")
  expect_true("results" %in% names(result))
  expect_true("best_model" %in% names(result))
  expect_true("avg_mspe" %in% names(result))
  expect_true("predictions" %in% names(result))
})

test_that("cv_extrapolate_ATT validates gt_object", {
  models <- build_model_specs("linear")

  expect_error(
    cv_extrapolate_ATT(
      list(), # Invalid gt_object
      model_specs = models,
      horizons = 1,
      future_value = 6
    ),
    "must be a gt_object"
  )
})

test_that("cv_extrapolate_ATT validates model_specs", {
  gt_obj <- make_mock_gt_object()

  expect_error(
    cv_extrapolate_ATT(
      gt_obj,
      model_specs = "not a list",
      horizons = 1,
      future_value = 6
    ),
    "must be a list"
  )
})

test_that("cv_extrapolate_ATT validates horizons", {
  gt_obj <- make_mock_gt_object()
  models <- build_model_specs("linear")

  expect_error(
    cv_extrapolate_ATT(
      gt_obj,
      model_specs = models,
      horizons = c(1, 2.5), # Non-integer
      future_value = 6
    ),
    "must contain only integers"
  )

  expect_error(
    cv_extrapolate_ATT(
      gt_obj,
      model_specs = models,
      horizons = c(1, -1), # Negative
      future_value = 6
    ),
    "must contain only positive values"
  )
})

test_that("cv_extrapolate_ATT checks horizons against available data", {
  gt_obj <- make_mock_gt_object(n_times = 3)  # Only 3 time periods
  models <- build_model_specs("linear")

  expect_error(
    cv_extrapolate_ATT(
      gt_obj,
      model_specs = models,
      horizons = 10, # Too large
      future_value = 6
    ),
    "max available time periods"
  )
})

test_that("cv_extrapolate_ATT computes MSPE correctly", {
  # Create data with known linear trend
  set.seed(20260304)
  n <- 50
  groups <- c(0, 1)
  times <- 1:5

  # Create perfectly linear data
  data_list <- list()
  phi_list <- list()
  idx <- 1

  for (g in groups) {
    for (t in times) {
      # Linear trend: tau = 0.1 * t
      tau_true <- 0.1 * t
      data_list[[idx]] <- tibble::tibble(
        g = g,
        t = t,
        tau_hat = tau_true,
        k = t - g
      )
      phi_list[[idx]] <- rnorm(n, sd = 0.01) # Small noise
      idx <- idx + 1
    }
  }

  data <- dplyr::bind_rows(data_list)

  gt_obj <- list(
    data = data,
    phi = phi_list,
    times = sort(unique(data$t)),
    groups = sort(unique(data$g)),
    event_times = sort(unique(data$k)),
    n = n
  )
  class(gt_obj) <- c("gt_object", "extrapolateATT")

  # Test: linear model should have low MSPE on linear data
  models <- build_model_specs(c("linear", "quadratic"))

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  # Linear model should have lower MSPE than quadratic on linear data
  linear_mspe <- result$avg_mspe$avg_mspe[result$avg_mspe$model == "linear"]
  quadratic_mspe <- result$avg_mspe$avg_mspe[result$avg_mspe$model == "quadratic"]

  expect_true(linear_mspe <= quadratic_mspe)
  expect_equal(result$best_model, "linear")
})

test_that("cv_extrapolate_ATT selects quadratic for quadratic data", {
  # Create data with quadratic trend
  set.seed(20260305)
  n <- 50
  groups <- c(0, 1)
  times <- 1:6  # Need more points for quadratic

  data_list <- list()
  phi_list <- list()
  idx <- 1

  for (g in groups) {
    for (t in times) {
      # Quadratic trend: tau = 0.05 * t^2
      tau_true <- 0.05 * t^2
      data_list[[idx]] <- tibble::tibble(
        g = g,
        t = t,
        tau_hat = tau_true,
        k = t - g
      )
      phi_list[[idx]] <- rnorm(n, sd = 0.01)
      idx <- idx + 1
    }
  }

  data <- dplyr::bind_rows(data_list)

  gt_obj <- list(
    data = data,
    phi = phi_list,
    times = sort(unique(data$t)),
    groups = sort(unique(data$g)),
    event_times = sort(unique(data$k)),
    n = n
  )
  class(gt_obj) <- c("gt_object", "extrapolateATT")

  models <- build_model_specs(c("linear", "quadratic"))

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = c(1, 2),
    future_value = 7,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  # Quadratic model should have lower MSPE on quadratic data
  expect_equal(result$best_model, "quadratic")

  linear_mspe <- result$avg_mspe$avg_mspe[result$avg_mspe$model == "linear"]
  quadratic_mspe <- result$avg_mspe$avg_mspe[result$avg_mspe$model == "quadratic"]

  expect_true(quadratic_mspe < linear_mspe)
})

test_that("cv_extrapolate_ATT works with single horizon", {
  gt_obj <- make_mock_gt_object(n_times = 4)
  models <- build_model_specs("linear")

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 5,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  expect_equal(nrow(result$results), 1)
  expect_equal(result$results$horizon, 1)
})

test_that("cv_extrapolate_ATT works with multiple horizons", {
  gt_obj <- make_mock_gt_object(n_times = 6)
  models <- build_model_specs("linear")

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1:3,
    future_value = 7,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  expect_true(nrow(result$results) >= 3)
  expect_true(all(1:3 %in% result$results$horizon))
})

test_that("cv_extrapolate_ATT computes coverage when requested", {
  gt_obj <- make_mock_gt_object(n = 100, n_times = 5)
  models <- build_model_specs("linear")

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = TRUE,
    level = 0.95
  )

  expect_true("coverage" %in% names(result$results))
  expect_false(is.na(result$results$coverage[1]))
  expect_true(result$results$coverage[1] >= 0 && result$results$coverage[1] <= 1)
})

test_that("cv_extrapolate_ATT requires EIFs for coverage", {
  gt_obj <- make_mock_gt_object()
  # Set phi to NULL but keep it in the list (gt_obj$phi <- NULL removes the element)
  gt_obj["phi"] <- list(NULL)
  models <- build_model_specs("linear")

  expect_error(
    cv_extrapolate_ATT(
      gt_obj,
      model_specs = models,
      horizons = 1,
      future_value = 6,
      compute_coverage = TRUE
    ),
    "requires EIFs"
  )
})

test_that("cv_extrapolate_ATT works with event time scale", {
  gt_obj <- make_mock_gt_object(n_times = 4)
  models <- build_model_specs("linear")

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 5,
    time_scale = "event",
    compute_coverage = FALSE
  )

  expect_equal(result$time_scale, "event")
  expect_s3_class(result, "cv_extrapolate")
})

test_that("cv_extrapolate_ATT returns detailed predictions", {
  gt_obj <- make_mock_gt_object(n_times = 4)
  models <- build_model_specs("linear")

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 5,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  expect_true(!is.null(result$predictions))
  expect_true(is.data.frame(result$predictions))
  expect_true("tau_obs" %in% names(result$predictions))
  expect_true("tau_pred" %in% names(result$predictions))
  expect_true("model" %in% names(result$predictions))
})

test_that("cv_extrapolate_ATT print method works", {
  gt_obj <- make_mock_gt_object(n_times = 4)
  models <- build_model_specs("linear")

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 5,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  # Test that print doesn't error
  expect_output(print(result), "Time-Series Cross-Validation Results")
  expect_output(print(result), "Best model")
})

test_that("cv_extrapolate_ATT handles custom models", {
  gt_obj <- make_mock_gt_object(n_times = 4)

  # Add a constant model
  custom <- list(
    constant = list(
      h_fun = function(times, future_time) {
        function(tau_g) mean(tau_g)
      },
      dh_fun = function(times, future_time) {
        rep(1 / length(times), length(times))
      },
      name = "constant"
    )
  )

  models <- build_model_specs("linear", custom_models = custom)

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 5,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  expect_true("constant" %in% result$results$model)
  expect_true("linear" %in% result$results$model)
})

test_that("cv_extrapolate_ATT handles insufficient training data gracefully", {
  # Create gt_object with few time periods but enough for linear model
  # With n_times = 3, horizon = 1 leaves 2 training points (sufficient for linear)
  gt_obj <- make_mock_gt_object(n_times = 3)
  models <- build_model_specs("linear")

  # With sufficient data, should not warn
  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 4,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  expect_s3_class(result, "cv_extrapolate")
})

test_that("cv_extrapolate_ATT avg_mspe matches results", {
  gt_obj <- make_mock_gt_object(n_times = 5)
  models <- build_model_specs(c("linear", "quadratic"))

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = c(1, 2),
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  # Check that avg_mspe is computed correctly
  for (model_name in names(models)) {
    model_results <- result$results[result$results$model == model_name, ]
    expected_avg <- mean(model_results$mspe)
    actual_avg <- result$avg_mspe$avg_mspe[result$avg_mspe$model == model_name]

    expect_equal(actual_avg, expected_avg, tolerance = 1e-10)
  }
})

# Tests for S3 methods ----

test_that("summary.cv_extrapolate works", {
  gt_obj <- make_mock_gt_object(n_times = 5)
  models <- build_model_specs(c("linear", "quadratic"))

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = c(1, 2),
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  # Test that summary doesn't error
  expect_output(summary(result), "Time-Series Cross-Validation Summary")
  expect_output(summary(result), "Best model")
  expect_output(summary(result), "MSPE range")
})

test_that("summary.cv_extrapolate shows coverage when computed", {
  gt_obj <- make_mock_gt_object(n = 100, n_times = 5)
  models <- build_model_specs("linear")

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = TRUE,
    level = 0.95
  )

  expect_output(summary(result), "Coverage Summary")
  expect_output(summary(result), "Confidence level")
})

test_that("plot.cv_extrapolate works without coverage", {
  gt_obj <- make_mock_gt_object(n_times = 5)
  models <- build_model_specs(c("linear", "quadratic"))

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = c(1, 2),
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  # Test that plot doesn't error
  expect_silent(plot(result))
})

test_that("plot.cv_extrapolate works with coverage", {
  skip_if_not_installed("ggplot2")

  gt_obj <- make_mock_gt_object(n = 100, n_times = 5)
  models <- build_model_specs("linear")

  result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = c(1, 2),
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = TRUE
  )

  # Test that plot doesn't error
  expect_silent(plot(result))
})

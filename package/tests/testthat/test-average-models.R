test_that("average_models runs with valid inputs", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 2, n_times = 5)
  models <- build_model_specs(c("linear", "quadratic"))

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = c(1, 2),
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  result <- average_models(
    cv_result,
    gt_obj,
    future_value = 6,
    time_scale = "calendar",
    temperature = 1,
    per_group = TRUE
  )

  expect_s3_class(result, "extrap_object_averaged")
  expect_s3_class(result, "extrap_object")
  expect_true("weights" %in% names(result))
  expect_true("tau_g_future" %in% names(result))
  expect_true("phi_g_future" %in% names(result))
})

test_that("average_models validates inputs", {
  gt_obj <- make_mock_gt_object()
  models <- build_model_specs("linear")

  expect_error(
    average_models(
      list(),  # Invalid cv_result
      gt_obj,
      future_value = 6
    ),
    "must be a cv_extrapolate object"
  )
})

test_that("average_models weights sum to 1", {
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

  result <- average_models(
    cv_result,
    gt_obj,
    future_value = 6,
    time_scale = "calendar"
  )

  expect_equal(sum(result$weights), 1, tolerance = 1e-10)
  expect_length(result$weights, length(models))
})

test_that("average_models exponential weights prioritize low MSPE", {
  # Create data where linear is clearly better
  set.seed(20260306)
  n <- 50
  groups <- c(0, 1)
  times <- 1:6

  data_list <- list()
  phi_list <- list()
  idx <- 1

  for (g in groups) {
    for (t in times) {
      # Linear trend
      tau_true <- 0.1 * t
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

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = c(1, 2),
    future_value = 7,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  # With default temperature = 1
  result <- average_models(cv_result, gt_obj, future_value = 7, time_scale = "calendar")

  # Check that model with lower MSPE gets higher weight
  best_model <- cv_result$best_model
  worst_model <- setdiff(names(models), best_model)

  expect_true(result$weights[best_model] >= result$weights[worst_model])
})

test_that("average_models temperature affects weight concentration", {
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

  # Low temperature (more concentrated)
  result_low <- average_models(cv_result, gt_obj, future_value = 6,
                                time_scale = "calendar", temperature = 0.1)

  # High temperature (more uniform)
  result_high <- average_models(cv_result, gt_obj, future_value = 6,
                                 time_scale = "calendar", temperature = 10)

  # Low temp should have more extreme weights (higher entropy)
  weight_range_low <- diff(range(result_low$weights))
  weight_range_high <- diff(range(result_high$weights))

  expect_true(weight_range_low >= weight_range_high)
})

test_that("average_models propagates EIFs correctly", {
  gt_obj <- make_mock_gt_object(n = 100, n_groups = 2, n_times = 5)
  models <- build_model_specs(c("linear", "quadratic"))

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  result <- average_models(cv_result, gt_obj, future_value = 6, time_scale = "calendar")

  # Check phi_g_future structure
  expect_type(result$phi_g_future, "list")
  expect_length(result$phi_g_future, length(gt_obj$groups))

  # Each phi should be a numeric vector of length n
  for (phi in result$phi_g_future) {
    expect_type(phi, "double")
    expect_length(phi, gt_obj$n)
  }

  # Variance should be positive
  for (phi in result$phi_g_future) {
    var_est <- mean(phi^2)
    expect_true(var_est > 0)
  }
})

test_that("average_models aggregates when per_group = FALSE", {
  gt_obj <- make_mock_gt_object(n_times = 5)
  models <- build_model_specs("linear")

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  omega <- c(0.6, 0.4)
  result <- average_models(
    cv_result,
    gt_obj,
    future_value = 6,
    time_scale = "calendar",
    omega = omega,
    per_group = FALSE
  )

  expect_true("tau_future" %in% names(result))
  expect_true("phi_future" %in% names(result))
  expect_type(result$tau_future, "double")
  expect_length(result$tau_future, 1)
  expect_type(result$phi_future, "double")
  expect_length(result$phi_future, gt_obj$n)
})

test_that("average_models requires omega for aggregation", {
  gt_obj <- make_mock_gt_object(n_times = 5)
  models <- build_model_specs("linear")

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  expect_error(
    average_models(cv_result, gt_obj, future_value = 6,
                   time_scale = "calendar", per_group = FALSE),
    "omega is required"
  )
})

test_that("average_models validates temperature", {
  gt_obj <- make_mock_gt_object(n_times = 5)
  models <- build_model_specs("linear")

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  expect_error(
    average_models(cv_result, gt_obj, future_value = 6,
                   time_scale = "calendar", temperature = 0),
    "must be positive"
  )

  expect_error(
    average_models(cv_result, gt_obj, future_value = 6,
                   time_scale = "calendar", temperature = -1),
    "must be positive"
  )
})

test_that("average_models print method works", {
  gt_obj <- make_mock_gt_object(n_times = 5)
  models <- build_model_specs(c("linear", "quadratic"))

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  result <- average_models(cv_result, gt_obj, future_value = 6, time_scale = "calendar")

  expect_output(print(result), "Model-Averaged Extrapolation")
  expect_output(print(result), "Model weights")
})

test_that("average_models handles uniform MSPE gracefully", {
  gt_obj <- make_mock_gt_object(n_times = 4)

  # Create a model where both will have same MSPE (constant model)
  custom <- list(
    const1 = list(
      h_fun = function(times, future_time) function(tau_g) mean(tau_g),
      dh_fun = function(times, future_time) rep(1/length(times), length(times)),
      name = "const1"
    ),
    const2 = list(
      h_fun = function(times, future_time) function(tau_g) mean(tau_g),
      dh_fun = function(times, future_time) rep(1/length(times), length(times)),
      name = "const2"
    )
  )

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = custom,
    horizons = 1,
    future_value = 5,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  expect_message(
    result <- average_models(cv_result, gt_obj, future_value = 5, time_scale = "calendar"),
    "uniform weights"
  )

  # Weights should be equal (strip names for comparison)
  expect_equal(as.numeric(result$weights["const1"]), as.numeric(result$weights["const2"]), tolerance = 1e-10)
  expect_equal(as.numeric(result$weights["const1"]), 0.5, tolerance = 1e-10)
})

test_that("average_models matches manual weighted average", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 2, n_times = 5)
  models <- build_model_specs(c("linear", "quadratic"))

  cv_result <- cv_extrapolate_ATT(
    gt_obj,
    model_specs = models,
    horizons = 1,
    future_value = 6,
    time_scale = "calendar",
    compute_coverage = FALSE
  )

  result_avg <- average_models(cv_result, gt_obj, future_value = 6, time_scale = "calendar")

  # Manually compute weighted average
  result_linear <- extrapolate_ATT(gt_obj, h_fun = hg_linear, dh_fun = dh_linear,
                                   future_value = 6, time_scale = "calendar", per_group = TRUE)
  result_quad <- extrapolate_ATT(gt_obj, h_fun = hg_quadratic, dh_fun = dh_quadratic,
                                 future_value = 6, time_scale = "calendar", per_group = TRUE)

  w_linear <- result_avg$weights["linear"]
  w_quad <- result_avg$weights["quadratic"]

  manual_tau <- result_linear$tau_g_future$tau_future * w_linear +
                result_quad$tau_g_future$tau_future * w_quad

  expect_equal(result_avg$tau_g_future$tau_future, manual_tau, tolerance = 1e-10)
})

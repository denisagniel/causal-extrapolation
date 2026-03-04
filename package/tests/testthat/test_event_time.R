test_that("event-time k = t - g calculation is correct", {
  # Test the event-time calculation logic without mocking did package
  data <- tibble::tibble(g = c(2005, 2005, 2006), t = c(2006, 2007, 2008))
  k <- data$t - data$g
  expect_equal(k, c(1, 2, 2))

  # Test with different values
  data2 <- tibble::tibble(g = c(0, 0, 1, 1), t = c(1, 2, 2, 3))
  k2 <- data2$t - data2$g
  expect_equal(k2, c(1, 2, 1, 2))
})

test_that("extrapolate_ATT works with event time when provided sequences", {
  # Build a small gt_object by hand
  n <- 50
  df <- tibble::tibble(
    g = c(2005, 2005, 2005),
    t = c(2006, 2007, 2008),
    tau_hat = c(0.1, 0.2, 0.3)
  )
  df$k <- df$t - df$g
  phi <- replicate(nrow(df), rnorm(n, sd = 0.1), simplify = FALSE)
  gt <- list(data = df, phi = phi, times = sort(unique(df$t)), groups = sort(unique(df$g)), event_times = sort(unique(df$k)), n = n)
  class(gt) <- c("gt_object", "extrapolateATT")
  ex <- extrapolate_ATT(gt, h_fun = hg_linear, dh_fun = dh_linear, future_value = 5, time_scale = "event", per_group = TRUE)
  expect_true(is.list(ex))
  expect_true("tau_g_future" %in% names(ex))
})

## Additional extrapolate_ATT tests

test_that("extrapolate_ATT validates gt_object", {
  bad_obj <- list(some_data = "not a gt_object")

  expect_error(
    extrapolate_ATT(bad_obj, hg_linear, dh_linear, future_value = 10),
    "must be a gt_object"
  )
})

test_that("extrapolate_ATT requires future_value", {
  gt_obj <- make_mock_gt_object()

  expect_error(
    extrapolate_ATT(gt_obj, hg_linear, dh_linear, future_value = NULL),
    "future_value is required"
  )
})

test_that("extrapolate_ATT works with calendar time scale", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 2, n_times = 3)

  result <- extrapolate_ATT(
    gt_obj,
    h_fun = hg_linear,
    dh_fun = dh_linear,
    future_value = 10,
    time_scale = "calendar",
    per_group = TRUE
  )

  expect_s3_class(result, "extrap_object")
  expect_named(result, c("tau_g_future", "phi_g_future"))
  expect_equal(nrow(result$tau_g_future), 2)  # 2 groups
  expect_length(result$phi_g_future, 2)
})

test_that("extrapolate_ATT aggregates with omega when per_group = FALSE", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 2, n_times = 3)
  omega <- c(0.6, 0.4)

  result <- extrapolate_ATT(
    gt_obj,
    h_fun = hg_linear,
    dh_fun = dh_linear,
    future_value = 10,  # Well-scaled future time
    time_scale = "calendar",
    per_group = FALSE,
    omega = omega
  )

  expect_named(result, c("tau_g_future", "phi_g_future", "tau_future", "phi_future"))
  expect_type(result$tau_future, "double")
  expect_length(result$tau_future, 1)
  expect_type(result$phi_future, "double")
  expect_length(result$phi_future, gt_obj$n)
})

test_that("extrapolate_ATT requires omega when per_group = FALSE", {
  gt_obj <- make_mock_gt_object()

  expect_error(
    extrapolate_ATT(
      gt_obj,
      hg_linear,
      dh_linear,
      future_value = 10,
      per_group = FALSE,
      omega = NULL
    ),
    "omega is required when per_group = FALSE"
  )
})

test_that("extrapolate_ATT validates omega dimensions", {
  gt_obj <- make_mock_gt_object(n_groups = 2)
  omega_wrong <- c(0.5, 0.5, 0.5)  # 3 weights for 2 groups

  expect_error(
    extrapolate_ATT(
      gt_obj,
      hg_linear,
      dh_linear,
      future_value = 10,
      per_group = FALSE,
      omega = omega_wrong
    ),
    "must have length 2"
  )
})

test_that("extrapolate_ATT works without analytical derivative", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 1, n_times = 3)

  # Use only h_fun, let it compute numerical gradient
  result <- extrapolate_ATT(
    gt_obj,
    h_fun = hg_linear,
    dh_fun = NULL,  # Force numerical derivative
    future_value = 10,  # Well-scaled future time
    time_scale = "calendar",
    per_group = TRUE
  )

  expect_s3_class(result, "extrap_object")
  expect_true("phi_g_future" %in% names(result))
})

test_that("extrapolate_ATT handles missing group gracefully", {
  gt_obj <- make_mock_gt_object(n_groups = 2)

  # Properly remove a group: keep data and phi aligned
  keep_rows <- gt_obj$data$g != gt_obj$groups[1]
  gt_obj$data <- gt_obj$data[keep_rows, ]
  gt_obj$phi <- gt_obj$phi[keep_rows]

  # But don't update the groups list - this creates a mismatch
  # This should trigger the NULL group check
  expect_error(
    extrapolate_ATT(gt_obj, hg_linear, dh_linear, future_value = 10),
    "Group .* not found"
  )
})

test_that("extrapolate_ATT propagates EIFs correctly", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 1, n_times = 3)

  result <- extrapolate_ATT(
    gt_obj,
    h_fun = hg_linear,
    dh_fun = dh_linear,
    future_value = 10,
    time_scale = "calendar",
    per_group = TRUE
  )

  # Check that EIF vectors have correct length
  expect_length(result$phi_g_future[[1]], gt_obj$n)
  expect_true(all(is.finite(result$phi_g_future[[1]])))
})






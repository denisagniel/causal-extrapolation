test_that("path1_aggregate computes group averages", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 2, n_times = 3)
  omega <- c(0.6, 0.4)

  result <- path1_aggregate(gt_obj, omega)

  expect_type(result, "list")
  expect_named(result, c("tau_future", "phi_future", "tau_g", "phi_g"))
  expect_length(result$tau_g, 2)
  expect_length(result$phi_g, 2)
  expect_type(result$tau_future, "double")
  expect_length(result$tau_future, 1)
  expect_length(result$phi_future, 50)
})

test_that("path1_aggregate(weighting = 'gls-joint') requires ids and errors clearly without", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 2, n_times = 3)
  expect_null(gt_obj$ids)

  expect_error(
    path1_aggregate(gt_obj, omega = c(0.5, 0.5), weighting = "gls-joint"),
    "ids"
  )
})

test_that("path1_aggregate(weighting = 'gls-joint') bypasses the two-step structure end to end", {
  set.seed(20260925)
  n <- 300
  data <- expand.grid(t = 1:3, g = 0:1)[, c("g", "t")]
  data <- tibble::as_tibble(data)
  data$tau_hat <- c(0.4, 0.45, 0.5, 0.6, 0.65, 0.7)
  data$k <- data$t - data$g

  # Cells within a group share a group-specific comparator component, so the joint
  # covariance is genuinely non-diagonal -- the scenario "gls-joint" exists for.
  common_g0 <- rnorm(n)
  common_g1 <- rnorm(n)
  phi <- list(
    common_g0 * 0.8 + rnorm(n, sd = 0.3),
    common_g0 * 0.8 + rnorm(n, sd = 0.3),
    common_g0 * 0.8 + rnorm(n, sd = 0.3),
    common_g1 * 0.8 + rnorm(n, sd = 0.3),
    common_g1 * 0.8 + rnorm(n, sd = 0.3),
    common_g1 * 0.8 + rnorm(n, sd = 0.3)
  )
  ids <- paste0("u", seq_len(n))
  gt_obj <- list(
    data = data, phi = phi, times = 1:3, groups = 0:1,
    event_times = sort(unique(data$k)), n = n, ids = ids, meta = list()
  )
  class(gt_obj) <- c("gt_object", "extrapolateATT")

  omega <- c(0.5, 0.5)
  res <- path1_aggregate(gt_obj, omega, weighting = "gls-joint")

  expect_named(res, c("tau_future", "phi_future", "tau_g", "phi_g"))
  expect_length(res$phi_future, n)
  expect_length(res$tau_g, 2)
  expect_named(res$tau_g, c("0", "1"))
  expect_length(res$phi_g, 2)
  expect_named(res$phi_g, c("0", "1"))
  for (g in res$phi_g) expect_length(g, n)

  # The overall estimate is still the omega-weighted combination of the per-group estimates
  # (same contract as the two-step "gls"/"equal" paths), even though beta_g's weights
  # within each group are no longer diagonal-only.
  expect_equal(res$tau_future, sum(omega * res$tau_g), tolerance = 1e-8)
  expect_equal(res$phi_future, as.numeric(res$phi_g[[1]]) * omega[1] +
    as.numeric(res$phi_g[[2]]) * omega[2], tolerance = 1e-8)
})

test_that("path1_aggregate(weighting = 'gls-joint') accepts an explicit ids= override", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 2, n_times = 3)
  ids <- paste0("u", seq_len(50))

  res <- path1_aggregate(gt_obj, omega = c(0.5, 0.5), weighting = "gls-joint", ids = ids)
  expect_length(res$phi_future, 50)
})

test_that("path1_aggregate validates gt_object", {
  bad_obj <- list(data = data.frame())

  expect_error(
    path1_aggregate(bad_obj, omega = c(0.5, 0.5)),
    "gt_object"
  )
})

test_that("path1_aggregate checks omega length", {
  gt_obj <- make_mock_gt_object(n_groups = 2)
  omega_wrong <- c(0.5, 0.3, 0.2)  # 3 weights for 2 groups

  expect_error(
    path1_aggregate(gt_obj, omega_wrong),
    "omega must have length 2"
  )
})

test_that("path1_aggregate checks phi and data alignment", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 2)
  gt_obj$phi <- gt_obj$phi[-1]  # Remove one element

  expect_error(
    path1_aggregate(gt_obj, omega = c(0.5, 0.5)),
    "phi"
  )
})

test_that("path1_aggregate computes correct group means", {
  # Create controlled data
  set.seed(20260304)
  n <- 50
  data <- tibble::tibble(
    g = c(0, 0, 0, 1, 1),
    t = c(1, 2, 3, 1, 2),
    tau_hat = c(1, 2, 3, 4, 5),
    k = t - g
  )

  phi <- replicate(nrow(data), rnorm(n, sd = 0.1), simplify = FALSE)

  gt_obj <- list(
    data = data,
    phi = phi,
    times = sort(unique(data$t)),
    groups = sort(unique(data$g)),
    n = n
  )
  class(gt_obj) <- c("gt_object", "extrapolateATT")

  omega <- c(0.5, 0.5)
  result <- path1_aggregate(gt_obj, omega)

  # Group 0 should have mean (1+2+3)/3 = 2
  # Group 1 should have mean (4+5)/2 = 4.5
  expect_equal(result$tau_g[1], 2, tolerance = 1e-10)
  expect_equal(result$tau_g[2], 4.5, tolerance = 1e-10)

  # Overall should be 0.5 * 2 + 0.5 * 4.5 = 3.25
  expect_equal(result$tau_future, 3.25, tolerance = 1e-10)
})

test_that("path1_aggregate propagates EIFs correctly", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 2, n_times = 3)
  omega <- c(0.6, 0.4)

  result <- path1_aggregate(gt_obj, omega)

  # Check per-group EIFs
  expect_length(result$phi_g[[1]], gt_obj$n)
  expect_length(result$phi_g[[2]], gt_obj$n)

  # Check aggregated EIF
  expect_length(result$phi_future, gt_obj$n)
  expect_true(all(is.finite(result$phi_future)))
})

test_that("path1_aggregate handles single group", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 1, n_times = 3)
  omega <- 1.0

  result <- path1_aggregate(gt_obj, omega)

  expect_length(result$tau_g, 1)
  expect_equal(result$tau_future, result$tau_g[1])
})

test_that("path1_aggregate handles single time per group", {
  set.seed(20260304)
  n <- 50
  data <- tibble::tibble(
    g = c(0, 1),
    t = c(1, 2),
    tau_hat = c(0.5, 0.3),
    k = t - g
  )

  phi <- list(rnorm(n, sd = 0.1), rnorm(n, sd = 0.1))

  gt_obj <- list(
    data = data,
    phi = phi,
    times = sort(unique(data$t)),
    groups = sort(unique(data$g)),
    n = n
  )
  class(gt_obj) <- c("gt_object", "extrapolateATT")

  omega <- c(0.5, 0.5)
  result <- path1_aggregate(gt_obj, omega)

  # With one time per group, group mean = that single value
  expect_equal(result$tau_g[1], 0.5)
  expect_equal(result$tau_g[2], 0.3)
})

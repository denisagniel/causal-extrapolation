test_that("gls_weights returns normalized inverse-variance weights", {
  set.seed(1)
  phi_list <- list(
    rnorm(200, sd = 1),   # var ~ 1
    rnorm(200, sd = 2),   # var ~ 4
    rnorm(200, sd = 0.5)  # var ~ 0.25
  )
  w <- gls_weights(phi_list)

  expect_length(w, 3)
  expect_equal(sum(w), 1, tolerance = 1e-10)
  expect_true(all(w > 0))
  # Lower-variance cell should receive the largest weight
  expect_equal(which.max(w), 3L)
  expect_equal(which.min(w), 2L)
})

test_that("gls_weights floors near-zero variance to avoid unbounded weight", {
  phi_list <- list(rep(0, 50), rnorm(50, sd = 1))
  w <- gls_weights(phi_list, floor = 1e-8)
  expect_true(all(is.finite(w)))
  expect_true(w[1] > w[2])  # the (floored) zero-variance cell still dominates
})

test_that("gls_weights errors on an empty list", {
  expect_error(gls_weights(list()), "at least one EIF vector")
})

test_that("path1_aggregate defaults to equal weighting (unchanged behavior)", {
  set.seed(2)
  n <- 100
  gt_data <- tibble::tibble(g = c(0, 0, 0), t = c(1, 2, 3), k = c(1, 2, 3), tau_hat = c(0.2, 0.3, 0.4))
  phi <- replicate(3, rnorm(n, sd = 0.1), simplify = FALSE)
  gt_obj <- structure(
    list(data = gt_data, phi = phi, times = 1:3, groups = 0, n = n),
    class = c("gt_object", "extrapolateATT")
  )

  res_default <- path1_aggregate(gt_obj, omega = 1)
  res_equal <- path1_aggregate(gt_obj, omega = 1, weighting = "equal")
  expect_equal(res_default$tau_future, res_equal$tau_future)
  expect_equal(res_default$tau_future, mean(gt_data$tau_hat))
})

test_that("path1_aggregate with weighting = 'gls' reduces variance under heteroskedastic EIFs", {
  set.seed(3)
  n <- 500
  sigma_t <- c(0.05, 0.1, 0.2, 0.4)
  theta_t <- rep(0.3, 4)
  n_rep <- 200
  est_equal <- numeric(n_rep)
  est_gls <- numeric(n_rep)
  for (r in seq_len(n_rep)) {
    tau_hat <- theta_t + rnorm(4, 0, sigma_t)
    phi <- lapply(seq_len(4), function(j) rnorm(n, 0, sigma_t[j] * sqrt(n)))
    gt_obj <- structure(
      list(data = tibble::tibble(g = rep(0, 4), t = 1:4, k = 1:4, tau_hat = tau_hat),
           phi = phi, times = 1:4, groups = 0, n = n),
      class = c("gt_object", "extrapolateATT")
    )
    est_equal[r] <- path1_aggregate(gt_obj, omega = 1, weighting = "equal")$tau_future
    est_gls[r] <- path1_aggregate(gt_obj, omega = 1, weighting = "gls")$tau_future
  }
  expect_lt(stats::var(est_gls), stats::var(est_equal))
})

test_that("dh_linear with weights = NULL matches the prior unweighted (OLS) behavior", {
  times <- c(1, 2, 3)
  expect_equal(dh_linear(times, future_time = 5), dh_linear(times, future_time = 5, weights = NULL))
})

test_that("dh_linear with equal weights matches the unweighted fit", {
  times <- c(1, 2, 3, 4)
  w_unweighted <- dh_linear(times, future_time = 6)
  w_equal <- dh_linear(times, future_time = 6, weights = rep(1, 4))
  expect_equal(w_unweighted, w_equal, tolerance = 1e-10)
})

test_that("dh_linear rejects a weights vector of the wrong length", {
  expect_error(dh_linear(c(1, 2, 3), future_time = 5, weights = c(1, 2)), "length 3")
})

test_that("dh_quadratic with weights reproduces a manual WLS projection", {
  times <- c(1, 2, 3, 4)
  weights <- c(1, 1, 4, 4)
  future_time <- 6

  X <- cbind(1, times, times^2)
  W <- diag(weights)
  xstar <- c(1, future_time, future_time^2)
  w_manual <- as.numeric(t(xstar) %*% solve(t(X) %*% W %*% X) %*% t(X) %*% W)

  w_pkg <- dh_quadratic(times, future_time, weights = weights)
  expect_equal(w_pkg, w_manual, tolerance = 1e-8)
})

test_that("hg_linear with weights extrapolates consistently with dh_linear's projection", {
  times <- c(1, 2, 3)
  tau <- c(0.2, 0.3, 0.5)
  weights <- c(1, 2, 3)
  h <- hg_linear(times, future_time = 5, weights = weights)
  manual <- sum(dh_linear(times, future_time = 5, weights = weights) * tau)
  expect_equal(h(tau), manual, tolerance = 1e-10)
})

test_that("extrapolate_ATT with weight_scheme = 'equal' matches prior default behavior", {
  set.seed(4)
  n <- 100
  gt_data <- tibble::tibble(g = c(0, 0, 0, 1, 1, 1), t = c(1, 2, 3, 1, 2, 3), k = c(1, 2, 3, 1, 2, 3),
                            tau_hat = c(0.2, 0.3, 0.4, 0.5, 0.55, 0.6))
  phi <- replicate(6, rnorm(n, sd = 0.1), simplify = FALSE)
  gt_obj <- structure(
    list(data = gt_data, phi = phi, times = 1:3, groups = c(0, 1), n = n),
    class = c("gt_object", "extrapolateATT")
  )

  ex_default <- extrapolate_ATT(gt_obj, h_fun = hg_linear, dh_fun = dh_linear,
                                future_value = 4, time_scale = "calendar",
                                omega = c(0.5, 0.5), per_group = FALSE)
  ex_equal <- extrapolate_ATT(gt_obj, h_fun = hg_linear, dh_fun = dh_linear,
                              future_value = 4, time_scale = "calendar",
                              omega = c(0.5, 0.5), per_group = FALSE, weight_scheme = "equal")
  expect_equal(ex_default$tau_future, ex_equal$tau_future)
})

test_that("extrapolate_ATT with weight_scheme = 'gls' reduces variance under heteroskedastic EIFs", {
  set.seed(5)
  n <- 500
  sigma_t <- c(0.05, 0.1, 0.2, 0.4, 0.5)
  theta_gt_true <- c(0.1, 0.2, 0.3, 0.4, 0.5)  # linear in t, slope 0.1

  make_gt <- function(seed) {
    set.seed(seed)
    tau_hat <- theta_gt_true + rnorm(5, 0, sigma_t)
    phi <- lapply(seq_len(5), function(j) rnorm(n, 0, sigma_t[j] * sqrt(n)))
    structure(
      list(data = tibble::tibble(g = rep(0, 5), t = 1:5, k = 1:5, tau_hat = tau_hat),
           phi = phi, times = 1:5, groups = 0, n = n),
      class = c("gt_object", "extrapolateATT")
    )
  }

  n_rep <- 200
  est_equal <- numeric(n_rep)
  est_gls <- numeric(n_rep)
  for (r in seq_len(n_rep)) {
    gt_obj <- make_gt(2000 + r)
    est_equal[r] <- extrapolate_ATT(gt_obj, h_fun = hg_linear, dh_fun = dh_linear,
                                    future_value = 6, time_scale = "calendar",
                                    omega = 1, per_group = FALSE, weight_scheme = "equal")$tau_future
    est_gls[r] <- extrapolate_ATT(gt_obj, h_fun = hg_linear, dh_fun = dh_linear,
                                  future_value = 6, time_scale = "calendar",
                                  omega = 1, per_group = FALSE, weight_scheme = "gls")$tau_future
  }
  expect_lt(stats::var(est_gls), stats::var(est_equal))
})

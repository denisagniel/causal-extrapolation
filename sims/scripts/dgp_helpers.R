# DGP helpers for causal-extrapolation simulations
# Shared data-generating process, true FATT/ATT, and gt_object builder.

library(tibble)
library(dplyr)

#' Generate true group-time effects theta_gt
#'
#' @param q Number of groups (cohorts).
#' @param p Last observed calendar time.
#' @param spec One of "constant", "linear", "quadratic" (in event time k = t - g).
#' @param alpha_g Optional length-q vector of group intercepts; else drawn from N(0, 0.5).
#' @param beta_g Optional length-q vector of linear coefficients (event time); used for linear/quadratic.
#' @param delta_g Optional length-q vector of quadratic coefficients; used for quadratic.
#' @param theta_g Optional length-q vector of constant effects; used for constant spec.
#' @param seed Optional seed for reproducibility.
#' @return A tibble with columns g, t, k, theta_gt (one row per observed (g,t), g <= t <= p).
#' @export
make_theta_gt <- function(q, p, spec = c("constant", "linear", "quadratic"),
                         alpha_g = NULL, beta_g = NULL, delta_g = NULL, theta_g = NULL,
                         seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  spec <- match.arg(spec)

  # Observed (g,t): g in 1..q, t in g..p
  grid <- expand.grid(g = seq_len(q), t = seq_len(p), stringsAsFactors = FALSE)
  grid <- grid[grid$t >= grid$g, , drop = FALSE]
  grid$k <- grid$t - grid$g

  if (spec == "constant") {
    if (is.null(theta_g)) theta_g <- stats::rnorm(q, mean = 0, sd = 0.5)
    grid$theta_gt <- theta_g[grid$g]
  } else if (spec == "linear") {
    if (is.null(alpha_g)) alpha_g <- stats::rnorm(q, mean = 0, sd = 0.3)
    if (is.null(beta_g)) beta_g <- stats::rnorm(q, mean = 0.1, sd = 0.1)
    grid$theta_gt <- alpha_g[grid$g] + beta_g[grid$g] * grid$k
  } else {
    # quadratic
    if (is.null(alpha_g)) alpha_g <- stats::rnorm(q, mean = 0, sd = 0.3)
    if (is.null(beta_g)) beta_g <- stats::rnorm(q, mean = 0.05, sd = 0.05)
    if (is.null(delta_g)) delta_g <- stats::rnorm(q, mean = 0.02, sd = 0.02)
    grid$theta_gt <- alpha_g[grid$g] + beta_g[grid$g] * grid$k + delta_g[grid$g] * (grid$k^2)
  }

  tibble::as_tibble(grid)
}

#' True FATT at future calendar time from DGP parameters
#'
#' @param omega Length-q vector of group weights.
#' @param future_time Calendar time (e.g. p + 1).
#' @param q Number of groups.
#' @param spec "constant", "linear", or "quadratic".
#' @param alpha_g,beta_g,delta_g,theta_g Group-level parameters (theta_g for constant).
#' @return Scalar true FATT.
#' @export
true_fatt_from_dgp <- function(omega, future_time, q, spec,
                               alpha_g = NULL, beta_g = NULL, delta_g = NULL, theta_g = NULL) {
  stopifnot(length(omega) == q, spec %in% c("constant", "linear", "quadratic"))
  k_star <- future_time - seq_len(q)
  theta_future <- if (spec == "constant") {
    theta_g
  } else if (spec == "linear") {
    alpha_g + beta_g * k_star
  } else {
    alpha_g + beta_g * k_star + delta_g * (k_star^2)
  }
  sum(omega * theta_future)
}

#' True backward-looking ATT (average of theta_gt over observed cells)
#'
#' @param theta_gt Tibble with theta_gt column.
#' @param weights Optional vector of length nrow(theta_gt); default equal weights.
#' @return Scalar.
#' @export
true_backward_att <- function(theta_gt, weights = NULL) {
  if (is.null(weights)) weights <- rep(1, nrow(theta_gt))
  weights <- weights / sum(weights)
  sum(weights * theta_gt$theta_gt)
}

#' Add estimation noise and build gt_object with EIFs
#'
#' Given true theta_gt, generates tau_hat = theta_gt + N(0, sigma_tau) and
#' EIF vectors such that variance of the mean is correct (independent cell-wise contributions).
#'
#' @param theta_gt Tibble from make_theta_gt (g, t, k, theta_gt).
#' @param n Sample size (length of each EIF vector).
#' @param sigma_tau SD of additive noise on tau_hat per cell; EIF scale is set so Var(mean(phi_j)) = sigma_tau^2.
#' @param sigma_phi Unused; retained for backward compatibility.
#' @param seed Optional seed.
#' @return A gt_object (list with data, phi, times, groups, n) compatible with extrapolate_ATT and path1_aggregate.
#' @export
add_noise_and_eif <- function(theta_gt, n, sigma_tau = 0.1, sigma_phi = 0.2, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  J <- nrow(theta_gt)
  tau_hat <- theta_gt$theta_gt + stats::rnorm(J, mean = 0, sd = sigma_tau)
  # EIF for cell j: tau_hat[j] has variance sigma_tau^2, so we need Var(mean(phi_j)) = sigma_tau^2.
  # Hence Var(phi_j) = n * sigma_tau^2, i.e. SD(phi_j) = sigma_tau * sqrt(n).
  phi_list <- lapply(seq_len(J), function(j) stats::rnorm(n, mean = 0, sd = sigma_tau * sqrt(n)))
  data <- tibble::tibble(
    g = theta_gt$g,
    t = theta_gt$t,
    k = theta_gt$k,
    tau_hat = tau_hat
  )
  groups <- sort(unique(theta_gt$g))
  times <- sort(unique(theta_gt$t))
  obj <- list(
    data = data,
    phi = phi_list,
    times = times,
    groups = groups,
    event_times = sort(unique(theta_gt$k)),
    n = n
  )
  class(obj) <- c("gt_object", "extrapolateATT")
  obj
}

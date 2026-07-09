#' Test fixtures for extrapolateATT package
#'
#' Reusable mock data builders for testing

#' Create a mock gt_object for testing
#'
#' @param n Sample size
#' @param n_groups Number of groups
#' @param n_times Number of time periods per group
#' @param seed Random seed for reproducibility
#' @return A gt_object suitable for testing
make_mock_gt_object <- function(n = 50, n_groups = 2, n_times = 3, seed = 20260304) {
  set.seed(seed)

  # Create groups and times (use 0-indexed to avoid numerical issues with large values)
  groups <- 0:(n_groups - 1)
  times <- 1:n_times

  # Build data: each group has observations at each time
  data <- expand.grid(g = groups, t = times)
  data$tau_hat <- rnorm(nrow(data), mean = 0.5, sd = 0.1)
  data$k <- data$t - data$g

  # Create EIF vectors (one per row of data)
  phi <- replicate(nrow(data), rnorm(n, sd = 0.1), simplify = FALSE)

  # Construct gt_object
  gt_obj <- list(
    data = tibble::as_tibble(data),
    phi = phi,
    times = sort(unique(data$t)),
    groups = sort(unique(data$g)),
    event_times = sort(unique(data$k)),
    n = n,
    ids = NULL,
    meta = list(call = match.call())
  )

  class(gt_obj) <- c("gt_object", "extrapolateATT")
  gt_obj
}

#' Create a mock extrap_object for testing
#'
#' @param n_groups Number of groups
#' @param n Sample size for EIF vectors
#' @param per_group Whether to include per-group results only
#' @param seed Random seed
#' @return An extrap_object suitable for testing
make_mock_extrap_object <- function(n_groups = 2, n = 50, per_group = TRUE, seed = 20260304) {
  set.seed(seed)

  groups <- 0:(n_groups - 1)
  tau_g_future <- rnorm(n_groups, mean = 0.5, sd = 0.1)
  phi_g_future <- replicate(n_groups, rnorm(n, sd = 0.1), simplify = FALSE)

  out <- list(
    tau_g_future = tibble::tibble(g = groups, tau_future = tau_g_future),
    phi_g_future = phi_g_future
  )

  if (!per_group) {
    omega <- rep(1 / n_groups, n_groups)
    out$tau_future <- sum(omega * tau_g_future)
    out$phi_future <- Reduce(`+`, Map(function(w, p) w * p, omega, phi_g_future))
  }

  class(out) <- c("extrap_object", "extrapolateATT")
  out
}

#' Build a CATE contract for testing integrate_cate()
#'
#' Simulates a simple AIPW-style DGP (or 2-period DiD) and returns the generic CATE
#' contract list expected by `integrate_cate()`, with the true FATT attached as an
#' attribute for recovery checks.
#'
#' @param n Sample size.
#' @param d Number of covariates.
#' @param design "unconfoundedness" or "did".
#' @param seed Random seed.
#' @return A CATE contract list (list(tau, mu1, mu0, e, A, Y, X) for unconfoundedness;
#'   list(tau, dY, m0_dY, e, A, X) for did), with attr "true_fatt".
make_cate_input <- function(n = 500, d = 1, design = "unconfoundedness", seed = 20260708) {
  set.seed(seed)

  X <- as.data.frame(matrix(rnorm(n * d), nrow = n, ncol = d))
  names(X) <- paste0("x", seq_len(d))
  # Linear index used for propensity and effect heterogeneity.
  lin <- rowSums(X) / sqrt(d)
  e <- plogis(0.6 * lin)
  A <- rbinom(n, 1, e)
  tau_x <- 1 + 0.5 * lin  # true CATE

  if (design == "unconfoundedness") {
    mu0 <- 0.8 * lin
    mu1 <- mu0 + tau_x
    Y <- mu0 + A * tau_x + rnorm(n, sd = 0.5)
    cate <- list(tau = tau_x, mu1 = mu1, mu0 = mu0, e = e, A = A, Y = Y, X = X)
    # FATT = mean of tau over the treated units.
    attr(cate, "true_fatt") <- mean(tau_x[A == 1])
  } else {
    # 2-period DiD: outcome change dY; conditional change among untreated = m0.
    m0_dY <- 0.3 * lin
    dY <- m0_dY + A * tau_x + rnorm(n, sd = 0.5)
    cate <- list(tau = tau_x, dY = dY, m0_dY = m0_dY, e = e, A = A, X = X)
    attr(cate, "true_fatt") <- mean(tau_x[A == 1])
  }
  cate
}

#' Reference ordinary AIPW/ATT efficient influence function
#'
#' The no-transport (w == 1) EIF, used as the collapse-certificate oracle.
#'
#' @param cate An unconfoundedness CATE contract list.
#' @param psi Scalar estimate to center on.
#' @return Length-n numeric EIF vector.
reference_aipw_eif <- function(cate, psi) {
  (cate$tau - psi) +
    cate$A * (cate$Y - cate$mu1) / cate$e -
    (1 - cate$A) * (cate$Y - cate$mu0) / (1 - cate$e)
}

#' Create simple numeric vectors for testing validators
#'
#' @param type Type of problematic vector: "normal", "na", "inf", "character"
#' @param length Length of vector
#' @return A test vector
make_test_vector <- function(type = "normal", length = 10) {
  switch(type,
    normal = rnorm(length),
    na = c(1:5, NA, 7:length),
    inf = c(1:5, Inf, 7:length),
    character = as.character(1:length),
    negative = -abs(rnorm(length)),
    stop("Unknown type")
  )
}

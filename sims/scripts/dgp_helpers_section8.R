# DGP helpers for Section 8: Stress Tests and Edge Cases
# Purpose: Show where each extrapolation path fails (constitution §9 compliance)
#
# Each DGP is designed to break a specific path while preserving the general
# extrapolation setting. This builds credibility by being honest about method limitations.

library(tibble)
library(dplyr)

# ============================================================================
# Section 8.2: Conditional Model Misspecification (Path 3 Break Point)
# ============================================================================

#' Generate group-time effects with unobserved heterogeneity
#'
#' Purpose: Show Path 3 fails when unobserved heterogeneity dominates
#' Expected result: Path 3 biased when U omitted; coverage fails
#'
#' @description
#' True effect: tau(X, U) = alpha + beta_X * X + beta_U * U
#' where U is unobserved and correlated with X.
#'
#' Path 3 fits: m(X; beta) = beta_0 + beta_1 * X (misspecified - omits U)
#'
#' When cor(X, U) != 0, Path 3 suffers omitted variable bias.
#' The magnitude of bias depends on:
#' - Strength of cor(X, U)
#' - Magnitude of beta_U (effect of unobserved confounder)
#'
#' @param q Number of groups.
#' @param p Last observed calendar time.
#' @param alpha Intercept of conditional ATT model.
#' @param beta_X Effect of observed covariate X.
#' @param beta_U Effect of unobserved confounder U.
#' @param cor_XU Correlation between X and U (0 = no confounding, ±1 = perfect confounding).
#' @param mu_g Length-q vector: mean of X within each group.
#' @param sigma_X SD of X (homogeneous across groups).
#' @param seed Optional seed for reproducibility.
#' @return A tibble with columns g, t, k, theta_gt, plus attributes for the conditional model.
#'   Attributes: alpha, beta_X, beta_U, cor_XU, mu_g, mu_U_g (group means of U), sigma_X, sigma_U.
#' @export
make_theta_gt_unobserved <- function(q, p,
                                     alpha = 2.0,
                                     beta_X = 1.5,
                                     beta_U = 3.0,
                                     cor_XU = 0.5,
                                     mu_g = NULL,
                                     sigma_X = 1.0,
                                     seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  if (is.null(mu_g)) mu_g <- seq(-1, 1, length.out = q)

  # For correlated X and U, use bivariate normal:
  # X ~ N(mu_X, sigma_X^2)
  # U ~ N(mu_U, sigma_U^2)
  # cor(X, U) = cor_XU
  #
  # We construct U given X to induce correlation:
  # U = rho * (X - mu_X) / sigma_X * sigma_U + epsilon
  # where epsilon ~ N(0, sigma_U^2 * (1 - rho^2))
  #
  # For simplicity, let mu_U = 0, sigma_U = 1.

  sigma_U <- 1.0
  mu_U <- 0.0

  # Group-level mean of U induced by correlation with X:
  # E[U | G=g] = rho * (E[X | G=g] - 0) / sigma_X * sigma_U
  #           = cor_XU * mu_g / sigma_X * sigma_U
  mu_U_g <- cor_XU * mu_g / sigma_X * sigma_U

  # Group-time ATT = E[tau(X, U) | G=g]
  #                = alpha + beta_X * E[X | G=g] + beta_U * E[U | G=g]
  #                = alpha + beta_X * mu_g[g] + beta_U * mu_U_g[g]

  grid <- expand.grid(g = seq_len(q), t = seq_len(p), stringsAsFactors = FALSE)
  grid <- grid[grid$t >= grid$g, , drop = FALSE]  # Only post-treatment cells
  grid$k <- grid$t - grid$g

  # Group-time ATT integrates over both X and U distributions
  grid$theta_gt <- alpha + beta_X * mu_g[grid$g] + beta_U * mu_U_g[grid$g]

  # Return with attributes for covariate structure
  result <- tibble::as_tibble(grid)
  attr(result, "alpha") <- alpha
  attr(result, "beta_X") <- beta_X
  attr(result, "beta_U") <- beta_U
  attr(result, "cor_XU") <- cor_XU
  attr(result, "mu_g") <- mu_g
  attr(result, "mu_U_g") <- mu_U_g
  attr(result, "sigma_X") <- sigma_X
  attr(result, "sigma_U") <- sigma_U
  attr(result, "conditional_model") <- "linear_with_unobserved"
  result
}

#' True FATT under unobserved heterogeneity for a target distribution
#'
#' @param alpha Intercept of tau(X, U).
#' @param beta_X Effect of observed X.
#' @param beta_U Effect of unobserved U.
#' @param mu_X_target Mean of X in target distribution.
#' @param mu_U_target Mean of U in target distribution.
#' @return Scalar true FATT = alpha + beta_X * mu_X_target + beta_U * mu_U_target.
#' @export
true_fatt_unobserved <- function(alpha, beta_X, beta_U, mu_X_target, mu_U_target) {
  alpha + beta_X * mu_X_target + beta_U * mu_U_target
}

#' Generate target covariate sample with unobserved heterogeneity
#'
#' @param n_target Sample size for target population.
#' @param mu_X_target Mean of X in target.
#' @param mu_U_target Mean of U in target.
#' @param sigma_X SD of X.
#' @param sigma_U SD of U.
#' @param cor_XU Correlation between X and U.
#' @param seed Optional seed.
#' @return Tibble with columns X, U (n_target draws from bivariate normal).
#' @export
generate_target_covariates_unobserved <- function(n_target,
                                                   mu_X_target,
                                                   mu_U_target = 0.0,
                                                   sigma_X = 1.0,
                                                   sigma_U = 1.0,
                                                   cor_XU = 0.5,
                                                   seed = NULL) {
  if (!is.null(seed)) set.seed(seed)

  # Bivariate normal: (X, U) ~ N(mu, Sigma)
  # Sigma = [sigma_X^2, cor*sigma_X*sigma_U]
  #         [cor*sigma_X*sigma_U, sigma_U^2]

  # Use Cholesky decomposition for correlated normals
  # X = mu_X + sigma_X * Z1
  # U = mu_U + cor*sigma_U*Z1 + sqrt(1-cor^2)*sigma_U*Z2
  # where Z1, Z2 ~ N(0, 1) independent

  Z1 <- stats::rnorm(n_target, mean = 0, sd = 1)
  Z2 <- stats::rnorm(n_target, mean = 0, sd = 1)

  X <- mu_X_target + sigma_X * Z1
  U <- mu_U_target + cor_XU * sigma_U * Z1 + sqrt(1 - cor_XU^2) * sigma_U * Z2

  tibble::tibble(X = X, U = U)
}

# ============================================================================
# Section 8.1: Non-Smooth Dynamics (Path 2 Break Point)
# ============================================================================

#' Generate piecewise linear group-time effects
#'
#' Purpose: Show Path 2 fails when true functional form is not smooth
#' Expected result: All smooth parametric models struggle; extrapolation beyond break point biased
#'
#' @description
#' Piecewise linear with break at k = break_k:
#' theta_gt = alpha_g + beta1_g * k  if k <= break_k
#'          = alpha_g + beta1_g * break_k + beta2_g * (k - break_k)  if k > break_k
#'
#' When beta2_g ≠ beta1_g, the slope changes sharply at k = break_k.
#' Smooth parametric models (linear, quadratic, spline with fixed knots) cannot
#' adapt to this break and will systematically mis-extrapolate beyond break_k.
#'
#' @param q Number of groups.
#' @param p Last observed calendar time.
#' @param alpha_g Length-q vector of group intercepts.
#' @param beta1_g Length-q vector of slope before break.
#' @param beta2_g Length-q vector of slope after break.
#' @param break_k Event time at which slope changes (default 3).
#' @param seed Optional seed for reproducibility.
#' @return A tibble with columns g, t, k, theta_gt.
#' @export
make_theta_gt_piecewise <- function(q, p,
                                    alpha_g = NULL,
                                    beta1_g = NULL,
                                    beta2_g = NULL,
                                    break_k = 3,
                                    seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  if (is.null(alpha_g)) alpha_g <- stats::rnorm(q, mean = 0, sd = 0.3)
  if (is.null(beta1_g)) beta1_g <- stats::rnorm(q, mean = 0.1, sd = 0.05)
  if (is.null(beta2_g)) beta2_g <- stats::rnorm(q, mean = 0.3, sd = 0.05)  # Different slope after break

  grid <- expand.grid(g = seq_len(q), t = seq_len(p), stringsAsFactors = FALSE)
  grid <- grid[grid$t >= grid$g, , drop = FALSE]
  grid$k <- grid$t - grid$g

  # Piecewise linear
  grid$theta_gt <- ifelse(
    grid$k <= break_k,
    alpha_g[grid$g] + beta1_g[grid$g] * grid$k,
    alpha_g[grid$g] + beta1_g[grid$g] * break_k + beta2_g[grid$g] * (grid$k - break_k)
  )

  result <- tibble::as_tibble(grid)
  attr(result, "alpha_g") <- alpha_g
  attr(result, "beta1_g") <- beta1_g
  attr(result, "beta2_g") <- beta2_g
  attr(result, "break_k") <- break_k
  attr(result, "spec") <- "piecewise_linear"
  result
}

#' True FATT for piecewise linear DGP
#'
#' @param omega Length-q vector of group weights.
#' @param future_time Calendar time (e.g. p + 1).
#' @param q Number of groups.
#' @param alpha_g,beta1_g,beta2_g,break_k Group-level parameters.
#' @return Scalar true FATT.
#' @export
true_fatt_piecewise <- function(omega, future_time, q, alpha_g, beta1_g, beta2_g, break_k) {
  stopifnot(length(omega) == q)
  k_star <- future_time - seq_len(q)

  theta_future <- ifelse(
    k_star <= break_k,
    alpha_g + beta1_g * k_star,
    alpha_g + beta1_g * break_k + beta2_g * (k_star - break_k)
  )

  sum(omega * theta_future)
}

# ============================================================================
# Section 8.5: Extreme Regime Change (Path 3 Out-of-Support)
# ============================================================================

#' Generate target covariates far out of observed support
#'
#' Purpose: Show Path 3 fails when extrapolating beyond observed X support
#' Expected result: Linear extrapolation valid under linearity, but high uncertainty
#'                  and risk of model misspecification beyond observed data
#'
#' @param n_target Sample size for target population.
#' @param mu_target Mean of X in target (far from historical support).
#' @param sigma_X SD of X.
#' @param seed Optional seed.
#' @return Tibble with column X (n_target draws from N(mu_target, sigma_X^2)).
#' @export
generate_target_covariates_extreme <- function(n_target,
                                                mu_target,
                                                sigma_X = 1.0,
                                                seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  tibble::tibble(X = stats::rnorm(n_target, mean = mu_target, sd = sigma_X))
}

# ============================================================================
# Section 8.4: Heavy-Tailed Noise (Robustness Check)
# ============================================================================

#' Add noise and EIF with heavy-tailed distribution
#'
#' Purpose: Test robustness to heavy-tailed first-stage errors
#' Expected result: Point estimates robust (consistent), but inference anti-conservative
#'                  (CIs too narrow under heavy tails, coverage below nominal)
#'
#' @description
#' Similar to add_noise_and_eif from dgp_helpers.R, but with t-distributed noise
#' instead of Gaussian. Mimics first-stage estimation errors with heavy tails.
#'
#' @param theta_gt Tibble from make_theta_gt (g, t, k, theta_gt).
#' @param n Sample size (length of each EIF vector).
#' @param df Degrees of freedom for t-distribution (default 3 = heavy tails).
#' @param scale_tau Scale parameter for t-distribution (analogous to sigma_tau).
#' @param seed Optional seed.
#' @param within_group_correlation Correlation of EIF within group (default 0.98).
#' @return A gt_object (list with data, phi, times, groups, n) compatible with extrapolate_ATT.
#' @export
add_noise_and_eif_heavytail <- function(theta_gt, n,
                                        df = 3,
                                        scale_tau = 0.1,
                                        seed = NULL,
                                        within_group_correlation = 0.98) {
  if (!is.null(seed)) set.seed(seed)
  J <- nrow(theta_gt)

  # Heavy-tailed noise: t-distribution with df degrees of freedom
  # Scale to have variance approximately scale_tau^2 * df / (df - 2) for df > 2
  tau_hat <- theta_gt$theta_gt + stats::rt(J, df = df) * scale_tau

  # EIF vectors: Use Gaussian EIF (as in standard case) to show that
  # inference is anti-conservative when true errors are heavy-tailed but
  # we use Gaussian-based EIF for variance estimation

  groups <- sort(unique(theta_gt$g))
  rho <- within_group_correlation

  # Generate group-level EIF components (shared across cells within group)
  phi_group <- lapply(groups, function(g) {
    stats::rnorm(n, mean = 0, sd = scale_tau * sqrt(n))
  })
  names(phi_group) <- groups

  # Generate cell-level EIF vectors with within-group correlation
  phi_list <- lapply(seq_len(J), function(j) {
    g <- theta_gt$g[j]
    sqrt(rho) * phi_group[[as.character(g)]] +
      sqrt(1 - rho) * stats::rnorm(n, mean = 0, sd = scale_tau * sqrt(n))
  })

  data <- tibble::tibble(
    g = theta_gt$g,
    t = theta_gt$t,
    k = theta_gt$k,
    tau_hat = tau_hat
  )
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

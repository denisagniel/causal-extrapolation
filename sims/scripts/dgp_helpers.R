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
add_noise_and_eif <- function(theta_gt, n, sigma_tau = 0.1, sigma_phi = 0.2, seed = NULL,
                               within_group_correlation = 0.98) {
  if (!is.null(seed)) set.seed(seed)
  J <- nrow(theta_gt)
  tau_hat <- theta_gt$theta_gt + stats::rnorm(J, mean = 0, sd = sigma_tau)

  # EIF for cell j: tau_hat[j] has variance sigma_tau^2, so we need Var(mean(phi_j)) = sigma_tau^2.
  # Hence Var(phi_j) = n * sigma_tau^2, i.e. SD(phi_j) = sigma_tau * sqrt(n).
  #
  # IMPORTANT: Cells within the same group should have correlated EIF vectors because
  # they're based on the same individuals. Without this, variance is underestimated by factor of p
  # (number of time periods per group), leading to severe undercoverage.
  #
  # Generate correlated EIF vectors within each group:
  # phi_{gt,i} = sqrt(rho) * phi_{g,i} + sqrt(1-rho) * epsilon_{gt,i}
  # where phi_{g,i} is group-level (shared across time) and epsilon is cell-specific noise.

  groups <- sort(unique(theta_gt$g))
  rho <- within_group_correlation

  # Generate group-level EIF components (shared across cells within group)
  phi_group <- lapply(groups, function(g) {
    stats::rnorm(n, mean = 0, sd = sigma_tau * sqrt(n))
  })
  names(phi_group) <- groups

  # Generate cell-level EIF vectors with within-group correlation
  phi_list <- lapply(seq_len(J), function(j) {
    g <- theta_gt$g[j]
    # Correlated component (shared within group) + independent component (cell-specific)
    sqrt(rho) * phi_group[[as.character(g)]] +
      sqrt(1 - rho) * stats::rnorm(n, mean = 0, sd = sigma_tau * sqrt(n))
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

# ============================================================================
# Path 3: Covariate-driven effects (Lucas critique scenario)
# ============================================================================

#' Generate group-time effects from covariate-driven conditional ATT
#'
#' Under Path 3, effects are driven by covariates: tau(X) = alpha + beta * X.
#' Group-time ATTs arise from integrating over group-specific covariate distributions.
#' This allows regime change (composition shifts) where temporal patterns break but
#' the conditional effect tau(X) remains invariant.
#'
#' @param q Number of groups.
#' @param p Last observed calendar time.
#' @param alpha Intercept of conditional ATT model tau(X) = alpha + beta * X.
#' @param beta Slope of conditional ATT model.
#' @param mu_g Length-q vector: mean of X within each group (covariate distribution shifts by group).
#' @param sigma_X SD of X (homogeneous across groups).
#' @param seed Optional seed for reproducibility.
#' @return A tibble with columns g, t, k, theta_gt, plus attributes for the conditional model.
#' @export
make_theta_gt_conditional <- function(q, p, alpha = 2.0, beta = 1.5,
                                      mu_g = NULL, sigma_X = 1.0, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  if (is.null(mu_g)) mu_g <- seq(-1, 1, length.out = q)

  # For each (g,t), the group-time ATT is:
  # theta_gt = E[tau(X) | G=g] = alpha + beta * mu_g[g]
  # Note: No time variation in theta_gt within group under structural stability of tau(X).

  grid <- expand.grid(g = seq_len(q), t = seq_len(p), stringsAsFactors = FALSE)
  grid <- grid[grid$t >= grid$g, , drop = FALSE]  # Only post-treatment cells
  grid$k <- grid$t - grid$g

  # Group-time ATT = conditional model integrated over group-specific X distribution
  grid$theta_gt <- alpha + beta * mu_g[grid$g]

  # Return with attributes for covariate structure
  result <- tibble::as_tibble(grid)
  attr(result, "alpha") <- alpha
  attr(result, "beta") <- beta
  attr(result, "mu_g") <- mu_g
  attr(result, "sigma_X") <- sigma_X
  attr(result, "conditional_model") <- "linear"
  result
}

#' True FATT under covariate-driven effects for a target distribution
#'
#' @param alpha Intercept of tau(X).
#' @param beta Slope of tau(X).
#' @param mu_target Mean of X in the target distribution (e.g., at p+1 or in new population).
#' @return Scalar true FATT = alpha + beta * mu_target.
#' @export
true_fatt_conditional <- function(alpha, beta, mu_target) {
  alpha + beta * mu_target
}

#' Generate target covariate sample (finite-population case for Path 3)
#'
#' @param n_target Sample size for target population.
#' @param mu_target Mean of X in target.
#' @param sigma_X SD of X.
#' @param seed Optional seed.
#' @return Tibble with column X (n_target draws from N(mu_target, sigma_X^2)).
#' @export
generate_target_covariates <- function(n_target, mu_target, sigma_X = 1.0, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  tibble::tibble(X = stats::rnorm(n_target, mean = mu_target, sd = sigma_X))
}

# ============================================================================
# Real first-stage: unit-level panel DGP + did::att_gt() integration
# ============================================================================

#' Generate unit-level staggered panel data from DGP parameters
#'
#' Creates a balanced panel suitable for `did::att_gt()`. Units are assigned
#' to cohorts (treatment timing groups) with a "never-treated" control group.
#' Potential outcomes follow a linear DGP with group-time heterogeneity
#' matching `make_theta_gt()`.
#'
#' @param theta_gt Tibble from `make_theta_gt()` with columns g, t, k, theta_gt.
#'   Defines true group-time ATTs. Internal group indices (1..q) are shifted to
#'   start at 2 so every cohort has at least one pre-treatment period visible to did.
#' @param n_per_cohort Number of units per treated cohort. The never-treated
#'   control group receives the same number of units.
#' @param p Last observed calendar time for the *original* theta_gt grid
#'   (internal calendar time is extended by 1 to accommodate the shift).
#' @param sigma_Y SD of idiosyncratic outcome noise.
#' @param sigma_alpha SD of unit fixed effects.
#' @param seed Optional seed for reproducibility.
#' @return A tibble with columns: id, g_true (cohort; `Inf` = never-treated per
#'   did convention), t (calendar time), Y (outcome), D (treatment indicator).
#' @export
generate_panel_data <- function(theta_gt, n_per_cohort, p,
                                sigma_Y = 0.5, sigma_alpha = 1.0, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)

  # Shift group indices by +1 so that the earliest cohort is treated at t=2,
  # guaranteeing at least one pre-treatment period (t=1) for every cohort.
  # Calendar times are similarly extended: t runs 1..(p+1).
  groups_orig <- sort(unique(theta_gt$g))  # e.g. 1, 2, 3
  q           <- length(groups_orig)
  groups_did  <- groups_orig + 1L          # e.g. 2, 3, 4  (did cohort labels)
  p_did       <- p + 1L                    # extend calendar to match shift

  # Map did cohort label back to original for theta_gt lookup
  g_did_to_orig <- setNames(groups_orig, as.character(groups_did))

  # --- Assign units to cohorts ---
  # did convention: Inf = never-treated (not 0, which did treats as treated at t=0)
  all_cohorts <- c(Inf, groups_did)
  n_units     <- (q + 1L) * n_per_cohort

  cohort_vec <- rep(all_cohorts, each = n_per_cohort)
  id_vec     <- seq_len(n_units)

  # Unit fixed effects (shared across time)
  alpha_i <- stats::rnorm(n_units, mean = 0, sd = sigma_alpha)

  # Look up true theta_gt for each (did cohort, did calendar time) pair.
  # did calendar t maps to original calendar t_orig = t_did - 1;
  # did cohort g_did maps to original cohort g_orig via g_did_to_orig.
  theta_lookup <- function(g_did_val, t_did_val) {
    if (!is.finite(g_did_val)) return(0)          # never-treated
    t_orig <- t_did_val - 1L
    g_orig <- g_did_to_orig[as.character(as.integer(g_did_val))]
    if (t_orig < g_orig) return(0)                # pre-treatment
    row <- theta_gt[theta_gt$g == g_orig & theta_gt$t == t_orig, , drop = FALSE]
    if (nrow(row) == 0L) return(0)
    row$theta_gt[1L]
  }

  # Build long panel
  panel <- expand.grid(id = id_vec, t = seq_len(p_did), stringsAsFactors = FALSE)
  panel <- tibble::as_tibble(panel)
  panel$g_true  <- cohort_vec[panel$id]
  panel$alpha_i <- alpha_i[panel$id]
  panel$D       <- as.integer(is.finite(panel$g_true) & panel$t >= panel$g_true)

  # True ATT for this unit's (cohort, time) cell
  panel$tau_gt <- mapply(theta_lookup, panel$g_true, panel$t)

  # Potential outcomes: Y(0) = alpha_i + N(0, sigma_Y), Y(1) = Y(0) + tau_gt
  panel$eps <- stats::rnorm(nrow(panel), mean = 0, sd = sigma_Y)
  panel$Y   <- panel$alpha_i + panel$D * panel$tau_gt + panel$eps

  # Keep only columns needed by did::att_gt()
  tibble::tibble(
    id     = panel$id,
    g_true = panel$g_true,
    t      = panel$t,
    Y      = panel$Y,
    D      = panel$D
  )
}

#' Estimate group-time ATTs via did::att_gt() and return a gt_object
#'
#' Drop-in replacement for `add_noise_and_eif()` that uses a real
#' `did::att_gt()` first stage instead of synthetic Gaussian noise.
#' Exercises the full pipeline: unit-level data → did estimation →
#' `as_gt_object()` → `extrapolate_ATT()` → `compute_variance()`.
#'
#' @param theta_gt Tibble from `make_theta_gt()`.
#' @param n_per_cohort Units per treated cohort (and for never-treated group).
#' @param p Last observed calendar time.
#' @param sigma_Y SD of outcome noise.
#' @param sigma_alpha SD of unit fixed effects.
#' @param seed Optional seed (passed to `generate_panel_data()`).
#' @param ... Additional arguments forwarded to `did::att_gt()`.
#' @return A `gt_object` with real EIFs extracted from `did::att_gt()$inffunc`.
#' @export
add_did_eif <- function(theta_gt, n_per_cohort, p,
                        sigma_Y = 0.5, sigma_alpha = 1.0,
                        seed = NULL, ...) {
  if (!requireNamespace("did", quietly = TRUE)) {
    stop("Package 'did' is required for add_did_eif(). Install it with install.packages('did').",
         call. = FALSE)
  }

  panel <- generate_panel_data(
    theta_gt     = theta_gt,
    n_per_cohort = n_per_cohort,
    p            = p,
    sigma_Y      = sigma_Y,
    sigma_alpha  = sigma_alpha,
    seed         = seed
  )

  # did::att_gt requires: yname, tname, idname, gname, data
  # control_group = "nevertreated": units with g_true == 0 serve as controls
  att <- did::att_gt(
    yname         = "Y",
    tname         = "t",
    idname        = "id",
    gname         = "g_true",
    data          = panel,
    control_group = "nevertreated",
    ...
  )

  # did::att_gt() reports ATT(g,t) for EVERY (g,t) pair it can identify,
  # including pre-treatment placebo cells (t < g, i.e. event time k < 0) used
  # for parallel-trends diagnostics. as_gt_object() passes these through
  # verbatim (gt_object_from_att_gt() copies att$group/att$t as-is), but
  # hg_linear()/extrapolate_ATT() fit a single OLS line per group across
  # whatever cells they're given -- pre-treatment cells (true ATT ~= 0 by
  # design) pooled with the increasing post-treatment cells flatten the
  # fitted slope and bias the extrapolated FATT downward. Path 2's model
  # theta_gt = f(g,t;gamma) is defined for post-treatment cells only, so
  # filter to t >= g (k >= 0) before building the gt_object.
  post_idx <- att$t >= att$group
  att$group <- att$group[post_idx]
  att$t     <- att$t[post_idx]
  att$att   <- att$att[post_idx]
  if (!is.null(att$se)) att$se <- att$se[post_idx]
  if (!is.null(att$inffunc)) att$inffunc <- att$inffunc[, post_idx, drop = FALSE]

  # Convert to gt_object, extracting real inffunc EIFs
  as_gt_object(att, extract_eif = TRUE)
}

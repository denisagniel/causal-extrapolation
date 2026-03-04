# Section 8.1: Non-Smooth Dynamics (Path 2 Break Point)
#
# Purpose: Show Path 2 fails when true functional form is not smooth
#
# DGP: Piecewise linear with break at k=3
#      theta_gt = alpha_g + beta1_g * k  if k <= 3
#               = alpha_g + beta1_g * 3 + beta2_g * (k - 3)  if k > 3
#      where beta2_g ≠ beta1_g (sharp slope change)
#
# Methods:
#   - Path 2 with linear model (underfit)
#   - Path 2 with quadratic model (still smooth → bad approximation)
#   - Path 2 with spline model (may adapt if knots placed correctly)
#
# Expected result:
#   - All smooth parametric models struggle
#   - Extrapolation beyond k=3 systematically biased
#   - Coverage collapse
#
# Why this matters:
#   - Path 2 assumes effects follow a smooth parametric function
#   - Real policy effects may have breaks (e.g., phase-in, saturation, regime change)
#   - This shows the consequences when structural form is misspecified

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})

devtools::load_all("package")
source("sims/scripts/dgp_helpers.R")
source("sims/scripts/dgp_helpers_section8.R")

# Simulation parameters
q <- 3                   # Number of groups
p <- 5                   # Last observed period (covers both regimes: k=0..4)
n <- 500                 # Sample size
n_replicates <- 1000     # Number of simulation replications
future_time <- p + 1     # Extrapolation target (k=5 for earliest group)
level <- 0.95            # Confidence level
sigma_tau <- 0.1         # First-stage noise

# Weights (equal)
omega <- rep(1 / q, q)

# DGP parameters: Piecewise linear with break at k=3
break_k <- 3
alpha_g <- c(0.2, 0, -0.1)
beta1_g <- c(0.1, 0.08, 0.12)   # Slope before break
beta2_g <- c(0.3, 0.25, 0.35)   # Slope after break (much steeper)

# Generate true group-time effects (piecewise linear)
theta_gt_piecewise <- make_theta_gt_piecewise(
  q = q, p = p,
  alpha_g = alpha_g,
  beta1_g = beta1_g,
  beta2_g = beta2_g,
  break_k = break_k,
  seed = 8101
)

# True FATT at p+1
true_fatt_piecewise <- true_fatt_piecewise(
  omega = omega,
  future_time = future_time,
  q = q,
  alpha_g = alpha_g,
  beta1_g = beta1_g,
  beta2_g = beta2_g,
  break_k = break_k
)

message("True FATT (piecewise linear): ", round(true_fatt_piecewise, 3))
message("Break occurs at k = ", break_k)
message("Extrapolating to k = ", future_time - seq_len(q), " for groups 1-", q)

# ============================================================================
# Method 1: Path 2 with linear model (underfit)
# ============================================================================

message("\nRunning Method 1: Path 2 with linear model...")

bias_linear <- numeric(n_replicates)
covered_linear <- logical(n_replicates)

for (r in seq_len(n_replicates)) {
  gt <- add_noise_and_eif(
    theta_gt_piecewise, n = n,
    sigma_tau = sigma_tau, seed = 8100L + r
  )

  ex <- extrapolate_ATT(
    gt,
    h_fun = hg_linear,
    dh_fun = dh_linear,
    future_value = future_time,
    time_scale = "calendar",
    omega = omega,
    per_group = FALSE
  )

  inf <- compute_variance(
    ex$phi_future,
    estimate = ex$tau_future,
    level = level
  )

  bias_linear[r] <- ex$tau_future - true_fatt_piecewise
  covered_linear[r] <- (
    true_fatt_piecewise >= inf$ci[1] &&
    true_fatt_piecewise <= inf$ci[2]
  )
}

# ============================================================================
# Method 2: Path 2 with quadratic model (still smooth)
# ============================================================================

message("Running Method 2: Path 2 with quadratic model...")

bias_quadratic <- numeric(n_replicates)
covered_quadratic <- logical(n_replicates)

for (r in seq_len(n_replicates)) {
  gt <- add_noise_and_eif(
    theta_gt_piecewise, n = n,
    sigma_tau = sigma_tau, seed = 8200L + r
  )

  ex <- extrapolate_ATT(
    gt,
    h_fun = hg_quadratic,
    dh_fun = dh_quadratic,
    future_value = future_time,
    time_scale = "calendar",
    omega = omega,
    per_group = FALSE
  )

  inf <- compute_variance(
    ex$phi_future,
    estimate = ex$tau_future,
    level = level
  )

  bias_quadratic[r] <- ex$tau_future - true_fatt_piecewise
  covered_quadratic[r] <- (
    true_fatt_piecewise >= inf$ci[1] &&
    true_fatt_piecewise <= inf$ci[2]
  )
}

# ============================================================================
# Method 3: Path 2 with spline model (knots at observed times)
# ============================================================================

message("Running Method 3: Path 2 with spline model...")

# Define custom spline model (natural cubic spline with knots at observed times)
# This is more flexible than linear/quadratic but still may miss sharp breaks

# For simplicity, we'll use a quadratic spline with a knot at t=4 (near the break)
# In practice, knot placement is critical for capturing non-smooth dynamics

hg_spline_knot4 <- function(times_vec, future_value, knot_time = 4, ...) {
  # Simplified linear spline with knot (piecewise linear, not quadratic)
  # h(t) = beta_0 + beta_1 * t + beta_2 * max(t - knot, 0)
  # Only 3 parameters to avoid singularity issues with small p

  # Build design matrix
  X <- cbind(
    1,                               # Intercept
    times_vec,                       # Linear term
    pmax(times_vec - knot_time, 0)   # Knot term (linear spline)
  )

  # Future design vector
  x_star <- c(
    1,
    future_value,
    max(future_value - knot_time, 0)
  )

  # Safe matrix inversion (use package utility)
  XtX_inv <- extrapolateATT:::safe_matrix_inverse(X)
  weights <- as.numeric(t(x_star) %*% XtX_inv %*% t(X))

  # Return function that applies weights to tau_vec
  function(tau_vec) {
    as.numeric(sum(weights * tau_vec))
  }
}

dh_spline_knot4 <- function(times_vec, future_value, knot_time = 4, ...) {
  # Gradient for linear spline model
  # Returns vector of weights (Jacobian)

  # Build design matrix
  X <- cbind(
    1,
    times_vec,
    pmax(times_vec - knot_time, 0)
  )

  # Future design vector
  x_star <- c(
    1,
    future_value,
    max(future_value - knot_time, 0)
  )

  # Safe matrix inversion
  XtX_inv <- extrapolateATT:::safe_matrix_inverse(X)
  weights <- as.numeric(t(x_star) %*% XtX_inv %*% t(X))

  weights
}

bias_spline <- numeric(n_replicates)
covered_spline <- logical(n_replicates)

for (r in seq_len(n_replicates)) {
  gt <- add_noise_and_eif(
    theta_gt_piecewise, n = n,
    sigma_tau = sigma_tau, seed = 8300L + r
  )

  ex <- extrapolate_ATT(
    gt,
    h_fun = hg_spline_knot4,
    dh_fun = dh_spline_knot4,
    future_value = future_time,
    time_scale = "calendar",
    omega = omega,
    per_group = FALSE
  )

  inf <- compute_variance(
    ex$phi_future,
    estimate = ex$tau_future,
    level = level
  )

  bias_spline[r] <- ex$tau_future - true_fatt_piecewise
  covered_spline[r] <- (
    true_fatt_piecewise >= inf$ci[1] &&
    true_fatt_piecewise <= inf$ci[2]
  )
}

# ============================================================================
# Compile Results
# ============================================================================

results_s8_1 <- list(
  true_fatt = true_fatt_piecewise,
  linear_model = list(
    bias = mean(bias_linear),
    rmse = sqrt(mean(bias_linear^2)),
    coverage = mean(covered_linear),
    n_replicates = n_replicates
  ),
  quadratic_model = list(
    bias = mean(bias_quadratic),
    rmse = sqrt(mean(bias_quadratic^2)),
    coverage = mean(covered_quadratic),
    n_replicates = n_replicates
  ),
  spline_model = list(
    bias = mean(bias_spline),
    rmse = sqrt(mean(bias_spline^2)),
    coverage = mean(covered_spline),
    n_replicates = n_replicates
  ),
  dgp_params = list(
    break_k = break_k,
    alpha_g = alpha_g,
    beta1_g = beta1_g,
    beta2_g = beta2_g,
    n = n,
    q = q,
    p = p,
    future_time = future_time,
    sigma_tau = sigma_tau
  )
)

# Save results
dir.create("sims/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(results_s8_1, "sims/results/section8_1_nonsmooth.rds")
message("Section 8.1 done: section8_1_nonsmooth.rds saved")

# Print summary
message("\n=== Section 8.1 Results Summary ===")
message(sprintf("True FATT (piecewise linear): %.3f", results_s8_1$true_fatt))
message(sprintf("Break at k=%d, extrapolating to k=%d-%d",
                break_k, min(future_time - seq_len(q)), max(future_time - seq_len(q))))
message("\nLinear model:")
message(sprintf("  Bias: %.3f, RMSE: %.3f, Coverage: %.1f%%",
                results_s8_1$linear_model$bias,
                results_s8_1$linear_model$rmse,
                results_s8_1$linear_model$coverage * 100))
message("\nQuadratic model:")
message(sprintf("  Bias: %.3f, RMSE: %.3f, Coverage: %.1f%%",
                results_s8_1$quadratic_model$bias,
                results_s8_1$quadratic_model$rmse,
                results_s8_1$quadratic_model$coverage * 100))
message("\nSpline model (knot at t=4):")
message(sprintf("  Bias: %.3f, RMSE: %.3f, Coverage: %.1f%%",
                results_s8_1$spline_model$bias,
                results_s8_1$spline_model$rmse,
                results_s8_1$spline_model$coverage * 100))

message("\n=== Key Insight ===")
message("Smooth parametric models (linear, quadratic, spline) cannot capture")
message("sharp breaks in treatment effect dynamics. Extrapolation beyond the")
message("break point is systematically biased when the true functional form")
message("has discontinuities in the derivative (non-smooth).")

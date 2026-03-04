# Section 8.3: Small-Sample Extrapolation (All Paths)
#
# Purpose: Show uncertainty explosion with few periods
#
# DGP: Linear in event time (true model simple)
#      Vary p = 2, 3, 4, 5, 10 (number of observed periods)
#
# Methods:
#   - Path 1: Average over sparse observations
#   - Path 2: Fit linear model with p-2 degrees of freedom remaining
#
# Expected result:
#   - SE grows rapidly as p → 2
#   - Path 2 undefined for p < 3 (cannot fit linear model in calendar time)
#   - Coverage may be anti-conservative due to model uncertainty
#
# Why this matters:
#   - Researchers often have limited post-treatment periods (DiD reality)
#   - Extrapolation with few observations is highly uncertain
#   - This simulation quantifies the uncertainty-sample size relationship

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})

devtools::load_all("package")
source("sims/scripts/dgp_helpers.R")

# Simulation parameters
q <- 2                   # Number of groups (fixed at 2 to ensure p >= g for all groups)
n <- 500                 # Sample size
n_replicates <- 1000     # Number of simulation replications
level <- 0.95            # Confidence level
sigma_tau <- 0.1         # First-stage noise

# DGP parameters: Linear in event time (simple, well-specified)
alpha_g <- c(0.2, 0)
beta_g <- c(0.1, 0.08)

# Grid of p values (number of observed periods)
p_grid <- c(2, 3, 4, 5, 10)

# Storage for results across p values
results_by_p <- list()

for (p_val in p_grid) {
  message("\n=== Running simulations for p = ", p_val, " ===")

  future_time <- p_val + 1

  # Determine which groups have been treated by time p_val
  # Group g is treated at time g, so by time p_val, groups 1..p_val have been treated
  # But q=3, so we need min(q, p_val) groups
  q_active <- min(q, p_val)
  omega <- rep(1 / q_active, q_active)

  message("  Active groups: ", q_active, " (treated by time ", p_val, ")")

  # Generate true group-time effects
  theta_gt_linear <- make_theta_gt(
    q = q_active, p = p_val,
    spec = "linear",
    alpha_g = alpha_g[1:q_active],
    beta_g = beta_g[1:q_active],
    seed = 8300 + p_val
  )

  # True FATT at p+1
  true_fatt <- true_fatt_from_dgp(
    omega = omega,
    future_time = future_time,
    q = q_active,
    spec = "linear",
    alpha_g = alpha_g[1:q_active],
    beta_g = beta_g[1:q_active]
  )

  # ============================================================================
  # Path 1: Simple average (always defined)
  # ============================================================================

  bias_path1 <- numeric(n_replicates)
  se_path1 <- numeric(n_replicates)
  ci_width_path1 <- numeric(n_replicates)
  covered_path1 <- logical(n_replicates)

  for (r in seq_len(n_replicates)) {
    gt <- add_noise_and_eif(
      theta_gt_linear, n = n,
      sigma_tau = sigma_tau, seed = 8300L + p_val * 1000L + r
    )

    # Path 1: Average (constant model extrapolation)
    # Assumes time homogeneity: future effect = average of observed effects

    ex <- extrapolate_ATT(
      gt,
      h_fun = function(times_vec, future_value, ...) {
        # Constant model: h(t) = mean(tau)
        # Returns function factory that averages tau_vec
        function(tau_vec) {
          mean(tau_vec)
        }
      },
      dh_fun = function(times_vec, future_value, ...) {
        # Gradient: equal weights on all observations
        rep(1 / length(times_vec), length(times_vec))
      },
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

    bias_path1[r] <- ex$tau_future - true_fatt
    se_path1[r] <- inf$se
    ci_width_path1[r] <- inf$ci[2] - inf$ci[1]
    covered_path1[r] <- (
      true_fatt >= inf$ci[1] &&
      true_fatt <= inf$ci[2]
    )
  }

  # ============================================================================
  # Path 2: Linear extrapolation (requires p >= 3 for calendar-time fit)
  # ============================================================================

  if (p_val >= 3) {
    bias_path2 <- numeric(n_replicates)
    se_path2 <- numeric(n_replicates)
    ci_width_path2 <- numeric(n_replicates)
    covered_path2 <- logical(n_replicates)

    for (r in seq_len(n_replicates)) {
      gt <- add_noise_and_eif(
        theta_gt_linear, n = n,
        sigma_tau = sigma_tau, seed = 8400L + p_val * 1000L + r
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

      bias_path2[r] <- ex$tau_future - true_fatt
      se_path2[r] <- inf$se
      ci_width_path2[r] <- inf$ci[2] - inf$ci[1]
      covered_path2[r] <- (
        true_fatt >= inf$ci[1] &&
        true_fatt <= inf$ci[2]
      )
    }
  } else {
    # Path 2 undefined for p < 3
    bias_path2 <- NA
    se_path2 <- NA
    ci_width_path2 <- NA
    covered_path2 <- NA
  }

  # ============================================================================
  # Store results for this p
  # ============================================================================

  results_by_p[[paste0("p_", p_val)]] <- list(
    p = p_val,
    true_fatt = true_fatt,
    path1 = list(
      bias = mean(bias_path1),
      rmse = sqrt(mean(bias_path1^2)),
      se_mean = mean(se_path1),
      se_sd = sd(se_path1),
      ci_width_mean = mean(ci_width_path1),
      coverage = mean(covered_path1),
      n_replicates = n_replicates
    ),
    path2 = if (p_val >= 3) {
      list(
        bias = mean(bias_path2),
        rmse = sqrt(mean(bias_path2^2)),
        se_mean = mean(se_path2),
        se_sd = sd(se_path2),
        ci_width_mean = mean(ci_width_path2),
        coverage = mean(covered_path2),
        n_replicates = n_replicates
      )
    } else {
      list(
        bias = NA,
        rmse = NA,
        se_mean = NA,
        se_sd = NA,
        ci_width_mean = NA,
        coverage = NA,
        n_replicates = n_replicates,
        note = "Path 2 undefined for p < 3 (insufficient degrees of freedom)"
      )
    }
  )
}

# ============================================================================
# Compile Results
# ============================================================================

results_s8_3 <- list(
  results_by_p = results_by_p,
  dgp_params = list(
    alpha_g = alpha_g,
    beta_g = beta_g,
    n = n,
    q = q,
    sigma_tau = sigma_tau,
    spec = "linear"
  ),
  p_grid = p_grid
)

# Save results
dir.create("sims/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(results_s8_3, "sims/results/section8_3_smallsample.rds")
message("\nSection 8.3 done: section8_3_smallsample.rds saved")

# Print summary table
message("\n=== Section 8.3 Results Summary ===")
message("\nPath 1 (Simple Average):")
message(sprintf("%-5s | %8s | %8s | %12s | %10s", "p", "Bias", "RMSE", "CI Width", "Coverage"))
message(strrep("-", 55))
for (p_val in p_grid) {
  res <- results_s8_3$results_by_p[[paste0("p_", p_val)]]$path1
  message(sprintf("%-5d | %8.3f | %8.3f | %12.3f | %9.1f%%",
                  p_val, res$bias, res$rmse, res$ci_width_mean, res$coverage * 100))
}

message("\nPath 2 (Linear Extrapolation):")
message(sprintf("%-5s | %8s | %8s | %12s | %10s", "p", "Bias", "RMSE", "CI Width", "Coverage"))
message(strrep("-", 55))
for (p_val in p_grid) {
  res <- results_s8_3$results_by_p[[paste0("p_", p_val)]]$path2
  if (is.na(res$bias)) {
    message(sprintf("%-5d | %s", p_val, "undefined (p < 3)"))
  } else {
    message(sprintf("%-5d | %8.3f | %8.3f | %12.3f | %9.1f%%",
                    p_val, res$bias, res$rmse, res$ci_width_mean, res$coverage * 100))
  }
}

message("\n=== Key Insight ===")
message("Standard error (SE) and CI width grow rapidly as p decreases.")
message("With few observed periods (p=2,3), extrapolation is highly uncertain.")
message("Path 2 requires p >= 3 to fit linear model (2 parameters: intercept + slope).")
message("Even when p >= 3, CI width is much larger for small p.")
message("\nFor p=2: CI width ≈ ", sprintf("%.2f", results_s8_3$results_by_p$p_2$path1$ci_width_mean))
message("For p=10: CI width ≈ ", sprintf("%.2f", results_s8_3$results_by_p$p_10$path1$ci_width_mean))
message("\nThis quantifies the practical cost of limited post-treatment data.")

# Section 7: Path 3 (Covariate Integration) under Lucas Critique / Regime Change
#
# Demonstrates Path 3's advantage when:
# - True effects are driven by structural covariates: tau(X) = alpha + beta * X
# - Regime change occurs (covariate distribution shifts at p+1)
# - Path 1 fails: averages historical effects under old composition
# - Path 2 fails: extrapolates spurious "time trends" that are actually composition changes
# - Path 3 succeeds: tau(X) is regime-invariant, integrated over new distribution

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})

devtools::load_all("package")
source("sims/scripts/dgp_helpers.R")

# Setup
q <- 3
p <- 5
n <- 500
n_replicates <- 1000
omega <- rep(1 / q, q)
future_time <- p + 1
level <- 0.95
sigma_tau <- 0.1

# Conditional model: tau(X) = 2 + 1.5 * X (structural, time-invariant)
alpha <- 2.0
beta <- 1.5

# Group-specific X distributions (composition differences)
mu_g <- c(-1.0, 0.0, 1.0)  # Groups differ systematically in X
sigma_X <- 1.0

# Regime change: target distribution at p+1 has shifted mean
# (e.g., policy now targets higher-X units, or demographic composition changed)
mu_target <- 0.5  # Historical average was ~0, new target is +0.5

# Generate DGP
theta_gt <- make_theta_gt_conditional(
  q = q, p = p, alpha = alpha, beta = beta,
  mu_g = mu_g, sigma_X = sigma_X, seed = 701
)

# True FATT under target distribution
true_fatt <- true_fatt_conditional(alpha, beta, mu_target)  # 2 + 1.5*0.5 = 2.75

# True backward-looking ATT (historical average)
# Since theta_gt = alpha + beta * mu_g[g], and groups are equally weighted:
true_backward_att <- true_backward_att(theta_gt)  # alpha + beta * mean(mu_g) = 2 + 1.5*0 = 2.0

message(sprintf("True FATT (target mu=%.1f): %.3f", mu_target, true_fatt))
message(sprintf("True backward ATT (historical): %.3f", true_backward_att))
message(sprintf("Divergence due to regime change: %.3f\n", true_fatt - true_backward_att))

# Storage for results
path1_est <- numeric(n_replicates)
path1_covered <- logical(n_replicates)

# Path 2: Fit temporal model (will pick up spurious "trend" from composition changes)
# Note: In this DGP, theta_gt is constant within group (no true time dynamics),
# but if we naively fit a temporal model to calendar time, it may pick up composition effects.
path2_est <- numeric(n_replicates)
path2_covered <- logical(n_replicates)

# Path 3: Placeholder for when integrate_covariates() is implemented (Phase 4)
# For now, we compute the oracle Path 3 estimate: average tau(X_i*) over target sample
# This demonstrates what Path 3 *should* achieve.
path3_est <- numeric(n_replicates)
path3_covered <- logical(n_replicates)

for (r in seq_len(n_replicates)) {
  gt <- add_noise_and_eif(theta_gt, n = n, sigma_tau = sigma_tau, seed = 7000L + r)

  # --- Path 1: Time homogeneity (aggregate historical effects) ---
  path1 <- path1_aggregate(gt, omega)
  inf1 <- compute_variance(path1$phi_future, estimate = path1$tau_future, level = level)
  path1_est[r] <- path1$tau_future
  path1_covered[r] <- (true_fatt >= inf1$ci[1] && true_fatt <= inf1$ci[2])

  # --- Path 2: Temporal extrapolation (linear in calendar time) ---
  # Note: Since theta_gt has no true time trend (constant within group),
  # any fitted trend is spurious (composition artifact).
  # We'll fit a linear-in-calendar-time model as a "bad" extrapolation.
  ex <- extrapolate_ATT(gt, h_fun = hg_linear, dh_fun = dh_linear,
                       future_value = future_time, time_scale = "calendar",
                       omega = omega, per_group = FALSE)
  inf2 <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = level)
  path2_est[r] <- ex$tau_future
  path2_covered[r] <- (true_fatt >= inf2$ci[1] && true_fatt <= inf2$ci[2])

  # --- Path 3: Covariate integration (oracle version for demonstration) ---
  # Oracle: Draw target covariates and compute mean(tau(X_i*)) = mean(alpha + beta * X_i*)
  # This is what integrate_covariates() will do in Phase 4.
  # For now, compute oracle estimate with correct EIF propagation (simplified).
  X_target <- generate_target_covariates(n_target = 200, mu_target = mu_target,
                                         sigma_X = sigma_X, seed = 7000L + r)
  tau_X <- alpha + beta * X_target$X
  path3_oracle <- mean(tau_X)

  # Simplified EIF for Path 3 (oracle case):
  # In reality, this would propagate through beta estimation from gt.
  # For demonstration, we add noise matching the Path 1/2 variance structure.
  path3_est[r] <- path3_oracle + rnorm(1, mean = 0, sd = sigma_tau)

  # Simplified CI (oracle + noise)
  path3_se <- sigma_tau  # Placeholder; true SE would come from EIF propagation
  path3_ci <- path3_est[r] + c(-1, 1) * qnorm(1 - (1 - level) / 2) * path3_se
  path3_covered[r] <- (true_fatt >= path3_ci[1] && true_fatt <= path3_ci[2])
}

# Results summary
results_s7 <- list(
  true_fatt = true_fatt,
  true_backward_att = true_backward_att,
  regime_change_gap = true_fatt - true_backward_att,
  mu_target = mu_target,
  mu_g = mu_g,
  alpha = alpha,
  beta = beta,
  Path1_TimeHomogeneity = list(
    bias = mean(path1_est - true_fatt),
    rmse = sqrt(mean((path1_est - true_fatt)^2)),
    coverage = mean(path1_covered),
    note = "Biased: averages historical effects under old composition"
  ),
  Path2_TemporalExtrapolation = list(
    bias = mean(path2_est - true_fatt),
    rmse = sqrt(mean((path2_est - true_fatt)^2)),
    coverage = mean(path2_covered),
    note = "Biased: extrapolates spurious trends from composition changes"
  ),
  Path3_CovariateIntegration_Oracle = list(
    bias = mean(path3_est - true_fatt),
    rmse = sqrt(mean((path3_est - true_fatt)^2)),
    coverage = mean(path3_covered),
    note = "Unbiased (oracle): tau(X) is regime-invariant"
  ),
  n_replicates = n_replicates
)

# Save results
dir.create("sims/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(results_s7, "sims/results/section7_path3_covariates.rds")

# Print summary
cat("\n=== Section 7: Path 3 under Regime Change ===\n")
cat(sprintf("True FATT (target mu=%.1f): %.3f\n", mu_target, true_fatt))
cat(sprintf("True backward ATT: %.3f\n", true_backward_att))
cat(sprintf("Regime change gap: %.3f\n\n", results_s7$regime_change_gap))

cat("Path 1 (Time Homogeneity):\n")
cat(sprintf("  Bias: %.4f, RMSE: %.4f, Coverage: %.2f%%\n",
            results_s7$Path1_TimeHomogeneity$bias,
            results_s7$Path1_TimeHomogeneity$rmse,
            results_s7$Path1_TimeHomogeneity$coverage * 100))

cat("\nPath 2 (Temporal Extrapolation):\n")
cat(sprintf("  Bias: %.4f, RMSE: %.4f, Coverage: %.2f%%\n",
            results_s7$Path2_TemporalExtrapolation$bias,
            results_s7$Path2_TemporalExtrapolation$rmse,
            results_s7$Path2_TemporalExtrapolation$coverage * 100))

cat("\nPath 3 (Covariate Integration, Oracle):\n")
cat(sprintf("  Bias: %.4f, RMSE: %.4f, Coverage: %.2f%%\n",
            results_s7$Path3_CovariateIntegration_Oracle$bias,
            results_s7$Path3_CovariateIntegration_Oracle$rmse,
            results_s7$Path3_CovariateIntegration_Oracle$coverage * 100))

cat("\n** Note: Path 3 is oracle version for demonstration (Phase 4 will implement full integrate_covariates()) **\n")

message("\nSection 7 done: section7_path3_covariates.rds saved")

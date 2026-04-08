# Section 8.2: Conditional Model Misspecification (Path 3 Break Point)
#
# Purpose: Show Path 3 fails when unobserved heterogeneity dominates
#
# DGP: True effect driven by X (observed) AND U (unobserved)
#      tau(X, U) = alpha + beta_X * X + beta_U * U
#      where U ~ N(0, 1), correlated with X: cor(X, U) = rho
#
# Methods:
#   - Path 3 with linear-in-X model (misspecified - omits U)
#   - Oracle: Path 3 with true model including U (for comparison)
#
# Expected result:
#   - Path 3 biased when U omitted
#   - Bias magnitude depends on cor(X, U) and beta_U
#   - Coverage fails
#
# Why this matters:
#   - Covariate-based extrapolation (Path 3) relies on observing all relevant
#     predictors of treatment effects
#   - In practice, unobserved heterogeneity (U) is common
#   - This simulation shows the consequences of omitted variable bias for
#     extrapolation, not just for point estimation

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})

devtools::load_all("package")
source("sims/scripts/dgp_helpers.R")
source("sims/scripts/dgp_helpers_section8.R")

# Simulation parameters
q <- 3                   # Number of groups
p <- 5                   # Last observed period
n <- 500                 # Sample size
n_replicates <- 1000     # Number of simulation replications
future_time <- p + 1     # Extrapolation target
level <- 0.95            # Confidence level

# DGP parameters
alpha <- 2.0             # Intercept
beta_X <- 1.5            # Effect of observed X
beta_U <- 3.0            # Effect of unobserved U (strong)
sigma_X <- 1.0           # SD of X
n_target <- 200          # Target sample size

# Historical covariate distribution (by group)
mu_g <- c(-1, 0, 1)      # Group means of X (spread across support)

# Target covariate distribution (regime change: shift in X)
mu_X_target <- 0.5       # Moderate shift from historical mean(mu_g) = 0
mu_U_target <- 0.0       # U mean stays at 0 (structural stability)

# Weights (equal for simplicity)
omega <- rep(1 / q, q)

# ============================================================================
# Scenario 1: Moderate confounding (cor(X, U) = 0.5)
# ============================================================================

message("Running Section 8.2 Scenario 1: Moderate confounding (cor = 0.5)...")

cor_XU <- 0.5

# Generate true group-time effects
theta_gt_confounded <- make_theta_gt_unobserved(
  q = q, p = p,
  alpha = alpha, beta_X = beta_X, beta_U = beta_U,
  cor_XU = cor_XU, mu_g = mu_g, sigma_X = sigma_X,
  seed = 8201
)

# True FATT at p+1
# Target distribution: X ~ N(mu_X_target, sigma_X^2), U ~ N(mu_U_target, sigma_U^2)
# with cor(X, U) = cor_XU
# For target, we need E[U | mean(X) = mu_X_target]
# Under bivariate normal: E[U | X] = mu_U + cor_XU * (X - mu_X) / sigma_X * sigma_U
# Since mu_X = 0, mu_U = 0, sigma_U = 1:
# E[U | X = mu_X_target] = cor_XU * mu_X_target / sigma_X
mu_U_given_X_target <- cor_XU * mu_X_target / sigma_X

true_fatt_confounded <- true_fatt_unobserved(
  alpha = alpha,
  beta_X = beta_X,
  beta_U = beta_U,
  mu_X_target = mu_X_target,
  mu_U_target = mu_U_given_X_target
)

# Generate target sample (FIXED across replications for consistency)
set.seed(8202)
target_sample <- generate_target_covariates_unobserved(
  n_target = n_target,
  mu_X_target = mu_X_target,
  mu_U_target = mu_U_given_X_target,
  sigma_X = sigma_X,
  sigma_U = 1.0,
  cor_XU = cor_XU
)

# Storage
bias_path3_misspec_mod <- numeric(n_replicates)
covered_path3_misspec_mod <- logical(n_replicates)
bias_path3_oracle_mod <- numeric(n_replicates)
covered_path3_oracle_mod <- logical(n_replicates)

for (r in seq_len(n_replicates)) {
  # Generate gt_object with first-stage estimates
  gt <- add_noise_and_eif(
    theta_gt_confounded, n = n,
    sigma_tau = 0.1, seed = 8200L + r
  )

  # Path 3 (misspecified): fit linear-in-X model (omits U)
  # This uses only observed X
  ex_misspec <- integrate_covariates(
    gt,
    x_vars = target_sample$X,  # Only X, not U
    x_target = target_sample %>% select(X),
    omega = omega
  )

  inf_misspec <- compute_variance(
    ex_misspec$phi_future,
    estimate = ex_misspec$tau_future,
    level = level
  )

  bias_path3_misspec_mod[r] <- ex_misspec$tau_future - true_fatt_confounded
  covered_path3_misspec_mod[r] <- (
    true_fatt_confounded >= inf_misspec$ci[1] &&
    true_fatt_confounded <= inf_misspec$ci[2]
  )

  # Oracle: fit true model including both X and U
  # In practice U is unobserved, but we include it here to show what happens
  # if we had the correct model
  ex_oracle <- integrate_covariates(
    gt,
    x_vars = target_sample %>% select(X, U),
    x_target = target_sample %>% select(X, U),
    omega = omega
  )

  inf_oracle <- compute_variance(
    ex_oracle$phi_future,
    estimate = ex_oracle$tau_future,
    level = level
  )

  bias_path3_oracle_mod[r] <- ex_oracle$tau_future - true_fatt_confounded
  covered_path3_oracle_mod[r] <- (
    true_fatt_confounded >= inf_oracle$ci[1] &&
    true_fatt_confounded <= inf_oracle$ci[2]
  )
}

# ============================================================================
# Scenario 2: Strong confounding (cor(X, U) = 0.8)
# ============================================================================

message("Running Section 8.2 Scenario 2: Strong confounding (cor = 0.8)...")

cor_XU_strong <- 0.8

theta_gt_strong <- make_theta_gt_unobserved(
  q = q, p = p,
  alpha = alpha, beta_X = beta_X, beta_U = beta_U,
  cor_XU = cor_XU_strong, mu_g = mu_g, sigma_X = sigma_X,
  seed = 8203
)

mu_U_given_X_target_strong <- cor_XU_strong * mu_X_target / sigma_X

true_fatt_strong <- true_fatt_unobserved(
  alpha = alpha,
  beta_X = beta_X,
  beta_U = beta_U,
  mu_X_target = mu_X_target,
  mu_U_target = mu_U_given_X_target_strong
)

# Generate target sample
set.seed(8204)
target_sample_strong <- generate_target_covariates_unobserved(
  n_target = n_target,
  mu_X_target = mu_X_target,
  mu_U_target = mu_U_given_X_target_strong,
  sigma_X = sigma_X,
  sigma_U = 1.0,
  cor_XU = cor_XU_strong
)

bias_path3_misspec_strong <- numeric(n_replicates)
covered_path3_misspec_strong <- logical(n_replicates)
bias_path3_oracle_strong <- numeric(n_replicates)
covered_path3_oracle_strong <- logical(n_replicates)

for (r in seq_len(n_replicates)) {
  gt <- add_noise_and_eif(
    theta_gt_strong, n = n,
    sigma_tau = 0.1, seed = 8300L + r
  )

  # Misspecified (X only)
  ex_misspec <- integrate_covariates(
    gt,
    x_vars = target_sample_strong$X,
    x_target = target_sample_strong %>% select(X),
    omega = omega
  )

  inf_misspec <- compute_variance(
    ex_misspec$phi_future,
    estimate = ex_misspec$tau_future,
    level = level
  )

  bias_path3_misspec_strong[r] <- ex_misspec$tau_future - true_fatt_strong
  covered_path3_misspec_strong[r] <- (
    true_fatt_strong >= inf_misspec$ci[1] &&
    true_fatt_strong <= inf_misspec$ci[2]
  )

  # Oracle (X and U)
  ex_oracle <- integrate_covariates(
    gt,
    x_vars = target_sample_strong %>% select(X, U),
    x_target = target_sample_strong %>% select(X, U),
    omega = omega
  )

  inf_oracle <- compute_variance(
    ex_oracle$phi_future,
    estimate = ex_oracle$tau_future,
    level = level
  )

  bias_path3_oracle_strong[r] <- ex_oracle$tau_future - true_fatt_strong
  covered_path3_oracle_strong[r] <- (
    true_fatt_strong >= inf_oracle$ci[1] &&
    true_fatt_strong <= inf_oracle$ci[2]
  )
}

# ============================================================================
# Scenario 3: No confounding (cor(X, U) = 0, baseline)
# ============================================================================

message("Running Section 8.2 Scenario 3: No confounding (cor = 0)...")

cor_XU_none <- 0.0

theta_gt_none <- make_theta_gt_unobserved(
  q = q, p = p,
  alpha = alpha, beta_X = beta_X, beta_U = beta_U,
  cor_XU = cor_XU_none, mu_g = mu_g, sigma_X = sigma_X,
  seed = 8205
)

mu_U_given_X_target_none <- 0.0  # No correlation

true_fatt_none <- true_fatt_unobserved(
  alpha = alpha,
  beta_X = beta_X,
  beta_U = beta_U,
  mu_X_target = mu_X_target,
  mu_U_target = mu_U_given_X_target_none
)

# Generate target sample
set.seed(8206)
target_sample_none <- generate_target_covariates_unobserved(
  n_target = n_target,
  mu_X_target = mu_X_target,
  mu_U_target = mu_U_given_X_target_none,
  sigma_X = sigma_X,
  sigma_U = 1.0,
  cor_XU = cor_XU_none
)

bias_path3_misspec_none <- numeric(n_replicates)
covered_path3_misspec_none <- logical(n_replicates)

for (r in seq_len(n_replicates)) {
  gt <- add_noise_and_eif(
    theta_gt_none, n = n,
    sigma_tau = 0.1, seed = 8400L + r
  )

  # Misspecified (X only) - but no confounding, so should be unbiased
  ex_misspec <- integrate_covariates(
    gt,
    x_vars = target_sample_none$X,
    x_target = target_sample_none %>% select(X),
    omega = omega
  )

  inf_misspec <- compute_variance(
    ex_misspec$phi_future,
    estimate = ex_misspec$tau_future,
    level = level
  )

  bias_path3_misspec_none[r] <- ex_misspec$tau_future - true_fatt_none
  covered_path3_misspec_none[r] <- (
    true_fatt_none >= inf_misspec$ci[1] &&
    true_fatt_none <= inf_misspec$ci[2]
  )
}

# ============================================================================
# Compile Results
# ============================================================================

results_s8_2 <- list(
  scenario_1_moderate_confounding = list(
    cor_XU = cor_XU,
    true_fatt = true_fatt_confounded,
    path3_misspec = list(
      bias = mean(bias_path3_misspec_mod),
      rmse = sqrt(mean(bias_path3_misspec_mod^2)),
      coverage = mean(covered_path3_misspec_mod),
      n_replicates = n_replicates
    ),
    path3_oracle = list(
      bias = mean(bias_path3_oracle_mod),
      rmse = sqrt(mean(bias_path3_oracle_mod^2)),
      coverage = mean(covered_path3_oracle_mod),
      n_replicates = n_replicates
    )
  ),
  scenario_2_strong_confounding = list(
    cor_XU = cor_XU_strong,
    true_fatt = true_fatt_strong,
    path3_misspec = list(
      bias = mean(bias_path3_misspec_strong),
      rmse = sqrt(mean(bias_path3_misspec_strong^2)),
      coverage = mean(covered_path3_misspec_strong),
      n_replicates = n_replicates
    ),
    path3_oracle = list(
      bias = mean(bias_path3_oracle_strong),
      rmse = sqrt(mean(bias_path3_oracle_strong^2)),
      coverage = mean(covered_path3_oracle_strong),
      n_replicates = n_replicates
    )
  ),
  scenario_3_no_confounding = list(
    cor_XU = cor_XU_none,
    true_fatt = true_fatt_none,
    path3_misspec = list(
      bias = mean(bias_path3_misspec_none),
      rmse = sqrt(mean(bias_path3_misspec_none^2)),
      coverage = mean(covered_path3_misspec_none),
      n_replicates = n_replicates
    )
  ),
  dgp_params = list(
    alpha = alpha,
    beta_X = beta_X,
    beta_U = beta_U,
    mu_X_target = mu_X_target,
    sigma_X = sigma_X,
    n = n,
    q = q,
    p = p,
    future_time = future_time
  )
)

# Save results
dir.create("sims/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(results_s8_2, "sims/results/section8_2_misspec.rds")
message("Section 8.2 done: section8_2_misspec.rds saved")

# Print summary
message("\n=== Section 8.2 Results Summary ===")
message("\nScenario 1: Moderate confounding (cor = 0.5)")
message(sprintf("  True FATT: %.3f", results_s8_2$scenario_1_moderate_confounding$true_fatt))
message(sprintf("  Path 3 (X only) - Bias: %.3f, Coverage: %.1f%%",
                results_s8_2$scenario_1_moderate_confounding$path3_misspec$bias,
                results_s8_2$scenario_1_moderate_confounding$path3_misspec$coverage * 100))
message(sprintf("  Path 3 (Oracle) - Bias: %.3f, Coverage: %.1f%%",
                results_s8_2$scenario_1_moderate_confounding$path3_oracle$bias,
                results_s8_2$scenario_1_moderate_confounding$path3_oracle$coverage * 100))

message("\nScenario 2: Strong confounding (cor = 0.8)")
message(sprintf("  True FATT: %.3f", results_s8_2$scenario_2_strong_confounding$true_fatt))
message(sprintf("  Path 3 (X only) - Bias: %.3f, Coverage: %.1f%%",
                results_s8_2$scenario_2_strong_confounding$path3_misspec$bias,
                results_s8_2$scenario_2_strong_confounding$path3_misspec$coverage * 100))
message(sprintf("  Path 3 (Oracle) - Bias: %.3f, Coverage: %.1f%%",
                results_s8_2$scenario_2_strong_confounding$path3_oracle$bias,
                results_s8_2$scenario_2_strong_confounding$path3_oracle$coverage * 100))

message("\nScenario 3: No confounding (cor = 0, baseline)")
message(sprintf("  True FATT: %.3f", results_s8_2$scenario_3_no_confounding$true_fatt))
message(sprintf("  Path 3 (X only) - Bias: %.3f, Coverage: %.1f%%",
                results_s8_2$scenario_3_no_confounding$path3_misspec$bias,
                results_s8_2$scenario_3_no_confounding$path3_misspec$coverage * 100))

message("\n=== Key Insight ===")
message("When unobserved heterogeneity (U) is correlated with observed X,")
message("Path 3 suffers omitted variable bias. The bias grows with cor(X,U).")
message("Oracle (true model with U) shows Path 3 works when correctly specified.")

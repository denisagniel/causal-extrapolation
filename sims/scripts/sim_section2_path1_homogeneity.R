# Section 2: Path 1 — time homogeneity vs dynamics
# Scenario A: time homogeneity -> Path 1 should have low bias and good coverage for FATT.
# Scenario B: dynamics -> Path 1 biased for FATT.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})

devtools::load_all("package")
source("sims/scripts/dgp_helpers.R")

q <- 3
p <- 5
n <- 500
n_replicates <- 1000
omega <- rep(1 / q, q)
future_time <- p + 1
level <- 0.95
sigma_tau <- 0.1

# ---- Scenario A: time homogeneity ----
set.seed(101)
theta_g <- c(0.3, -0.1, 0.2)
theta_gt_A <- make_theta_gt(q, p, spec = "constant", theta_g = theta_g, seed = 102)
true_fatt_A <- true_fatt_from_dgp(omega, future_time, q, "constant", theta_g = theta_g)

bias_A <- numeric(n_replicates)
rmse_A <- numeric(n_replicates)
covered_A <- logical(n_replicates)
ests_A <- numeric(n_replicates)
ses_A <- numeric(n_replicates)

for (r in seq_len(n_replicates)) {
  gt <- add_noise_and_eif(theta_gt_A, n = n, sigma_tau = sigma_tau, seed = 1000L + r)
  path1 <- path1_aggregate(gt, omega)
  inf <- compute_variance(path1$phi_future, estimate = path1$tau_future, level = level)
  ests_A[r] <- path1$tau_future
  ses_A[r] <- inf$se
  bias_A[r] <- path1$tau_future - true_fatt_A
  covered_A[r] <- (true_fatt_A >= inf$ci[1] && true_fatt_A <= inf$ci[2])
}

metrics_A <- list(
  scenario = "A_homogeneity",
  true_fatt = true_fatt_A,
  bias = mean(bias_A),
  rmse = sqrt(mean(bias_A^2)),
  coverage = mean(covered_A),
  emp_var = var(ests_A),
  avg_est_var = mean(ses_A^2),
  n_replicates = n_replicates
)

# ---- Scenario B: dynamics (linear in event time) ----
alpha_g <- c(0.2, 0, -0.1)
beta_g <- c(0.15, 0.1, 0.12)
theta_gt_B <- make_theta_gt(q, p, spec = "linear", alpha_g = alpha_g, beta_g = beta_g, seed = 103)
true_fatt_B <- true_fatt_from_dgp(omega, future_time, q, "linear", alpha_g = alpha_g, beta_g = beta_g)

bias_B <- numeric(n_replicates)
rmse_B <- numeric(n_replicates)
covered_B <- logical(n_replicates)
ests_B <- numeric(n_replicates)

for (r in seq_len(n_replicates)) {
  gt <- add_noise_and_eif(theta_gt_B, n = n, sigma_tau = sigma_tau, seed = 2000L + r)
  path1 <- path1_aggregate(gt, omega)
  inf <- compute_variance(path1$phi_future, estimate = path1$tau_future, level = level)
  ests_B[r] <- path1$tau_future
  bias_B[r] <- path1$tau_future - true_fatt_B
  covered_B[r] <- (true_fatt_B >= inf$ci[1] && true_fatt_B <= inf$ci[2])
}

metrics_B <- list(
  scenario = "B_dynamics",
  true_fatt = true_fatt_B,
  bias = mean(bias_B),
  rmse = sqrt(mean(bias_B^2)),
  coverage = mean(covered_B),
  n_replicates = n_replicates
)

dir.create("sims/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(list(ScenarioA = metrics_A, ScenarioB = metrics_B), "sims/results/section2_path1_homogeneity.rds")
message("Section 2 done: section2_path1_homogeneity.rds saved")

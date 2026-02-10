# Section 5: Path 1 vs Path 2 on the same DGP (mild dynamics)
# Compare bias, RMSE, and coverage when both paths are applied to data with a mild trend.

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

# Mild dynamics: small slope in event time
alpha_g <- c(0.2, 0, -0.1)
beta_g <- c(0.06, 0.05, 0.07)
theta_gt <- make_theta_gt(q, p, spec = "linear", alpha_g = alpha_g, beta_g = beta_g, seed = 501)
true_fatt <- true_fatt_from_dgp(omega, future_time, q, "linear", alpha_g = alpha_g, beta_g = beta_g)

path1_est <- numeric(n_replicates)
path1_covered <- logical(n_replicates)
path2_est <- numeric(n_replicates)
path2_covered <- logical(n_replicates)

for (r in seq_len(n_replicates)) {
  gt <- add_noise_and_eif(theta_gt, n = n, sigma_tau = sigma_tau, seed = 5000L + r)

  path1 <- path1_aggregate(gt, omega)
  inf1 <- compute_variance(path1$phi_future, estimate = path1$tau_future, level = level)
  path1_est[r] <- path1$tau_future
  path1_covered[r] <- (true_fatt >= inf1$ci[1] && true_fatt <= inf1$ci[2])

  ex <- extrapolate_ATT(gt, h_fun = hg_linear, dh_fun = dh_linear,
                       future_value = future_time, time_scale = "calendar",
                       omega = omega, per_group = FALSE)
  inf2 <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = level)
  path2_est[r] <- ex$tau_future
  path2_covered[r] <- (true_fatt >= inf2$ci[1] && true_fatt <= inf2$ci[2])
}

results_s5 <- list(
  true_fatt = true_fatt,
  Path1 = list(
    bias = mean(path1_est - true_fatt),
    rmse = sqrt(mean((path1_est - true_fatt)^2)),
    coverage = mean(path1_covered)
  ),
  Path2 = list(
    bias = mean(path2_est - true_fatt),
    rmse = sqrt(mean((path2_est - true_fatt)^2)),
    coverage = mean(path2_covered)
  ),
  n_replicates = n_replicates
)

dir.create("sims/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(results_s5, "sims/results/section5_path1_vs_path2.rds")
message("Section 5 done: section5_path1_vs_path2.rds saved")

# Section 4: EIF variance and coverage
# Verify EIF-based variance and Wald CIs achieve nominal coverage when model is correct.

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

# DGP: linear (so Path 2 with hg_linear is correct)
alpha_g <- c(0.2, 0, -0.1)
beta_g <- c(0.1, 0.08, 0.12)
theta_gt <- make_theta_gt(q, p, spec = "linear", alpha_g = alpha_g, beta_g = beta_g, seed = 401)
true_fatt <- true_fatt_from_dgp(omega, future_time, q, "linear", alpha_g = alpha_g, beta_g = beta_g)

ests <- numeric(n_replicates)
var_est <- numeric(n_replicates)
covered_95 <- logical(n_replicates)
covered_90 <- logical(n_replicates)

for (r in seq_len(n_replicates)) {
  gt <- add_noise_and_eif(theta_gt, n = n, sigma_tau = sigma_tau, seed = 4000L + r)
  ex <- extrapolate_ATT(gt, h_fun = hg_linear, dh_fun = dh_linear,
                       future_value = future_time, time_scale = "calendar",
                       omega = omega, per_group = FALSE)
  inf <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = level)
  ests[r] <- ex$tau_future
  var_est[r] <- inf$se^2
  covered_95[r] <- (true_fatt >= inf$ci[1] && true_fatt <= inf$ci[2])
  inf90 <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = 0.90)
  covered_90[r] <- (true_fatt >= inf90$ci[1] && true_fatt <= inf90$ci[2])
}

emp_var <- var(ests)
avg_est_var <- mean(var_est)
variance_ratio <- avg_est_var / emp_var

results_s4 <- list(
  true_fatt = true_fatt,
  emp_var = emp_var,
  avg_est_var = avg_est_var,
  variance_ratio = variance_ratio,
  coverage_95 = mean(covered_95),
  coverage_90 = mean(covered_90),
  n_replicates = n_replicates,
  n = n
)

dir.create("sims/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(results_s4, "sims/results/section4_eif_coverage.rds")
message("Section 4 done: section4_eif_coverage.rds saved (variance_ratio and coverage)")

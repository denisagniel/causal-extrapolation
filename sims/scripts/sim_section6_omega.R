# Section 6 (optional): Role of omega_g and cohort composition
# Fix theta_gt; vary omega; compare true FATT and estimates under correct vs uniform omega.

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
future_time <- p + 1
level <- 0.95
sigma_tau <- 0.1

# Fixed theta_gt (linear)
alpha_g <- c(0.2, 0, -0.1)
beta_g <- c(0.1, 0.08, 0.12)
theta_gt <- make_theta_gt(q, p, spec = "linear", alpha_g = alpha_g, beta_g = beta_g, seed = 601)

# Different omega configurations: more weight on early vs late adopters
omega_early <- c(0.6, 0.3, 0.1)   # mostly group 1
omega_late  <- c(0.1, 0.3, 0.6)   # mostly group 3
omega_unif <- rep(1 / q, q)

true_fatt_early <- true_fatt_from_dgp(omega_early, future_time, q, "linear", alpha_g = alpha_g, beta_g = beta_g)
true_fatt_late  <- true_fatt_from_dgp(omega_late,  future_time, q, "linear", alpha_g = alpha_g, beta_g = beta_g)
true_fatt_unif  <- true_fatt_from_dgp(omega_unif, future_time, q, "linear", alpha_g = alpha_g, beta_g = beta_g)

# For each omega scenario we generate data once (or few replicates) and estimate with (a) correct omega (b) uniform omega.
# Bias when using wrong omega = estimate - true_fatt under the *true* omega for that scenario.

run_omega_comparison <- function(omega_true, omega_est, true_fatt_val, scenario_name, n_rep = 1000) {
  path1_bias <- numeric(n_rep)
  path2_bias <- numeric(n_rep)
  for (r in seq_len(n_rep)) {
    gt <- add_noise_and_eif(theta_gt, n = n, sigma_tau = sigma_tau, seed = 6000L + r)
    path1 <- path1_aggregate(gt, omega_est)
    path1_bias[r] <- path1$tau_future - true_fatt_val
    ex <- extrapolate_ATT(gt, h_fun = hg_linear, dh_fun = dh_linear,
                         future_value = future_time, time_scale = "calendar",
                         omega = omega_est, per_group = FALSE)
    path2_bias[r] <- ex$tau_future - true_fatt_val
  }
  list(
    scenario = scenario_name,
    true_fatt = true_fatt_val,
    omega_used = omega_est,
    path1_bias = mean(path1_bias),
    path2_bias = mean(path2_bias),
    n_replicates = n_rep
  )
}

res_early_correct <- run_omega_comparison(omega_early, omega_early, true_fatt_early, "early_correct_omega")
res_early_wrong   <- run_omega_comparison(omega_early, omega_unif, true_fatt_early, "early_uniform_omega")
res_late_correct  <- run_omega_comparison(omega_late,  omega_late,  true_fatt_late,  "late_correct_omega")
res_late_wrong    <- run_omega_comparison(omega_late,  omega_unif,   true_fatt_late,  "late_uniform_omega")

results_s6 <- list(
  true_fatts = list(early = true_fatt_early, late = true_fatt_late, uniform = true_fatt_unif),
  early_correct = res_early_correct,
  early_wrong   = res_early_wrong,
  late_correct  = res_late_correct,
  late_wrong    = res_late_wrong
)

dir.create("sims/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(results_s6, "sims/results/section6_omega.rds")
message("Section 6 done: section6_omega.rds saved")

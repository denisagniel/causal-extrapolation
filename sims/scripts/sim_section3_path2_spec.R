# Section 3: Path 2 — correct vs misspecified extrapolation
# Correct: DGP linear in event time, fit hg_linear.
# Misspec: DGP quadratic, fit hg_linear only.

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

# ---- Correct spec: DGP linear, fit linear (in calendar time for extrapolation) ----
alpha_g <- c(0.2, 0, -0.1)
beta_g <- c(0.1, 0.08, 0.12)
theta_gt_linear <- make_theta_gt(q, p, spec = "linear", alpha_g = alpha_g, beta_g = beta_g, seed = 301)
true_fatt_linear <- true_fatt_from_dgp(omega, future_time, q, "linear", alpha_g = alpha_g, beta_g = beta_g)

bias_correct <- numeric(n_replicates)
rmse_correct <- numeric(n_replicates)
covered_correct <- logical(n_replicates)

for (r in seq_len(n_replicates)) {
  gt <- add_noise_and_eif(theta_gt_linear, n = n, sigma_tau = sigma_tau, seed = 3000L + r)
  ex <- extrapolate_ATT(gt, h_fun = hg_linear, dh_fun = dh_linear,
                       future_value = future_time, time_scale = "calendar",
                       omega = omega, per_group = FALSE)
  inf <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = level)
  bias_correct[r] <- ex$tau_future - true_fatt_linear
  covered_correct[r] <- (true_fatt_linear >= inf$ci[1] && true_fatt_linear <= inf$ci[2])
}

# ---- Misspec: DGP quadratic, fit linear ----
alpha_g2 <- c(0.2, 0, -0.1)
beta_g2 <- c(0.05, 0.05, 0.05)
delta_g2 <- c(0.03, 0.02, 0.04)
theta_gt_quad <- make_theta_gt(q, p, spec = "quadratic", alpha_g = alpha_g2, beta_g = beta_g2, delta_g = delta_g2, seed = 302)
true_fatt_quad <- true_fatt_from_dgp(omega, future_time, q, "quadratic", alpha_g = alpha_g2, beta_g = beta_g2, delta_g = delta_g2)

bias_misspec <- numeric(n_replicates)
rmse_misspec <- numeric(n_replicates)
covered_misspec <- logical(n_replicates)

for (r in seq_len(n_replicates)) {
  gt <- add_noise_and_eif(theta_gt_quad, n = n, sigma_tau = sigma_tau, seed = 4000L + r)
  ex <- extrapolate_ATT(gt, h_fun = hg_linear, dh_fun = dh_linear,
                       future_value = future_time, time_scale = "calendar",
                       omega = omega, per_group = FALSE)
  inf <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = level)
  bias_misspec[r] <- ex$tau_future - true_fatt_quad
  covered_misspec[r] <- (true_fatt_quad >= inf$ci[1] && true_fatt_quad <= inf$ci[2])
}

# Optional: same quadratic DGP, fit quadratic
bias_quad_fit <- numeric(n_replicates)
covered_quad_fit <- logical(n_replicates)
# For calendar-time quadratic we need hg_quadratic on calendar t (same pattern as linear).
for (r in seq_len(n_replicates)) {
  gt <- add_noise_and_eif(theta_gt_quad, n = n, sigma_tau = sigma_tau, seed = 5000L + r)
  ex <- extrapolate_ATT(gt, h_fun = hg_quadratic, dh_fun = dh_quadratic,
                       future_value = future_time, time_scale = "calendar",
                       omega = omega, per_group = FALSE)
  inf <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = level)
  bias_quad_fit[r] <- ex$tau_future - true_fatt_quad
  covered_quad_fit[r] <- (true_fatt_quad >= inf$ci[1] && true_fatt_quad <= inf$ci[2])
}

results_s3 <- list(
  correct_spec = list(
    true_fatt = true_fatt_linear,
    bias = mean(bias_correct),
    rmse = sqrt(mean(bias_correct^2)),
    coverage = mean(covered_correct),
    n_replicates = n_replicates
  ),
  misspec_linear_on_quad = list(
    true_fatt = true_fatt_quad,
    bias = mean(bias_misspec),
    rmse = sqrt(mean(bias_misspec^2)),
    coverage = mean(covered_misspec),
    n_replicates = n_replicates
  ),
  quadratic_fit_on_quad = list(
    true_fatt = true_fatt_quad,
    bias = mean(bias_quad_fit),
    rmse = sqrt(mean(bias_quad_fit^2)),
    coverage = mean(covered_quad_fit),
    n_replicates = n_replicates
  )
)

dir.create("sims/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(results_s3, "sims/results/section3_path2_spec.rds")
message("Section 3 done: section3_path2_spec.rds saved")

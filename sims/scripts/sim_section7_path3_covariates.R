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
  library(fs)
})

# Package now lives at the repo root (was package/ pre-Phase-2). load_all(".") from the
# repo root; fall back to "package" for older checkouts.
if (file.exists("DESCRIPTION")) devtools::load_all(".") else devtools::load_all("package")
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

# Path 3 unit-level DGP (for integrate_cate). Paths 1-2 operate on the group-time object
# above; Path 3 estimates the conditional effect tau(x) directly from unit-level data and
# transports it, so it needs a unit-level cross-section. We use an unconfoundedness contract
# with the SAME structural conditional effect tau(x) = alpha + beta*x, a source covariate
# distribution centered at 0 (matching the historical mean), and Form B density-ratio
# weights that transport to the shifted target N(mu_target, sigma_X). This makes Path 3's
# estimand identical to Paths 1-2 (true FATT = alpha + beta*mu_target), so all three are
# compared on the same target.
n_unit <- 500      # unit-level sample size per replication
mu_source <- 0.0   # historical/source covariate mean
sigma_Y <- 0.5     # outcome noise SD

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

# Path 3: direct CATE + covariate transport via the package (integrate_cate).
# Estimates tau(x) on unit-level data and transports it to the shifted target distribution.
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

  # --- Path 3: direct CATE + covariate transport (package integrate_cate) ---
  # Unit-level cross-section with the structural conditional effect tau(x) = alpha + beta*x.
  # Oracle nuisances (correctly specified) so the arm isolates the transport logic; the
  # regime-change robustness comes from tau(x) being invariant, not from the nuisance fit.
  # Use a DISTINCT seed offset (90000L) from the gt draw's seed (7000L + r) so the Path 3
  # unit-level RNG stream does not coincide with the gt-noise stream (which would make the
  # two arms deterministically correlated rather than independent draws).
  set.seed(90000L + r)
  X_u <- stats::rnorm(n_unit, mean = mu_source, sd = sigma_X)
  e_u <- plogis(0.4 * X_u)
  A_u <- stats::rbinom(n_unit, 1, e_u)
  tau_u <- alpha + beta * X_u
  mu0_u <- 0.5 * X_u
  mu1_u <- mu0_u + tau_u
  Y_u <- mu0_u + A_u * tau_u + stats::rnorm(n_unit, sd = sigma_Y)

  # Form B transport weights: density ratio from source N(mu_source, sigma_X) to the
  # shifted target N(mu_target, sigma_X). Self-normalize so E_src[w] = 1 exactly (removes
  # finite-sample misnormalization that otherwise depresses coverage).
  w_u <- stats::dnorm(X_u, mu_target, sigma_X) / stats::dnorm(X_u, mu_source, sigma_X)
  w_u <- w_u / mean(w_u)

  cate <- list(tau = tau_u, mu1 = mu1_u, mu0 = mu0_u, e = e_u,
               A = A_u, Y = Y_u, X = data.frame(x1 = X_u))
  path3_result <- integrate_cate(cate, design = "unconfoundedness",
                                 weights = w_u, level = level)

  path3_est[r] <- path3_result$estimate
  path3_covered[r] <- (true_fatt >= path3_result$ci[1] && true_fatt <= path3_result$ci[2])
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
  Path3_CovariateIntegration = list(
    bias = mean(path3_est - true_fatt),
    rmse = sqrt(mean((path3_est - true_fatt)^2)),
    coverage = mean(path3_covered),
    note = "Unbiased: tau(X) is regime-invariant (integrate_cate transport)"
  ),
  n_replicates = n_replicates
)

# Save results
fs::dir_create("sims/results")
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

cat("\nPath 3 (Covariate Integration):\n")
cat(sprintf("  Bias: %.4f, RMSE: %.4f, Coverage: %.2f%%\n",
            results_s7$Path3_CovariateIntegration$bias,
            results_s7$Path3_CovariateIntegration$rmse,
            results_s7$Path3_CovariateIntegration$coverage * 100))

cat("\n** Path 3 uses integrate_cate() (direct CATE + covariate transport) **\n")

message("\nSection 7 done: section7_path3_covariates.rds saved")

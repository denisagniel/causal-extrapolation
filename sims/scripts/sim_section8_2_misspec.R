# Section 8.2: Conditional Model Misspecification (Path 3 break point)
#
# Purpose (constitution §9 stress regime): show Path 3 fails when treatment-effect
# heterogeneity is driven by an UNOBSERVED effect modifier U that the observed covariate
# X does not capture, and the target regime shifts in a way X cannot track.
#
# DGP (unit-level cross-section, for integrate_cate):
#   tau(X, U) = alpha + beta_X * X + beta_U * U
#   (X, U) ~ bivariate normal, source means 0, corr cor_XU, unit variances.
#   e(X) = plogis(0.4 * X)  -- propensity depends on X ONLY, so A _||_ U | X and
#     unconfoundedness holds given X (the AIPW correction is mean-zero given X). The
#     failure below is therefore a pure TRANSPORT / structural-stability failure, not
#     confounding.
#   Y = mu0_base(X) + A * tau(X, U) + noise, with mu0_base(X) = 0.5 * X.
#
# Target regime: X shifts to mu_X_target; U's marginal mean stays at 0 (the unobserved
#   structural component does NOT follow the source X-U relationship into the future --
#   a structural break in the reduced-form X-U link). True FATT = alpha + beta_X * mu_X_target.
#
# Two arms (oracle nuisances in both, to isolate the transport logic):
#   - Misspecified (X only): CATE and nuisances are the true conditionals given X,
#     tau_mis(X) = E[tau|X] = alpha + beta_X*X + beta_U*cor_XU*X. The X-only model absorbs
#     U's effect into an inflated X-slope via the source correlation. Transport weights are
#     the X-marginal density ratio. Because the target X-U link differs from the source,
#     the absorbed slope mispredicts: bias = beta_U * cor_XU * mu_X_target (grows with cor_XU).
#   - Oracle (X and U): CATE is the true tau(X,U); transport weights are the JOINT (X,U)
#     density ratio. Unbiased -- it transports the genuine deep parameters (Lucas critique).
#
# Expected result: misspecified bias grows with cor_XU (0 at cor_XU = 0); coverage collapses.
#   Oracle is ~unbiased with ~nominal coverage. This is the honest analog of Sections 8.1/8.3.

set.seed(20260709)

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(fs)
  library(readr)
})

# Package lives at the repo root (was package/ pre-Phase-2). Fall back for older checkouts.
if (file.exists("DESCRIPTION")) devtools::load_all(".") else devtools::load_all("package")
source("sims/scripts/dgp_helpers_section8.R")  # true_fatt_unobserved()

# ---- Simulation parameters ----
n_unit <- 1000          # unit-level sample size per replication
n_replicates <- 1000    # number of Monte Carlo replications
level <- 0.95           # confidence level

# ---- DGP parameters ----
alpha <- 2.0            # intercept of tau(X, U)
beta_X <- 1.5           # effect of observed X
beta_U <- 3.0           # effect of UNOBSERVED U (strong heterogeneity)
sigma_Y <- 0.5          # outcome noise SD
mu_X_target <- 0.5      # target regime shift in X (U's target mean stays 0)

# Stress dial: correlation between observed X and unobserved U in the source.
cor_grid <- c(0.0, 0.5, 0.8)

# True FATT is the same in every scenario (target U mean is 0): alpha + beta_X * mu_X_target.
true_fatt <- true_fatt_unobserved(
  alpha = alpha, beta_X = beta_X, beta_U = beta_U,
  mu_X_target = mu_X_target, mu_U_target = 0.0
)

#' Density-ratio transport weight for a mean shift of a (bivariate) normal
#'
#' Source and target share the covariance matrix and differ only in mean, so the density
#' ratio is a log-linear function of the covariates (Gaussian mean-shift). Unit variances
#' are assumed (sigma_X = sigma_U = 1). Returns UN-normalized weights; the caller
#' self-normalizes so that the source-mean of w is exactly 1.
#'
#' For the X-only (misspecified) arm, pass `u = NULL` and `rho = 0` (marginal-X shift).
#' For the (X, U) oracle arm, pass both and the source correlation `rho`.
bivar_shift_weight <- function(x, u = NULL, mu_x, rho = 0) {
  if (is.null(u)) {
    # Marginal N(0,1) -> N(mu_x, 1): log w = mu_x * x - 0.5 * mu_x^2.
    log_w <- mu_x * x - 0.5 * mu_x^2
  } else {
    # Joint N(0, Sigma) -> N((mu_x, 0), Sigma), Sigma = [[1, rho], [rho, 1]].
    # log w = mu_x/(1 - rho^2) * (x - rho * u) - 0.5 * mu_x^2 / (1 - rho^2).
    denom <- 1 - rho^2
    log_w <- mu_x / denom * (x - rho * u) - 0.5 * mu_x^2 / denom
  }
  exp(log_w)
}

#' Run all replications for one correlation scenario
run_scenario <- function(cor_XU) {
  bias_mis <- numeric(n_replicates)
  cov_mis <- logical(n_replicates)
  bias_orc <- numeric(n_replicates)
  cov_orc <- logical(n_replicates)

  for (r in seq_len(n_replicates)) {
    # --- Source cross-section: (X, U) bivariate normal (unit variances, corr cor_XU) ---
    Z1 <- stats::rnorm(n_unit)
    Z2 <- stats::rnorm(n_unit)
    X_u <- Z1
    U_u <- cor_XU * Z1 + sqrt(1 - cor_XU^2) * Z2

    e_u <- stats::plogis(0.4 * X_u)          # propensity depends on X only -> A _||_ U | X
    A_u <- stats::rbinom(n_unit, 1, e_u)
    tau_true <- alpha + beta_X * X_u + beta_U * U_u
    mu0_base <- 0.5 * X_u
    Y_u <- mu0_base + A_u * tau_true + stats::rnorm(n_unit, sd = sigma_Y)

    # --- Misspecified arm (X only): true conditionals GIVEN X ---
    # E[U | X] = cor_XU * X (unit variances), so tau_mis(X) = E[tau | X].
    tau_mis <- alpha + beta_X * X_u + beta_U * cor_XU * X_u
    mu0_mis <- mu0_base
    mu1_mis <- mu0_mis + tau_mis
    w_mis <- bivar_shift_weight(X_u, u = NULL, mu_x = mu_X_target)
    w_mis <- w_mis / mean(w_mis)                       # self-normalize: E_src[w] = 1
    cate_mis <- list(tau = tau_mis, mu1 = mu1_mis, mu0 = mu0_mis, e = e_u,
                     A = A_u, Y = Y_u, X = data.frame(x1 = X_u))
    res_mis <- integrate_cate(cate_mis, design = "unconfoundedness",
                              weights = w_mis, level = level)

    # --- Oracle arm (X and U): true structural tau(X, U), joint transport ---
    tau_orc <- tau_true
    mu0_orc <- mu0_base
    mu1_orc <- mu0_orc + tau_orc
    w_orc <- bivar_shift_weight(X_u, u = U_u, mu_x = mu_X_target, rho = cor_XU)
    w_orc <- w_orc / mean(w_orc)
    cate_orc <- list(tau = tau_orc, mu1 = mu1_orc, mu0 = mu0_orc, e = e_u,
                     A = A_u, Y = Y_u, X = data.frame(x1 = X_u, x2 = U_u))
    res_orc <- integrate_cate(cate_orc, design = "unconfoundedness",
                              weights = w_orc, level = level)

    bias_mis[r] <- res_mis$estimate - true_fatt
    cov_mis[r] <- (true_fatt >= res_mis$ci[1] && true_fatt <= res_mis$ci[2])
    bias_orc[r] <- res_orc$estimate - true_fatt
    cov_orc[r] <- (true_fatt >= res_orc$ci[1] && true_fatt <= res_orc$ci[2])
  }

  list(
    cor_XU = cor_XU,
    true_fatt = true_fatt,
    expected_bias_misspec = beta_U * cor_XU * mu_X_target,  # analytic check
    path3_misspec = list(
      bias = mean(bias_mis),
      rmse = sqrt(mean(bias_mis^2)),
      coverage = mean(cov_mis),
      n_replicates = n_replicates
    ),
    path3_oracle = list(
      bias = mean(bias_orc),
      rmse = sqrt(mean(bias_orc^2)),
      coverage = mean(cov_orc),
      n_replicates = n_replicates
    )
  )
}

# ---- Run all scenarios ----
message("Running Section 8.2 (Path 3 unobserved-heterogeneity stress test)...")
message(sprintf("True FATT (target mu_X = %.1f): %.3f", mu_X_target, true_fatt))

scenarios <- lapply(cor_grid, function(rho) {
  message(sprintf("  Scenario cor(X, U) = %.1f ...", rho))
  run_scenario(rho)
})
names(scenarios) <- sprintf("cor_%02d", round(cor_grid * 10))

results_s8_2 <- list(
  scenarios = scenarios,
  cor_grid = cor_grid,
  true_fatt = true_fatt,
  dgp_params = list(
    alpha = alpha, beta_X = beta_X, beta_U = beta_U,
    sigma_Y = sigma_Y, mu_X_target = mu_X_target,
    n_unit = n_unit, n_replicates = n_replicates
  )
)

# ---- Save ----
fs::dir_create("sims/results")
readr::write_rds(results_s8_2, "sims/results/section8_2_misspec.rds")
message("Section 8.2 done: sims/results/section8_2_misspec.rds saved")

# ---- Summary ----
message("\n=== Section 8.2 Results Summary ===")
for (nm in names(scenarios)) {
  s <- scenarios[[nm]]
  message(sprintf("\ncor(X, U) = %.1f  (expected misspec bias %.3f):", s$cor_XU,
                  s$expected_bias_misspec))
  message(sprintf("  Path 3 (X only) - Bias: %+.3f, RMSE: %.3f, Coverage: %.1f%%",
                  s$path3_misspec$bias, s$path3_misspec$rmse,
                  s$path3_misspec$coverage * 100))
  message(sprintf("  Path 3 (oracle) - Bias: %+.3f, RMSE: %.3f, Coverage: %.1f%%",
                  s$path3_oracle$bias, s$path3_oracle$rmse,
                  s$path3_oracle$coverage * 100))
}

message("\n=== Key insight ===")
message("An X-only Path 3 absorbs the unobserved U's effect into an inflated X-slope via")
message("the source X-U correlation. When the target regime shifts X but U does not follow")
message("that source relationship, the absorbed slope mispredicts: bias grows with cor(X,U)")
message("and coverage collapses. The oracle (X and U) transports the true deep parameters")
message("and stays unbiased -- the Lucas-critique failure mode of Path 3.")

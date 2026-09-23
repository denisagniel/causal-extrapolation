# Section 4b: EIF variance and coverage — real did::att_gt() first stage
#
# Mirrors Section 4 (sim_section4_eif_coverage.R) but replaces the synthetic
# noise first stage (add_noise_and_eif) with a real did::att_gt() call via
# add_did_eif(). This exercises the full pipeline:
#
#   generate_panel_data() -> did::att_gt() -> as_gt_object() (inffunc EIFs)
#   -> extrapolate_ATT() -> compute_variance()
#
# and validates that EIF-based variance propagation achieves nominal coverage
# when EIFs come from a real semiparametric estimator, not synthetic noise.
#
# Local run (fast smoke test): set n_replicates = 5 before sourcing.
# Full run (1000 reps): use O2 SLURM array (sims/slurm/run_rep_section4b.R).
#
# Approximate run time: ~1-2 sec per replicate (did::att_gt on ~600 units x 6 periods).
# Full 1000 reps: ~15-30 min locally; ~20 min on O2 with 10 reps/job x 100 jobs.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})

if (!requireNamespace("did", quietly = TRUE)) {
  stop("Package 'did' is required for Section 4b. Install with install.packages('did').",
       call. = FALSE)
}

# Load package (repo root or package/ subdirectory for older checkouts)
if (file.exists("DESCRIPTION")) devtools::load_all(".") else devtools::load_all("package")
source("sims/scripts/dgp_helpers.R")

# --- Parameters ---------------------------------------------------------------
# n_replicates can be overridden before sourcing (e.g. n_replicates <- 5 for smoke test)
# or via sims/config/sim_config.R
if (!exists("n_replicates")) n_replicates <- 200L   # local default; 1000 on O2

q             <- 3L
p             <- 5L
n_per_cohort  <- 200L    # units per treated cohort; control group same size -> ~800 total
omega         <- rep(1 / q, q)
future_time   <- p + 1L
# generate_panel_data() relabels cohorts/calendar time as g_did = g_orig + 1,
# t_did = t_orig + 1 (guarantees a pre-period for did::att_gt()). as_gt_object()
# copies did::att_gt()'s $group/$t verbatim (see gt_object_from_att_gt() in
# R/from_did.R), so the resulting gt_object lives in did-space calendar
# coordinates. extrapolate_ATT(time_scale = "calendar") must therefore target
# future_time + 1, not future_time, or it extrapolates to the last *observed*
# did-space period instead of one period ahead -- an off-by-one that biased
# the FATT estimate toward the last observed slope-step and collapsed coverage
# (95% CI coverage measured ~23% instead of ~95% before this fix).
future_time_did <- future_time + 1L
level         <- 0.95
sigma_Y       <- 0.5
sigma_alpha   <- 1.0

# DGP: linear in event time (same as Section 4) so hg_linear is correctly specified
alpha_g <- c(0.2, 0, -0.1)
beta_g  <- c(0.1, 0.08, 0.12)

theta_gt <- make_theta_gt(
  q, p,
  spec    = "linear",
  alpha_g = alpha_g,
  beta_g  = beta_g,
  seed    = 401L
)

true_fatt <- true_fatt_from_dgp(
  omega, future_time, q, "linear",
  alpha_g = alpha_g, beta_g = beta_g
)

# --- Replication loop ---------------------------------------------------------
ests       <- numeric(n_replicates)
var_est    <- numeric(n_replicates)
covered_95 <- logical(n_replicates)
covered_90 <- logical(n_replicates)

# Seed offset distinct from Section 4 (4000L) to avoid any accidental correlation
base_seed <- 40000L

for (r in seq_len(n_replicates)) {
  # Real first stage: generates panel data and calls did::att_gt() internally
  gt <- tryCatch(
    add_did_eif(
      theta_gt     = theta_gt,
      n_per_cohort = n_per_cohort,
      p            = p,
      sigma_Y      = sigma_Y,
      sigma_alpha  = sigma_alpha,
      seed         = base_seed + r
    ),
    error = function(e) {
      warning(sprintf("Replicate %d failed in add_did_eif(): %s", r, conditionMessage(e)))
      NULL
    }
  )

  # Skip failed replicates (did::att_gt can occasionally fail on degenerate draws)
  if (is.null(gt) || is.null(gt$phi)) {
    ests[r]       <- NA_real_
    var_est[r]    <- NA_real_
    covered_95[r] <- NA
    covered_90[r] <- NA
    next
  }

  ex   <- extrapolate_ATT(gt, h_fun = hg_linear, dh_fun = dh_linear,
                          future_value = future_time_did, time_scale = "calendar",
                          omega = omega, per_group = FALSE)
  inf  <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = level)
  inf2 <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = 0.90)

  ests[r]       <- ex$tau_future
  var_est[r]    <- inf$se^2
  covered_95[r] <- (true_fatt >= inf$ci[1] && true_fatt <= inf$ci[2])
  covered_90[r] <- (true_fatt >= inf2$ci[1] && true_fatt <= inf2$ci[2])
}

# --- Summary ------------------------------------------------------------------
valid         <- !is.na(ests)
n_valid       <- sum(valid)
emp_var       <- var(ests[valid])
avg_est_var   <- mean(var_est[valid])
variance_ratio <- avg_est_var / emp_var

results_s4b <- list(
  true_fatt      = true_fatt,
  emp_var        = emp_var,
  avg_est_var    = avg_est_var,
  variance_ratio = variance_ratio,
  coverage_95    = mean(covered_95[valid]),
  coverage_90    = mean(covered_90[valid]),
  n_replicates   = n_replicates,
  n_valid        = n_valid,
  n_per_cohort   = n_per_cohort,
  q              = q,
  p              = p,
  note           = "Real did::att_gt() first stage (not synthetic noise)"
)

dir.create("sims/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(results_s4b, "sims/results/section4b_real_firststage.rds")

cat("\n=== Section 4b: Real First-Stage EIF Coverage ===\n")
cat(sprintf("True FATT:        %.4f\n", true_fatt))
cat(sprintf("Empirical var:    %.6f\n", emp_var))
cat(sprintf("Avg estimated var:%.6f\n", avg_est_var))
cat(sprintf("Variance ratio:   %.4f  (target ~1.0)\n", variance_ratio))
cat(sprintf("Coverage 95%%:     %.3f  (target 0.950)\n", results_s4b$coverage_95))
cat(sprintf("Coverage 90%%:     %.3f  (target 0.900)\n", results_s4b$coverage_90))
cat(sprintf("Valid reps:       %d / %d\n", n_valid, n_replicates))

message("\nSection 4b done: section4b_real_firststage.rds saved")

#!/usr/bin/env Rscript
# =============================================================================
# R/dgp.R -- data-generating process for section7est
# =============================================================================
# Thin wrapper: loads the shared dgp_helpers.R from sims/scripts/ and
# pre-computes the fixed DGP objects used by every replication.
# run_one.R sources this file; no side effects beyond the assignments below.
# =============================================================================

# Shared helpers (make_theta_gt_conditional, true_fatt_conditional,
# add_noise_and_eif, etc.).
# STUDY_DIR is the absolute study dir (.../sims/section7est); the shared helpers
# live at .../sims/scripts, i.e. ONE level up then into scripts/.
source(file.path(STUDY_DIR, "..", "scripts", "dgp_helpers.R"))

# Pre-compute the fixed conditional theta_gt and true FATT once (same across all
# reps). Seeded at a fixed value (701L, matching the old batch runner) so the
# DGP is identical regardless of rep order.
S7EST_THETA_GT <- make_theta_gt_conditional(
  q       = S7EST_Q,
  p       = S7EST_P,
  alpha   = S7EST_ALPHA,
  beta    = S7EST_BETA,
  mu_g    = S7EST_MU_G,
  sigma_X = S7EST_SIGMA_X,
  seed    = 701L
)

S7EST_TRUE_FATT <- true_fatt_conditional(
  alpha     = S7EST_ALPHA,
  beta      = S7EST_BETA,
  mu_target = S7EST_MU_TARGET
)

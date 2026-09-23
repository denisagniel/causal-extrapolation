#!/usr/bin/env Rscript
# =============================================================================
# R/dgp.R -- data-generating process for section4b
# =============================================================================
# Thin wrapper: loads the shared dgp_helpers.R from sims/scripts/ and
# pre-computes the fixed DGP objects used by every replication.
# run_one.R sources this file; no side effects beyond the assignments below.
# =============================================================================

# Shared helpers (make_theta_gt, add_did_eif, etc.)
# STUDY_DIR is the absolute study dir (.../sims/section4b); the shared helpers
# live at .../sims/scripts, i.e. ONE level up then into scripts/.
source(file.path(STUDY_DIR, "..", "scripts", "dgp_helpers.R"))

# Pre-compute the fixed theta_gt and true FATT once (same across all reps).
# Seeded at a fixed value so the DGP is identical regardless of rep order.
S4B_THETA_GT <- make_theta_gt(
  q       = S4B_Q,
  p       = S4B_P,
  spec    = "linear",
  alpha_g = S4B_ALPHA_G,
  beta_g  = S4B_BETA_G,
  seed    = 401L
)

S4B_TRUE_FATT <- true_fatt_from_dgp(
  omega       = S4B_OMEGA,
  future_time = S4B_FUTURE_TIME,
  q           = S4B_Q,
  spec        = "linear",
  alpha_g     = S4B_ALPHA_G,
  beta_g      = S4B_BETA_G
)

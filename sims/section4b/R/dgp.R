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

# add_did_eif()/generate_panel_data() relabel cohorts/calendar time as
# g_did = g_orig + 1, t_did = t_orig + 1 (guarantees a did::att_gt() pre-period
# for every cohort). as_gt_object() copies did::att_gt()'s $group/$t verbatim,
# so the gt_object passed to extrapolate_ATT() lives in did-space calendar
# coordinates. run_one.R must therefore extrapolate to S4B_FUTURE_TIME + 1,
# not S4B_FUTURE_TIME -- see sims/scripts/sim_section4b_real_firststage.R for
# the local run that surfaced this (fixed 2026-09-23; unfixed here produced
# ~23% coverage of a nominal-95% target instead of ~95%).
S4B_FUTURE_TIME_DID <- S4B_FUTURE_TIME + 1L

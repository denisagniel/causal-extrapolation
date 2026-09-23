#!/usr/bin/env Rscript
# =============================================================================
# R/run_one.R -- run a single replication for section4b
# =============================================================================
# Contract: run_one(unit_row) receives one row of unit_table() and returns a
# one-row data.frame with columns:
#   unit, config_id, rep_id, estimate, se, covered_95, covered_90, error_msg
#
# Called by run_replication.R (which handles checkpointing and error capture).
# Assumes dgp.R and estimators.R have already been sourced, and that the
# extrapolateATT and did packages are loaded.
# =============================================================================

run_one <- function(unit_row) {
  config_id <- unit_row$config_id
  rep_id    <- unit_row$rep_id
  unit      <- unit_row$unit
  seed      <- .unit_seed(config_id, rep_id)

  # --- Run the estimation pipeline ------------------------------------------
  gt <- add_did_eif(
    theta_gt     = S4B_THETA_GT,
    n_per_cohort = S4B_N_PER_COHORT,
    p            = S4B_P,
    sigma_Y      = S4B_SIGMA_Y,
    sigma_alpha  = S4B_SIGMA_ALPHA,
    seed         = seed
  )

  if (is.null(gt) || is.null(gt$phi)) {
    stop("add_did_eif returned NULL or missing phi")
  }

  ex   <- extrapolate_ATT(gt,
                          h_fun       = hg_linear,
                          dh_fun      = dh_linear,
                          future_value = S4B_FUTURE_TIME,
                          time_scale  = "calendar",
                          omega       = S4B_OMEGA,
                          per_group   = FALSE)
  inf95 <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = 0.95)
  inf90 <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = 0.90)

  data.frame(
    unit       = unit,
    config_id  = config_id,
    rep_id     = rep_id,
    estimate   = ex$tau_future,
    se         = inf95$se,
    covered_95 = (S4B_TRUE_FATT >= inf95$ci[1] & S4B_TRUE_FATT <= inf95$ci[2]),
    covered_90 = (S4B_TRUE_FATT >= inf90$ci[1] & S4B_TRUE_FATT <= inf90$ci[2]),
    true_fatt  = S4B_TRUE_FATT,
    error_msg  = NA_character_,
    stringsAsFactors = FALSE
  )
}

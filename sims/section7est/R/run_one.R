#!/usr/bin/env Rscript
# =============================================================================
# R/run_one.R -- run a single replication for section7est
# =============================================================================
# Contract: run_one(unit_row) receives one row of unit_table() and returns a
# data.frame with FOUR rows (one per estimator arm), columns (in this order):
#   unit, config_id, rep_id, arm, estimate, se, covered_95, covered_90,
#   true_fatt, error_msg
# where arm is one of "path1", "path2", "path3_oracle", "path3_grf".
#
# Each arm runs inside its OWN tryCatch so a failure in one arm (e.g. a grf
# convergence error) does NOT kill the other arms: the failed arm's row carries
# the error text in error_msg with NA estimate/se/coverage, and combine.R
# surfaces it (M4: no silent all-NA).
#
# Called by run_replication.R (which handles checkpointing and error capture).
# Assumes dgp.R and estimators.R have already been sourced, and that the
# extrapolateATT and grf packages are loaded.
# =============================================================================

# Offset that separates the unit-level covariate RNG stream from the gt-draw
# stream so the two arms of the DGP stay independent (mirrors the old batch
# runner's distinct 7000+r and 90000+r seed bands). With one config and
# N_REPS = 1000, seed + this offset never collides with any gt-draw seed.
S7EST_UNIT_SEED_OFFSET <- 500000L

run_one <- function(unit_row) {
  config_id <- unit_row$config_id
  rep_id    <- unit_row$rep_id
  unit      <- unit_row$unit
  seed      <- .unit_seed(config_id, rep_id)

  # One-row builder so every arm shares the exact column schema (and order).
  make_row <- function(arm, estimate = NA_real_, se = NA_real_,
                       covered_95 = NA, covered_90 = NA,
                       error_msg = NA_character_) {
    data.frame(
      unit       = unit,
      config_id  = config_id,
      rep_id     = rep_id,
      arm        = arm,
      estimate   = estimate,
      se         = se,
      covered_95 = covered_95,
      covered_90 = covered_90,
      true_fatt  = S7EST_TRUE_FATT,
      error_msg  = error_msg,
      stringsAsFactors = FALSE
    )
  }

  # --- Shared group-time draw (used by path1 and path2) ---------------------
  gt_err <- NA_character_
  gt <- tryCatch(
    add_noise_and_eif(S7EST_THETA_GT, n = S7EST_N,
                      sigma_tau = S7EST_SIGMA_TAU, seed = seed),
    error = function(e) { gt_err <<- conditionMessage(e); NULL }
  )

  # --- Arm 1: Path 1 (time-homogeneity aggregate) ---------------------------
  row_p1 <- tryCatch({
    if (is.null(gt)) stop(gt_err)
    p1      <- path1_aggregate(gt, S7EST_OMEGA)
    inf1_95 <- compute_variance(p1$phi_future, estimate = p1$tau_future, level = 0.95)
    inf1_90 <- compute_variance(p1$phi_future, estimate = p1$tau_future, level = 0.90)
    make_row("path1", estimate = p1$tau_future, se = inf1_95$se,
             covered_95 = (S7EST_TRUE_FATT >= inf1_95$ci[1] & S7EST_TRUE_FATT <= inf1_95$ci[2]),
             covered_90 = (S7EST_TRUE_FATT >= inf1_90$ci[1] & S7EST_TRUE_FATT <= inf1_90$ci[2]))
  }, error = function(e) make_row("path1", error_msg = conditionMessage(e)))

  # --- Arm 2: Path 2 (temporal extrapolation) -------------------------------
  row_p2 <- tryCatch({
    if (is.null(gt)) stop(gt_err)
    ex      <- extrapolate_ATT(gt, h_fun = hg_linear, dh_fun = dh_linear,
                               future_value = S7EST_FUTURE_TIME, time_scale = "calendar",
                               omega = S7EST_OMEGA, per_group = FALSE)
    inf2_95 <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = 0.95)
    inf2_90 <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = 0.90)
    make_row("path2", estimate = ex$tau_future, se = inf2_95$se,
             covered_95 = (S7EST_TRUE_FATT >= inf2_95$ci[1] & S7EST_TRUE_FATT <= inf2_95$ci[2]),
             covered_90 = (S7EST_TRUE_FATT >= inf2_90$ci[1] & S7EST_TRUE_FATT <= inf2_90$ci[2]))
  }, error = function(e) make_row("path2", error_msg = conditionMessage(e)))

  # --- Shared unit-level draw (used by path3-oracle and path3-grf) -----------
  # Independent RNG stream (see S7EST_UNIT_SEED_OFFSET above).
  unit_err <- NA_character_
  ud <- tryCatch({
    set.seed(seed + S7EST_UNIT_SEED_OFFSET)
    X_u   <- stats::rnorm(S7EST_N_UNIT, mean = S7EST_MU_SOURCE, sd = S7EST_SIGMA_X)
    e_u   <- stats::plogis(0.4 * X_u)
    A_u   <- stats::rbinom(S7EST_N_UNIT, 1, e_u)
    mu0_u <- 0.5 * X_u
    tau_u <- S7EST_ALPHA + S7EST_BETA * X_u
    mu1_u <- mu0_u + tau_u
    Y_u   <- mu0_u + A_u * tau_u + stats::rnorm(S7EST_N_UNIT, sd = S7EST_SIGMA_Y)
    w_u   <- stats::dnorm(X_u, S7EST_MU_TARGET, S7EST_SIGMA_X) /
             stats::dnorm(X_u, S7EST_MU_SOURCE, S7EST_SIGMA_X)
    w_u   <- w_u / mean(w_u)
    list(X_u = X_u, e_u = e_u, A_u = A_u, mu0_u = mu0_u,
         tau_u = tau_u, mu1_u = mu1_u, Y_u = Y_u, w_u = w_u)
  }, error = function(e) { unit_err <<- conditionMessage(e); NULL })

  # --- Arm 3: Path 3a (oracle CATE) -----------------------------------------
  row_p3o <- tryCatch({
    if (is.null(ud)) stop(unit_err)
    cate_oracle <- list(tau = ud$tau_u, mu1 = ud$mu1_u, mu0 = ud$mu0_u, e = ud$e_u,
                        A = ud$A_u, Y = ud$Y_u, X = data.frame(x1 = ud$X_u))
    p3o_95 <- integrate_cate(cate_oracle, design = "unconfoundedness",
                             weights = ud$w_u, level = 0.95)
    p3o_90 <- integrate_cate(cate_oracle, design = "unconfoundedness",
                             weights = ud$w_u, level = 0.90)
    make_row("path3_oracle", estimate = p3o_95$estimate, se = p3o_95$se,
             covered_95 = (S7EST_TRUE_FATT >= p3o_95$ci[1] & S7EST_TRUE_FATT <= p3o_95$ci[2]),
             covered_90 = (S7EST_TRUE_FATT >= p3o_90$ci[1] & S7EST_TRUE_FATT <= p3o_90$ci[2]))
  }, error = function(e) make_row("path3_oracle", error_msg = conditionMessage(e)))

  # --- Arm 4: Path 3b (estimated CATE via grf) ------------------------------
  row_p3g <- tryCatch({
    if (is.null(ud)) stop(unit_err)
    forest   <- grf::causal_forest(X = matrix(ud$X_u, ncol = 1), Y = ud$Y_u, W = ud$A_u,
                                   num.trees = 500)
    cate_est <- as_cate(forest)
    p3g_95 <- integrate_cate(cate_est, design = "unconfoundedness",
                             weights = ud$w_u, level = 0.95)
    p3g_90 <- integrate_cate(cate_est, design = "unconfoundedness",
                             weights = ud$w_u, level = 0.90)
    make_row("path3_grf", estimate = p3g_95$estimate, se = p3g_95$se,
             covered_95 = (S7EST_TRUE_FATT >= p3g_95$ci[1] & S7EST_TRUE_FATT <= p3g_95$ci[2]),
             covered_90 = (S7EST_TRUE_FATT >= p3g_90$ci[1] & S7EST_TRUE_FATT <= p3g_90$ci[2]))
  }, error = function(e) make_row("path3_grf", error_msg = conditionMessage(e)))

  rbind(row_p1, row_p2, row_p3o, row_p3g)
}

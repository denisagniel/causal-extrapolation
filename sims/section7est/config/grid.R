# =============================================================================
# config/grid.R -- single source of truth for the "section7est" simulation study
# =============================================================================
# Section 7 (estimated CATE): Path 3 transport of a conditional ATT to a target
# covariate distribution, comparing four estimator arms (path1, path2,
# path3-oracle, path3-grf). One configuration (fixed DGP), 1000 total reps.
#
# Sourced by run_replication.R, profile_timing.R, and combine.R.
# No side effects beyond assigning objects in the calling environment.
# =============================================================================

STUDY_NAME   <- "section7est"
PROJECT_NAME <- "causal-extrapolation"
BASE_SEED    <- 20260803L   # distinct from the old gt/unit seeds (7000/90000 bands)

# --- DGP parameters -----------------------------------------------------------
# Extracted verbatim from sims/slurm/run_rep_section7est.R (must match
# sim_section7_path3_covariates.R). DO NOT change without re-running.
S7EST_Q          <- 3L
S7EST_P          <- 5L
S7EST_N          <- 500L
S7EST_OMEGA      <- rep(1 / S7EST_Q, S7EST_Q)
S7EST_FUTURE_TIME <- S7EST_P + 1L
S7EST_LEVEL      <- 0.95
S7EST_SIGMA_TAU  <- 0.1
S7EST_ALPHA      <- 2.0
S7EST_BETA       <- 1.5
S7EST_MU_G       <- c(-1.0, 0.0, 1.0)
S7EST_SIGMA_X    <- 1.0
S7EST_MU_TARGET  <- 0.5
S7EST_N_UNIT     <- 500L
S7EST_MU_SOURCE  <- 0.0
S7EST_SIGMA_Y    <- 0.5

# --- Grid and replication count -----------------------------------------------
# One config; the "grid" exists to satisfy the unit_table() contract.
GRID <- data.frame(
  config_id = 1L,
  stringsAsFactors = FALSE
)

N_REPS <- 1000L

# --- unit_table() -------------------------------------------------------------
# Returns a data.frame with one row per (config_id, rep_id), columns:
#   unit      -- globally unique 1-based integer id
#   config_id
#   rep_id
# Row ordering: rep-fastest within config (only one config here).
unit_table <- function() {
  ut <- expand.grid(
    config_id = GRID$config_id,
    rep_id    = seq_len(N_REPS),
    STRINGSASFACTORS = FALSE
  )
  ut <- ut[order(ut$config_id, ut$rep_id), , drop = FALSE]
  ut$unit <- seq_len(nrow(ut))
  ut[, c("unit", "config_id", "rep_id"), drop = FALSE]
}

# --- n_units() ----------------------------------------------------------------
n_units <- function() nrow(GRID) * N_REPS

# --- .unit_seed() -------------------------------------------------------------
# Deterministic per-unit seed independent of row ordering.
# seed = BASE_SEED + config_id * SEED_STRIDE + rep_id
# With N_REPS = 1000 and one config, seeds occupy a well-separated band.
SEED_STRIDE <- 100000L
.unit_seed <- function(config_id, rep_id) {
  BASE_SEED + config_id * SEED_STRIDE + rep_id
}

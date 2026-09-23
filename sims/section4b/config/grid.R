# =============================================================================
# config/grid.R -- single source of truth for the "section4b" simulation study
# =============================================================================
# Section 4b: EIF coverage with a real did::att_gt() first stage.
# One configuration (fixed DGP), 1000 total replications.
#
# Sourced by run_replication.R, profile_timing.R, and combine.R.
# No side effects beyond assigning objects in the calling environment.
# =============================================================================

STUDY_NAME   <- "section4b"
PROJECT_NAME <- "causal-extrapolation"
BASE_SEED    <- 20260803L   # distinct from the old base_seed 40000

# --- DGP parameters -----------------------------------------------------------
# These are the canonical parameters; DO NOT change without re-running.
S4B_Q            <- 3L
S4B_P            <- 5L
S4B_N_PER_COHORT <- 200L
S4B_OMEGA        <- rep(1 / S4B_Q, S4B_Q)
S4B_FUTURE_TIME  <- S4B_P + 1L
S4B_LEVEL        <- 0.95
S4B_SIGMA_Y      <- 0.5
S4B_SIGMA_ALPHA  <- 1.0
S4B_ALPHA_G      <- c(0.2, 0.0, -0.1)
S4B_BETA_G       <- c(0.1, 0.08, 0.12)

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

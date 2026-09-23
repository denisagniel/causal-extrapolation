#!/usr/bin/env Rscript
# =============================================================================
# R/estimators.R -- estimators for section4b
# =============================================================================
# Thin wrapper: loads the shared dgp_helpers.R functions needed for estimation.
# The actual estimation logic (extrapolate_ATT, compute_variance) lives in the
# extrapolateATT package, loaded by run_replication.R via library().
# No side effects.
# =============================================================================

# Nothing to define here beyond what dgp.R already sourced.
# extrapolate_ATT(), compute_variance(), hg_linear, dh_linear come from
# the extrapolateATT package (library(extrapolateATT) in run_replication.R).

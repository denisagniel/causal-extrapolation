#!/usr/bin/env Rscript
# =============================================================================
# R/estimators.R -- estimators for section7est
# =============================================================================
# Thin wrapper. The four estimator arms exercised by run_one.R come from the
# extrapolateATT package (loaded by run_replication.R via library()):
#   * path1  -- path1_aggregate()            (time-homogeneity aggregate)
#   * path2  -- extrapolate_ATT() + hg_linear/dh_linear (temporal extrapolation)
#   * path3  -- integrate_cate() over a CATE contract (oracle tau(X) and grf)
# compute_variance() supplies the influence-function inference for path1/path2.
# grf::causal_forest() (loaded via library(grf)) supplies the estimated CATE for
# the path3-grf arm; as_cate() adapts it to the integrate_cate() contract.
# No side effects.
# =============================================================================

# Nothing to define here beyond what dgp.R already sourced.
# path1_aggregate(), extrapolate_ATT(), compute_variance(), integrate_cate(),
# as_cate(), hg_linear, dh_linear come from the extrapolateATT package
# (library(extrapolateATT) in run_replication.R).

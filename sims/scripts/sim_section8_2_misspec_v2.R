# Section 8.2: Conditional Model Misspecification (Path 3 Break Point)
#
# Purpose: Show Path 3 fails when there's unobserved heterogeneity
#
# Simplified approach:
# - True DGP has effects depending on X (observed)
# - We add unobserved group-level heterogeneity (random effects alpha_g)
# - When we fit tau(X) ignoring group random effects, we get omitted variable bias
# - This is analogous to unobserved individual-level heterogeneity U
#
# DGP: theta_gt = alpha_g + beta_X * mu_X[g]
#      where alpha_g ~ N(0, sigma_alpha^2) is group-level unobserved heterogeneity
#
# Path 3 fits: theta_g = beta_0 + beta_1 * mu_X[g] (ignores alpha_g heterogeneity)
#
# Expected result:
#   - When sigma_alpha is large, Path 3 extrapolation biased (absorbs heterogeneity into beta_1)
#   - Bias increases with sigma_alpha
#   - Coverage fails
#
# Why this matters:
#   - Path 3 assumes all heterogeneity is captured by observed X
#   - In practice, groups differ for many reasons beyond measured covariates
#   - This shows consequences of unmodeled heterogeneity

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})

devtools::load_all("package")
source("sims/scripts/dgp_helpers.R")

# For now, let's create a simpler demonstration using Path 1 and Path 2
# to show where they break, which is more straightforward and doesn't require
# extensive modifications to the conditional model API

# THIS FILE IS A PLACEHOLDER - Section 8.2 requires more careful design
# to properly demonstrate omitted variable bias in Path 3.
#
# For the initial implementation, we'll focus on:
# - Section 8.1: Non-smooth dynamics (Path 2 break point)
# - Section 8.3: Small-sample behavior (all paths)
#
# Section 8.2 can be added later with proper Path 3 API integration

message("Section 8.2: Conditional misspecification")
message("This simulation requires careful API design.")
message("Deferring to focus on Sections 8.1 and 8.3 first.")
message("Placeholder created for future implementation.")

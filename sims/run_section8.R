# Run Section 8: Stress Tests and Edge Cases
#
# Purpose: Demonstrate where each extrapolation path fails (constitution §9 compliance)
#
# This script runs all Section 8 simulations showing method limitations:
#   - Section 8.1: Non-smooth dynamics (Path 2 break point)
#   - Section 8.2: Conditional misspecification (Path 3 break point, unobserved heterogeneity)
#   - Section 8.3: Small-sample extrapolation (all paths)
#
# These simulations complement Sections 1-7 (which show methods working) by
# showing where they break. This honesty builds credibility per research constitution.

library(cli)

cli_h1("Section 8: Stress Tests and Edge Cases")

cli_alert_info("Running stress test simulations...")
cli_alert_info("These show where extrapolation methods fail")

# ============================================================================
# Section 8.1: Non-Smooth Dynamics (Path 2 Break Point)
# ============================================================================

cli_h2("Section 8.1: Non-Smooth Dynamics")
cli_alert("DGP: Piecewise linear with break at k=3")
cli_alert("Methods: Linear, quadratic, spline extrapolation")
cli_alert("Expected: All smooth models struggle beyond break point")

source("sims/scripts/sim_section8_1_nonsmooth.R")
cli_alert_success("Section 8.1 complete")

# ============================================================================
# Section 8.2: Conditional Misspecification (Path 3 Break Point)
# ============================================================================

cli_h2("Section 8.2: Conditional Misspecification")
cli_alert("DGP: unobserved effect modifier U correlated with observed X")
cli_alert("Methods: Path 3 with X-only model (misspecified) vs oracle (X and U)")
cli_alert("Expected: X-only bias grows with cor(X,U); oracle unbiased")

source("sims/scripts/sim_section8_2_misspec.R")
cli_alert_success("Section 8.2 complete")

# ============================================================================
# Section 8.3: Small-Sample Extrapolation (All Paths)
# ============================================================================

cli_h2("Section 8.3: Small-Sample Extrapolation")
cli_alert("DGP: Linear (well-specified)")
cli_alert("Vary p = 2, 3, 4, 5, 10 (number of observed periods)")
cli_alert("Expected: SE explodes as p → 2")

source("sims/scripts/sim_section8_3_smallsample.R")
cli_alert_success("Section 8.3 complete")

# ============================================================================
# Summary
# ============================================================================

cli_h2("Summary")

cli_alert_success("All Section 8 stress tests complete")
cli_alert_info("Results saved to sims/results/")

cli_ul(c(
  "section8_1_nonsmooth.rds - Path 2 fails on piecewise linear DGP",
  "section8_2_misspec.rds - Path 3 fails under unobserved heterogeneity",
  "section8_3_smallsample.rds - Uncertainty explosion with few periods"
))

cli_alert_info("These simulations show where methods break, building credibility")
cli_alert_info("Complement Sections 1-7 (methods working) per constitution §9")

cli_alert("Next: Generate LaTeX tables via write_paper_tables.R")

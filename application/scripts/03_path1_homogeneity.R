# Phase 2.2: Path 1 - Time Homogeneity
# Assume constant post-treatment effects; aggregate group-time ATTs with the package,
# propagating efficient influence functions for valid (EIF-based) inference.

library(tidyverse)
library(fs)

devtools::load_all(".")

set.seed(20260709)
dir_create("application/results")

cat("=== Phase 2.2: Path 1 - Time Homogeneity ===\n\n")

gt_obj <- readRDS("application/results/gt_object_training.rds")

# ---------------------------------------------------------------------------
# Path 1 assumes a constant effect within each cohort, so we aggregate over the
# POST-treatment group-time cells (k >= 0). Subset the gt_object (data + aligned
# EIFs) to post-treatment cells, then let path1_aggregate() do within-group
# averaging + across-group weighting, propagating the EIF at each step.
# ---------------------------------------------------------------------------
post_idx <- which(gt_obj$data$g > 0 & gt_obj$data$k >= 0)

gt_post <- gt_obj
gt_post$data <- gt_obj$data[post_idx, ]
gt_post$phi <- gt_obj$phi[post_idx]
gt_post$groups <- sort(unique(gt_post$data$g))
gt_post$event_times <- sort(unique(gt_post$data$k))

cat("Post-treatment cells:", nrow(gt_post$data), "across",
    length(gt_post$groups), "cohorts\n\n")

# Group weights omega_g: proportional to each cohort's number of treated states.
# (Reflects how many units each cohort represents; equal weights are the fallback.)
cohort_sizes <- readr::read_csv("application/results/syg_cohorts.csv",
                                show_col_types = FALSE) %>%
  filter(cohort %in% gt_post$groups) %>%
  count(cohort, name = "n_states")

omega_tbl <- tibble(cohort = gt_post$groups) %>%
  left_join(cohort_sizes, by = "cohort") %>%
  mutate(n_states = replace_na(n_states, 1),
         omega = n_states / sum(n_states))
omega <- omega_tbl$omega

cat("Cohort weights (omega_g, proportional to treated states):\n")
print(omega_tbl)
cat("\n")

# Path 1: within-group average then across-group aggregation, with EIF propagation.
p1 <- path1_aggregate(gt_post, omega = omega)

# EIF-based variance / CI (reuses the package's compute_variance()). center = FALSE uses
# the uncentered mean(phi^2)/n estimator, matching cv_extrapolate_ATT()'s convention (the
# EIF is mean-zero by construction, so this is numerically identical but consistent).
inf <- compute_variance(p1$phi_future, estimate = p1$tau_future, level = 0.95,
                        center = FALSE)

cat("Path 1 constant effect (EIF-based inference):\n")
cat("  ATT   =", round(p1$tau_future, 3), "\n")
cat("  SE    =", round(inf$se, 3), "\n")
cat("  95% CI = [", round(inf$ci[1], 3), ",", round(inf$ci[2], 3), "]\n\n")

# Constant prediction carried forward to every validation year 2016-2022.
future_years <- 2016:2022
predictions_path1 <- tibble(
  year = future_years,
  att_pred = p1$tau_future,
  se_pred = inf$se,
  ci_lower = inf$ci[1],
  ci_upper = inf$ci[2]
)

cat("Predictions for 2016-2022:\n")
print(predictions_path1)

saveRDS(list(
  predictions = predictions_path1,
  tau_future = p1$tau_future,
  se = inf$se,
  phi_future = p1$phi_future,
  omega = omega_tbl,
  method = "Time homogeneity (constant effects, EIF-based)"
), "application/results/path1_homogeneity.rds")

cat("\nSaved: application/results/path1_homogeneity.rds\n")
cat("\n=== Phase 2.2 Complete ===\n")
cat("Next: Run 04_path2_model_selection.R\n")

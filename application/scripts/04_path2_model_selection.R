# Phase 2.3: Path 2 - Temporal Model Selection via Time-Series CV
# Select a temporal extrapolation model by the package's time-series cross-validation
# (paper Section 5.2), then extrapolate each cohort forward with EIF propagation.

library(tidyverse)
library(fs)

devtools::load_all(".")

set.seed(20260709)
dir_create("application/results")

cat("=== Phase 2.3: Path 2 - Model Selection (time-series CV) ===\n\n")

gt_obj <- readRDS("application/results/gt_object_training.rds")
syg_cohorts <- readr::read_csv("application/results/syg_cohorts.csv",
                               show_col_types = FALSE)

# Post-treatment subset (event time k >= 0), EIF-aligned.
post_idx <- which(gt_obj$data$g > 0 & gt_obj$data$k >= 0)
gt_post <- gt_obj
gt_post$data <- gt_obj$data[post_idx, ]
gt_post$phi <- gt_obj$phi[post_idx]
gt_post$groups <- sort(unique(gt_post$data$g))
gt_post$event_times <- sort(unique(gt_post$data$k))

cat("Post-treatment cells:", nrow(gt_post$data), "| event times",
    min(gt_post$data$k), "-", max(gt_post$data$k), "\n")

# Cohort weights (match Path 1): proportional to number of treated states.
omega_tbl <- tibble(cohort = gt_post$groups) %>%
  left_join(count(filter(syg_cohorts, cohort %in% gt_post$groups),
                  cohort, name = "n_states"), by = "cohort") %>%
  mutate(n_states = replace_na(n_states, 1),
         omega = n_states / sum(n_states))
omega <- omega_tbl$omega

# ---------------------------------------------------------------------------
# Step 1: time-series cross-validation to select the temporal model.
# Hold out the last 1-2 event-time periods, fit on earlier, score by MSPE.
# NOTE: late event-times are supported by only the longest-history cohort (1995);
# CV therefore leans on that cohort's trajectory. We report this rather than hide it.
# ---------------------------------------------------------------------------
specs <- build_model_specs(c("linear", "quadratic"))
max_k <- max(gt_post$data$k)

cv <- cv_extrapolate_ATT(
  gt_post,
  model_specs = specs,
  horizons = 1:2,
  future_value = max_k,
  time_scale = "event"
)
best_name <- select_best_model(cv, criterion = "mspe")  # public selection API

cat("\nCV results (time-series, event scale):\n")
print(cv$results)
cat("\nSelected model (min MSPE):", best_name, "\n\n")

best_spec <- specs[[best_name]]

# ---------------------------------------------------------------------------
# Step 2: forecast each cohort to the event-time it reaches in each future year,
# then aggregate across cohorts with omega. In year `yr`, cohort `g` is at event
# time k = yr - g. extrapolate_ATT() takes a single event time (future_value = k*)
# and forecasts every cohort there, propagating the EIF via the model Jacobian; we
# read off each cohort's own k*, then aggregate cohorts with omega per year.
#
# We cache the per-group forecast + EIF at each needed k* to avoid recomputation.
# ---------------------------------------------------------------------------
future_years <- 2016:2022
needed_ks <- sort(unique(as.vector(outer(future_years, gt_post$groups, `-`))))
needed_ks <- needed_ks[needed_ks >= 0]

# One extrapolate_ATT call per distinct target event time; keep per-group tau + EIF.
forecasts_by_k <- purrr::map(needed_ks, function(kstar) {
  ex <- extrapolate_ATT(
    gt_post,
    h_fun = best_spec$h_fun,
    dh_fun = best_spec$dh_fun,
    future_value = kstar,
    time_scale = "event",
    per_group = TRUE
  )
  list(tau = setNames(ex$tau_g_future$tau_future, ex$tau_g_future$g),
       phi = setNames(ex$phi_g_future, names(ex$phi_g_future)))
})
names(forecasts_by_k) <- as.character(needed_ks)

# Aggregate cohorts within each year: att(yr) = sum_g omega_g * tau_g(k = yr - g),
# with the matching EIF aggregation for a valid SE.
omega_by_cohort <- setNames(omega, as.character(gt_post$groups))

year_preds <- purrr::map_dfr(future_years, function(yr) {
  ks <- yr - gt_post$groups
  keep <- ks >= 0                                   # cohort must be post-treatment by yr
  gs <- gt_post$groups[keep]
  w <- omega_by_cohort[as.character(gs)]
  w <- w / sum(w)                                   # renormalize over contributing cohorts

  tau_yr <- 0
  phi_yr <- numeric(gt_post$n)
  for (j in seq_along(gs)) {
    kstar <- as.character(yr - gs[j])
    gkey <- as.character(gs[j])
    # Guard against a future change in how did/extrapolate_ATT orders/names groups.
    stopifnot(gkey %in% names(forecasts_by_k[[kstar]]$tau))
    tau_yr <- tau_yr + w[j] * forecasts_by_k[[kstar]]$tau[[gkey]]
    phi_yr <- phi_yr + w[j] * forecasts_by_k[[kstar]]$phi[[gkey]]
  }
  # center = FALSE: uncentered mean(phi^2)/n, consistent with cv_extrapolate_ATT().
  inf <- compute_variance(phi_yr, estimate = tau_yr, level = 0.95, center = FALSE)
  tibble(year = yr, att_pred = tau_yr, se_pred = inf$se,
         ci_lower = inf$ci[1], ci_upper = inf$ci[2])
})

cat("Predictions for 2016-2022 (model:", best_name, ", EIF-based):\n")
print(year_preds)

saveRDS(list(
  predictions = year_preds,
  best_model = best_name,
  cv_results = cv$results,
  omega = omega_tbl,
  method = paste0("Model selection via time-series CV (", best_name, ", EIF-based)")
), "application/results/path2_model_selection.rds")

cat("\nSaved: application/results/path2_model_selection.rds\n")
cat("\n=== Phase 2.3 Complete ===\n")
cat("Next: Run 06_validation.R\n")

# Phase 2.5: Validation
# Compare Path 1 / Path 2 predictions (EIF-based) against realized 2016-2022 ATTs.
# Path 3 is deferred (see 05 banner) pending the DiD transport influence function.

library(tidyverse)
library(fs)

cat("=== Phase 2.5: Validation ===\n\n")

dir_create("application/results")

# Path 1 / Path 2 predictions (both now EIF-based).
path1 <- readRDS("application/results/path1_homogeneity.rds")
path2 <- readRDS("application/results/path2_model_selection.rds")

# Realized ATTs (from full-period estimation), aggregated by year with the SAME cohort
# weights the predictions use. The predictions target sum_g omega_g * tau_g (omega =
# cohort-size weights, renormalized over cohorts post-treatment that year), so the
# realized validation target MUST use the same weighting or the comparison mixes
# estimands (an equal-weighted realized mean vs an omega-weighted prediction).
realized <- readRDS("application/results/realized_atts_2016_2022.rds")

# omega_g by cohort (from Path 1; identical weights in Path 2).
omega_by_cohort <- path1$omega %>% select(cohort, omega)

realized_yearly <- realized %>%
  left_join(omega_by_cohort, by = c("group" = "cohort")) %>%
  mutate(omega = replace_na(omega, 0)) %>%
  group_by(year) %>%
  summarize(
    # Renormalize omega over the cohorts contributing this year, matching the
    # per-year renormalization in scripts 03/04.
    att_realized = weighted.mean(att, omega, na.rm = TRUE),
    se_realized = mean(se, na.rm = TRUE),
    n_groups = n(), .groups = "drop")

cat("Realized ATTs by year (omega-weighted, matching predictions):\n")
print(realized_yearly)
cat("\n")

all_preds <- realized_yearly %>%
  select(year, realized = att_realized) %>%
  left_join(path1$predictions %>% select(year, path1 = att_pred,
                                         se_path1 = se_pred,
                                         lo_path1 = ci_lower, hi_path1 = ci_upper),
            by = "year") %>%
  left_join(path2$predictions %>% select(year, path2 = att_pred,
                                         se_path2 = se_pred,
                                         lo_path2 = ci_lower, hi_path2 = ci_upper),
            by = "year")

cat("Predictions vs realized:\n")
print(all_preds)
cat("\n")

# Validation metrics per path.
metric_row <- function(pred, lo, hi, realized, label, method) {
  tibble(
    path = label, method = method,
    mspe = mean((pred - realized)^2, na.rm = TRUE),
    mae = mean(abs(pred - realized), na.rm = TRUE),
    coverage_95 = mean(realized >= lo & realized <= hi, na.rm = TRUE)
  )
}

validation_summary <- bind_rows(
  metric_row(all_preds$path1, all_preds$lo_path1, all_preds$hi_path1,
             all_preds$realized, "Path 1", path1$method),
  metric_row(all_preds$path2, all_preds$lo_path2, all_preds$hi_path2,
             all_preds$realized, "Path 2", path2$method)
)

cat("Validation summary (Path 1 & 2; Path 3 deferred):\n")
print(validation_summary)
cat("\nBest by MSPE:", validation_summary$path[which.min(validation_summary$mspe)], "\n")

saveRDS(validation_summary, "application/results/validation_summary.rds")
saveRDS(all_preds, "application/results/validation_full.rds")
cat("\nSaved: application/results/validation_summary.rds, validation_full.rds\n")

cat("\n=== Phase 2.5 Complete ===\n")
cat("Next: Run 07_generate_tables.R\n")

# Phase 2.5: Validation
# Compare predictions against realized 2016-2022 outcomes

library(tidyverse)

cat("=== Phase 2.5: Validation ===\n\n")

# Load realized ATTs (from full estimation)
realized <- readRDS("application/results/realized_atts_2016_2022.rds")

cat("Realized ATTs (2016-2022):\n")
cat("  Observations:", nrow(realized), "\n")
cat("  Mean ATT:", round(mean(realized$att, na.rm = TRUE), 3), "\n")
cat("  SD ATT:", round(sd(realized$att, na.rm = TRUE), 3), "\n\n")

# Compute simple average by year for validation
realized_yearly <- realized %>%
  group_by(year) %>%
  summarize(
    att_realized = mean(att, na.rm = TRUE),
    se_realized = mean(se, na.rm = TRUE),  # Average SE across groups
    n_groups = n(),
    .groups = "drop"
  )

cat("Realized ATTs by year:\n")
print(realized_yearly)
cat("\n")

# Load predictions from all three paths
path1 <- readRDS("application/results/path1_homogeneity.rds")
path2 <- readRDS("application/results/path2_model_selection.rds")
path3 <- readRDS("application/results/path3_covariate_integration.rds")

# Combine predictions
all_preds <- data.frame(
  year = path1$predictions$year,
  realized = realized_yearly$att_realized,
  path1 = path1$predictions$att_pred,
  path2 = path2$predictions$att_pred,
  path3 = path3$predictions$att_pred,
  se_realized = realized_yearly$se_realized,
  se_path1 = path1$predictions$se_pred,
  se_path2 = path2$predictions$se_pred,
  se_path3 = path3$predictions$se_pred
)

cat("Combined predictions and realized values:\n")
print(all_preds)
cat("\n")

# Compute validation metrics

# Mean Squared Prediction Error (MSPE)
mspe1 <- mean((all_preds$path1 - all_preds$realized)^2, na.rm = TRUE)
mspe2 <- mean((all_preds$path2 - all_preds$realized)^2, na.rm = TRUE)
mspe3 <- mean((all_preds$path3 - all_preds$realized)^2, na.rm = TRUE)

# Mean Absolute Error (MAE)
mae1 <- mean(abs(all_preds$path1 - all_preds$realized), na.rm = TRUE)
mae2 <- mean(abs(all_preds$path2 - all_preds$realized), na.rm = TRUE)
mae3 <- mean(abs(all_preds$path3 - all_preds$realized), na.rm = TRUE)

# Coverage rate (95% CI)
# Path 1
ci_lower1 <- path1$predictions$ci_lower
ci_upper1 <- path1$predictions$ci_upper
coverage1 <- mean(all_preds$realized >= ci_lower1 & all_preds$realized <= ci_upper1)

# Path 2
ci_lower2 <- path2$predictions$ci_lower
ci_upper2 <- path2$predictions$ci_upper
coverage2 <- mean(all_preds$realized >= ci_lower2 & all_preds$realized <= ci_upper2)

# Path 3
ci_lower3 <- path3$predictions$ci_lower
ci_upper3 <- path3$predictions$ci_upper
coverage3 <- mean(all_preds$realized >= ci_lower3 & all_preds$realized <= ci_upper3)

# Summarize
validation_summary <- data.frame(
  path = c("Path 1: Homogeneity", "Path 2: Model Selection", "Path 3: Covariate Integration"),
  method = c(path1$method, path2$method, path3$method),
  mspe = c(mspe1, mspe2, mspe3),
  mae = c(mae1, mae2, mae3),
  coverage_95 = c(coverage1, coverage2, coverage3)
)

cat("Validation Summary:\n")
print(validation_summary)
cat("\n")

# Best method by MSPE
best_method <- validation_summary$path[which.min(validation_summary$mspe)]
cat("Best method by MSPE:", best_method, "\n\n")

# Save results
saveRDS(validation_summary, "application/results/validation_summary.rds")
saveRDS(all_preds, "application/results/validation_full.rds")

cat("Saved: application/results/validation_summary.rds\n")
cat("Saved: application/results/validation_full.rds\n")

cat("\n=== Phase 2.5 Complete ===\n")
cat("Next: Run 07_generate_tables.R\n")

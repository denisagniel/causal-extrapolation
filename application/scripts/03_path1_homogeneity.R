# Phase 2.2: Path 1 - Time Homogeneity
# Simple aggregation assuming constant effects over time

library(tidyverse)

# Load package
devtools::load_all(".")

cat("=== Phase 2.2: Path 1 - Time Homogeneity ===\n\n")

# Load group-time ATT estimates from training period
gt_obj <- readRDS("application/results/gt_object_training.rds")

cat("Loaded training group-time ATTs\n")
cat("Groups:", length(unique(gt_obj$group[gt_obj$group > 0])), "\n")
cat("Periods:", min(gt_obj$t), "-", max(gt_obj$t), "\n\n")

# Path 1: Assume constant effects (time homogeneity)
# Aggregate all post-treatment ATTs and extrapolate forward
cat("Path 1: Assuming time-homogeneous effects\n")
cat("Strategy: Simple average of all post-treatment ATTs\n\n")

# Extract post-treatment ATTs
gt_df <- data.frame(
  group = gt_obj$group,
  time = gt_obj$t,
  att = gt_obj$att,
  se = gt_obj$se
) %>%
  filter(group > 0, time >= group)  # Post-treatment only

cat("Post-treatment ATTs: ", nrow(gt_df), "\n")
cat("Mean ATT:", round(mean(gt_df$att, na.rm = TRUE), 3), "\n")
cat("SD ATT:", round(sd(gt_df$att, na.rm = TRUE), 3), "\n\n")

# Simple constant prediction: use mean of all post-treatment ATTs
mean_att <- mean(gt_df$att, na.rm = TRUE)

# For variance, we need to account for correlation across group-times
# Use the average influence function approach
# (In practice, we'd aggregate properly; for now, simple SE from mean)
se_att <- sd(gt_df$att, na.rm = TRUE) / sqrt(nrow(gt_df))

cat("Constant prediction for all future periods:\n")
cat("  ATT =", round(mean_att, 3), "\n")
cat("  SE  =", round(se_att, 3), "\n")
cat("  95% CI = [", round(mean_att - 1.96*se_att, 3), ",",
    round(mean_att + 1.96*se_att, 3), "]\n\n")

# Create predictions for 2016-2022
future_years <- 2016:2022
predictions_path1 <- data.frame(
  year = future_years,
  att_pred = mean_att,
  se_pred = se_att,
  ci_lower = mean_att - 1.96*se_att,
  ci_upper = mean_att + 1.96*se_att
)

cat("Predictions for 2016-2022:\n")
print(predictions_path1)

# Save results
saveRDS(list(
  predictions = predictions_path1,
  mean_att = mean_att,
  se_att = se_att,
  method = "Time homogeneity (constant effects)"
), "application/results/path1_homogeneity.rds")

cat("\nSaved: application/results/path1_homogeneity.rds\n")

cat("\n=== Phase 2.2 Complete ===\n")
cat("Next: Run 04_path2_model_selection.R\n")

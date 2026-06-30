# Phase 2.1: First-Stage Estimation
# Estimate group-time ATTs using did package

library(tidyverse)
library(did)  # Callaway & Sant'Anna

# Load package
devtools::load_all(".")

# Load analysis-ready data
data <- readRDS("application/results/analysis_data.rds")

cat("=== Phase 2.1: First-Stage Estimation ===\n\n")

# Training data: 1981-2015
# Focus on states that adopted SYG by 2015 (to have post-treatment data in training)
training_data <- data %>%
  filter(year <= 2015)

cat("Training data: ", nrow(training_data), " observations\n")
cat("States:", length(unique(training_data$state)), "\n")
cat("Years: ", min(training_data$year), "-", max(training_data$year), "\n\n")

# States that adopted SYG by 2015
early_adopters <- training_data %>%
  filter(cohort > 0, cohort <= 2015) %>%
  distinct(state, cohort)

cat("States adopting SYG by 2015: ", nrow(early_adopters), "\n")
cat("Adoption years:", paste(sort(unique(early_adopters$cohort)), collapse = ", "), "\n\n")

# Estimate group-time ATTs on training data
# Using did package (Callaway & Sant'Anna 2021)
cat("Estimating group-time ATTs (training period)...\n")

# Convert to format expected by did package
training_did <- training_data %>%
  mutate(
    # did wants cohort = 0 for never-treated
    # year as time period
    G = cohort,
    T = year,
    Y = deaths_per_100k,
    id = as.numeric(factor(state))  # Numeric state ID
  ) %>%
  select(id, G, T, Y, state)

# Estimate ATT(g,t) for all group-time combinations
# Using doubly-robust estimator (default)
gt_obj_training <- att_gt(
  yname = "Y",
  gname = "G",
  idname = "id",
  tname = "T",
  data = training_did,
  control_group = "nevertreated",  # Use never-treated as control
  anticipation = 0,
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000,
  clustervars = "id",
  est_method = "dr"  # Doubly-robust
)

cat("Done.\n\n")

# Summary
cat("Group-time ATTs estimated:\n")
cat("  Groups:", length(unique(gt_obj_training$group[gt_obj_training$group > 0])), "\n")
cat("  Periods:", length(unique(gt_obj_training$t)), "\n")
cat("  Total estimates:", length(gt_obj_training$att), "\n\n")

# Save training results
saveRDS(gt_obj_training, "application/results/gt_object_training.rds")
cat("Saved: application/results/gt_object_training.rds\n\n")

# Also estimate on full data (1981-2022) for validation
cat("Estimating group-time ATTs (full period)...\n")

full_did <- data %>%
  mutate(
    G = cohort,
    T = year,
    Y = deaths_per_100k,
    id = as.numeric(factor(state))
  ) %>%
  select(id, G, T, Y, state)

gt_obj_full <- att_gt(
  yname = "Y",
  gname = "G",
  idname = "id",
  tname = "T",
  data = full_did,
  control_group = "nevertreated",
  anticipation = 0,
  bstrap = TRUE,
  cband = TRUE,
  biters = 1000,
  clustervars = "id",
  est_method = "dr"
)

cat("Done.\n\n")

# Save full results
saveRDS(gt_obj_full, "application/results/gt_object_full.rds")
cat("Saved: application/results/gt_object_full.rds\n\n")

# Extract realized ATTs for 2016-2022 (for validation)
realized_atts <- data.frame(
  group = gt_obj_full$group,
  year = gt_obj_full$t,
  att = gt_obj_full$att,
  se = gt_obj_full$se
) %>%
  filter(year >= 2016, year <= 2022, group > 0, group <= 2015)

cat("Realized ATTs (2016-2022) for early adopters:\n")
print(head(realized_atts, 10))

saveRDS(realized_atts, "application/results/realized_atts_2016_2022.rds")
cat("\nSaved: application/results/realized_atts_2016_2022.rds\n")

cat("\n=== Phase 2.1 Complete ===\n")
cat("Next: Run 03_path1_homogeneity.R\n")

# Phase 2.4: Path 3 - Covariate Integration
# Conditional model: effects vary by state covariates

library(tidyverse)

# Load package
devtools::load_all(".")

cat("=== Phase 2.4: Path 3 - Covariate Integration ===\n\n")

# Load group-time ATT estimates and analysis data
gt_obj <- readRDS("application/results/gt_object_training.rds")
data <- readRDS("application/results/analysis_data.rds")

cat("Loaded training group-time ATTs and covariate data\n\n")

# Extract group-time data with state info
gt_df <- data.frame(
  group = gt_obj$group,
  time = gt_obj$t,
  att = gt_obj$att,
  se = gt_obj$se
) %>%
  filter(group > 0, time >= group)  # Post-treatment only

# Get state IDs from did object (need to map back)
# The did package uses numeric IDs, but we need state names
# Create mapping from training data
training_data <- data %>% filter(year <= 2015)
state_mapping <- training_data %>%
  mutate(id = as.numeric(factor(state))) %>%
  distinct(state, id, cohort) %>%
  arrange(id)

cat("State mapping: ", nrow(state_mapping), " states\n")

# Merge covariates with group-time ATTs
# Match group (cohort) with state covariates
# Use baseline covariates (pre-treatment or first year)
baseline_covariates <- data %>%
  filter(year == 1981) %>%  # Use 1981 as baseline
  select(state, poverty_rate, urbanization, pct_black)

# Merge with state_mapping
state_covars <- state_mapping %>%
  left_join(baseline_covariates, by = "state")

cat("Baseline covariates (1981):\n")
print(head(state_covars))
cat("\n")

# Merge covariates with group-time ATTs
gt_with_covars <- gt_df %>%
  left_join(
    state_covars %>% select(cohort, poverty_rate, urbanization, pct_black),
    by = c("group" = "cohort")
  )

cat("Group-time ATTs with covariates: ", nrow(gt_with_covars), "\n")
cat("Missing covariates: ", sum(is.na(gt_with_covars$poverty_rate)), "\n\n")

# Remove rows with missing covariates
gt_with_covars <- gt_with_covars %>%
  filter(!is.na(poverty_rate), !is.na(pct_black))

cat("After removing missing: ", nrow(gt_with_covars), " observations\n\n")

# Fit conditional model: ATT ~ f(X)
# Model: ATT = beta0 + beta1 * poverty + beta2 * pct_black
# (urbanization has too many NAs, skip it)

cat("Fitting conditional model: ATT ~ poverty_rate + pct_black\n")

conditional_fit <- lm(att ~ poverty_rate + pct_black, data = gt_with_covars)

cat("\nConditional model coefficients:\n")
print(summary(conditional_fit)$coefficients)
cat("\n")
cat("R-squared:", round(summary(conditional_fit)$r.squared, 3), "\n\n")

# Predict for 2016-2022
# Get target covariate values for states in 2016-2022
# For early adopters, use their covariate values from 2016-2022
target_states <- state_covars %>%
  filter(cohort > 0, cohort <= 2015) %>%
  pull(state)

cat("Target states (early adopters): ", length(target_states), "\n")
cat("States:", paste(target_states, collapse = ", "), "\n\n")

# Get covariate values for these states in 2016-2022
target_covars <- data %>%
  filter(state %in% target_states, year >= 2016, year <= 2022) %>%
  group_by(year) %>%
  summarize(
    poverty_rate = mean(poverty_rate, na.rm = TRUE),
    pct_black = mean(pct_black, na.rm = TRUE),
    .groups = "drop"
  )

cat("Target covariate values (2016-2022):\n")
print(target_covars)
cat("\n")

# Predict ATTs for 2016-2022 using conditional model
preds <- predict(conditional_fit, newdata = target_covars,
                 se.fit = TRUE, interval = "confidence")

predictions_path3 <- data.frame(
  year = target_covars$year,
  poverty_rate = target_covars$poverty_rate,
  pct_black = target_covars$pct_black,
  att_pred = preds$fit[, "fit"],
  se_pred = preds$se.fit,
  ci_lower = preds$fit[, "lwr"],
  ci_upper = preds$fit[, "upr"]
)

cat("Predictions for 2016-2022:\n")
print(predictions_path3)

# Save results
saveRDS(list(
  predictions = predictions_path3,
  conditional_fit = conditional_fit,
  target_covars = target_covars,
  covariates = c("poverty_rate", "pct_black"),
  method = "Covariate integration (conditional model)"
), "application/results/path3_covariate_integration.rds")

cat("\nSaved: application/results/path3_covariate_integration.rds\n")

cat("\n=== Phase 2.4 Complete ===\n")
cat("Next: Run 06_validation.R\n")

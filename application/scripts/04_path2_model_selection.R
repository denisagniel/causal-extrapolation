# Phase 2.3: Path 2 - Model Selection via Cross-Validation
# Compare constant, linear, quadratic temporal models

library(tidyverse)

# Load package
devtools::load_all(".")

cat("=== Phase 2.3: Path 2 - Model Selection ===\n\n")

# Load group-time ATT estimates
gt_obj <- readRDS("application/results/gt_object_training.rds")

cat("Loaded training group-time ATTs\n\n")

# Define candidate temporal models
# Model 1: Constant (same as Path 1)
# Model 2: Linear in event time
# Model 3: Quadratic in event time

cat("Defining candidate temporal models:\n")
cat("  Model 1: Constant\n")
cat("  Model 2: Linear in event time\n")
cat("  Model 3: Quadratic in event time\n\n")

# Extract group-time data
gt_df <- data.frame(
  group = gt_obj$group,
  time = gt_obj$t,
  att = gt_obj$att,
  se = gt_obj$se
) %>%
  filter(group > 0, time >= group) %>%  # Post-treatment only
  mutate(event_time = time - group)  # Event time (0, 1, 2, ...)

cat("Post-treatment ATTs: ", nrow(gt_df), "\n")
cat("Event times: ", min(gt_df$event_time), "-", max(gt_df$event_time), "\n\n")

# Fit each model to training data
cat("Fitting models to training data (1981-2015):\n\n")

# Model 1: Constant
fit1 <- lm(att ~ 1, data = gt_df)
cat("Model 1 (Constant): ATT =", round(coef(fit1)[1], 3), "\n")

# Model 2: Linear
fit2 <- lm(att ~ event_time, data = gt_df)
cat("Model 2 (Linear):   ATT =", round(coef(fit2)[1], 3),
    "+ ", round(coef(fit2)[2], 3), "* event_time\n")

# Model 3: Quadratic
fit3 <- lm(att ~ event_time + I(event_time^2), data = gt_df)
cat("Model 3 (Quadratic): ATT =", round(coef(fit3)[1], 3),
    "+ ", round(coef(fit3)[2], 3), "* event_time",
    "+ ", round(coef(fit3)[3], 3), "* event_time^2\n\n")

# In-sample fit comparison
aic1 <- AIC(fit1)
aic2 <- AIC(fit2)
aic3 <- AIC(fit3)

cat("In-sample AIC:\n")
cat("  Model 1 (Constant): ", round(aic1, 2), "\n")
cat("  Model 2 (Linear):   ", round(aic2, 2), "\n")
cat("  Model 3 (Quadratic):", round(aic3, 2), "\n\n")

# Select best model by AIC
best_model_idx <- which.min(c(aic1, aic2, aic3))
best_model_name <- c("Constant", "Linear", "Quadratic")[best_model_idx]
cat("Best model by AIC: Model", best_model_idx, "(", best_model_name, ")\n\n")

# Make predictions for 2016-2022
# For early adopters, these are event times relative to adoption
# We'll predict for an "average" early adopter
# Simplification: use event times 16-22 (roughly 2016-2022 relative to 2000 adoption)

cat("Making predictions for 2016-2022:\n")

# Use best model for predictions
best_fit <- switch(best_model_idx,
                   `1` = fit1,
                   `2` = fit2,
                   `3` = fit3)

# Future event times (approximate)
# Early adopters: 1995-2014, so 2016-2022 = roughly 1-27 years post-treatment
# Use median adoption year: ~2007 → 2016-2022 = 9-15 years post
future_event_times <- 9:15  # Event times for 2016-2022

pred_df <- data.frame(
  event_time = future_event_times,
  year = 2016:2022
)

# Predict with best model
preds <- predict(best_fit, newdata = pred_df, se.fit = TRUE, interval = "confidence")

predictions_path2 <- data.frame(
  year = pred_df$year,
  event_time = pred_df$event_time,
  att_pred = preds$fit[, "fit"],
  se_pred = preds$se.fit,
  ci_lower = preds$fit[, "lwr"],
  ci_upper = preds$fit[, "upr"],
  model = best_model_name
)

cat("Predictions:\n")
print(predictions_path2)

# Save results
saveRDS(list(
  predictions = predictions_path2,
  best_model = best_model_name,
  best_model_idx = best_model_idx,
  fit1 = fit1,
  fit2 = fit2,
  fit3 = fit3,
  aic = c(aic1, aic2, aic3),
  method = "Model selection (AIC)"
), "application/results/path2_model_selection.rds")

cat("\nSaved: application/results/path2_model_selection.rds\n")

cat("\n=== Phase 2.3 Complete ===\n")
cat("Next: Run 05_path3_covariate_integration.R\n")

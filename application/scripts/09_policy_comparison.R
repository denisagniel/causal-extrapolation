# Policy Comparison: Which policies predict well?
# Tests all 7 policies with Path 1 (constant model)

library(tidyverse)
library(did)

cat("=== Quick Policy Comparison ===\n\n")

# Load data
data <- readRDS("application/results/analysis_data.rds")

# Define policies to test
policies <- c("syg", "ubc", "ma20", "cc_pc", "cc_si", "cap", "vm")
policy_names <- c(
  "syg" = "Stand Your Ground",
  "ubc" = "Universal Background Checks",
  "ma20" = "Minimum Age 20",
  "cc_pc" = "Concealed Carry (Permit)",
  "cc_si" = "Concealed Carry (Shall-Issue)",
  "cap" = "Child Access Prevention",
  "vm" = "Violent Misdemeanor"
)

# Function to analyze one policy
analyze_policy <- function(policy_var, data, verbose = TRUE) {
  if (verbose) cat("Analyzing", policy_names[policy_var], "...\n")

  # Identify treatment cohorts
  cohorts <- data %>%
    filter(!!sym(policy_var) == 1) %>%
    group_by(state) %>%
    summarize(cohort_year = min(year), .groups = "drop")

  # Check if we have enough adopters
  n_adopters <- nrow(cohorts)
  n_early <- if (n_adopters > 0) sum(cohorts$cohort_year <= 2015) else 0

  if (verbose) {
    cat("  Adopters:", n_adopters, "(", n_early, "by 2015)\n")
  }

  if (n_early < 3) {
    if (verbose) cat("  SKIP: Too few early adopters (<3)\n\n")
    return(NULL)
  }

  # Create treatment data
  data_policy <- data %>%
    left_join(cohorts, by = "state") %>%
    mutate(
      cohort = coalesce(cohort_year, 0),
      treated = (cohort > 0)
    ) %>%
    select(-cohort_year)

  # Training data
  training <- data_policy %>%
    filter(year <= 2015) %>%
    mutate(
      G = cohort,
      T = year,
      Y = deaths_per_100k,
      id = as.numeric(factor(state))
    )

  # Skip if no variation
  if (length(unique(training$G[training$G > 0])) < 2) {
    if (verbose) cat("  SKIP: Insufficient cohort variation\n\n")
    return(NULL)
  }

  # Estimate group-time ATTs (training period)
  tryCatch({
    gt_obj <- att_gt(
      yname = "Y",
      gname = "G",
      idname = "id",
      tname = "T",
      data = training,
      control_group = "nevertreated",
      anticipation = 0,
      bstrap = TRUE,
      cband = FALSE,  # Skip for speed
      biters = 500,   # Reduce for speed
      clustervars = "id",
      est_method = "dr",
      print_details = FALSE
    )

    # Extract post-treatment ATTs
    gt_df <- data.frame(
      group = gt_obj$group,
      time = gt_obj$t,
      att = gt_obj$att,
      se = gt_obj$se
    ) %>%
      filter(group > 0, time >= group)

    # Path 1: Constant prediction
    mean_att <- mean(gt_df$att, na.rm = TRUE)
    se_att <- sd(gt_df$att, na.rm = TRUE) / sqrt(nrow(gt_df))

    # Estimate on full data for validation
    full_data <- data_policy %>%
      mutate(
        G = cohort,
        T = year,
        Y = deaths_per_100k,
        id = as.numeric(factor(state))
      )

    gt_obj_full <- att_gt(
      yname = "Y",
      gname = "G",
      idname = "id",
      tname = "T",
      data = full_data,
      control_group = "nevertreated",
      anticipation = 0,
      bstrap = FALSE,  # Skip bootstrap for speed
      est_method = "dr",
      print_details = FALSE
    )

    # Extract realized 2016-2022 ATTs
    realized <- data.frame(
      group = gt_obj_full$group,
      year = gt_obj_full$t,
      att = gt_obj_full$att
    ) %>%
      filter(year >= 2016, year <= 2022, group > 0, group <= 2015) %>%
      group_by(year) %>%
      summarize(att_realized = mean(att, na.rm = TRUE), .groups = "drop")

    if (nrow(realized) == 0) {
      if (verbose) cat("  SKIP: No realized ATTs for validation\n\n")
      return(NULL)
    }

    # Compute validation metrics
    pred <- rep(mean_att, nrow(realized))
    mspe <- mean((pred - realized$att_realized)^2, na.rm = TRUE)
    mae <- mean(abs(pred - realized$att_realized), na.rm = TRUE)

    # Coverage
    ci_lower <- mean_att - 1.96 * se_att
    ci_upper <- mean_att + 1.96 * se_att
    coverage <- mean(realized$att_realized >= ci_lower &
                     realized$att_realized <= ci_upper, na.rm = TRUE)

    if (verbose) {
      cat("  Prediction:", round(mean_att, 3),
          "| Realized mean:", round(mean(realized$att_realized), 3),
          "| MSPE:", round(mspe, 3), "\n\n")
    }

    return(list(
      policy = policy_var,
      n_adopters = n_adopters,
      n_early = n_early,
      prediction = mean_att,
      se = se_att,
      realized_mean = mean(realized$att_realized, na.rm = TRUE),
      realized_sd = sd(realized$att_realized, na.rm = TRUE),
      mspe = mspe,
      mae = mae,
      coverage = coverage,
      n_realized = nrow(realized)
    ))

  }, error = function(e) {
    if (verbose) cat("  ERROR:", e$message, "\n\n")
    return(NULL)
  })
}

# Run comparison for all policies
cat("Testing all policies...\n\n")

results_list <- lapply(policies, function(p) {
  analyze_policy(p, data, verbose = TRUE)
})

# Remove NULLs
results_list <- results_list[!sapply(results_list, is.null)]

if (length(results_list) == 0) {
  cat("ERROR: No policies could be analyzed\n")
  quit(status = 1)
}

# Combine into data frame
results_df <- bind_rows(results_list) %>%
  mutate(
    policy_name = policy_names[policy],
    prediction_error = abs(prediction - realized_mean),
    bias = prediction - realized_mean,
    rmse = sqrt(mspe)
  ) %>%
  arrange(mspe)

# Print summary table
cat("\n=== Policy Comparison Results ===\n\n")
cat("Ranked by MSPE (lower is better):\n\n")

print(results_df %>%
  select(policy_name, n_early, prediction, realized_mean, mspe, mae, coverage) %>%
  mutate(across(where(is.numeric) & !n_early, ~round(.x, 3))))

# Save results
saveRDS(results_df, "application/results/policy_comparison.rds")
write_csv(results_df, "application/results/policy_comparison.csv")

cat("\nSaved: application/results/policy_comparison.{rds,csv}\n")

# Identify best and worst
best <- results_df %>% slice_min(mspe, n = 1)
worst <- results_df %>% slice_max(mspe, n = 1)

cat("\n=== Key Findings ===\n\n")
cat("BEST predictor:", best$policy_name, "\n")
cat("  - Prediction:", round(best$prediction, 3), "vs Realized:", round(best$realized_mean, 3), "\n")
cat("  - MSPE:", round(best$mspe, 3), "| Coverage:", round(best$coverage * 100, 0), "%\n\n")

cat("WORST predictor:", worst$policy_name, "\n")
cat("  - Prediction:", round(worst$prediction, 3), "vs Realized:", round(worst$realized_mean, 3), "\n")
cat("  - MSPE:", round(worst$mspe, 3), "| Coverage:", round(worst$coverage * 100, 0), "%\n\n")

# Compare to SYG
syg_result <- results_df %>% filter(policy == "syg")
if (nrow(syg_result) > 0) {
  syg_rank <- which(results_df$policy == "syg")
  cat("SYG ranking:", syg_rank, "out of", nrow(results_df), "policies\n")

  if (syg_rank == 1) {
    cat("  → SYG is the BEST predictor (no need to change)\n")
  } else if (syg_rank == nrow(results_df)) {
    cat("  → SYG is the WORST predictor (consider replacing)\n")
  } else {
    cat("  → SYG is mid-range (representative example)\n")
  }
}

cat("\n=== Comparison Complete ===\n")

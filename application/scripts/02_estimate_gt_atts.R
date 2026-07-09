# Phase 2.1: First-Stage Estimation
# Estimate group-time ATTs using the did package, then convert to the package's
# gt_object (carrying efficient influence functions) for downstream EIF propagation.

library(tidyverse)
library(did)   # Callaway & Sant'Anna
library(fs)

# Load the extrapolateATT package (provides as_gt_object()).
devtools::load_all(".")

# Reproducibility: single seed at top (bstrap = FALSE below, but seed guards any RNG).
set.seed(20260709)

dir_create("application/results")

# Load analysis-ready data
data <- readr::read_rds("application/results/analysis_data.rds")

message("=== Phase 2.1: First-Stage Estimation ===\n")

# ---------------------------------------------------------------------------
# Helper: estimate group-time ATTs with did::att_gt() and convert to gt_object.
# bstrap = FALSE gives analytic inference; did returns the influence-function
# matrix (inffunc) either way, and as_gt_object() extracts it into gt_object$phi.
# ---------------------------------------------------------------------------
estimate_gt <- function(df) {
  did_data <- df %>%
    mutate(
      G = cohort,                        # did: 0 for never-treated
      T = year,
      Y = deaths_per_100k,
      id = as.numeric(factor(state))     # numeric unit id (aligns inffunc rows)
    ) %>%
    select(id, G, T, Y, state)

  att <- att_gt(
    yname = "Y",
    gname = "G",
    idname = "id",
    tname = "T",
    data = did_data,
    control_group = "nevertreated",
    anticipation = 0,
    bstrap = FALSE,                      # analytic SE; inffunc returned for EIF extraction
    est_method = "dr"                    # doubly-robust
    # No clustervars: we extract the influence function and compute variance ourselves
    # (clustered SEs in did require the bootstrap, which we do not use here).
  )

  # Convert to gt_object: extracts group-time ATTs AND the EIF list (phi).
  as_gt_object(att, extract_eif = TRUE)
}

# --- Training period: 1981-2015 -------------------------------------------
training_data <- data %>% filter(year <= 2015)
message("Training data: ", nrow(training_data), " observations, ",
        length(unique(training_data$state)), " states, ",
        min(training_data$year), " - ", max(training_data$year))

message("Estimating group-time ATTs (training period)...")
gt_obj_training <- estimate_gt(training_data)

if (!isTRUE(gt_obj_training$meta$eif_available)) {
  stop("Training gt_object has no EIFs; downstream EIF-based inference would be invalid.")
}

message("  Cohorts: ", paste(gt_obj_training$groups[gt_obj_training$groups > 0], collapse = ", "))
message("  Group-time cells: ", nrow(gt_obj_training$data), " | EIF vectors: ",
        length(gt_obj_training$phi), " | n = ", gt_obj_training$n, "\n")

readr::write_rds(gt_obj_training, "application/results/gt_object_training.rds")
message("Saved: application/results/gt_object_training.rds\n")

# --- Full period: 1981-2022 (for realized-ATT validation targets) ----------
message("Estimating group-time ATTs (full period)...")
gt_obj_full <- estimate_gt(data)
readr::write_rds(gt_obj_full, "application/results/gt_object_full.rds")
message("Saved: application/results/gt_object_full.rds\n")

# Realized ATTs for 2016-2022 (early adopters), the validation targets.
realized_atts <- gt_obj_full$data %>%
  filter(t >= 2016, t <= 2022, g > 0, g <= 2015) %>%
  transmute(group = g, year = t, att = tau_hat,
            se = if ("se" %in% names(.)) se else NA_real_)

message("Realized ATTs (2016-2022) for early adopters: ", nrow(realized_atts), " rows")
readr::write_rds(realized_atts, "application/results/realized_atts_2016_2022.rds")
message("Saved: application/results/realized_atts_2016_2022.rds")

message("\n=== Phase 2.1 Complete ===")
message("Next: Run 03_path1_homogeneity.R")

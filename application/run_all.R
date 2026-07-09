# Master script: run the full application pipeline from the repository root.
#   Rscript application/run_all.R

scripts <- c(
  "application/scripts/01_data_prep.R",
  "application/scripts/02_estimate_gt_atts.R",
  "application/scripts/03_path1_homogeneity.R",
  "application/scripts/04_path2_model_selection.R",
  "application/scripts/05_path3_covariate_integration.R",
  "application/scripts/06_validation.R",
  "application/scripts/07_generate_tables.R",
  "application/scripts/08_create_validation_plot.R"
)

for (s in scripts) {
  cat("\n==================================================\n")
  cat("RUN:", s, "\n")
  cat("==================================================\n")
  source(s, echo = FALSE)
}

cat("\nAll steps complete. Outputs in application/results/, application/figures/,",
    "and inst/paper/sim_tables/.\n")

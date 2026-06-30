# Phase 2.6: Generate LaTeX Tables for Paper
# Following pattern from sims/scripts/write_paper_tables.R

library(tidyverse)

cat("=== Phase 2.6: Generate LaTeX Tables ===\n\n")

# Helper functions (matching simulation pattern)
f <- function(x, d = 3) format(round(x, d), nsmall = d)
pct <- function(x, d = 1) format(round(100 * x, d), nsmall = d)

# Load validation results
val_summary <- readRDS("application/results/validation_summary.rds")
val_full <- readRDS("application/results/validation_full.rds")

cat("Loaded validation results\n\n")

# ============================================================================
# Table 9.1: Validation Summary (Main Results)
# ============================================================================

cat("Generating Table 9.1: Validation summary...\n")

table9_1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Prediction accuracy: Stand-your-ground laws 2016--2022}",
  "\\label{tab:app_validation}",
  "\\begin{tabular}{lp{5cm}ccc}",
  "\\toprule",
  "Method & Description & MSPE & MAE & Coverage (\\%) \\\\",
  "\\midrule"
)

# Add rows for each method
for (i in 1:nrow(val_summary)) {
  row_text <- paste0(
    "Path ", i, " & ",
    val_summary$method[i], " & ",
    f(val_summary$mspe[i], 2), " & ",
    f(val_summary$mae[i], 2), " & ",
    pct(val_summary$coverage_95[i], 0), " \\\\"
  )
  table9_1 <- c(table9_1, row_text)
}

table9_1 <- c(
  table9_1,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{\\textwidth}",
  "\\vspace{0.1in}",
  "\\footnotesize",
  "\\textit{Notes:} Validation metrics comparing predictions from three extrapolation approaches",
  "against realized ATTs for 2016--2022. MSPE = mean squared prediction error;",
  "MAE = mean absolute error; Coverage = proportion of realized values within 95\\% confidence intervals.",
  "Training period: 1981--2015. Outcome: firearm homicide deaths per 100,000 population.",
  "Path 1 assumes constant effects; Path 2 selects best temporal model by AIC;",
  "Path 3 conditions on poverty rate and racial composition.",
  "\\end{minipage}",
  "\\end{table}"
)

# Write table
writeLines(table9_1, "inst/paper/sim_tables/section9_validation.tex")
cat("Saved: inst/paper/sim_tables/section9_validation.tex\n\n")

# ============================================================================
# Table 9.2: Year-by-Year Predictions and Realized Values
# ============================================================================

cat("Generating Table 9.2: Year-by-year comparison...\n")

table9_2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Predictions versus realized ATTs by year (2016--2022)}",
  "\\label{tab:app_yearly}",
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  "Year & Realized & Path 1 & Path 2 & Path 3 & Best Match \\\\",
  "\\midrule"
)

# Add rows for each year
for (i in 1:nrow(val_full)) {
  # Find best match (smallest absolute error)
  errors <- c(
    abs(val_full$path1[i] - val_full$realized[i]),
    abs(val_full$path2[i] - val_full$realized[i]),
    abs(val_full$path3[i] - val_full$realized[i])
  )
  best_idx <- which.min(errors)
  best_label <- c("Path 1", "Path 2", "Path 3")[best_idx]

  row_text <- paste0(
    val_full$year[i], " & ",
    f(val_full$realized[i], 2), " & ",
    f(val_full$path1[i], 2), " & ",
    f(val_full$path2[i], 2), " & ",
    f(val_full$path3[i], 2), " & ",
    best_label, " \\\\"
  )
  table9_2 <- c(table9_2, row_text)
}

# Add mean row
table9_2 <- c(
  table9_2,
  "\\midrule",
  paste0(
    "Mean & ",
    f(mean(val_full$realized), 2), " & ",
    f(mean(val_full$path1), 2), " & ",
    f(mean(val_full$path2), 2), " & ",
    f(mean(val_full$path3), 2), " & ",
    "-- \\\\"
  )
)

table9_2 <- c(
  table9_2,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{\\textwidth}",
  "\\vspace{0.1in}",
  "\\footnotesize",
  "\\textit{Notes:} Year-by-year comparison of predicted and realized ATTs.",
  "``Best Match'' indicates which path had smallest absolute error for that year.",
  "All values in units of deaths per 100,000 population.",
  "\\end{minipage}",
  "\\end{table}"
)

# Write table
writeLines(table9_2, "inst/paper/sim_tables/section9_yearly.tex")
cat("Saved: inst/paper/sim_tables/section9_yearly.tex\n\n")

# ============================================================================
# Optional: Summary statistics table
# ============================================================================

cat("Generating Table 9.3: Data summary...\n")

# Load data
data <- readRDS("application/results/analysis_data.rds")
syg_cohorts <- read_csv("application/results/syg_cohorts.csv", show_col_types = FALSE)

# Summary stats
training <- data %>% filter(year <= 2015)
validation <- data %>% filter(year >= 2016)

table9_3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Data summary: Stand-your-ground laws and firearm homicide}",
  "\\label{tab:app_data}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Training (1981--2015) & Validation (2016--2022) \\\\",
  "\\midrule",
  paste0("States & ", length(unique(training$state)), " & ", length(unique(validation$state)), " \\\\"),
  paste0("Years & ", max(training$year) - min(training$year) + 1, " & ",
         max(validation$year) - min(validation$year) + 1, " \\\\"),
  paste0("Observations & ", nrow(training), " & ", nrow(validation), " \\\\"),
  "\\midrule",
  paste0("Treated states & ", nrow(syg_cohorts), " & -- \\\\"),
  paste0("Never-treated states & ", sum(data$cohort == 0 & data$year == 2015), " & -- \\\\"),
  "\\midrule",
  paste0("Mean deaths/100k & ", f(mean(training$deaths_per_100k), 2), " & ",
         f(mean(validation$deaths_per_100k), 2), " \\\\"),
  paste0("SD deaths/100k & ", f(sd(training$deaths_per_100k), 2), " & ",
         f(sd(validation$deaths_per_100k), 2), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{\\textwidth}",
  "\\vspace{0.1in}",
  "\\footnotesize",
  "\\textit{Notes:} Summary of state-level panel data on firearm homicide.",
  "Training period used to estimate group-time ATTs and fit temporal models;",
  "validation period used to assess prediction accuracy.",
  "\\end{minipage}",
  "\\end{table}"
)

# Write table
writeLines(table9_3, "inst/paper/sim_tables/section9_data.tex")
cat("Saved: inst/paper/sim_tables/section9_data.tex\n\n")

cat("=== Phase 2.6 Complete ===\n")
cat("All tables generated in inst/paper/sim_tables/\n")
cat("Next: Create validation plot and paper section\n")

# Phase 2.6: Generate LaTeX Tables for Paper (Paths 1 & 2)
# Path 3 is deferred pending the DiD transport influence function; its row is marked
# "pending" rather than populated with a superseded (ecological-regression) number.

library(tidyverse)
library(fs)

cat("=== Phase 2.6: Generate LaTeX Tables ===\n\n")

dir_create("inst/paper/sim_tables")

f <- function(x, d = 2) format(round(x, d), nsmall = d)
pct <- function(x, d = 0) format(round(100 * x, d), nsmall = d)

val_summary <- readRDS("application/results/validation_summary.rds")
val_full <- readRDS("application/results/validation_full.rds")

# ---------------------------------------------------------------------------
# Table 9.1: Validation summary (main results) — Paths 1 & 2 + Path 3 pending row.
# ---------------------------------------------------------------------------
cat("Generating Table 9.1: Validation summary...\n")

table9_1 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Prediction accuracy: stand-your-ground laws, 2016--2022}",
  "\\label{tab:app_validation}",
  "\\begin{tabular}{lp{5.5cm}ccc}",
  "\\toprule",
  "Method & Description & MSPE & MAE & Coverage (\\%) \\\\",
  "\\midrule"
)
for (i in seq_len(nrow(val_summary))) {
  table9_1 <- c(table9_1, paste0(
    val_summary$path[i], " & ", val_summary$method[i], " & ",
    f(val_summary$mspe[i]), " & ", f(val_summary$mae[i]), " & ",
    pct(val_summary$coverage_95[i]), " \\\\"
  ))
}
table9_1 <- c(table9_1,
  "Path 3 & Direct CATE + covariate transport (DiD design; pending) & -- & -- & -- \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{\\textwidth}",
  "\\vspace{0.1in}\\footnotesize",
  "\\textit{Notes:} Predictions from the extrapolation paths compared against realized",
  "group-time ATTs for 2016--2022 (firearm homicide deaths per 100{,}000). Training period:",
  "1981--2015. Standard errors and intervals are propagated through efficient influence",
  "functions (package \\texttt{extrapolateATT}). Path 1 assumes constant post-treatment",
  "effects; Path 2 selects a temporal model by time-series cross-validation. Path 3",
  "(covariate transport under a difference-in-differences design) is pending the",
  "corresponding transport influence function.",
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(table9_1, "inst/paper/sim_tables/section9_validation.tex")
cat("Saved: inst/paper/sim_tables/section9_validation.tex\n\n")

# ---------------------------------------------------------------------------
# Table 9.2: Year-by-year predictions vs realized.
# ---------------------------------------------------------------------------
cat("Generating Table 9.2: Year-by-year comparison...\n")

table9_2 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Predictions versus realized ATTs by year (2016--2022)}",
  "\\label{tab:app_yearly}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Year & Realized & Path 1 & Path 2 & Closer path \\\\",
  "\\midrule"
)
for (i in seq_len(nrow(val_full))) {
  e1 <- abs(val_full$path1[i] - val_full$realized[i])
  e2 <- abs(val_full$path2[i] - val_full$realized[i])
  closer <- if (e2 <= e1) "Path 2" else "Path 1"
  table9_2 <- c(table9_2, paste0(
    val_full$year[i], " & ", f(val_full$realized[i]), " & ",
    f(val_full$path1[i]), " & ", f(val_full$path2[i]), " & ", closer, " \\\\"
  ))
}
table9_2 <- c(table9_2,
  "\\midrule",
  paste0("Mean & ", f(mean(val_full$realized)), " & ",
         f(mean(val_full$path1)), " & ", f(mean(val_full$path2)), " & -- \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{\\textwidth}",
  "\\vspace{0.1in}\\footnotesize",
  "\\textit{Notes:} Year-by-year predicted versus realized ATTs (deaths per 100{,}000).",
  "``Closer path'' indicates the smaller absolute error that year.",
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(table9_2, "inst/paper/sim_tables/section9_yearly.tex")
cat("Saved: inst/paper/sim_tables/section9_yearly.tex\n\n")

# ---------------------------------------------------------------------------
# Table 9.3: Data summary.
# ---------------------------------------------------------------------------
cat("Generating Table 9.3: Data summary...\n")
data <- readRDS("application/results/analysis_data.rds")
syg_cohorts <- read_csv("application/results/syg_cohorts.csv", show_col_types = FALSE)
training <- data %>% filter(year <= 2015)
validation <- data %>% filter(year >= 2016)

table9_3 <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Data summary: stand-your-ground laws and firearm homicide}",
  "\\label{tab:app_data}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  " & Training (1981--2015) & Validation (2016--2022) \\\\",
  "\\midrule",
  paste0("States & ", length(unique(training$state)), " & ",
         length(unique(validation$state)), " \\\\"),
  paste0("Years & ", max(training$year) - min(training$year) + 1, " & ",
         max(validation$year) - min(validation$year) + 1, " \\\\"),
  paste0("Observations & ", nrow(training), " & ", nrow(validation), " \\\\"),
  "\\midrule",
  paste0("Treated states & ", nrow(syg_cohorts), " & -- \\\\"),
  paste0("Never-treated states & ",
         sum(data$cohort == 0 & data$year == 2015), " & -- \\\\"),
  "\\midrule",
  paste0("Mean deaths/100k & ", f(mean(training$deaths_per_100k)), " & ",
         f(mean(validation$deaths_per_100k)), " \\\\"),
  paste0("SD deaths/100k & ", f(sd(training$deaths_per_100k)), " & ",
         f(sd(validation$deaths_per_100k)), " \\\\"),
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{minipage}{\\textwidth}",
  "\\vspace{0.1in}\\footnotesize",
  "\\textit{Notes:} State-level panel on firearm homicide. Training used to estimate",
  "group-time ATTs and select temporal models; validation used to assess accuracy.",
  "\\end{minipage}",
  "\\end{table}"
)
writeLines(table9_3, "inst/paper/sim_tables/section9_data.tex")
cat("Saved: inst/paper/sim_tables/section9_data.tex\n\n")

cat("=== Phase 2.6 Complete ===\n")

# Generate LaTeX tables for Section 8 stress tests
#
# Reads Section 8 simulation results and creates LaTeX tables
# following the format of existing simulation tables

library(dplyr)

# Output directory
out_dir <- "latex/Estimating_policy_effects_in_the_presence_of_heterogeneity/sim_tables"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# ============================================================================
# Section 8.1: Non-Smooth Dynamics
# ============================================================================

message("Generating Section 8.1 table (non-smooth dynamics)...")

results_8_1 <- readRDS("sims/results/section8_1_nonsmooth.rds")

# Extract results
true_fatt <- results_8_1$true_fatt
linear <- results_8_1$linear_model
quadratic <- results_8_1$quadratic_model
spline <- results_8_1$spline_model

# Build LaTeX table using sprintf
tex_8_1 <- sprintf(
  "\\begin{table}[htbp]
\\centering
\\caption{Path~2 under non-smooth dynamics: piecewise linear DGP with break at \\(k=3\\).
All smooth parametric models fail to capture the sharp break, resulting in systematic bias
and coverage collapse.}
\\label{tab:section8_1}
\\begin{tabular}{lcccc}
\\toprule
Model & True FATT & Bias & RMSE & 95\\%% coverage \\\\
\\midrule
Linear &
%s
 &
%s
 &
%s
 &
%s
\\%% \\\\
Quadratic &
%s
 &
%s
 &
%s
 &
%s
\\%% \\\\
Spline (knot at \\(t=4\\)) &
%s
 &
%s
 &
%s
 &
%s
\\%% \\\\
\\bottomrule
\\end{tabular}
\\end{table}
",
  format(true_fatt, digits=3, nsmall=3),
  format(linear$bias, digits=3, nsmall=3),
  format(linear$rmse, digits=3, nsmall=3),
  format(linear$coverage * 100, digits=3, nsmall=1),
  format(true_fatt, digits=3, nsmall=3),
  format(quadratic$bias, digits=3, nsmall=3),
  format(quadratic$rmse, digits=3, nsmall=3),
  format(quadratic$coverage * 100, digits=3, nsmall=1),
  format(true_fatt, digits=3, nsmall=3),
  format(spline$bias, digits=3, nsmall=3),
  format(spline$rmse, digits=3, nsmall=3),
  format(spline$coverage * 100, digits=3, nsmall=1)
)

writeLines(tex_8_1, file.path(out_dir, "section8_1.tex"))
message("  Saved: ", file.path(out_dir, "section8_1.tex"))

# ============================================================================
# Section 8.3: Small-Sample Extrapolation
# ============================================================================

message("\nGenerating Section 8.3 tables (small-sample extrapolation)...")

results_8_3 <- readRDS("sims/results/section8_3_smallsample.rds")

# Extract p values
p_vals <- results_8_3$p_grid

# Build data frame for Path 1
path1_df <- purrr::map_dfr(p_vals, function(p) {
  res <- results_8_3$results_by_p[[paste0("p_", p)]]
  tibble(
    p = p,
    true_fatt = res$true_fatt,
    bias = res$path1$bias,
    rmse = res$path1$rmse,
    coverage = res$path1$coverage
  )
})

# Build data frame for Path 2
path2_df <- purrr::map_dfr(p_vals, function(p) {
  res <- results_8_3$results_by_p[[paste0("p_", p)]]
  tibble(
    p = p,
    true_fatt = res$true_fatt,
    bias = res$path2$bias,
    rmse = res$path2$rmse,
    coverage = res$path2$coverage
  )
})

# Build LaTeX table for Path 1
tex_8_3a_rows <- purrr::map_chr(seq_len(nrow(path1_df)), function(i) {
  row <- path1_df[i, ]
  sprintf(
    "%d &\n%s\n &\n%s\n &\n%s\n &\n%s\n\\%% \\\\",
    row$p,
    format(row$true_fatt, digits=3, nsmall=3),
    format(row$bias, digits=3, nsmall=3),
    format(row$rmse, digits=3, nsmall=3),
    format(row$coverage * 100, digits=3, nsmall=1)
  )
})

tex_8_3a <- sprintf(
  "\\begin{table}[htbp]
\\centering
\\caption{Path~1 (constant model) under small-sample conditions.
When true effects are dynamic (linear in event time), Path~1 exhibits catastrophic failure
as \\(p\\) increases: bias grows and coverage collapses to 0\\%%.}
\\label{tab:section8_3a}
\\begin{tabular}{lcccc}
\\toprule
\\(p\\) (periods) & True FATT & Bias & RMSE & 95\\%% coverage \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\end{table}
",
  paste(tex_8_3a_rows, collapse = "\n")
)

writeLines(tex_8_3a, file.path(out_dir, "section8_3a.tex"))
message("  Saved: ", file.path(out_dir, "section8_3a.tex"))

# Build LaTeX table for Path 2
tex_8_3b_rows <- purrr::map_chr(seq_len(nrow(path2_df)), function(i) {
  row <- path2_df[i, ]
  if (is.na(row$bias)) {
    # Path 2 undefined for p < 3
    sprintf("%d & --- & --- & --- & undefined \\\\", row$p)
  } else {
    sprintf(
      "%d &\n%s\n &\n%s\n &\n%s\n &\n%s\n\\%% \\\\",
      row$p,
      format(row$true_fatt, digits=3, nsmall=3),
      format(row$bias, digits=3, nsmall=3),
      format(row$rmse, digits=3, nsmall=3),
      format(row$coverage * 100, digits=3, nsmall=1)
    )
  }
})

tex_8_3b <- sprintf(
  "\\begin{table}[htbp]
\\centering
\\caption{Path~2 (linear extrapolation) under small-sample conditions.
Model is correctly specified (linear DGP, linear fit).
Coverage improves dramatically with more periods: 69.2\\%% at \\(p=3\\) to 99.5\\%% at \\(p=10\\).
Undefined for \\(p < 3\\) (insufficient degrees of freedom).}
\\label{tab:section8_3b}
\\begin{tabular}{lcccc}
\\toprule
\\(p\\) (periods) & True FATT & Bias & RMSE & 95\\%% coverage \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\end{table}
",
  paste(tex_8_3b_rows, collapse = "\n")
)

writeLines(tex_8_3b, file.path(out_dir, "section8_3b.tex"))
message("  Saved: ", file.path(out_dir, "section8_3b.tex"))

# ============================================================================
# Combined table for Section 8.3 (both paths)
# ============================================================================

message("\nGenerating Section 8.3 combined table...")

# Build combined rows showing both paths side-by-side
combined_rows <- purrr::map_chr(seq_len(nrow(path1_df)), function(i) {
  p1 <- path1_df[i, ]
  p2 <- path2_df[i, ]

  if (is.na(p2$bias)) {
    # Path 2 undefined
    sprintf(
      "%d &\n%s\n &\n%s\n\\%% & --- & undefined \\\\",
      p1$p,
      format(p1$bias, digits=3, nsmall=3),
      format(p1$coverage * 100, digits=3, nsmall=1)
    )
  } else {
    sprintf(
      "%d &\n%s\n &\n%s\n\\%% &\n%s\n &\n%s\n\\%% \\\\",
      p1$p,
      format(p1$bias, digits=3, nsmall=3),
      format(p1$coverage * 100, digits=3, nsmall=1),
      format(p2$bias, digits=3, nsmall=3),
      format(p2$coverage * 100, digits=3, nsmall=1)
    )
  }
})

tex_8_3_combined <- sprintf(
  "\\begin{table}[htbp]
\\centering
\\caption{Small-sample extrapolation: Path~1 (constant model) vs Path~2 (linear extrapolation).
DGP is linear in event time. Path~1 fails catastrophically with dynamics (coverage \\(\\to 0\\%%\\)).
Path~2 is correctly specified and shows coverage improving with \\(p\\): 69\\%% (\\(p=3\\)) \\(\\to\\) 99.5\\%% (\\(p=10\\)).}
\\label{tab:section8_3_combined}
\\begin{tabular}{lccccc}
\\toprule
& \\multicolumn{2}{c}{Path~1 (constant)} & \\multicolumn{2}{c}{Path~2 (linear)} \\\\
\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}
\\(p\\) (periods) & Bias & Coverage & Bias & Coverage \\\\
\\midrule
%s
\\bottomrule
\\end{tabular}
\\end{table}
",
  paste(combined_rows, collapse = "\n")
)

writeLines(tex_8_3_combined, file.path(out_dir, "section8_3_combined.tex"))
message("  Saved: ", file.path(out_dir, "section8_3_combined.tex"))

# ============================================================================
# Summary
# ============================================================================

message("\n=== Section 8 LaTeX Tables Generated ===")
message("Created 4 tables:")
message("  1. section8_1.tex - Non-smooth dynamics (Path 2 failure)")
message("  2. section8_3a.tex - Small-sample Path 1 (catastrophic failure)")
message("  3. section8_3b.tex - Small-sample Path 2 (coverage vs p)")
message("  4. section8_3_combined.tex - Both paths side-by-side")
message("\nTo include in paper, add to main.tex:")
message("  \\input{sim_tables/section8_1}")
message("  \\input{sim_tables/section8_3_combined}")

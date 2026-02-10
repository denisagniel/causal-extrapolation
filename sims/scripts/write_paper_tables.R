# Write LaTeX table fragments and copy figure for the paper
# Run from project root: source("sims/scripts/write_paper_tables.R")

results_dir <- "sims/results"
latex_dir <- "latex/Estimating_policy_effects_in_the_presence_of_heterogeneity"
figures_dir <- file.path(latex_dir, "figures")
sim_tables_dir <- file.path(latex_dir, "sim_tables")

dir.create(figures_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(sim_tables_dir, showWarnings = FALSE, recursive = TRUE)

# Copy Section 1 plot
if (file.exists(file.path(results_dir, "section1_plot.png"))) {
  file.copy(
    file.path(results_dir, "section1_plot.png"),
    file.path(figures_dir, "section1_backward_vs_fatt.png"),
    overwrite = TRUE
  )
  message("Copied section1_plot.png to figures/section1_backward_vs_fatt.png")
}

f <- function(x, d = 3) format(round(x, d), nsmall = d, trim = TRUE)
pct <- function(x, d = 2) format(round(100 * x, d), nsmall = d, trim = TRUE)

# Section 2: Path 1 homogeneity vs dynamics
p2 <- readRDS(file.path(results_dir, "section2_path1_homogeneity.rds"))
A <- p2$ScenarioA
B <- p2$ScenarioB
writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Path 1: time homogeneity (Scenario A) vs dynamics (Scenario B).}",
  "\\label{tab:path1}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Scenario & True FATT & Bias & RMSE & 95\\% coverage \\\\",
  "\\midrule",
  "A (homogeneity) & ", f(A$true_fatt), " & ", f(A$bias), " & ", f(A$rmse), " & ", pct(A$coverage), "\\% \\\\",
  "B (dynamics) & ", f(B$true_fatt), " & ", f(B$bias), " & ", f(B$rmse), " & ", pct(B$coverage), "\\% \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
), file.path(sim_tables_dir, "section2.tex"))

# Section 3: Path 2 correct vs misspecified
p3 <- readRDS(file.path(results_dir, "section3_path2_spec.rds"))
c1 <- p3$correct_spec
c2 <- p3$misspec_linear_on_quad
c3 <- p3$quadratic_fit_on_quad
writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Path 2: correct specification (linear DGP, linear fit), misspecified (quadratic DGP, linear fit), and quadratic fit (quadratic DGP, quadratic fit).}",
  "\\label{tab:path2}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  "Specification & True FATT & Bias & RMSE & 95\\% coverage \\\\",
  "\\midrule",
  "Correct (linear fit) & ", f(c1$true_fatt), " & ", f(c1$bias), " & ", f(c1$rmse), " & ", pct(c1$coverage), "\\% \\\\",
  "Misspecified (linear on quad) & ", f(c2$true_fatt), " & ", f(c2$bias), " & ", f(c2$rmse), " & ", pct(c2$coverage), "\\% \\\\",
  "Quadratic fit on quad & ", f(c3$true_fatt), " & ", f(c3$bias), " & ", f(c3$rmse), " & ", pct(c3$coverage), "\\% \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
), file.path(sim_tables_dir, "section3.tex"))

# Section 4: EIF variance and coverage
p4 <- readRDS(file.path(results_dir, "section4_eif_coverage.rds"))
writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{EIF-based variance and Wald coverage (Path 2, correct specification).}",
  "\\label{tab:eif}",
  "\\begin{tabular}{lc}",
  "\\toprule",
  "Metric & Value \\\\",
  "\\midrule",
  "Variance ratio (est./emp.) & ", f(p4$variance_ratio, 2), " \\\\",
  "95\\% coverage & ", pct(p4$coverage_95), "\\% \\\\",
  "90\\% coverage & ", pct(p4$coverage_90), "\\% \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
), file.path(sim_tables_dir, "section4.tex"))

# Section 5: Path 1 vs Path 2
p5 <- readRDS(file.path(results_dir, "section5_path1_vs_path2.rds"))
P1 <- p5$Path1
P2 <- p5$Path2
writeLines(c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Path 1 vs Path 2 on the same DGP with mild dynamics (target: true FATT).}",
  "\\label{tab:path1vs2}",
  "\\begin{tabular}{lccc}",
  "\\toprule",
  "Estimator & Bias & RMSE & 95\\% coverage \\\\",
  "\\midrule",
  "Path 1 & ", f(P1$bias), " & ", f(P1$rmse), " & ", pct(P1$coverage), "\\% \\\\",
  "Path 2 & ", f(P2$bias), " & ", f(P2$rmse), " & ", pct(P2$coverage), "\\% \\\\",
  "\\bottomrule",
  "\\end{tabular}",
  "\\end{table}"
), file.path(sim_tables_dir, "section5.tex"))

message("Wrote sim_tables/section2.tex, section3.tex, section4.tex, section5.tex")

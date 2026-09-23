# Write LaTeX table fragments and copy figure for the paper
# Run from project root: source("sims/scripts/write_paper_tables.R")

results_dir <- "sims/results"
# Canonical paper location (inst/paper); the old latex/... path is legacy/untracked and the
# tracked main.tex \input's sim_tables from here, so tables must be written here.
latex_dir <- "inst/paper"
figures_dir <- file.path(latex_dir, "figures")
sim_tables_dir <- file.path(latex_dir, "sim_tables")

fs::dir_create(figures_dir)
fs::dir_create(sim_tables_dir)

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

# Section 4b: EIF variance and coverage, real did::att_gt() first stage
if (file.exists(file.path(results_dir, "section4b_real_firststage.rds"))) {
  p4b <- readRDS(file.path(results_dir, "section4b_real_firststage.rds"))
  writeLines(c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{EIF-based variance and Wald coverage, real \\texttt{did::att\\_gt()} first stage (Path 2, correct specification; ", p4b$n_valid, " replicates).}",
    "\\label{tab:eif-real}",
    "\\begin{tabular}{lc}",
    "\\toprule",
    "Metric & Value \\\\",
    "\\midrule",
    "Variance ratio (est./emp.) & ", f(p4b$variance_ratio, 2), " \\\\",
    "95\\% coverage & ", pct(p4b$coverage_95), "\\% \\\\",
    "90\\% coverage & ", pct(p4b$coverage_90), "\\% \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{table}"
  ), file.path(sim_tables_dir, "section4b.tex"))
  message("Wrote section4b.tex")
} else {
  message("Section 4b results not found; skipping section4b.tex")
}

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

# Section 6: Role of omega_g (cohort composition weights)
if (file.exists(file.path(results_dir, "section6_omega.rds"))) {
  p6 <- readRDS(file.path(results_dir, "section6_omega.rds"))
  ec <- p6$early_correct
  ew <- p6$early_wrong
  lc <- p6$late_correct
  lw <- p6$late_wrong
  f4 <- function(x) format(round(x, 4), nsmall = 4, trim = TRUE, scientific = FALSE)
  writeLines(c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Role of cohort weights $\\omega_g$: same DGP, two compositions (early- vs late-adopter-heavy), correct vs uniform $\\omega_g$. Path 1 (constant-within-group) is biased regardless of $\\omega_g$, since the DGP has genuine event-time dynamics; Path 2 (correctly specified) is unbiased under the correct $\\omega_g$ but picks up bias from misweighting cohorts under an incorrectly assumed uniform $\\omega_g$ (", ec$n_replicates, " replicates per cell).}",
    "\\label{tab:omega}",
    "\\begin{tabular}{lc cc cc}",
    "\\toprule",
    "& & \\multicolumn{2}{c}{Path 1 bias} & \\multicolumn{2}{c}{Path 2 bias} \\\\",
    "\\cmidrule(lr){3-4} \\cmidrule(lr){5-6}",
    "Composition & True FATT & Correct $\\omega_g$ & Uniform $\\omega_g$ & Correct $\\omega_g$ & Uniform $\\omega_g$ \\\\",
    "\\midrule",
    paste0("Early-heavy ($\\omega=(.6,.3,.1)$) & ", f(ec$true_fatt), " & ", f4(ec$path1_bias), " & ", f4(ew$path1_bias), " & ", f4(ec$path2_bias), " & ", f4(ew$path2_bias), " \\\\"),
    paste0("Late-heavy ($\\omega=(.1,.3,.6)$) & ", f(lc$true_fatt), " & ", f4(lc$path1_bias), " & ", f4(lw$path1_bias), " & ", f4(lc$path2_bias), " & ", f4(lw$path2_bias), " \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{table}"
  ), file.path(sim_tables_dir, "section6.tex"))
  message("Wrote sim_tables/section6.tex")
} else {
  message("Section 6 results not found; skipping section6.tex")
}

# Section 7: Path 3 (covariate integration) under regime change
if (file.exists(file.path(results_dir, "section7_path3_covariates.rds"))) {
  p7 <- readRDS(file.path(results_dir, "section7_path3_covariates.rds"))
  p1  <- p7$Path1_TimeHomogeneity
  p2  <- p7$Path2_TemporalExtrapolation
  p3o <- p7$Path3_Oracle
  p3g <- p7$Path3_GRF
  writeLines(c(
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{Path 3 under regime change: covariate-driven effects when target distribution shifts. True FATT = ", f(p7$true_fatt), " (target $\\mu=", f(p7$mu_target), "$); backward-looking ATT = ", f(p7$true_backward_att), " (historical $\\bar{\\mu} \\approx 0$). Regime change gap = ", f(p7$regime_change_gap), ". Paths 1 and 2 fail (biased, zero coverage); Path 3 succeeds whether $\\tau(X)$ is known (oracle) or estimated (\\texttt{grf}), since $\\tau(X)$ is regime-invariant; ", p7$n_replicates, " replicates.}",
    "\\label{tab:path3}",
    "\\begin{tabular}{lcccc}",
    "\\toprule",
    "Path & True FATT & Bias & RMSE & 95\\% coverage \\\\",
    "\\midrule",
    "1: Time homogeneity & ", f(p7$true_fatt), " & ", f(p1$bias), " & ", f(p1$rmse), " & ", pct(p1$coverage), "\\% \\\\",
    "2: Temporal extrapolation & ", f(p7$true_fatt), " & ", f(p2$bias), " & ", f(p2$rmse), " & ", pct(p2$coverage), "\\% \\\\",
    "3a: Covariate integration (oracle $\\tau(X)$) & ", f(p7$true_fatt), " & ", f(p3o$bias), " & ", f(p3o$rmse), " & ", pct(p3o$coverage), "\\% \\\\",
    "3b: Covariate integration (estimated $\\widehat{\\tau}(X)$, \\texttt{grf}) & ", f(p7$true_fatt), " & ", f(p3g$bias), " & ", f(p3g$rmse), " & ", pct(p3g$coverage), "\\% \\\\",
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{table}"
  ), file.path(sim_tables_dir, "section7.tex"))
  message("Wrote section7.tex")
} else {
  message("Section 7 results not found; skipping section7.tex")
}

message("Section 7 table generation complete.")

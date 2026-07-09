# Session Log — Phase 3B: DiD transport EIF

**Date:** 2026-07-09
**Branch:** phase3b-did-transport
**Plan:** ~/.claude/plans/toasty-wondering-stardust.md

## Goal
Derive + validate the conditional DR-DiD transport influence function, un-gate
`integrate_cate(design="did")`, complete the application's Path 3 column, rewire the §8 sim
through the package, and update the lean paper §9 / Appendix E to report Path 3 honestly.

## Key insight (derived + numerically pre-verified)
Conditional parallel trends (Sant'Anna–Zhao DR-DiD, conditional form) = conditional
unconfoundedness on the outcome change ΔY. So the DR-DiD transport correction is the AIPW
correction with Y→ΔY, mu_a→m_a=E[ΔY|X,A=a], m1=m0+tau:
  score_drdid = A*(dY-m1)/e - (1-A)*(dY-m0)/(1-e),  m1=m0_dY+tau, m0=m0_dY.
No new contract fields. Collapse to AIPW-on-changes EIF verified to machine precision.

## Caveat (Plan-agent review)
DRDID cross-check: assert point estimates agree, NOT SE. Form A uses hard 1{A=1} weight;
Sant'Anna–Zhao ATT uses smooth propensity weight e/E[A] → different variance by construction.

## Decisions (user)
- Application CATE learner: parametric primary + causal-forest robustness (compare).
- Fix §8 sim fidelity gap in this task too.

## Approach
Part A (package) → B (sims) → C (application) → D (paper). Orchestrator loop; commit ≥80, PR ≥90.

## Status
- [DONE] Part A: package DiD EIF. score_drdid() = two-arm AIPW-on-changes; gate removed;
  roxygen updated; DRDID added to Suggests; DiD test suite added (collapse/misspec/DRDID
  cross-check). 635 tests pass (was ~618). Cross-check: integrate_cate ATT 1.138 vs DRDID
  1.156 (diff 0.019 < 0.05); SEs 0.025 vs 0.020 as expected (hard vs smooth weight).
- [DONE] Part B: rewired sim_section7 Path 3 arm from removed integrate_covariates() to
  unit-level integrate_cate() (Form B density-ratio transport, self-normalized weights).
  1000 reps: Path 3 bias -0.006, RMSE 0.106, cover 93% (Paths 1-2 fail 0%) — regime-change
  story holds, consistent with paper §8 hardcoded table. Also fixed stale load_all("package")
  → load_all("."). **2nd fidelity bug found+fixed:** write_paper_tables.R wrote to legacy
  untracked latex/... dir; retargeted to canonical inst/paper/. Regenerated section7.tex
  (only that table changed; section2-5 identical). NOTE section8_2_misspec.R also references
  removed integrate_covariates() but is deferred (not in run_section8 pipeline) — left as-is.
- [DONE] Part C: application Path 3. Rewrote script 05: conditional-DiD collapse (ΔY =
  post[2006-15]-pre[1981-90]; A = 23 early adopters vs 20 never-treated; dropped 7 states
  adopting 2016+ and urbanization[100% missing]). Two learners: parametric (primary) +
  causal forest (robustness). Per-year Form B density-ratio transport to early adopters'
  covariates (classification, trimmed@95, self-normalized). Scripts 06/07/08 + run_all.R
  wired for Path 3. Pipeline 01-08 runs end-to-end.
  **Honest result:** Path 3 MSPE 3.14 / MAE 1.66 / coverage 14% — worst by MSPE (predicts
  ~0/slightly-negative; observed covariate shift doesn't capture post-2015 acceleration).
  n_eff drops to 8-36 (overlap limit). Path 2 still best. Forest τ(x) nearly flat (weak
  heterogeneity at n=43) — flagged as small-n limit. All three underpredict.
- [DONE] Part D: lean paper §9 (Paths applied → all 3; Findings itemize + Path 3 MSPE 3.14
  / coverage 14%; Promise/Limits + Lesson prose updated; Appendix E pointer). Compiles clean
  (24pp, exit 0). No "deferred/pending" Path 3 language remains.

## Review pass (r-reviewer + verifier + fixes)
- **verifier:** all items PASS; fidelity confirmed (§9 numbers match across code/package/paper:
  P1 2.51, P2 1.47, P3 3.14/14%). section7.tex regenerated valid (Path 3 95% coverage).
- **r-reviewer:** 1 critical + 6 major. Fixed C1 (sim set.seed collision: gt draw used
  seed 7000L+r, Path 3 reused same → not independent; changed Path 3 to 90000L+r; Path 3 now
  bias -0.003/RMSE 0.099/cover 95%), M1 (trimming bias — CHECKED: untrimmed mean -0.45 vs
  trimmed -0.10, so trimming pulls UP toward source; underprediction is conservative not
  manufactured; disclosed in header + comment), M2 (surfaced overlap n_eff diagnostic,
  muffle only the expected misnormalization warning), M4 (dir.create → fs::dir_create in 2
  sim scripts). Deferred as batched cleanup (pre-existing across ALL application scripts,
  style not correctness): M5 saveRDS→readr::write_rds, M6 randplot theme_rand on val plot,
  m1 console cat hygiene, m8 native-pipe consistency. 635 tests pass.

## Deferred follow-ups (logged, not blocking)
- Full-paper main.tex Appendix B app:eif3 DR-DiD write-up + §12 theory-note LaTeX checklist
  (Prop 3', A1-A3, asymptotic-normality Path-3 step) — separate theory-prose task.
- sims/scripts/sim_section8_2_misspec.R also calls removed integrate_covariates() but is
  DEFERRED (not in run_section8 pipeline) — rewire when that section is revived.
- Application style batch: readr::write_rds, theme_rand, message() over cat, pipe consistency.
- §9 SYG background \citep{[CITATIONS]} placeholder (pre-existing Phase-4 remainder).

## Quality: package/theory ~93 (validated, cross-checked, tested); application ~88 (honest,
## reproducible; style-debt deferred); paper ~90 (compiles, fidelity-consistent). PR-ready.

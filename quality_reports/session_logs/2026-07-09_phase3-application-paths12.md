# Session Log — 2026-07-09: Phase 3A Application Rewrite (Paths 1–2)

## Goal
Rewire the SYG/firearm-homicide application to call the extrapolateATT package for Paths
1–2 with EIF-based inference + reproducibility (audit C3, M8). Path 3 deferred pending the
DiD transport EIF.

## Approach
Plan: `~/.claude/plans/curried-painting-quasar.md` (approved). Keep 01_data_prep + train/
validate design. Rewire 02 (as_gt_object → gt_object w/ EIFs), 03 (path1_aggregate), 04
(cv_extrapolate_ATT + extrapolate_ATT), 06/07/08 (validation/tables/plot). Banner on 05.

## Key decisions (user)
- Path 3 needs conditional DR-DiD transport EIF derived + un-gated first → DEFERRED.
- This session = Paths 1–2, then checkpoint.

## Smoke test (pre-implementation)
Confirmed on real app data: att_gt() → class MP → as_gt_object() → gt_object, 272 EIF
vectors, eif_available=TRUE, n=50. 8 cohorts (1995–2014), post-treatment cells 21↓2. C4
fix works on real data. CV horizons must respect uneven cohort history.

## Work completed
- **02** rewired: `did::att_gt(bstrap=FALSE, dr)` → `as_gt_object()` → gt_object with 272
  EIF vectors, `eif_available=TRUE`. Dropped `clustervars` (needs bootstrap; we use EIF).
- **03 Path 1** via `path1_aggregate(gt_post, omega)` + `compute_variance` on post-treatment
  cells; ω = cohort-size weights. ATT 0.064, EIF SE 0.155.
- **04 Path 2**: `cv_extrapolate_ATT` (time-series CV, event scale) → `select_best_model`
  (linear) → per-cohort-year `extrapolate_ATT` forecasts cached by k*, aggregated across
  cohorts with per-year renormalized ω, EIF propagated → `compute_variance`.
- **06** validation ω-weighted (see C2 below); **07** tables (Path 3 row = pending);
  **08** plot with EIF CI ribbons. **05** banner (deferred). README + run_all.R + seeds +
  fs::dir_create.

## Reviewer pass (r-reviewer + verifier) — 2 criticals fixed
- **C2 (real bug, material):** predictions aggregate cohorts with ω but the realized
  validation target was an *unweighted* mean → estimand mismatch. Fixed 06 to ω-weight the
  realized target. **Changed the story honestly:** realized effect grows to ~2.0–2.25 by
  2020–22 (large 2007 cohort), so BOTH paths now underpredict (Path 1 MSPE 2.51, Path 2 1.47,
  coverage 0%). The prior 57% coverage was the mismatch artifact. This is the true
  "promise and limits" result the paper wants (audit M7).
- **C1 (consistency):** set `center=FALSE` in 03/04 to match cv_extrapolate_ATT's uncentered
  mean(phi^2) convention. Numerically identical (mean(phi)=8e-17) but consistent.
- **M2:** removed dead `best`; use `select_best_model()` (public API). **M1:** added
  `stopifnot` cache-key guard.
- **Deferred polish (non-blocking):** readr::write_rds (M3), cat→message (M4), randplot
  theme (M5/M6) — style conventions, consistent with existing sims/ scripts.

## Verification
- `Rscript application/run_all.R`: exit 0, full pipeline 01→08 (05 excluded).
- No iid/predict.lm inference in 02/03/04/06 (grep clean); SEs all EIF-based.
- section9_*.tex compile standalone (exit 0). Plot PDF valid.
- Quality ~90/100 (reproducible, seeded, documented, real EIF inference, honest reporting).

## Next
Phase 3B (Path 3 after DiD transport EIF derived + un-gated), Phase 4 (paper assembly —
wire real tables into §9, replace fabricated tab:application-results + false "Path 3 best"
narrative at main-lean.tex:682-731).

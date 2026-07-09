# Session Log — 2026-07-09 Phase 3B deferred items

**Branch:** `phase3b-deferred` (off `main`)
**Plan:** `~/.claude/plans/humble-kindling-unicorn.md`

## Goal
Clear the three Phase-3B deferred items:
1. §8.2 conditional-misspecification sim — rewrite to `integrate_cate()` + wire into pipeline.
2. DR-DiD transport derivation — add to `main.tex` `app:eif3` + mirror inline in `main-lean.tex`.
3. Application style batch — `readr::write_rds`, `cat`→`message`, `theme_rand` (9 scripts).

## Key context / decisions
- `main.tex` already has Prop 3′, RC8–RC10, `app:eif3` + collapse lemma, Path-3 asymptotic
  step. Only real gap = conditional **DR-DiD** design (one-line pointer at `main.tex:829`).
  LaTeX must match `R/score_builders.R::score_drdid` (AIPW-on-ΔY, `m1=m0_dY+tau`).
- `main-lean.tex` has NO appendix (its Appendix A/B/C/E refs are pre-existing dangling debt);
  "mirror" = compact inline paragraph in Path-3 / inference prose, not a new appendix.
- §8.2 sim uses unit-level `integrate_cate` (template: `sim_section7_path3_covariates.R`
  107–135); `_v2` is a placeholder stub → delete. Reuse `true_fatt_unobserved` /
  `generate_target_covariates_unobserved` from `dgp_helpers_section8.R`.
- Fidelity bug found: `write_section8_tables.R:9` writes to legacy `latex/...` dir (same class
  as the Phase-3B `write_paper_tables.R` fix) — fix to canonical `inst/paper/sim_tables`.

## Out of scope (flagged)
- Real Appendix B/D/E in `main-lean.tex`; `\input{sim_tables/section8_2}` into paper
  (needs the appendix first); SYG background `\citep{[CITATIONS]}` TODO.

## Progress
- **Task 1 (§8.2 sim) DONE.** Rewrote `sim_section8_2_misspec.R` to unit-level
  `integrate_cate` (unconfoundedness): unobserved effect-modifier U corr with X; X-only
  (misspec) vs oracle (X,U) arms; analytic Gaussian mean-shift transport weights. Result
  (1000 reps): misspec bias 0.001/0.748/1.205 for cor∈{0,.5,.8} (matches analytic
  β_U·ρ·μ=0/.75/1.20), coverage 95%→0.7%→0%; oracle unbiased ~95% throughout. Deleted `_v2`
  stub. Wired into `run_section8.R` (§8.2 block + summary). Added `section8_2.tex` to
  `write_section8_tables.R` + fixed its legacy `latex/...` out_dir → `inst/paper/sim_tables`.
  Also fixed a **pre-existing** blocker: `sim_section8_1`/`8_3` used stale `load_all("package")`
  → root-fallback idiom (same class as the Phase-3B sim_section7 fix). Full `run_section8.R`
  runs clean end-to-end (~21s).
  - NOTE (out of scope, flagged): `\input{sim_tables/section8_2}` not added to paper — §8
    tables target the not-yet-written Appendix D (would be a dangling ref). `.tex` generated
    for code↔paper fidelity readiness.
- **Task 2 (DR-DiD derivation) DONE.** `main.tex` `app:eif3`: replaced the one-line DR-DiD
  pointer with an explicit derivation — conditional parallel trends = unconfoundedness on ΔY,
  substitution Y→ΔY, μ_a→m_a, constraint m₁=m₀+τ, transport score (∗∗) matching
  `score_drdid` verbatim; extended collapse Lemma to name the DiD case. `main-lean.tex`:
  compact inline DR-DiD score + equation in the Estimation paragraph. §12 checklist verified:
  efficiency claims already downgraded (766/809 conditional), chernozhukov (×5) + santanna
  both in .bib. Both compile clean via 3-pass xelatex: main 46pp, main-lean 24pp, 0 errors,
  0 overfull>10pt. Remaining undefined citations are PRE-EXISTING (tibshirani/chen in main;
  `[CITATIONS]` SYG TODO in lean) — not introduced here. LaTeX↔package fidelity confirmed.
- **Task 3 (style batch) DONE.** All 9 `application/scripts/*.R`: `saveRDS`/`readRDS` →
  `readr::write_rds`/`read_rds` (all load tidyverse → readr already available; used explicit
  prefix); `cat(...)` → `message(...)` with correct trailing-\n stripping + arg-space folding
  (~106 calls, 0 residual `cat(`); `08_create_validation_plot.R` `theme_minimal` → `theme_rand`
  (+ `library(randplot)`; color scales kept — semantically load-bearing black-realized line).
  Full `application/run_all.R` runs clean end-to-end (exit 0, ~7s); all `.rds` + validation
  plot (PDF+PNG, theme_rand) reproduce.
  - PRE-EXISTING (not mine, flagged): `09_policy_comparison.R` fails on `main` too
    (`object 'cap' not found` — a data-column bug in analyze_policy); not in run_all.R; my
    style edits to it are valid (parse clean). Left as-is (real data bug, out of scope).
    Also `application/run_all.R` itself still uses `cat` (master runner, outside scripts/).

## Reviews (orchestrator loop)
- **r-reviewer:** no Critical/Major; all Minor (cosmetic — redundant trailing \n in message();
  08 keeps custom Okabe-Ito palette w/ black "Realized" line, justified; verified §8.2 DGP
  math + density-ratio helper analytically). Clears 90/PR gate.
- **domain-reviewer (DR-DiD derivation):** SOUND; code↔paper fidelity EXACT (∗∗) = score_drdid.
  Flagged 2 MAJOR exposition gaps + 1 minor — ALL FIXED in main.tex:
  1. Added explicit strict-overlap condition e(X)∈(η,1−η) (new "Overlap" paragraph) — the
     binding real-data limit (n_eff collapse).
  2. Made DiD nuisance set (m_0,e,w) explicit + orthogonality holds with τ fixed as first-stage
     CATE; generalized the orthogonality paragraph to both designs.
  3. Collapse-lemma caveat: hard 1{A=1} target weight vs SZ's e/E[A] → point EIF matches but SE
     need not (consistent with phase3b memory note).
  Recompiled clean: main 47pp (was 46; +1 for additions), 0 errors, 0 overfull>10pt, no new
  undefined refs (only pre-existing tibshirani/chen citations, present on main).

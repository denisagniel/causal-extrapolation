# Session Log — 2026-07-08/09: Phase 2 Package Refactor (direct-CATE Path 3)

## Goal
Execute Phase 2 of the audit remediation: replace the wrong invert-β-from-marginals
Path 3 in the R package with direct-CATE + covariate transport, assemble the DR
transport EIF (theory note eq. 2) with a collapse-to-AIPW certificate, and fix two
adjacent bugs (C4 did-converter dispatch, Path-1 ω default).

## Approach
Plan: `~/.claude/plans/curried-painting-quasar.md` (approved). Mapping-not-estimation:
package assembles EIF from user-supplied CATE/nuisance predictions; never fits a CATE or
estimates a density ratio.

## Key decisions (this session)
- API = generic contract (named list) + thin `as_cate()` adapters (grf/DoubleML/rlearner/
  drdid) behind Suggests. (user)
- Delete old Path 3 code outright (pre-1.0, provably wrong). (user)
- Scope = package only; application rewrite deferred to Phase 3. (user)
- **C4 is a live bug, not just stale docs:** verified `did` 2.3.0 `att_gt()` returns class
  `MP` (not `AGGTEobj`); the only converter is `as_gt_object.AGGTEobj`, so
  `estimate_group_time_ATT()` dispatches to `.default` and errors on real data today.
  Fixture-only tests hid it. `inffunc` present under `bstrap=TRUE`. Fix = add
  `as_gt_object.MP`.

## Work completed
- **New `R/integrate_cate.R`:** exported `integrate_cate()` (generic CATE contract, Form A
  index / Form B weights, eq.(2) transport EIF, overlap diagnostic) + internal
  `resolve_transport_weights`, `resolve_target_index`, `new_cate_integration`,
  `print.cate_integration`.
- **New `R/score_builders.R`:** internal `score_aipw()`, `score_drdid()`.
- **New `R/as_cate.R`:** `as_cate()` generic + grf/DoubleML/rlearner/drdid/default methods,
  all behind `requireNamespace` (drdid = informative not-implemented; unstable internals).
- **Deleted** `R/integrate_covariates.R` + `test-integrate-covariates.R`; trimmed `n_cells`
  from globals.R.
- **C4 fix:** added `as_gt_object.MP` (shared worker `gt_object_from_att_gt`); kept
  `.AGGTEobj` alias; corrected stale bstrap docs; `meta$eif_available` flag; flagged
  hardcoded `idname=NULL` for Phase 3.
- **Path 1 ω:** `path1_aggregate(omega=NULL)` equal-weight default + `validate_group_weights`.
- **`validate_cate_input()`** added to validators.R (e∈(0,1), 0/1 A, length/shape checks).
- **DESCRIPTION** Suggests += grf/DoubleML/rlearner/drdid; fixed stale `latex/…` path.
  Package doc: new "Path 3 — direct CATE + transport" section.
- **Tests:** `test-integrate-cate.R` (collapse cert, Form A==B, subset equivalence, d>1,
  DiD, oracle recovery, overlap, validation, print — 34 pass, 0 warn); `test-as_cate.R`
  (grf round-trip + override, default/drdid errors); `test-from_did.R` extended (MP dispatch
  + real att_gt regression). Fixtures `make_cate_input`, `reference_aipw_eif`.

## Verification
- `devtools::document(".")`: clean NAMESPACE regen (integrate_cate, as_cate +5 methods,
  print.cate_integration, as_gt_object.MP added; old exports removed).
- `devtools::test(".")`: **FAIL 0 | PASS 618 | SKIP 5**. 43 warnings all pre-existing
  (from_didmultiplegt, NA-warning tests); new Path-3 tests 0 warnings.
- **Collapse certificate verified exactly**: max|phi − AIPW_EIF| = 0 at target=source.
- `R CMD check`: 4 warnings / notes — ALL pre-existing/out-of-scope (non-portable refs/
  filenames, LICENSE pointer, fixest::influence, non-ASCII in 3 Mar-4 files, qnorm note).
  Fixed the one em-dash I introduced in as_cate.R. My changes add no new check issues.

## Quality: ~92/100 (R rubric — edge cases, informative errors, main+edge tests, collapse anchor).

## Commit
Committed as `a46f52b` on branch `phase2-package-direct-cate` (40 files, +1581/-879).
Paper build artifacts (`inst/paper/*.aux/.bbl/.blg/.log`) and unrelated untracked files
intentionally excluded. Branch not yet merged to main.

## Verification round (3-reviewer pass) + fixes — 2026-07-09
Ran r-reviewer + domain-reviewer + verifier on the Phase 2 code before building Phase 3.
Build was clean (624 pass, collapse cert green), but two reviewers independently caught a
**real correctness bug my oracle tests were blind to**:
- **One-step estimator (critical):** `integrate_cate()` reported the plug-in `mean(w*tau)`
  but paired it with the DR transport EIF. With *estimated* nuisances `mean(w*corr) != 0`,
  so the point estimate didn't match its own IF (biased CI center). Verified empirically
  (misspecified nuisances: plug-in 1.04 vs one-step 1.31). Fixed: `psi = mean(w*tau) +
  mean(w*corr) + mean(r)`; EIF now exactly mean-zero (2.5e-16); collapse cert strengthens
  to the AIPW one-step. Added a misspecified-nuisance regression test.
- **DiD gated (honesty):** `score_drdid` is NOT the Sant'Anna–Zhao score (not mean-zero);
  the old test was tautological. `design="did"` now errors; score marked experimental.
  Proper DR-DiD transport EIF is deferred Phase-1 theory work.
- **Robustness:** finite-phi guard, zero/negative/non-integer/single-row target guards,
  grf inform-once + W.hat/Y.hat guard, DoubleML multi-treatment guard, rlearner numeric-X,
  did_extract_gt accepts MP, Form B estimated-w SE caveat, path1 via validators, named
  magic constants.

Committed `7c22a01`, merged to main (`8fc414f`). 624 tests pass.
**Lesson [LEARN]:** oracle-nuisance tests hide DR estimator/EIF mismatches — always test
with *misspecified* nuisances so mean(correction) != 0.

## Next
Phase 3 (application re-run through package — grf/unconfoundedness Path 3), Phase 4 (lean
paper assembly). DiD transport EIF (theory) is a separate deferred item.

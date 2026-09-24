# Re-Audit — Path 3 Semiparametric Estimation / EIF Rewrite

**File:** `inst/paper/main.tex` · **Date:** 2026-09-24 · **Mode:** fresh, independent, adversarial via `proof-auditor` subagent, run against the rewritten Path-3 estimation/EIF content (the fix for the two-weight bug found earlier the same day).

---

## Summary

**0 Critical, 5 Major, 13 Minor, 1 Suggestion.** The headline finding: the Critical defect from the earlier audit (single shared density-ratio weight where the true EIF needs two different weights) is genuinely fixed, and the fix is algebraically correct — independently re-derived and verified, including the exact estimator-vs-EIF consistency check (delta method applied to the displayed ratio estimators) that caught the *original* bug. That check passes cleanly this time, for both Regime (i) and Regime (iii).

What remained wrong was not the math but what the paper claimed about it and which load-bearing steps were shown vs. asserted. All 5 Major findings (M1–M5) were fixed directly in `main.tex` following this re-audit:

- **M1** — `prop:asymp`/`RC10`(iii) centering was invalid when an externally-supplied (not truly known) density ratio is treated as fixed — that's a bias, not a variance, issue. Fixed: split "known $w$" from "supplied $\widetilde w$ treated as fixed," with the latter's estimator shown to target $\theta(\widetilde w) \ne \theta_{p+1}$ in general.
- **M2** — Regime (i) for the FATT under time-invariant covariates is degenerate (coincides with the backward-looking ATT per the paper's own identification remark + the collapse lemma), and the paper never said so. Fixed: one clarifying paragraph; non-degenerate Regime-(i) use cases are the FATU/FATE.
- **M3** — The assumption linking the internally-defined target's law to the actual transport target ($F_{\bX\mid T=1}=F^{p+1}_{\bX\mid A_{ip}=1}$, i.e. $q/\rho=w$) was never stated. Fixed: added to `RC10`(i) and the main-text Regime-(i) presentation.
- **M4** — The asymptotic-normality proof's Path-3 step asserted asymptotic linearity via named mechanisms (orthogonality + rate conditions) without showing (a) that the displayed ratio estimator actually solves the score equation, or (b) the second-order remainder's exact term structure. Fixed: added both derivations explicitly (the ratio-solves-score identity, and the $\delta_a\times\delta_e$/$\delta_a\times\delta_q$ remainder expansion) — this is exactly the class of check whose absence produced the *original* bug, so closing it here was treated as the highest-priority fix.
- **M5** — "Efficient influence function" was asserted for both regimes with no tangent-space/uniqueness argument, most acutely for Regime (iii) where "$w$ known" could be mistaken for a model restriction. Fixed: two sentences per regime establishing the observed-data model is nonparametric (the target law is not part of it), hence the gradient is unique.

Also fixed opportunistically (cheap, well-specified minors): `RC9`'s redundant ratio-based moment condition replaced with the actual binding condition (bounded conditional outcome variance); `app:prop-asymp`'s variance-estimation remark's citation of `RC6` (Paths 1–2 only) supplemented for Path 3; the cross-fitting remark's sole citation of `RC7` (Paths 1–2) supplemented with `RC8` (Path 3); the Path-3 plug-in variance estimator's nuisance list added to the remark.

**Not fixed (deferred as genuinely minor, no correctness impact):** label hygiene (`eq:eif-path3-fixed` unreferenced — since fixed by removing the premature forward-reference), notation overload ($\rho$ used for four distinct objects across the paper, one being a stress-test correlation coefficient), the DiD normalization nuance re: Sant'Anna–Zhao's $\E[w_0]$ vs. $\E[D]$ normalization (paper's display is correct at the truth, which is all an EIF requires), and citing Hahn (1998) by name in the collapse lemma.

## Compile verification (post-fix)

3-pass XeLaTeX + bibtex: 0 overfull hboxes, 0 new undefined references, 58 pages (up from 52pp pre-session, 57pp before this re-audit pass). The two remaining undefined-citation warnings (`tibshiraniExactPostselectionInference2016`, `chenValidInferenceModel2021`) are pre-existing, unrelated to any of today's changes, and already flagged in `session_notes/2026-09-24.md`'s morning entry.

## Full audit transcript

See the orchestrating session's background task `bg_5573026d` for the complete re-audit report (coverage manifest, all 10 requested re-derivation checks, full finding table, LaTeX-correctness notes). This file summarizes; that transcript is the primary record.

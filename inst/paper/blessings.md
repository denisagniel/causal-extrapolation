# Blessing Registry — `What we estimate when we estimate dynamic causal effects in panel data`

**Instance path:** `inst/paper/blessings.md`
**Governed by:** `.claude/rules/paper-sequencing-gate.md` (blessing gate), `draft-paper-section` skill Step 5
**Status:** current as of 2026-09-25

> **Why this file exists.** `/draft-paper-section` writes prose and updates `notation.md` /
> `claims.md` in the same turn, but drafted prose is not thereby *approved* — only the author's
> explicit review does that. This file is the record of which manuscript regions have been
> drafted-but-not-reviewed (`unblessed`) versus explicitly approved or edited by the author
> (`blessed`). An agent never writes `blessed`; only the author's approval or the author's own
> edit does.

---

## 1. Region ledger

| Region | Drafted at (turn) | Status | Notes |
|---|---|---|---|
| `main.tex` §1 Introduction (`main.tex:47-67`; Related Work subsection, `main.tex:69+`, unchanged) | 2026-09-25 — restructuring to the promoted `outline.md` | `unblessed` | Reuses most pre-existing (previously-audited) prose verbatim; new prose: the estimand-gap paragraph, the explicit invariance-choice organizing move, and the contribution paragraph re-anchored to the new section plan (contains forward references, now all resolved — see `outline.md` §2). |
| `main.tex` §2 "The Future Effect Family and Its Identification Problem" (`main.tex:95-151`) | 2026-09-25 | `unblessed` | Merges the old Setting/context + Estimands sections into two subsections. Definitions and the Absorbing Adoption assumption verbatim; new connective prose (the "not merely unobserved but wholly unknown" strengthening, explicit forward-pointers) and removal of two dead commented-out paragraph blocks. |
| `main.tex` §3 "Effect-Level Invariance: Weakening and Strengthening Dynamics" (`main.tex:152-337`) | 2026-09-25 | `unblessed` | Reorders the weakening (within-group) and strengthening (collapse-to-ATT) subsections (weakening now first, matching S2-then-S3) and removes the stale `theta_gt=f(g,I_t;theta)` "general framework" device main.tex's own former header flagged as SEMI-DEPRECATED. All propositions/lemmas/corollaries/proofs verbatim. |
| `main.tex` §4 "A Parametric Time Path for the Group-Time Effects" (`main.tex:305-337`) | 2026-09-25 | `unblessed` | Section-header promotion only (wrapped the unchanged Path-2 subsection in a new `\section{}`); zero change to Proposition 2 or its proof. |
| `main.tex` §5 "Covariate Transport: A Lucas-Critique Route" (`main.tex:338-424`) | 2026-09-25 | `unblessed` | Section-header promotion for the identification content (Proposition 3 verbatim). The two-regime EIF subsection has been **relocated to §6** (see that row); §5 now closes with a merged "When to use Path~3" paragraph pointing forward to §6 for estimation/inference. |
| `main.tex` §6 "Inference: Propagated, Not Re-Derived" (`main.tex:424-586`) | 2026-09-25 | `unblessed` | Retitled/re-labeled (`\label{sec:eif}\label{sec:inference}`, both kept) and its intro paragraph rewritten to state the propagate-vs-not-propagate asymmetry as the section's organizing point. **Now also contains Path 3's two-regime EIF material** (`main.tex:444-564`), relocated verbatim from §5 as a third `\paragraph` alongside Path 1's and Path 2's. One internal appendix cross-reference updated to follow the move (`\ref{sec:path3}`→`\ref{sec:eif-derivation}` at the point where the appendix says "as displayed in Section~..."). |
| `main.tex` §7 "Selecting a Temporal Model by Extrapolation, Not Fit" (`main.tex:590-644`) | 2026-09-25 | `unblessed` | Section-header promotion only; zero content change. |
| `main.tex` §8 "Simulation Evidence" (`main.tex:644-707`) | 2026-09-25 | `unblessed` | Title/label change. **Additional-simulations pull complete**: the Path-2 misspecification check (correct vs. misspecified functional form) relocated here verbatim from Appendix A, since it is the direct evidentiary anchor for S4's numbered claim. Appendix A's opening paragraph and the body's Figure~\ref{fig:backward-vs-fatt} transition sentence updated to match. Path~1 isolation, cohort-weights, synthetic-EIF-coverage-duplicate, the three stress tests, and CV robustness deliberately left in the appendix (genuine supplementary/robustness detail, not each tied to a numbered claim the way the misspecification check is) — see `outline.md` §2 row 8 for the itemized rationale. |
| `main.tex` §9/§10 and the Appendix | §10 drafted 2026-09-25; §9/Appendix not touched | mixed | §9 (`section9_application.tex`) already had the correct label; verified, not edited — not logged as `unblessed` since no region was actually redrafted. §10 Discussion (`main.tex:681-701`) **redrafted**: strengthened opening synthesis (explicit "one framework, three invariance choices" framing tying back to the Introduction's organizing move), a new paragraph explicitly reconciling the application's failure result (§9) against the paper's structural picture, and expanded scope-boundary restatements (no first-stage ID strategy; covariates unaffected by policy) per `outline.md` row 10 — status `unblessed`. The Appendix is line-shifted by all edits above but its content, title, and labels are unchanged.

**Registries updated in the same turns as the prose above:** `claims.md` (C1/C3 re-anchored to
now-existing sections; table 2 re-anchored to new line numbers; C7's anchor verified against
`section9_application.tex`), `notation.md` (staleness flag added — labels remain reliable, raw
line numbers not individually re-verified), `outline.md` §2 (content-migration table updated
with drafted/partially-drafted/open-item status per section).

---

## 2. Maintenance contract

- A drafting turn adds or updates the row for the region it touched, with status `unblessed`,
  in the same turn as the prose change — same discipline `notation.md`/`claims.md` already
  require.
- Only the author (explicit approval in conversation, or the author's own edit to the region)
  may set a row to `blessed`. An agent never writes `blessed` on its own initiative.
- A `blessed` region that is subsequently redrafted reverts to `unblessed` until re-approved.

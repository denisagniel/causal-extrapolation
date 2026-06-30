# Remediation Plan — Full-Paper Audit (2026-06-30)

**Status:** DRAFT — awaiting user approval
**Source:** `quality_reports/2026-06-30_full-paper-audit.md`
**Principle:** Everything provisional. Theory drives code drives application drives paper (code-paper-package-alignment). Sequence so each phase unblocks the next.

---

## Phase 0 — Lock the framing (no code yet)
1. Settle the abstract↔intro reconciliation (align abstract UP to Fundamental Promise — decided).
2. Settle estimand set: adopt lean's 2 estimands (FATT, FATE); FATU/FATS/FITE → footnote/supplement.
3. Settle title (name the parallel three-path / regime-change contribution).
4. Confirm the unifying abstraction: "asymptotically-linear first-stage estimator of the relevant object" (θ_gt for Paths 1–2, τ(x) for Path 3).
**Deliverable:** short framing memo; no file edits.

## Phase 1 — Theory: rewrite Path 3 + fix proofs (paper math first)
1. New Prop 3: τ_FATT(p+m) = ∫ τ(x) dF^{p+m}_{X|treated} = E_source[w(X)τ(X)], w=dF^{p+m}/dF^source.
2. New assumptions: structural stability of τ(x); conditional unconfoundedness OR conditional parallel trends/DR-DiD (both designs); overlap + bounded density ratio. Delete RC9/injectivity-for-Path-3.
3. New Path 3 EIF (transport/weighted-ATE IF); **prove collapse to ordinary ATT EIF when target=source** (correctness certificate).
4. Fix proof hygiene: replace `≈` (C2); add within-group assumption to Prop 2 hypotheses (M2); restate efficiency claims as "valid asymptotically-linear IF" (M3); add Path 3 step to asymptotic-normality proof (M5); scope `lem:injectivity` to Path 2.
**Deliverable:** corrected §4.3 + §5 + appendix proofs in main.tex (or a standalone math note first, if preferred).

## Phase 2 — Package: refactor for direct-CATE Path 3
1. New API: `integrate_cate(cate_fit, target_x, source_x, influence=, density_ratio=, ...)`; compose existing CATE learners (grf/DoubleML/rlearner) + density-ratio; assemble transport EIF.
2. Keep `compute_variance`, numerical utils, integration skeleton. Remove `estimate_beta_from_groups` + marginal-inversion Jacobian.
3. Fix `from_did.R` `bstrap`/`inffunc` handling (C4); make Paths 1–2 aggregation honor ω_g.
4. Tests: collapse property (target=source ⇒ ATT EIF), d>1, known-DGP recovery.
**Deliverable:** updated R/ + tests passing.

## Phase 3 — Application: re-run through the package, honestly
1. Re-run `02` with `bstrap=FALSE` (or confirmed inffunc) + `set.seed`; store `gt_object`.
2. Rewrite `03–05` to CALL the package (Path 1 ω-weighted; Path 2 correct future calendar times; Path 3 = real CATE fit on state-year microdata + integrate over 2016+ covariate dist).
3. Regenerate tables/figures from EIF-based SEs/CIs. Add `application/README.md`, `fs::dir_create`, seeds. Save script 09 outputs.
4. Record the real results (Path 3 likely still underperforms — keep honest narrative).
**Deliverable:** reproducible pipeline; real numbers feeding §9.

## Phase 4 — Paper assembly (lean as go-forward)
1. Port corrected theory into `main-lean.tex`; fill the 54 TODOs.
2. Real simulation table (≥1 real-first-stage DGP + non-oracle Path 3 stress regime, M6); real application numbers (M7).
3. Restore three-path parallelism (M1); demote "Connecting…" subsections; soften "first" claim; unify notation.
4. Fix compile blockers (C5): `\lemma` redef, 3 missing citations, 2 overfull hboxes. Verify clean build.
**Deliverable:** compiling lean paper, no placeholders.

## Phase 5 — Verify & align
1. Three-way fidelity check (paper ↔ code ↔ package).
2. Full reviewer re-run (verifier + domain + proof-auditor) to confirm criticals closed.

---

## Suggested order & checkpoints
Phase 0 → **checkpoint** → Phase 1 → **checkpoint (math correct?)** → Phases 2+3 together (they co-define the API) → Phase 4 → Phase 5.
Phase 1 (theory) is the linchpin: it defines the package API (Phase 2) and the application (Phase 3). Do not start code before Phase 1 math is approved.

## Quick wins available anytime (low-risk, independent)
- Fix `\lemma` redefinition + add 3 missing citations + 2 overfull hboxes (C5).
- Add `set.seed` + `application/README.md` (M8).
- Fix DESCRIPTION stale path; brodersen empty-journal bib field.

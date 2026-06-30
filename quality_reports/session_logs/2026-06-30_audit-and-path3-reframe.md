# Session Log — 2026-06-30: Audit + Path 3 Reframe (Phases 0–1)

## Goal
Resume the paper; reframe Path 3 (the audit's top critical), then audit everything and begin remediation. Treat all committed paper/code as provisional.

## Key decisions (all in memory/)
- **Path 3 → direct CATE + transport.** Estimate τ(x) directly from microdata (existing asymptotically-linear/cross-fit CATE), integrate over future covariate dist F^{p+1}. Overrides committed invert-β-from-marginals approach. (path3-direct-cate-estimation)
- **Contribution = mapping, not estimation.** All three paths = plug existing estimator → forward map → propagate EIF. (paper-contribution-is-mapping-not-estimation)
- **Keep Fundamental Promise framing** in intro; align abstract up to it. (keep-fundamental-promise-framing)
- **Phase 0 framing locked:** estimands FATT+FATU+FATE (FITE/FATS motivation only); title "Should We Keep the Policy? Forward-Looking Estimands and Identification for Panel Data"; unifying abstraction = asymptotically-linear first-stage estimator. (paper-framing-decisions)
- **DA correction:** CATE τ̂ NOT √n with continuous X; √n recovered at functional level via Neyman-orthogonal DR score + cross-fitting. DML rates kept at citation level; overlap/bounded-w is the substantive limit.
- **DA correction:** structural-stability assumption is testable for t≤p (untestable only at p+1) — fixed §4.3 prose.

## Work completed
1. **Committed accumulated work** (6d09ea4): application pipeline, lean draft, removed accidental nested data tree, gitignore for build artifacts.
2. **5-agent adversarial audit** (committed d8472af): `quality_reports/2026-06-30_full-paper-audit.md` + remediation plan. Cross-confirmed criticals: C1 Path3 invert-from-marginals wrong/vacuous; C2 ≈-in-proof; C3 application bypasses package (EIF claims false as run); C5 compile errors.
3. **Phase 1 theory note** (committed 7187968): `quality_reports/2026-06-30_phase1-path3-theory-note.md` — full reframed math, approved.
4. **Phase 1 LaTeX pass (main.tex), in progress — option (b) section-by-section:**
   - §4.3 body: new Prop 3' (transport), assumptions A1(cond-ident)/A2(struct-stab)/A3(target+overlap), A2'(cross-group, FATU/FATE), parametric special case. DONE.
   - §5 EIF + appendix proof + app:eif3: DR transport score (eq:eif-path3), change-of-measure proof, collapse lemma (lem:path3-collapse). DONE.
   - RC8–RC10 rewritten (nuisance rates, overlap, target access). DONE.
   - Efficiency overclaims (M3) downgraded Path 1 & 2. DONE.
   - Asymptotic-normality proof: Path 3 step added (M5). DONE.
   - Added Sant'Anna-Zhao + Chernozhukov bib entries; fixed `\lemma` duplicate (C5 unblocker). DONE.

## Verification
main.tex compiles clean: exit 0 all passes, **no undefined refs/citations**, 45 pages (was 46 — reframe is leaner). Remaining (pre-existing C5, not this work): 2 missing citations (tibshirani/chen, in model-selection §, no longer \cited in body) + 2 overfull hboxes (Assumptions, lines 194/238).

## Phase 1 COMPLETE (main.tex)
- M2: Prop 2 within-group heterogeneity promoted to stated hypothesis. DONE.
- Estimands §: FATT/FATU/FATE established as the carried family with explicit decision-mapping (repeal/adopt/universal) + shared-machinery note (one τ(x), three target dists); FITE/FATS demoted to motivation. DONE.
- C5 quick wins: all 4 overfull hboxes cleared (long assumption displays → display math); "withing-group" typo fixed. DONE.
- Verified: exit 0, 0 undefined refs, 0 undefined citations, 0 overfull hboxes >10pt, 45 pages.
- Deferred (non-blocking): 2 stale citation keys in .blg (tibshirani/chen — no longer \cited in body, no LaTeX error); lem:injectivity cosmetic scoping.

## Status: paused for user review of compiled main.tex before Phases 2–3 (package + application).

## Next phases (per remediation plan)
Phase 2 (package: integrate_cate API, DR transport EIF, delete estimate_beta_from_groups) + Phase 3 (application: real CATE fit, package calls, set.seed) together. Then Phase 4 (lean paper assembly), Phase 5 (re-verify).

## Open question for user
Paused for review of compiled Path 3 sections (§4.3, §5, appendices) before continuing remaining Phase 1 items.

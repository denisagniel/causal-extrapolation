# Full-Paper Audit — causal-extrapolation

**Date:** 2026-06-30
**Method:** Deep adversarial multi-agent (proof-auditor, domain-reviewer, r-reviewer, structure-reviewer, verifier), read-only. Object of record: full `inst/paper/main.tex`; lean `main-lean.tex` checked against it.
**Status:** Findings — no edits applied. Triage with user before remediation.

A finding is marked **[×N]** where N independent reviewers flagged it (cross-confirmation = higher confidence).

---

## CRITICAL

### C1. Path 3 "invert CATE from marginal group-time ATTs" is wrong/vacuous [×4]
*proof-auditor #1,#2 · domain 1.1,5.1 · r-reviewer C3 · structure*
The committed Path 3 (main.tex Prop 3, `R/integrate_covariates.R::estimate_beta_from_groups`) recovers β by inverting θ_gt = ∫ m(x;β) dF_{X|G=g}. For the linear model the paper uses, this collapses to θ_gt = X̄_g^⊤β — β identified only from q≈3 group means; injectivity (RC9) fails generically. It is an ecological regression dressed in structural ("deep parameters / Lucas") language, and does NOT support the regime-change-robustness claims. **Resolution already decided:** estimate τ(x) directly from microdata (asymptotically-linear/cross-fit CATE) + integrate over future F_X^{p+m}. Delete RC9/inversion. (See memory: path3-direct-cate-estimation.)

### C2. Prop 3 proof uses `≈` then concludes exact identification [×3]
*proof-auditor #1 · domain 2.1 · structure #6*
main.tex:698: `θ_{p+1} ≈ E[…|A_{i,p+1}=1]`, never upgraded to `=`. An identification proposition cannot conclude from an approximate step. Needs an explicit numbered conditional-exchangeability assumption (covariate-conditional analog), or downgrade to approximate identification with characterized bias. Dissolves under the direct-CATE reframe.

### C3. Application bypasses the package entirely — §9 EIF/inference claims are false as run [×2]
*r-reviewer C1 · verifier (corroborating)*
Grep of `application/scripts/` finds NO calls to any package entry point. Path 1 SE = `sd(att)/sqrt(n)` (iid), Path 2/3 SEs from `predict(lm())`. None of the paper's EIF machinery (`app:eif1–3`) is exercised. §9 claim "all three paths propagate uncertainty through influence functions" is not substantiated by the code. The application therefore also does not validate the package.

### C4. `bstrap=TRUE` in `att_gt()` precludes EIF extraction
*r-reviewer C2*
`02_estimate_gt_atts.R` uses `bstrap=TRUE`; `from_did.R` requires `inffunc` (needs `bstrap=FALSE` per its doc). Even if scripts called the package, EIFs would be dropped. (Also: verify whether current `did` returns `inffunc` regardless — the doc claim may be stale.)

### C5. Compile errors in main.tex (clean build would fail)
*verifier*
(a) `\lemma already defined` (main.tex:15–16, redefines env from common-defs.tex) — non-fatal only under nonstopmode. (b) 3 undefined citations: `tibshiraniExactPostselectionInference2016`, `chenValidInferenceModel2021`, `chernozhukovDoubleDebiasedMachine2018` (the last is actually used for the DML rate claim — important). (c) 2 overfull hboxes >10pt (lines 195–196, 239–240). Per quality-gates, each is "critical."

---

## MAJOR

### M1. Three paths not structurally parallel; Path 3 disproportionately heavy [×3]
*structure · domain 5.1 · proof-auditor (context)*
Path 3 alone carries inline estimation + full EIF in §4 (355–388) while Paths 1–2 defer EIFs to §5 — §5 explicitly says so (line 396). Breaks the "plug in existing estimator → map → propagate EIF" framing. Fix: move Path 3 EIF/estimation to §5; cut Path 3's 3× repeated "when to use" to one. Reframe should SHRINK Path 3's footprint.

### M2. Hidden assumption in Prop 2 [×2]
*proof-auditor #6 · domain 2.3*
Prop 2 proof (654–657) invokes within-group between-state heterogeneity not in the proposition's hypotheses. Promote to a stated hypothesis of Prop 2.

### M3. "Achieves semiparametric efficiency bound" overclaim [×2]
*proof-auditor #8 · domain 2.2*
Lines 774, 408, 386, 878: propagated IF is the IF of the plug-in; efficient only if first-stage IFs + aggregation weights are efficient (simple time-average generally isn't). Restate as "valid asymptotically-linear influence function." Matches the mapping-not-estimation framing.

### M4. Missing conditional-identification assumption for τ(x) [×2]
*proof-auditor #3 · domain 1.2*
Identifying τ(x) from the first stage needs conditional unconfoundedness (unconfoundedness design) or conditional parallel trends / conditional DR-DiD (DiD design). Currently asserted in-proof, not assumed. Promote to first-class; give both design analogs.

### M5. Path 3 EIF omits the transport/density-ratio term + no collapse check [×1, high-value]
*proof-auditor #4*
`app:eif3` derives only the invert-from-marginals IF; no density-ratio w(x)=dF^{p+m}/dF^source term, no empirical-measure term for target sampling, and no proof it collapses to the ordinary ATT EIF when target=source. The collapse property should be the correctness certificate for the reframe.

### M6. Simulations use a synthetic first stage (θ̂_gt = θ_gt + ε) [×2]
*domain 4.2/4.3 · structure*
EIF-propagation claim is never exercised against a real asymptotically-linear first stage; Path 3 sim is "oracle" (β supplied), so the fragile identification step isn't stress-tested (constitution §9). Add ≥1 end-to-end DGP with a real first stage; add non-oracle / near-collinear-X̄_g Path 3 regime.

### M7. Application results unstable across files (Path 3 best vs. worst) [×2]
*structure · domain 5.2*
Real `section9_application.tex`: Path 3 WORSE than Path 1 (R²≈0.035, MSPE 0.84). Lean skeleton tables/prose: Path 3 BEST (fabricated numbers, main-lean 753–788). Opposite stories. Replace lean placeholders with real outputs; rewrite lean discussion. (Honest "even structural modeling fails when covariates weak" is the stronger message.)

### M8. Reproducibility gaps [×2]
*verifier · r-reviewer C4*
No `set.seed()` anywhere (bootstrap SEs non-reproducible); no README/master script; scripts assume repo-root cwd; script 09 outputs (`policy_comparison.*`) never saved. Add seed, README, `fs::dir_create`.

### M9. `integrate_covariates` only correct for d=1; serialization/house-style deviations
*r-reviewer M5,M1,M2,M6*
Jacobian hardwires single covariate; base saveRDS vs readr; pervasive `cat()`; Path-2 script uses fabricated event times + AIC mislabeled as CV; Path-1 ignores ω_g weights. Most dissolve when scripts are rewritten to call the package.

---

## MINOR (selected)

- Estimand zoo: 5 estimands defined (FITE/FATS/FATE/FATT/FATU), ~only FATT identified — referee bait. Lean's 2-estimand cut resolves. [structure, domain]
- Abstract↔intro framing inconsistency — align abstract UP to Fundamental Promise framing (KEEP intro; see memory). [structure, domain, prior decision]
- Title differs across files; lean title under-sells parallel-paths/regime-change contribution. [structure]
- Notation drift full↔lean: ω_g vs π_g, τ(x)=m(x;β) vs θ(x,g), p+1 vs p+m. [structure]
- "First systematic framework for model selection in causal extrapolation" — soften "first." [domain 5.3]
- "Connecting…" subsections (221–259) are Path-1 corollaries formatted as top-level — demote to restore Path 1/2/3 spine. [structure]
- `lem:injectivity` supports Path 2 only; don't let it appear to justify Path 3. [proof-auditor #11]
- MC-error negligibility needs M_n/n→∞. [proof-auditor #10]
- Bib: empty journal in brodersen2015; DESCRIPTION points to defunct `latex/` path. [verifier]
- xelatex not on PATH / texbin symlink broken (environment, not paper). [verifier]
- Overlap/positivity + bounded density-ratio assumption needed for reframed Path 3 (w(x) can be unbounded under covariate shift). [proof-auditor edge-case]

---

## Positives (preserve)
- Estimand design is decision-relevant; "Fundamental Promise" framing is a genuine conceptual contribution. [domain, structure]
- Intellectual honesty in the application (reports failure, no cherry-picking) — aligns with constitution §8/§11. [domain]
- Unifying extrapolation-function framework (§4.1, Table 1) is the right scaffold for parallelism. [structure]
- Neighboring-literature positioning (Gische, Deb, Forastiere, transportability) accurate. [domain]
- Lean 8-section spine is sound; gives all EIFs one home (§5) — fixes Path-3 asymmetry if executed. [structure]

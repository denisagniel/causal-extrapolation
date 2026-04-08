# Handoff Prompt: EIF-Based Inference for Synthetic Control

**Date:** 2026-03-04
**Status:** Phase 2 complete (proof of concept), ready for Phase 3 (formal theory)

---

## Project Summary

Develop EIF-based variance estimation for synthetic control (SC) methods to provide rigorous inference that properly accounts for outcome model estimation uncertainty.

**Key insight:** SC and difference-in-differences (DiD) identify *different observed data functionals* because they make different assumptions:
- **DiD:** Parallel trends (unconditional)
- **SC:** Conditional parallel trends given pre-treatment outcomes Y_{pre}

SC estimates:
```
θ = E[E[Y_t(0) | D=0, Y_{pre}] | D=1]
```

This is a covariate-adjusted ATT where Y_{pre} serves as high-dimensional covariates. This functional has an efficient influence function (EIF) that can be used for variance estimation, but **existing SC methods don't use it**.

**Current practice:** SC literature uses ad-hoc inference (placebo tests, conformal inference, bootstrap)

**Problem:** These methods don't account for outcome model estimation uncertainty → underestimate variance → CIs too narrow → false confidence

**Solution:** Derive and use the EIF for the SC functional → doubly robust inference with correct coverage

---

## Phase 2 Results (Proof of Concept)

**Simulation:** N=100 (50 treated, 50 control), T_0=10, 500 replications

**DGP:** Factor model with violation of parallel trends but conditional parallel trends hold given Y_{pre}

### Coverage Rates (Target: 0.95)

| Method | Coverage | CI Width | Status |
|--------|----------|----------|--------|
| **EIF-based** | **0.944** | 0.925 | ✓ Correct |
| Placebo (standard) | 0.414 | 0.357 | ✗ 59% failure |
| Placebo (augmented) | 0.614 | 0.357 | ✗ 38% failure |

**Conclusion:** EIF works, placebo fails. This is a real and important contribution.

---

## Key Files to Port

From the `causal-extrapolation` project:

### 1. Conceptual Development
**File:** `development-docs/eif-for-sc-inference.md`

Contains:
- Full problem setup and motivation
- Comparison: SC vs. DiD identifying functionals
- EIF derivation (informal)
- Literature review notes (Ben-Michael et al. uses conformal, not EIF)
- Paper outline (sections, abstract draft)
- Actionable roadmap (Phase 1-7)
- Timeline estimates (4-7 months)

**Action:** Read this first to understand the full scope.

### 2. Formal Theory Sketch
**File:** `development-docs/eif-sc-theory-sketch.md`

Contains:
- Mathematical setup (panel data, potential outcomes, estimand)
- Identification assumptions (conditional parallel trends)
- Semiparametric model (nuisance parameters: m, e)
- EIF derivation (formal, with components)
- Double robustness proof sketch
- Connection to SC methods (standard, augmented)
- Asymptotic theory outline (rate requirements)
- Comparison to existing methods
- Open questions

**Action:** Use this as the basis for the theory section.

### 3. Proof-of-Concept Simulation
**File:** `sims/sim_sc_eif_poc.R`

Contains:
- DGP: Factor model with conditional parallel trends
- SC weight estimation (quadratic programming)
- Outcome model estimation (ridge regression)
- Standard SC estimator
- Augmented SC estimator
- EIF-based variance computation (three components)
- Placebo variance computation
- Full simulation framework (500 replications)

**Action:** This code works. Port it and extend for comprehensive simulations.

### 4. Session Log
**File:** `quality_reports/session_logs/2026-03-04_sc-eif-poc.md`

Contains:
- Timeline of work
- Design decisions
- Results interpretation
- Quality assessment
- Next steps

**Action:** Reference for context on what's been done and why.

---

## What's Been Done

### ✓ Phase 1: Novelty Check

**Finding:** Ben-Michael et al. (2021) augsynth package uses **conformal inference** for CIs, not EIF-based variance. This suggests:
- Either: EIF not derived in their paper (need to verify by reading full paper)
- Or: EIF derived for point estimation but not used for inference

**Implication:** EIF-based inference for SC appears to be novel.

### ✓ Phase 2: Proof of Concept

**Goal:** Show empirically that EIF works and placebo fails.

**Result:** STRONG POSITIVE
- EIF: 0.944 coverage (≈ 0.95 target)
- Placebo: 0.41-0.61 coverage (<< 0.95 target)
- Magnitude of failure is large, not marginal

**Conclusion:** This is worth pursuing as a standalone paper.

---

## What Needs to Happen

### Phase 3: Formal Theory (4-6 weeks)

**Goal:** Rigorous semiparametric framework with asymptotic theory

**Tasks:**
1. **Setup and identification**
   - Formalize panel data model
   - State conditional parallel trends assumption precisely
   - Prove identification of θ = E[m(Y_{pre}, X) | D=1]

2. **EIF derivation**
   - Define semiparametric model (parametric: θ, nonparametric: m, e, F)
   - Derive EIF via pathwise derivative or von Mises calculus
   - Verify efficiency (achieves semiparametric bound)

3. **Double robustness**
   - Prove: If m correct OR e correct, then √N(θ̂ - θ) →^d N(0, E[ψ²])
   - Show bias correction property

4. **Asymptotic normality**
   - State regularity conditions
   - Rate requirements for nuisances: ||m̂ - m|| ||ê - e|| = o_P(N^{-1/2})
   - Handle high-dimensional Y_{pre} (factor structure? sparsity?)

5. **Variance estimation**
   - Consistent estimator: V̂ = (1/N) Σ ψ̂_i²
   - Uniform validity over nuisance classes

**Deliverable:** Theory section (10-15 pages) with propositions and proofs

**References to check:**
- Kennedy (2016, 2022) - Semiparametric theory
- Chernozhukov et al. (2018) - Double/debiased ML (for rate conditions)
- Hahn (1998) - Propensity score efficiency
- Robins et al. (2008) - Higher-order influence functions

### Phase 4: Comprehensive Simulations (3-4 weeks)

**Goal:** Map out when EIF dominates and when it fails

**Vary:**
- N: 20, 50, 100, 200, 500
- N_treated / N: 0.1, 0.25, 0.5
- T_0: 5, 10, 20, 50
- Signal-to-noise ratio
- DGPs:
  - Parallel trends hold (DiD and SC both valid)
  - Parallel trends violated, conditional parallel trends hold (SC valid only)
  - Conditional parallel trends violated (SC invalid)
  - Factor models (à la SDID)
  - Nonlinear outcome models
  - Misspecified models (test double robustness)

**Compare:**
- EIF-based (ours)
- Placebo (ADH)
- Conformal inference (Lei et al.)
- Bootstrap
- DiD (for comparison when parallel trends hold)

**Metrics:**
- Coverage (target: 0.95)
- CI width (conditional on correct coverage)
- Power (reject H_0 when τ ≠ 0)
- Robustness to misspecification

**Deliverable:** Simulation section (8-10 pages) + figures/tables

### Phase 5: Empirical Applications (2-3 weeks)

**Goal:** Show this matters in real data

**Find applications with:**
- Multiple treated units (N_treated ≥ 10)
- Published SC study with reported inference
- Data accessible for replication

**Candidates:**
- Medicaid expansion (multiple states, staggered)
- Minimum wage studies (multiple cities/counties)
- School interventions (multiple districts)
- Place-based policies (multiple localities)

**For each application:**
1. Replicate original SC estimates
2. Compute EIF-based CIs
3. Compare to published CIs (typically placebo or conformal)
4. Report:
   - Original CI: [a, b]
   - EIF CI: [c, d]
   - Does conclusion change?
   - Sensitivity to outcome model specification (ridge, factor, RF)

**Deliverable:** Empirical section (6-8 pages)

### Phase 6: Write Paper (4-6 weeks)

**Target length:** 50-55 pages

**Structure:**
1. **Introduction** (5 pages)
   - Motivation: SC popular but inference is hard
   - Key insight: SC ≠ DiD (different functionals)
   - Contribution: EIF for SC + rigorous inference
   - Preview of results

2. **Setup and Identification** (4 pages)
   - Panel data, estimand (ATT)
   - DiD vs SC identification
   - Observed data functional for SC

3. **Semiparametric Theory** (12-15 pages)
   - Model specification
   - EIF derivation
   - Double robustness
   - Asymptotic theory

4. **Estimation and Inference** (5 pages)
   - Algorithm (steps 1-5)
   - Connection to augmented SC
   - Cross-fitting (optional)

5. **Simulations** (10 pages)
   - Design
   - Results (coverage, width, power)
   - When does EIF dominate?

6. **Empirical Applications** (8 pages)
   - Description of applications
   - Results
   - Comparison to published CIs
   - Sensitivity analysis

7. **Discussion** (3 pages)
   - When to use EIF (moderate N, multiple treated)
   - Limitations (small N, single treated)
   - Extensions (staggered, event studies)

8. **Appendix**
   - Proofs
   - Additional simulations
   - Software documentation

**Target venues:**
- Journal of Econometrics
- JASA (Theory & Methods)
- Econometric Theory
- Biometrika

### Phase 7: Software (3-4 weeks, parallel with Phase 6)

**Goal:** Usable R package

**Package name:** `sceif` (synthetic control EIF)

**Core functionality:**
```r
library(sceif)

# Basic usage
result <- sc_eif(
  data = panel_data,
  outcome = "Y",
  treatment = "D",
  unit = "id",
  time = "t",
  pre_periods = 1:10,
  post_period = 15,
  outcome_model = "ridge"  # or "sc_weights", "factor", "rf"
)

summary(result)
# ATT estimate, SE, 95% CI

# Compare to other methods
compare_inference(result, methods = c("placebo", "conformal", "bootstrap"))
```

**Features:**
- EIF-based variance (core)
- Multiple outcome models (ridge, SC weights, factor, RF)
- Cross-fitting option
- Comparison to existing methods
- S3 classes with print/summary/plot
- Vignettes (single adoption, staggered, comparison)

**Integrate with existing packages:**
- Import weights from `Synth` or `augsynth`
- Provide EIF-based inference on top of existing SC estimates

**Deliverable:** R package on GitHub, submit to CRAN

---

## Technical Details

### EIF Formula

For the SC functional θ = E[E[Y_t(0) | D=0, Y_{pre}] | D=1]:

```
ψ(O_i; θ, η) = [D_i / P(D=1)] · [Y_it - m(Y_{i,pre}, X_i)]
             + [(1-D_i) · e(Y_{i,pre}, X_i)] / [(1-e(·)) · P(D=1)] · [Y_it - m(·)]
             + [D_i / P(D=1)] · [m(Y_{i,pre}, X_i) - θ]
```

Components:
1. Treated residuals (scaled by inverse probability)
2. Control contribution (reweighted by generalized propensity score)
3. Centering (makes E[ψ] = 0)

### Nuisance Parameters

- **m(y_{pre}, x):** E[Y_t | D=0, Y_{pre} = y_{pre}, X = x] (outcome model)
- **e(y_{pre}, x):** P(D=1 | Y_{pre} = y_{pre}, X = x) (generalized propensity score)

**Estimation strategies:**
- m: Ridge regression, factor models, SC weights, random forest
- e: Often not needed (can use empirical distribution of Y_{pre} | D=1)

### Implementation Notes

**SC weights via quadratic programming:**
```
min ||Y_{treated,pre} - Σ_j w_j Y_{j,pre}||²
subject to: w ≥ 0, Σ w_j = 1
```

**Control contribution in EIF:**
For each control j, weight = average SC weight for j across all treated units

**Variance:**
```
V̂ = (1/N) Σ_{i=1}^N ψ̂_i²
SE = √V̂
95% CI: θ̂ ± 1.96 SE
```

---

## Open Questions

### Theoretical

1. **High-dimensional Y_{pre}:**
   - With T_0 ~ 10-50, standard rates may not hold
   - Need factor structure? Sparsity? Smoothness?
   - Can we get √N rate or only slower rate?

2. **Propensity score e(y_{pre}, x):**
   - Is this identifiable in high dimensions?
   - Density estimation in R^{T_0} is hard
   - Can we avoid estimating e explicitly?
   - Use SC weights as implicit propensity scores?

3. **Single treated unit:**
   - Can we define conditional EIF given Y_{1,pre} = y_0?
   - Prediction problem vs. ATT estimation?
   - Or declare out of scope and focus on multiple treated units?

### Practical

1. **Small N threshold:**
   - When does asymptotic approximation work?
   - N ≥ 50? N ≥ 100?
   - Bootstrap + EIF for small N?

2. **Cross-fitting:**
   - Necessary with panel data?
   - How to split (units? time periods? both)?
   - Does it help or hurt with small N?

3. **Outcome model choice:**
   - How sensitive are results to m̂ specification?
   - Does double robustness work in practice?
   - Guidelines for choosing outcome model?

---

## Literature (Must Read)

### SC Inference
- **Ben-Michael, Feller, Rothstein (2021)** - Augmented SC [CHECK: Do they have EIF?]
- Arkhangelsky et al. (2021) - Synthetic DiD
- Abadie, Diamond, Hainmueller (2010, 2015) - Original SC
- Ferman & Pinto (2021) - Imperfect pretreatment fit
- Chernozhukov et al. (2021) - Synthetic controls with inference
- Lei et al. (2018) - Conformal inference for SC

### Semiparametric Theory
- **Kennedy (2016, 2022)** - Semiparametric theory and EIF
- Hahn (1998) - Role of propensity score
- Chernozhukov et al. (2018) - Double/debiased ML
- Robins, Li, Tchetgen, van der Vaart (2008) - Higher order IF

### DiD with Covariates
- Callaway & Sant'Anna (2021) - DiD with multiple periods
- Roth & Sant'Anna (2023) - Efficient event studies
- Sant'Anna & Zhao (2020) - Doubly robust DiD

### Covariate Balancing
- Hainmueller (2012) - Entropy balancing
- Imai & Ratkovic (2014) - Covariate balancing propensity score
- Zhao (2019) - Covariate balancing

---

## Decision Points

### After reading Ben-Michael et al. (2021) full paper

**If they have EIF:**
- Contribution is "use EIF for inference, not conformal"
- Emphasize empirical performance gains
- Position as practical improvement

**If they don't have EIF:**
- Contribution is "derive EIF + inference"
- Emphasize theoretical novelty
- Position as foundational contribution

### After Phase 3 (theory)

**If theory works cleanly:**
- Proceed to Phase 4 (comprehensive sims)

**If high-dimensional Y_{pre} requires special treatment:**
- Add section on factor models or sparsity
- Possibly collaborate with panel data expert

### After Phase 4 (simulations)

**If EIF dominates broadly (N ≥ 50):**
- Strong paper, recommend for general use

**If EIF only works for N ≥ 200:**
- Narrower scope, still publishable but less impact

**If EIF fails with misspecification:**
- Need robustified version or acknowledge limitation

---

## Quality Thresholds

**Commit:** 80/100
**PR:** 90/100
**Excellence:** 95/100

**Current status:**
- Proof of concept: 90/100 (exceeds PR threshold)
- Ready for Phase 3

**Target for paper:**
- Theory: 90/100 minimum (rigorous, clear proofs)
- Simulations: 90/100 minimum (comprehensive, interpretable)
- Empirics: 85/100 minimum (at least 2 applications)
- Writing: 90/100 minimum (clear, concise, well-motivated)

---

## Timeline Estimate

**Conservative:** 6-7 months
- Phase 3 (theory): 6 weeks
- Phase 4 (sims): 4 weeks
- Phase 5 (empirics): 3 weeks
- Phase 6 (writing): 6 weeks
- Phase 7 (software): 4 weeks (parallel with Phase 6)
- Revisions: 4 weeks

**Aggressive:** 4-5 months
- Phase 3: 4 weeks
- Phase 4: 3 weeks
- Phase 5: 2 weeks
- Phase 6: 4 weeks
- Phase 7: 3 weeks (parallel)
- Revisions: 2 weeks

---

## Next Immediate Steps

1. **Set up new project repository**
   - Create directory structure
   - Port files from causal-extrapolation
   - Initialize git

2. **Complete novelty check**
   - Get Ben-Michael et al. (2021) full paper
   - Check Sections 3-4 for EIF derivation
   - Update positioning based on findings

3. **Start Phase 3 (theory)**
   - Formalize setup and identification
   - Derive EIF rigorously
   - Write proofs (double robustness, asymptotic normality)

4. **Sketch paper outline**
   - Based on theory section
   - Identify gaps in argument
   - Plan simulation studies to fill gaps

---

## Contact Context

This work originated from a research session on 2026-03-04 where the idea emerged:

> "Getting good standard errors for synthetic control estimators is really difficult, and a bunch of the methods implemented in SC packages basically do not work, even in the papers' own simulations. But couldn't you just use the EIF of E(Y_p | Y_1, ..., Y_{p-1}) to get a variance estimate?"

After exploration, the insight crystallized: SC identifies a different functional than DiD (conditional on Y_{pre}), and that functional has an EIF that provides principled inference.

Proof-of-concept simulations confirmed this works (EIF: 0.944 coverage vs. placebo: 0.41-0.61 coverage).

**Project is ready for Phase 3 (formal theory).**

---

## Files to Copy

From `causal-extrapolation/`:

```
development-docs/
├── eif-for-sc-inference.md          # Full conceptual development
└── eif-sc-theory-sketch.md          # Formal theory outline

sims/
├── sim_sc_eif_poc.R                 # Working simulation code
└── sim_sc_eif_results.txt           # Phase 2 results summary

quality_reports/session_logs/
└── 2026-03-04_sc-eif-poc.md         # Session documentation
```

**This file:** `development-docs/sc-eif-handoff-prompt.md`

---

## Final Note

This is a **high-quality, publishable project** with strong proof-of-concept results. The path forward is clear:
1. Formalize theory
2. Run comprehensive simulations
3. Apply to real data
4. Write paper
5. Build software

Estimated impact: High (fixes major inference problem in widely-used method)

Estimated timeline: 4-7 months

Estimated venue: Top econometrics/statistics journal

**Recommendation: Proceed to Phase 3.**

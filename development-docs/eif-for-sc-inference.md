# EIF-Based Variance Estimation for Synthetic Control

**Date:** 2026-03-04
**Status:** Exploratory sketch - potentially publishable

## Executive Summary

**The core insight:** Synthetic control (SC) and difference-in-differences (DiD) identify *different observed data functionals* because they make different identifying assumptions:
- **DiD:** Parallel trends (unconditional)
- **SC:** Conditional parallel trends given pre-treatment outcomes Y_{pre}

This means SC estimates:
```
θ = E[E[Y_t(0) | D=0, Y_{pre}] | D=1]
```

This is a **covariate-adjusted ATT** where Y_{pre} serves as high-dimensional covariates. This functional has an efficient influence function (EIF) that can be used for variance estimation - but **existing SC inference methods don't use it**.

**Why this matters:**
- Existing SC inference (placebo, conformal, bootstrap) is ad-hoc and often fails
- The EIF provides principled, doubly robust inference
- Works when N is moderate (≥ 50) and multiple treated units exist
- Could substantially improve inference in SC applications

**Main challenges:**
- Small N in typical SC applications (N ~ 10-30)
- Single treated unit case (no variation in treated population)
- High-dimensional Y_{pre} requires good outcome models

**Verdict:** This is a real contribution if we can show it works empirically in settings with multiple treated units and moderate N.

## The Idea

SC inference methods often fail, even in the papers' own simulations. Could we use the efficient influence function (EIF) for the estimand E(Y_{it}(0) | pre-treatment outcomes, covariates) to get principled variance estimates?

**Key realization:** This isn't just applying existing DiD EIF theory - SC identifies a *different functional* than DiD, so we need a different EIF.

## Background: SC as Conditional Expectation

**Literature:** Augmented SC (Ben-Michael et al. 2021, Arkhangelsky et al. 2021) frames SC as estimating:
- Counterfactual outcomes Y_{it}(0) for treated units post-treatment
- Using pre-treatment outcomes and covariates
- Augmented SC = augmented IPW with particular weight estimation strategy

## Setup

### Notation
- Units: i = 1, ..., N (i = 1 is treated, i = 2, ..., N are controls)
- Time: t = 1, ..., T (t = 1, ..., T_0 is pre-treatment, t = T_0 + 1, ..., T is post-treatment)
- Outcomes: Y_{it}
- Treatment: D_i ∈ {0, 1}
- Covariates: X_i

### Potential Outcomes
- Y_{it}(1) = outcome for unit i at time t under treatment
- Y_{it}(0) = outcome for unit i at time t under control

### Observed Data
Y_{it} = D_i Y_{it}(1) + (1 - D_i) Y_{it}(0)

For treated unit (i = 1):
- Observe: Y_{1t}(1) for t > T_0
- Want: Y_{1t}(0) for t > T_0 (counterfactual)

## Estimand

For a specific post-treatment period t > T_0, the SC estimand is:

τ_t = Y_{1t}(1) - E[Y_{1t}(0) | Y_{1,1:(T_0)}, X_1]

where Y_{1,1:(T_0)} = (Y_{11}, ..., Y_{1,T_0}) are pre-treatment outcomes.

The SC problem: **estimate E[Y_{1t}(0) | Y_{1,1:(T_0)}, X_1]**

## Identification

### Assumption 1: Parallel Trends (Conditional)
There exists weights w_i(Y_{1,1:(T_0)}, X_1) such that:

E[Y_{1t}(0) | Y_{1,1:(T_0)}, X_1] = Σ_{i=2}^N w_i Y_{it}

### Assumption 2: Support
For each treated unit's pre-treatment path, there exists a weighted combination of control units that matches it.

**Key insight:** SC restricts w_i ≥ 0 and Σw_i = 1 (convex hull). This is an *additional restriction* beyond what identification requires.

## SC Estimator

Standard SC:
1. Find weights ŵ_i that minimize:
   - ||Y_{1,1:(T_0)} - Σ_{i=2}^N w_i Y_{i,1:(T_0)}||^2 (pre-treatment fit)
   - Subject to: w_i ≥ 0, Σw_i = 1

2. Estimate: Ê[Y_{1t}(0) | Y_{1,1:(T_0)}, X_1] = Σ_{i=2}^N ŵ_i Y_{it}

Augmented SC adds outcome model for bias correction (like augmented IPW).

## EIF Approach: The Question

**Can we derive the EIF for E[Y_{1t}(0) | Y_{1,1:(T_0)}, X_1] and use it for variance estimation?**

### What We'd Need

1. **Statistical Model:** What assumptions define the model?
   - Panel data (Y_{it}, D_i, X_i) for i = 1, ..., N; t = 1, ..., T
   - Conditional parallel trends
   - What else? (distributional assumptions? stationarity?)

2. **Parameter of Interest:**
   θ = E[Y_{1t}(0) | Y_{1,1:(T_0)}, X_1]

3. **Nuisance Parameters:**
   - Outcome model: μ(Y_{1,1:(T_0)}, X_1) = E[Y_{1t}(0) | Y_{1,1:(T_0)}, X_1]
   - Weight model: w(Y_{1,1:(T_0)}, X_1) if we're doing IPW-style estimation
   - Other?

## EIF Structure (Preliminary)

For estimand θ = E[Y_{1t}(0) | Y_{1,1:(T_0)} = y_0, X_1 = x]:

The EIF would have form:

ψ(O; θ, η) = [efficient score for θ given nuisances η]

Standard structure for conditional expectation:
ψ = (Y_{1t}(0) - θ) · [weighting function] + correction terms

But we don't observe Y_{1t}(0) for the treated unit!

## First Problem: We Don't Observe the Counterfactual

For the treated unit (i = 1), we never observe Y_{1t}(0) for t > T_0.

**This is the core SC problem:** We're estimating a conditional expectation for a *specific unit's unobserved counterfactual*, not a population parameter.

### Potential Solutions?

1. **Frame as prediction problem:**
   - Parameter: E[Y_{1t}(0) | Y_{1,1:(T_0)}, X_1]
   - But what's the "superpopulation"? Units as random sample from distribution?
   - SC typically treats units as fixed (design-based inference)

2. **Use control units:**
   - EIF uses observed Y_{it} for control units (i ≥ 2)
   - But then we're estimating E[Y_{it}(0) | Y_{i,1:(T_0)}, X_i] for control units
   - Not the same as E[Y_{1t}(0) | Y_{1,1:(T_0)}, X_1]!

3. **Average over treated units:**
   - If multiple treated units, estimate ATT = E[Y_{it}(1) - Y_{it}(0) | D_i = 1]
   - This has a standard EIF in the causal inference literature
   - But individual SC applications often have N_treated = 1

## Second Problem: Design-Based vs. Model-Based

SC often uses **design-based inference:**
- Units are fixed
- Randomness comes from: treatment assignment? time? measurement error?
- Confidence intervals via placebo tests, permutation, etc.

EIF framework is **model-based:**
- Units are random sample from superpopulation
- Estimating population parameter
- Variance from sampling variability

**These are fundamentally different frameworks.**

## Third Problem: Small N

SC applications often have N_control ~ 10-50.

EIF-based inference requires:
- Estimating nuisance functions (outcome models, propensity scores)
- Consistency + convergence rates for nuisance estimators
- Cross-fitting to avoid overfitting bias

With N ~ 10, nuisance estimation is *highly* unstable.

This might be why existing SC inference fails - not theory, but N is too small for semiparametric methods.

## Could This Work? The Real Path

### Path 1: SC Identifying Functional ≠ DiD Identifying Functional

**Key insight:** Even with multiple treated units, SC and DiD have **different identifying assumptions** and therefore **different observed data functionals**.

**DiD Identification:**
- Assumption: Parallel trends
  - E[Y_t(0) - Y_{t-1}(0) | D=1] = E[Y_t(0) - Y_{t-1}(0) | D=0]
- Observed data functional:
  - θ_{DiD} = E[Y_t | D=1] - E[Y_t | D=0] - (E[Y_{pre} | D=1] - E[Y_{pre} | D=0])
- EIF: Available in DiD literature

**SC Identification:**
- Assumption: Conditional parallel trends given pre-treatment outcomes
  - E[Y_t(0) | D=1, Y_{pre}] = E[Y_t(0) | D=0, Y_{pre}]
  - (i.e., conditional on pre-treatment path, treated and control have same expected counterfactual)
- Observed data functional:
  - θ_{SC} = E[E[Y_t | D=0, Y_{pre}] | D=1]
  - This is a **reweighting/matching functional** conditioning on Y_{pre}
- EIF: **Not available** (this is what you're proposing!)

### The SC Functional More Precisely

Estimand: ATT_t = E[Y_t(1) - Y_t(0) | D=1]

Observable: E[Y_t(1) | D=1] (just average treated outcomes)

Need to identify: E[Y_t(0) | D=1]

SC gives us:
```
E[Y_t(0) | D=1] = E[E[Y_t(0) | D=0, Y_{pre}] | D=1]
                = ∫ m(y_{pre}) dF(y_{pre} | D=1)
```

where:
- m(y_{pre}) = E[Y_t | D=0, Y_{pre} = y_{pre}] (outcome model among controls)
- F(y_{pre} | D=1) = distribution of pre-treatment paths among treated

**This is a reweighting functional** where:
- Nuisance 1: m(y_{pre}) (outcome model, high-dimensional conditioning)
- Nuisance 2: F(y_{pre} | D=1) (could be empirical distribution, or could model propensity for Y_{pre})

### Why This Is Different from DiD

DiD doesn't condition on Y_{pre} in the identifying assumption. It uses:
```
E[Y_t(0) | D=1] = E[Y_t | D=0] + [E[Y_{pre} | D=1] - E[Y_{pre} | D=0]]
```

This is a **difference** functional, not a **reweighting** functional.

SC conditions on full pre-treatment trajectory, which:
- Allows violations of parallel trends (treated and control can have different trends unconditionally)
- Requires matching on high-dimensional Y_{pre}
- Changes the observed data functional and therefore the EIF

## Deriving the EIF for the SC Functional

### Setup

**Data:** (Y_{it}, D_i, X_i) for i = 1, ..., N; t = 1, ..., T
- Y_{it}: Outcome
- D_i ∈ {0,1}: Treatment indicator
- Y_{i,pre} = (Y_{i1}, ..., Y_{i,T_0}): Pre-treatment outcomes
- X_i: Baseline covariates (optional)

**Parameter:**
```
θ = E[Y_t(0) | D=1] = ∫ m(y_{pre}, x) dF(y_{pre}, x | D=1)
```

**Nuisances:**
- η_1 = m(y_{pre}, x) = E[Y_t | D=0, Y_{pre} = y_{pre}, X = x]
- η_2 = e(y_{pre}, x) = P(D=1 | Y_{pre} = y_{pre}, X = x) [generalized propensity score]
  - Note: In SC, we often don't model e explicitly, but it's implicit in the reweighting

### EIF for Covariate-Adjusted ATT

For the functional θ = E[m(Y_{pre}, X) | D=1], the EIF is:

```
ψ(O; θ, η) = D/P(D=1) · [Y_t - m(Y_{pre}, X)]                  [treated residual]
           + (1-D) · e(Y_{pre}, X)/(1-e(Y_{pre}, X)) · [Y_t - m(Y_{pre}, X)]  [control contribution]
           + D/P(D=1) · [m(Y_{pre}, X) - θ]                    [centering]
```

This has three terms:
1. **Treated residual:** How much do treated outcomes differ from predicted m?
2. **Control contribution:** Reweighted control residuals (like importance sampling)
3. **Centering:** Makes ψ mean zero

### Doubly Robust Property

If either:
- m is correctly specified, OR
- e is correctly specified

Then θ̂ is consistent and asymptotically normal with variance = Var(ψ).

### SC as Estimating These Nuisances

**Standard SC:**
- Estimates m̂(y_{pre}, x) implicitly via weights: m̂(y_{pre}, x) = Σ_i w_i(y_{pre}, x) Y_{it}
- Where weights minimize pre-treatment fit: ||Y_{pre} - Σ_i w_i Y_{i,pre}||
- Doesn't explicitly model e (assumes uniform or uses implicit weighting)

**Augmented SC:**
- Estimates m̂ via outcome regression (ridge, factor models, etc.)
- Uses SC weights as implicit propensity score weights
- This is the "augmented" part (bias correction)

### The Contribution

**What's new:**
1. SC identifies a different functional than DiD (conditional on Y_{pre}, not parallel trends)
2. That functional has an EIF (derived above)
3. SC methods are estimating the nuisances (m and e) in that EIF
4. We can use the EIF directly for variance estimation

**Why existing SC inference fails:**
- Ad-hoc methods (placebo, permutation) don't account for nuisance estimation uncertainty
- Existing variance estimators ignore that weights ŵ are estimated
- EIF-based variance properly accounts for:
  - Estimation of m
  - Estimation of weights (implicit propensity score)
  - Double robustness

### Path 2: Panel EIF with Factor Models

Arkhangelsky et al. (2021) SDID uses factor models for the outcome.

Could we:
- Specify a panel factor model for Y_{it}(0)
- Derive EIF for parameters of that model
- Use factor model to predict Y_{1t}(0)
- Propagate uncertainty through EIF

This feels closer to what you're doing in your current paper (model-based extrapolation with EIF for variance).

### Path 3: Conditional Inference Given Pre-Treatment Data

Fix Y_{1,1:(T_0)} = y_0 (condition on observed pre-treatment path).

Estimand: E[Y_{1t}(0) | Y_{1,1:(T_0)} = y_0]

If we assume:
- Y_{it}(0) ~ some distribution (Gaussian process? factor model?)
- Control units inform this distribution
- Want: E[Y_{1t}(0) | Y_{1,1:(T_0)} = y_0, {Y_{it}}_{i≥2}]

This is a prediction problem. Could derive EIF for prediction under a specific model.

But this requires specifying the generative model for Y_{it}(0), which SC typically avoids.

## Practical Challenges

### Challenge 1: High-Dimensional Y_{pre}

Y_{pre} = (Y_{i1}, ..., Y_{i,T_0}) is typically high-dimensional:
- T_0 ~ 10-50 time periods
- Estimating m(y_{pre}) = E[Y_t | D=0, Y_{pre} = y_{pre}] is a high-dimensional regression
- Need regularization, dimension reduction, or structural assumptions

**Solutions SC uses:**
- Factor models (SDID, Matrix Completion SC)
- Matching/weighting (implicitly estimates m via weighted average)
- Sparsity assumptions (some SC variants)

**EIF perspective:**
- These are all ways to estimate the nuisance m
- EIF-based variance should account for estimation uncertainty in whichever method you use
- Could use cross-fitting to reduce overfitting bias

### Challenge 2: Small N

SC applications often have:
- N_treated ~ 1-10
- N_control ~ 10-50

This creates problems:
- Estimating m with N_control ~ 10 is unstable
- Asymptotic approximations (CLT for EIF) may not hold
- Cross-fitting becomes difficult

**Possible solutions:**
- Bootstrap instead of asymptotic approximation
- Structured models (factor models, time series) to reduce effective dimensionality
- Acknowledge this is a large-N method (N ≥ 50?)

### Challenge 3: Generalized Propensity Score e(Y_{pre}, X)

The term e(Y_{pre}, X) = P(D=1 | Y_{pre}, X) is:
- High-dimensional (conditioning on Y_{pre})
- Often not identifiable (if Y_{pre} is continuous and high-dim, density estimation is hard)
- SC methods typically don't estimate this explicitly

**Solutions:**
- Assume e is constant (ignorable) → simplifies EIF
- Use inverse probability weighting implicitly through SC weights
- Frame as matching-on-covariate problem (don't need propensity score)

Actually, for covariate-adjusted ATT when **all units are observed** (not missing data problem):

```
θ = E[Y_t(1) - Y_t(0) | D=1]
  = E[Y_t(1) | D=1] - E[E[Y_t(0) | Y_{pre}, X] | D=1]
```

The EIF simplifies to:
```
ψ = (Y_t - θ - m(Y_{pre}, X)) · D/P(D=1)
  + (m(Y_{pre}, X) - E[m(Y_{pre}, X) | D=1]) · D/P(D=1)
  + (Y_t - m(Y_{pre}, X)) · (1-D) · [reweighting term]
```

The propensity score e enters through the reweighting term for controls.

If we just use **empirical distribution of Y_{pre} | D=1** (no need to model it), we might avoid estimating e entirely.

### Challenge 4: Single Treated Unit

If N_treated = 1:
- No randomness in "treated population"
- Can't estimate E[⋅ | D=1] with one observation
- EIF doesn't apply in standard form

**Solution:**
- Treat as **prediction problem**: predict Y_{1t}(0) given Y_{1,pre}
- Use **conditional EIF**: given Y_{1,pre} = y_0, what's the EIF for E[Y_t | D=0, Y_{pre} = y_0]?
- Or use **design-based inference** (placebo, permutation) instead

This might be why SC typically uses design-based methods.

## Where Does This Break?

Updated assessment:

1. **Multiple treated units (N_treated ≥ 10):** EIF approach should work. This is a genuine contribution.

2. **Small N_control (< 50):** Nuisance estimation is unstable. May need:
   - Strong structural assumptions (factor models)
   - Bootstrap instead of asymptotics
   - Or acknowledge method needs larger N

3. **Single treated unit:** EIF for ATT doesn't apply. Need conditional prediction framework or design-based inference.

4. **High-dimensional Y_{pre}:** Need dimension reduction or regularization. SC methods already do this (implicitly). EIF perspective: these are nuisance estimation strategies.

## Concrete Implementation

### Algorithm: EIF-Based SC Inference

**Input:**
- (Y_{it}, D_i, X_i) for i = 1, ..., N; t = 1, ..., T
- T_0 = pre-treatment periods
- t_target = post-treatment period of interest

**Step 1: Estimate outcome model m̂**

Option A (SC-style):
- For each treated unit i with D_i=1:
  - Find weights ŵ_{i,j} for controls j with D_j=0
  - Minimize ||Y_{i,pre} - Σ_j w_{i,j} Y_{j,pre}||^2 subject to w ≥ 0, Σw=1
  - Set m̂(Y_{i,pre}, X_i) = Σ_j ŵ_{i,j} Y_{j,t_target}

Option B (Augmented SC):
- Fit outcome model μ̂(Y_{pre}, X, t) on controls (e.g., ridge, factor model, random forest)
- For treated unit i: m̂(Y_{i,pre}, X_i) = μ̂(Y_{i,pre}, X_i, t_target)
- Use SC weights for bias correction (if needed)

Option C (Cross-fitted):
- Split controls into K folds
- For each fold k:
  - Fit μ̂^{(-k)} on other K-1 folds
  - Predict for fold k and treated units
- Average predictions

**Step 2: Estimate ATT**

```
θ̂ = (1/N_1) Σ_{i:D_i=1} Y_{i,t_target} - (1/N_1) Σ_{i:D_i=1} m̂(Y_{i,pre}, X_i)
```

where N_1 = number of treated units.

**Step 3: Compute EIF-based variance**

For each observation i:
```
ψ̂_i = D_i/P̂(D=1) · [Y_{i,t} - m̂(Y_{i,pre}, X_i)]           [treated residual]
     + D_i/P̂(D=1) · [m̂(Y_{i,pre}, X_i) - θ̂]                  [treated centering]
     + (1-D_i) · [contribution from control i]               [control contribution]
```

For the control contribution:
- If using SC weights: reweight by how much control i contributes to each treated unit's synthetic control
- If using propensity score: weight by ê(Y_{i,pre}, X_i)

Variance estimate:
```
V̂ = (1/N) Σ_i ψ̂_i^2
```

Standard error: SE = √V̂

**Step 4: Inference**

95% CI: θ̂ ± 1.96 · SE

### Comparison to Existing SC Inference

**Existing methods:**

1. **Placebo inference:**
   - Apply SC to control units (pretend they're treated)
   - Compare treated estimate to placebo distribution
   - Problems: Doesn't account for nuisance estimation, small N issues

2. **Conformal inference:**
   - Predict Y_t for controls, compute residuals
   - Use residual distribution for inference
   - Problems: Assumes exchangeability, no formal variance theory

3. **Bootstrap:**
   - Resample units, recompute SC
   - Problems: With small N, unstable; doesn't account for correct uncertainty source

4. **Bayesian:**
   - Put prior on m, integrate
   - Problems: Prior-dependent, computationally intensive

**EIF-based method:**
- Accounts for nuisance estimation (m̂)
- Doubly robust (if m or e correct, inference valid)
- Standard asymptotic theory (as N → ∞)
- Computationally simple (closed form)

### When Would This Work Better?

**Settings where EIF should dominate:**
- **Large N:** N ≥ 50 (controls + treated)
- **Multiple treated units:** N_treated ≥ 10
- **Good outcome model:** Can estimate m(Y_{pre}, X) reasonably (factor model, smooth model, etc.)
- **Staggered adoption:** Multiple treatment times, many post-treatment periods

**Settings where EIF might struggle:**
- **Small N:** N_control < 20 (asymptotic approximation fails)
- **Single treated unit:** No variation in D=1 population
- **Terrible outcome model:** If m is completely misspecified and e is also wrong (loses double robustness)
- **Curse of dimensionality:** T_0 very large, no structure in Y_{pre}

## Next Steps

### Theoretical Work

1. **Formal identification:**
   - State SC identifying assumptions precisely
   - Show observed data functional is identified
   - Verify conditions for EIF derivation

2. **Derive EIF:**
   - For the specific SC functional (done above, but formalize)
   - Account for high-dimensional Y_{pre} (dimension reduction via factor models?)
   - Address single-unit case (conditional EIF? or declare out of scope)

3. **Asymptotic theory:**
   - Under what conditions is θ̂ consistent?
   - What rate does m̂ need to converge at?
   - How does high-dimensionality of Y_{pre} affect rates?
   - Product limit (like Chernozhukov et al. 2018): m̂ rate × N^{-1/2}

### Empirical Work

1. **Simulation study:**
   - DGPs with violations of parallel trends (SC allowed, DiD not)
   - Vary: N, N_treated, T_0, signal-to-noise
   - Compare coverage: EIF vs. placebo vs. conformal vs. bootstrap vs. Bayesian

2. **Empirical applications:**
   - Reanalyze existing SC applications with multiple treated units
   - Compare inference: EIF vs. published methods
   - Check if conclusions change (wider/narrower CIs?)

3. **Sensitivity to nuisance estimation:**
   - Try different m̂ estimators (SC weights, factor models, ridge, random forest)
   - Does EIF variance properly account for misspecification?
   - Test double robustness empirically

### Software

Implement in R package:
```r
sc_eif_inference <- function(Y, D, X, pre_periods, post_period,
                             outcome_model = c("sc_weights", "factor", "ridge"),
                             cross_fit = TRUE) {
  # Returns: estimate, se, ci
}
```

## Connection to Current Project (extrapolateATT)

### Similarities

1. **EIF-based variance estimation:**
   - Current project: EIF for extrapolated ATT
   - SC project: EIF for SC estimand
   - Both propagate uncertainty through nuisance estimation

2. **Conditioning on pre-treatment:**
   - Current project: Extrapolate conditional on pre-treatment group-time ATTs
   - SC project: Predict counterfactual conditional on pre-treatment outcomes
   - Both condition on high-dimensional pre-treatment information

3. **Model-based inference:**
   - Current project: Temporal model (linear, AR, spline) + EIF
   - SC project: Outcome model m(Y_{pre}) + EIF
   - Both require estimating models and propagating uncertainty

### Differences

1. **Estimand:**
   - Current project: Future ATT (extrapolation beyond observed periods)
   - SC project: Contemporaneous ATT (matching on observed controls)

2. **Identification:**
   - Current project: Extrapolation model for τ_{gt} + conditional independence
   - SC project: Conditional parallel trends given Y_{pre}

3. **Structure:**
   - Current project: Time series structure (τ_{g,t-1} → τ_{gt})
   - SC project: Cross-sectional matching (Y_{i,pre} → Y_{it})

4. **Multiple treatment groups:**
   - Current project: Yes (staggered adoption, group-time ATTs)
   - SC project: Often single treated unit (but this paper focuses on multiple)

### Why These Are Separate Papers

**Current paper (extrapolateATT):**
- **Novel estimand:** Future ATT beyond observed periods
- **Contribution:** Extrapolation + EIF-based uncertainty for time-extended effects
- **Application:** Long-term policy effects, forecasting treatment impacts

**SC EIF paper:**
- **Novel framing:** SC identifies covariate-adjusted ATT (not DiD)
- **Contribution:** EIF for SC functional + principled inference
- **Application:** Improving inference in existing SC applications

**Overlap:** Both use EIF machinery for causal inference with conditioning on high-dimensional pre-treatment information. But estimands and identifying assumptions differ.

**Potential synergy:** Methods from current project (outcome model estimation, EIF variance) could inform SC EIF implementation. Could cite current paper as example of EIF-based inference in causal settings.

## Literature to Check

### Must-read (SC inference)
- Ben-Michael, Feller, Rothstein (2021) - Augmented Synthetic Control
  - **Preliminary finding:** Package uses **conformal inference** for CIs, not EIF-based variance
  - Need to verify: Do they derive EIF in paper? Or only for point estimation (doubly robust)?
  - Their augmented estimator has doubly robust **point estimation**, but unclear about inference
- Arkhangelsky et al. (2021) - Synthetic Difference-in-Differences
- Abadie, Diamond, Hainmueller (2010, 2015) - Original SC papers
- Ferman & Pinto (2021) - Synthetic controls with imperfect pretreatment fit
- Chernozhukov et al. (2021) - Synthetic controls with inference

### Must-read (EIF / semiparametric)
- Hahn (1998) - Role of propensity score in efficient estimation
- Hahn, Hirano, Karlan (2011) - Adaptive experimental design
- Chernozhukov et al. (2018) - Double/debiased ML
- Kennedy (2016, 2022) - Semiparametric theory
- Robins, Li, Tchetgen, van der Vaart (2008) - Higher order influence functions

### Must-read (DiD with covariates)
- Callaway & Sant'Anna (2021) - DiD with multiple periods
- Roth & Sant'Anna (2023) - Efficient estimation for event studies
- Sant'Anna & Zhao (2020) - Doubly robust DiD
- Chang (2020) - Pre-test with caution
- Imai & Kim (2021) - On the use of two-way fixed effects

### Must-read (covariate balancing)
- Hainmueller (2012) - Entropy balancing
- Imai & Ratkovic (2014) - Covariate balancing propensity score
- Zhao (2019) - Covariate balancing using propensity scores

### Panel data / factor models
- Bai (2009) - Panel data models with interactive fixed effects
- Xu (2017) - Generalized synthetic control
- Gobillon & Magnac (2016) - Regional policy evaluation

## Paper Outline

### Title Options
- "Efficient Inference for Synthetic Control Methods"
- "EIF-Based Variance Estimation for Covariate-Matched Causal Effects"
- "Beyond Parallel Trends: Efficient Inference with Pre-Treatment Matching"

### Abstract (Draft)

Synthetic control (SC) methods estimate treatment effects by matching treated units to weighted combinations of controls based on pre-treatment outcomes. Unlike difference-in-differences, SC does not require parallel trends, instead conditioning on the full pre-treatment trajectory. Despite SC's popularity, inference remains challenging: existing methods rely on ad-hoc approaches (placebo tests, conformal inference, bootstrap) that often fail to provide valid coverage.

We show that SC identifies a covariate-adjusted average treatment effect (ATT) functional where pre-treatment outcomes serve as high-dimensional covariates. This functional has an efficient influence function (EIF) that accounts for estimation uncertainty in the outcome model and treatment probability. We derive the EIF for the SC estimand and show it leads to doubly robust inference: if either the outcome model or treatment propensity is correctly specified, inference is valid.

We propose EIF-based variance estimation for SC and compare it to existing methods in simulations and empirical applications. Results show EIF-based inference provides better coverage than placebo or conformal methods when sample sizes are moderate (N ≥ 50) and outcome models are correctly specified. We discuss extensions to staggered adoption settings and provide R software implementing the method.

### Section 1: Introduction

- SC is popular but inference is hard
- Existing methods (placebo, conformal, bootstrap) often fail in simulations
- Key insight: SC ≠ DiD (different identifying assumptions)
- Our contribution: EIF for SC estimand → principled inference

### Section 2: Setup and Identification

- Panel data: (Y_{it}, D_i, X_i)
- Estimand: ATT = E[Y_t(1) - Y_t(0) | D=1]
- DiD identification vs. SC identification
  - DiD: Parallel trends (unconditional)
  - SC: Conditional parallel trends given Y_{pre}
- Observed data functional for SC:
  - θ = ∫ m(y_{pre}) dF(y_{pre} | D=1)
  - Different from DiD functional!

### Section 3: Efficient Influence Function

- Semiparametric theory background (brief)
- Nuisance parameters:
  - m(y_{pre}, x) = E[Y_t | D=0, Y_{pre}, X]
  - e(y_{pre}, x) = P(D=1 | Y_{pre}, X)
- Derivation of EIF for SC functional
- Doubly robust property
- Asymptotic normality under regularity conditions

### Section 4: Estimation and Inference

- Algorithm:
  1. Estimate m̂ (SC weights, factor model, ridge, etc.)
  2. Estimate θ̂ (augmented SC estimator)
  3. Compute ψ̂_i for each unit
  4. Variance: V̂ = (1/N) Σ ψ̂_i^2
- Cross-fitting to avoid overfitting bias
- Comparison to existing SC estimators (ADH, SDID, Augmented SC)
- Connection: Augmented SC ≈ EIF-based estimation (but not for inference)

### Section 5: Simulations

- DGPs:
  - Parallel trends hold (SC and DiD both valid)
  - Parallel trends violated but conditional parallel trends hold (SC valid, DiD not)
  - Factor models (SDID setting)
  - High-dimensional Y_{pre}
- Vary: N, N_treated, T_0, signal-to-noise
- Metrics: Coverage, CI width, power
- Comparisons: EIF vs. placebo vs. conformal vs. bootstrap vs. ADH uncertainty
- Show: EIF dominates when N ≥ 50, multiple treated units

### Section 6: Empirical Applications

- Reanalyze 2-3 published SC applications with multiple treated units
- Compare CIs: EIF vs. published methods
- Do conclusions change?
- Sensitivity to outcome model choice

### Section 7: Extensions

- Staggered adoption (multiple treatment times)
- Single treated unit (conditional prediction framework)
- Alternative EIF estimators (different m̂ strategies)
- Small-N adjustments (bootstrap, robust variance)

### Section 8: Discussion

- When does this work? (N ≥ 50, multiple treated, good m̂)
- When does it fail? (Small N, single treated, terrible m̂)
- Comparison to DiD: Different identifying assumptions matter
- Software and implementation

## Final Assessment

### Is This a Paper?

**Yes, this is a genuine contribution:**

1. **Novel framing:** SC estimates a different functional than DiD (conditioning on Y_{pre})
2. **Theory:** EIF for that functional has not been derived in SC literature
3. **Practice:** Existing SC inference methods are ad-hoc and often fail
4. **Impact:** Many applications have multiple treated units where this applies

### Where This Could Get Stuck

1. **It might already exist somewhere:**
   - Check augmented SC papers carefully (Ben-Michael et al., Arkhangelsky et al.)
   - Check covariate balancing literature (Hainmueller, Imai, etc.)
   - Check semiparametric panel data literature

2. **Small N is a killer:**
   - Most SC applications have N_control ~ 10-30
   - Asymptotic theory requires N ≥ 50 (rough threshold)
   - Might need to position as "when you have enough units" method

3. **Single treated unit:**
   - Very common in SC applications (California, Basque Country, etc.)
   - EIF for ATT doesn't apply (no variation in treated population)
   - Need conditional prediction framework (messier theory)

4. **High-dimensional Y_{pre}:**
   - T_0 ~ 10-50 is common
   - Need strong assumptions or dimension reduction
   - Factor models help but add complexity

### What Would Make This Strong

1. **Clear differentiation from DiD:**
   - Emphasize SC allows violations of parallel trends
   - Show simulations where DiD fails, SC works, EIF gives valid inference

2. **Practical performance:**
   - Not just theory - show empirically that coverage improves
   - Compare to *all* existing methods (placebo, conformal, bootstrap, Bayesian)
   - Identify settings where it dominates

3. **Software:**
   - Clean R package implementing EIF-based SC inference
   - Interface with existing SC packages (Synth, augsynth, gsynth)

4. **Empirical validation:**
   - Reanalyze 3-5 published applications
   - Show CIs are often too narrow/too wide with existing methods
   - EIF provides more principled uncertainty

### Positioning

**Audience:** Econometrics / causal inference
**Venue:** Journal of Econometrics, Econometric Theory, JASA, Biometrika

**Framing:**
- SC is widely used but inference is problematic
- Key insight: SC identifies a different functional than DiD
- EIF provides principled inference for that functional
- Works when N is large enough and outcome models are reasonable

**Not framing as:**
- "SC is wrong" - it's not, inference just needs theory
- "DiD is wrong" - different identifying assumptions, both valid
- "Always use this" - only works in certain settings (moderate N, multiple treated)

## Open Questions

1. **Does this already exist?**
   - Need comprehensive literature review
   - Check: augmented SC, covariate balancing, semiparametric panel data

2. **Can we handle single treated unit?**
   - Conditional EIF given Y_{1,pre} = y_0?
   - Design-based inference instead?
   - Or declare out of scope?

3. **What's the N threshold?**
   - Simulations needed to determine when asymptotic approximation works
   - N ≥ 50? N ≥ 100?
   - Bootstrap for small N?

4. **How sensitive to m̂ misspecification?**
   - Need double robustness to work
   - What if both m and e are wrong? (not unusual with high-dim Y_{pre})
   - Can we make this more robust?

---

**Bottom line:** This IS a real contribution. SC identifies a different functional than DiD, that functional has an EIF, and existing SC inference ignores it. The main challenges are: (1) small N in typical applications, (2) single treated unit case, (3) high-dimensional Y_{pre}. But with multiple treated units and moderate N, this should work and provide better inference than existing ad-hoc methods.

## Preliminary Literature Check: Ben-Michael et al. (2021)

**Date checked:** 2026-03-04

### What We Found

From the `augsynth` R package documentation (vignette):

**Inference methodology:**
- Uses **conformal inference** for confidence intervals (default)
  - Reference: [Lei et al. 2018 conformal inference paper](https://arxiv.org/abs/1712.09089)
- Alternative: Jackknife+ procedure (requires additional assumptions)
- Implementation: `plot(syn)` uses conformal inference automatically

**What they say about estimation:**
- "Augmented synthetic control" provides bias correction
- They estimate "the overall bias of synth" via augmentation
- Focus on **doubly robust point estimation** (outcome model OR SC weights)

**What's NOT in the vignette:**
- No mention of efficient influence function (EIF)
- No discussion of semiparametric variance estimation
- No EIF-based confidence intervals
- Inference is via conformal/jackknife, not asymptotic theory

### Critical Question

**Did Ben-Michael et al. derive the EIF but not use it for inference?**

Two possibilities:

1. **They derived EIF for point estimation only:**
   - Showed their estimator is doubly robust (point estimation)
   - Proved asymptotic linearity (if nuisances are consistent)
   - But used conformal inference for practical CIs (finite-sample, distribution-free)
   - EIF exists in theory section but not used for variance

2. **They didn't derive the EIF at all:**
   - Focused on bias correction (augmentation)
   - Proved double robustness via direct argument (not EIF)
   - Used conformal inference because no asymptotic theory available

**Need to verify:** Read the JASA paper Section on "Asymptotic Theory" or "Inference"

### Implication for Our Project

If Ben-Michael et al.:
- **Have the EIF but don't use it:** Our contribution is "use EIF for inference, not conformal"
- **Don't have the EIF:** Our contribution is "derive EIF for SC functional + inference"

Either way, **EIF-based inference for SC appears to be novel**.

### Why Conformal Instead of EIF?

Possible reasons augsynth uses conformal:

1. **Small N:** Conformal works with N ~ 10-30 (no asymptotics needed)
2. **Distribution-free:** No normality assumptions
3. **Finite-sample:** Valid coverage in finite samples
4. **Practical:** Easy to implement, robust

But conformal has limitations:
- **Wider CIs:** Conservative, especially with small N
- **No efficiency:** Not using semiparametric efficiency
- **Exchangeability:** Requires strong assumptions
- **Power:** Less powerful than asymptotic methods when N is large

**Our contribution:** EIF-based inference for **moderate-to-large N** (N ≥ 50) where asymptotic approximations work and efficiency matters.

## Actionable Next Steps

### Phase 1: Verify Novelty (1-2 weeks)

**Goal:** Confirm this isn't already in the literature

1. **Read augmented SC papers carefully:**
   - Ben-Michael et al. (2021) - Do they derive EIF? Or just use augmented estimator?
   - Arkhangelsky et al. (2021) - SDID uses factor models, do they have EIF?
   - Check their inference sections - are they using EIF-based variance?

2. **Check covariate balancing literature:**
   - Hainmueller, Imai, Zhao papers
   - Do they derive EIF for high-dimensional covariate matching?

3. **Check recent DiD papers:**
   - Roth & Sant'Anna (2023) - event study efficiency
   - Callaway & Sant'Anna (2021) - do they cover SC-style identification?

4. **Email colleagues:**
   - Ask causal inference people: "Is EIF for SC functional already derived?"
   - Get informal feedback before investing heavily

**Output:** 2-3 page memo: "What's novel, what exists, where's the gap"

### Phase 2: Simple Proof of Concept (2-3 weeks)

**Goal:** Show this can work empirically, even if theory is rough

1. **Simplest possible simulation:**
   - N = 100 (50 treated, 50 control)
   - T_0 = 10 (pre-treatment periods)
   - DGP: Factor model or AR(1) for Y_{it}(0)
   - Violates parallel trends but satisfies conditional parallel trends

2. **Implement EIF-based inference:**
   - Use SC weights or ridge regression for m̂
   - Compute ψ̂_i
   - Variance: V̂ = (1/N) Σ ψ̂_i^2
   - 95% CI: θ̂ ± 1.96√V̂

3. **Compare to baselines:**
   - Placebo inference (ADH style)
   - Conformal inference
   - Bootstrap (if feasible)
   - DiD (should fail because parallel trends violated)

4. **Metric:** Coverage rate over 1000 simulations
   - Target: 95% coverage for EIF
   - Show: Placebo/conformal have poor coverage

**Output:** Working R code + simulation showing EIF dominates

### Phase 3: Theory Development (4-6 weeks)

**Goal:** Formalize identification and derive EIF rigorously

1. **Write formal setup:**
   - Data: (Y_{it}, D_i, X_i), i = 1, ..., N; t = 1, ..., T
   - Estimand: ATT_t = E[Y_t(1) - Y_t(0) | D=1]
   - Identification: Conditional parallel trends + support

2. **Derive EIF:**
   - Define statistical model (what's nonparametric? what's assumed?)
   - Identify nuisances: m(y_{pre}, x), possibly e(y_{pre}, x)
   - Follow Kennedy (2016) or Chernozhukov et al. (2018) approach
   - Verify pathwise differentiability

3. **Asymptotic theory:**
   - Conditions for √N(θ̂ - θ) →^d N(0, V)
   - Rate requirements for m̂ (e.g., ||m̂ - m|| = o_P(N^{-1/4}))
   - High-dimensional Y_{pre}: need dimension reduction or structure

4. **Double robustness:**
   - Show: If m correct OR e correct, then inference valid
   - This is key selling point

**Output:** Theory section (10-15 pages) with formal propositions and proofs

### Phase 4: Comprehensive Simulations (3-4 weeks)

**Goal:** Map out when this works and when it doesn't

1. **Vary key parameters:**
   - N: 20, 50, 100, 200, 500
   - N_treated / N_total: 0.1, 0.25, 0.5
   - T_0: 5, 10, 20, 50
   - Signal-to-noise ratio
   - Outcome model: factor, AR(1), nonlinear, misspecified

2. **DGPs:**
   - Parallel trends hold (SC and DiD both valid)
   - Parallel trends violated, conditional parallel trends hold (SC valid only)
   - Conditional parallel trends violated (SC invalid)
   - Staggered adoption (multiple treatment times)

3. **Inference methods:**
   - EIF (ours)
   - Placebo (ADH)
   - Conformal
   - Bootstrap
   - DiD (for comparison)
   - Oracle (if possible)

4. **Metrics:**
   - Coverage (target: 95%)
   - CI width (shorter better, if coverage maintained)
   - Power (reject H_0 when treatment effect ≠ 0)

**Output:** Comprehensive simulation section (8-10 pages) + figures/tables

### Phase 5: Empirical Applications (2-3 weeks)

**Goal:** Show this matters in real data

1. **Find suitable applications:**
   - Need: Multiple treated units (N_treated ≥ 10)
   - Need: Published SC study with reported inference
   - Candidates:
     - Medicaid expansion (multiple states, staggered)
     - Minimum wage studies (multiple cities)
     - School interventions (multiple districts)

2. **Reanalyze 2-3 applications:**
   - Replicate original SC estimates
   - Compute EIF-based CIs
   - Compare to published CIs

3. **Report:**
   - Original CI: [a, b]
   - EIF CI: [c, d]
   - Interpretation: Wider/narrower? Conclusion change?
   - Sensitivity to m̂ specification

**Output:** Empirical section (6-8 pages)

### Phase 6: Write Paper (4-6 weeks)

**Goal:** Polished draft ready for submission

1. **Introduction** (5 pages):
   - Motivation: SC popular but inference is hard
   - Key insight: SC ≠ DiD (different functionals)
   - Our contribution: EIF for SC + inference
   - Roadmap

2. **Setup** (4 pages):
   - Panel data, estimand, identification
   - Comparison to DiD

3. **Theory** (12-15 pages):
   - Semiparametric model
   - EIF derivation
   - Asymptotic theory
   - Double robustness

4. **Estimation** (5 pages):
   - Algorithm
   - Cross-fitting
   - Connection to augmented SC

5. **Simulations** (10 pages):
   - Design, results, discussion

6. **Empirical** (8 pages):
   - Applications, results, sensitivity

7. **Discussion** (3 pages):
   - When to use this
   - Limitations
   - Extensions

**Output:** 50-55 page paper

### Phase 7: Software (3-4 weeks, parallel with Phase 6)

**Goal:** Usable R package

```r
library(sceif)  # synthetic control EIF

# Basic usage
result <- sc_eif(
  data = panel_data,
  outcome = "Y",
  treatment = "D",
  unit = "id",
  time = "t",
  pre_periods = 1:10,
  post_period = 15,
  outcome_model = "sc_weights"  # or "factor", "ridge"
)

summary(result)
# ATT estimate, SE, 95% CI

# Compare to other methods
compare_inference(result, methods = c("placebo", "conformal", "bootstrap"))
```

**Features:**
- Core: EIF-based variance
- Outcome models: SC weights, factor, ridge, random forest
- Cross-fitting option
- Comparison to existing methods
- S3 classes with print/summary/plot methods

**Output:** R package on GitHub, submitted to CRAN

---

## Decision Points

**After Phase 1 (novelty check):**
- **Stop if:** This already exists in augmented SC literature
- **Pivot if:** Close to existing work, but can extend/improve
- **Continue if:** Novel contribution confirmed

**After Phase 2 (proof of concept):**
- **Stop if:** EIF doesn't empirically beat existing methods
- **Pivot if:** Works only in very narrow settings
- **Continue if:** EIF shows clear improvement in realistic settings

**After Phase 4 (simulations):**
- **Stop if:** Method only works when N ≥ 500 (too restrictive)
- **Adjust scope if:** Works well for N ≥ 50, document threshold
- **Continue if:** Performs well in settings relevant to empirical practice

---

## Timeline Estimate

**Conservative (careful development):**
- Phase 1: 2 weeks
- Phase 2: 3 weeks
- Decision: Continue? (+1 week)
- Phase 3: 6 weeks
- Phase 4: 4 weeks
- Phase 5: 3 weeks
- Phase 6: 6 weeks
- Phase 7: 4 weeks (parallel with Phase 6)
- **Total: 29 weeks (~7 months)**

**Aggressive (assuming novelty confirmed quickly):**
- Phase 1: 1 week
- Phase 2: 2 weeks
- Phase 3: 4 weeks
- Phase 4: 3 weeks
- Phase 5: 2 weeks
- Phase 6: 4 weeks
- Phase 7: 3 weeks (parallel)
- **Total: 19 weeks (~4.5 months)**

---

## Investment Decision

**Low-risk first step:** Phase 1 (novelty check) + Phase 2 (proof of concept) = 4-5 weeks

If these confirm:
1. It's novel
2. It works empirically

Then this is worth pursuing as a standalone paper.

**Compatibility with current project:** These are independent papers. Could work on SC EIF as a "side project" while main extrapolation paper is under review.

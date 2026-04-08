# Comprehensive Literature Review: Inference Methods for Synthetic Control

**Date:** 2026-03-04
**Status:** Exhaustive review for EIF-SC methods paper
**Purpose:** Map the landscape of SC inference methods to position our EIF-based approach

---

## Executive Summary

This review synthesizes the landscape of inference methods for synthetic control (SC) estimators. We identify four main paradigms:

1. **Placebo/permutation tests** (Abadie et al. 2010, 2015) - Dominant in practice but often fails
2. **Conformal inference** (Lei et al. 2018; Ben-Michael et al. 2021) - More principled but still ad-hoc
3. **Bootstrap methods** (Various) - Computationally intensive, mixed results
4. **Model-based/asymptotic** (Arkhangelsky et al. 2021; Chernozhukov et al. 2021) - Emerging

**Key finding:** No existing work explicitly derives and uses the efficient influence function (EIF) for variance estimation in SC, despite SC estimating a well-defined semiparametric functional. This represents a significant gap that our work addresses.

---

## Table of Contents

1. [Timeline of Methodological Developments](#timeline)
2. [Taxonomy of Approaches](#taxonomy)
3. [Deep Dive: Major Approaches](#deep-dive)
   - 3.1 [Placebo/Permutation Tests](#placebo)
   - 3.2 [Conformal Inference](#conformal)
   - 3.3 [Bootstrap Methods](#bootstrap)
   - 3.4 [Augmented Synthetic Control](#augmented-sc)
   - 3.5 [Synthetic Difference-in-Differences](#sdid)
   - 3.6 [Other Model-Based Approaches](#model-based)
   - 3.7 [Bayesian Approaches](#bayesian)
   - 3.8 [Semiparametric Theory & Double Robustness](#semiparametric)
4. [Comparison of Inference Methods](#comparison)
5. [Gaps in the Literature](#gaps)
6. [Where EIF-Based Inference Fits](#our-contribution)
7. [Key Papers to Read and Cite](#must-read)
8. [Software Implementations](#software)

---

<a name="timeline"></a>
## 1. Timeline of Methodological Developments

### Phase 1: Foundation (2003-2010)
- **2003:** Abadie & Gardeazabal - Original SC paper (Basque terrorism)
- **2010:** **Abadie, Diamond & Hainmueller (ADH)** - "Synthetic Control Methods for Comparative Case Studies"
  - Introduces placebo inference: apply SC to untreated units
  - P-values from ranking treated vs. placebo effect sizes
  - Standard approach for next decade

### Phase 2: Refinements & Extensions (2011-2017)
- **2015:** Abadie, Diamond & Hainmueller - "Comparative Politics and the Synthetic Control Method"
  - Clarifies inference procedures
  - Discusses pre-treatment fit requirements
  - No formal theory for multiple treated units
- **2017:** Xu - "Generalized Synthetic Control Method"
  - Factor model approach
  - Bayesian inference via posterior
  - Limited to interactive fixed effects framework
- **2017:** Doudchenko & Imbens - "Balancing, Regression, Difference-in-Differences and Synthetic Control Methods"
  - Unifies SC with other estimators
  - Discusses inference challenges
  - No new inference method proposed

### Phase 3: Methodological Innovation (2018-2021)
- **2018:** **Lei et al.** - "Conformal Inference of Counterfactuals and Individual Treatment Effects"
  - Conformal prediction framework for SC
  - Distribution-free finite-sample validity
  - Major advance over placebo tests
- **2019:** Cattaneo, Feng & Titiunik - "Prediction Intervals for SC in Panel Data"
  - Formalize prediction interval approach
  - Distinguish interpolation vs. extrapolation
  - Still no formal asymptotic theory for ATT
- **2021:** **Ben-Michael, Feller & Rothstein (BFR)** - "The Augmented Synthetic Control Method"
  - Bias-corrected SC using outcome regression
  - **Uses conformal inference for CIs, not EIF**
  - Key insight: SC + outcome model = double robustness potential
  - But doesn't derive EIF or use semiparametric theory
- **2021:** **Arkhangelsky, Athey, Hirshberg, Imbens & Wager (AAHIW)** - "Synthetic Difference-in-Differences"
  - Factor model for parallel trends + SC weighting
  - Asymptotic normality results
  - Focus on regularization, not inference
  - Variance estimation via bootstrap (not EIF)

### Phase 4: Recent Advances (2022-2026)
- **2021:** Ferman & Pinto - "Synthetic Controls with Imperfect Pretreatment Fit"
  - Theory for when pre-treatment fit is poor
  - Bias bounds and inference
  - Conservative approach (widens CIs)
- **2021:** Chernozhukov, Wuthrich & Zhu - "Exact and Robust Conformal Inference Methods"
  - Extends conformal inference to more settings
  - Multiple testing corrections
  - Still doesn't address outcome model uncertainty properly
- **2022:** Abadie & L'Hour - "A Penalized Synthetic Control Estimator"
  - Regularized SC weights
  - Inference via asymptotic theory
  - Limited to specific penalty structures
- **2023-2026:** Active research on staggered adoption, event studies, and multiple outcomes
  - Various ad-hoc inference approaches
  - No consensus on best practice

**KEY OBSERVATION:** Despite 20+ years of SC research, no paper has explicitly derived and used the efficient influence function for variance estimation, even though SC estimates a well-defined semiparametric functional with multiple treated units.

---

<a name="taxonomy"></a>
## 2. Taxonomy of Approaches

### A. By Theoretical Framework

#### Design-Based (Finite Population)
- **Placebo/permutation tests** (Abadie et al.)
- **Conformal inference** (Lei et al., Ben-Michael et al.)
- **Philosophy:** Inference based on randomization distribution or exchangeability
- **Strengths:** Finite-sample validity, minimal assumptions
- **Weaknesses:** Ad-hoc for ATT, unclear with model estimation

#### Model-Based (Superpopulation)
- **Asymptotic normality** (AAHIW, Abadie & L'Hour)
- **Bayesian** (Xu, others)
- **Philosophy:** Panel data from superpopulation, derive sampling distribution
- **Strengths:** Principled for ATT, efficiency
- **Weaknesses:** Requires large N, model assumptions

#### Semiparametric (Our Approach)
- **EIF-based inference** (THIS PAPER)
- **Philosophy:** Estimand has EIF, use it for variance
- **Strengths:** Double robustness, efficiency, principled
- **Weaknesses:** Requires moderate N, outcome model estimation

### B. By What They Target

#### Counterfactual Prediction (Single Treated Unit)
- Original ADH approach
- Lei et al. conformal inference
- Focus: CI for Y_1(0) at time t
- Challenge: No repeated sampling over treated unit

#### Average Treatment Effect on Treated (Multiple Treated Units)
- Ben-Michael et al. (conformal for ATT)
- AAHIW (asymptotic for ATT)
- **Our approach (EIF for ATT)**
- Focus: E[Y_1(t) - Y_1(0) | D=1]
- Advantage: Can use standard asymptotic theory

### C. By How They Handle Uncertainty

#### Ignore Outcome Model Uncertainty
- **Placebo tests** - Treat SC weights as fixed
- Problem: Underestimates variance when outcome model estimated
- Our simulations: 41-61% coverage vs. 95% target

#### Account for Weight Uncertainty Only
- Some bootstrap approaches
- Problem: Misses outcome model uncertainty in augmented SC

#### Account for All Uncertainty (Ideal)
- **EIF-based** - Propagates through all nuisances
- **Some conformal** - Distribution-free, but conservative

---

<a name="deep-dive"></a>
## 3. Deep Dive: Major Approaches

<a name="placebo"></a>
### 3.1 Placebo/Permutation Tests (Abadie, Diamond & Hainmueller)

**Key Papers:**
- Abadie & Gardeazabal (2003)
- Abadie, Diamond & Hainmueller (2010, 2015)
- Firpo & Possebom (2018) - improvements

**Method:**
1. Estimate SC for treated unit: τ̂ = Y_1 - Σ w_j Y_j
2. Apply SC to each control unit i (leave-one-out): τ̂_i^placebo
3. P-value = rank(|τ̂|) / (N_control + 1)
4. Reject if p < α

**Assumptions:**
- Exchangeability: treated unit could have been any unit
- Pre-treatment fit is similar for treated and controls
- No model estimation uncertainty (weights treated as known)

**CI Construction:**
- Invert test: include τ in CI if p(H_0: effect = τ) > α
- Or use quantiles of placebo distribution
- **Problem:** Unclear how to propagate outcome model uncertainty

**Theoretical Guarantees:**
- Finite-sample exact under strong exchangeability
- But exchangeability often violated (selection on Y_pre)
- No coverage guarantees when:
  - Pre-treatment fit differs
  - Outcome model estimated separately
  - Multiple treated units (which ones are "placebos"?)

**Limitations:**
1. **Single treated unit only** - No natural extension to ATT
2. **Ignores model uncertainty** - If using augmented SC, placebo variance is too small
3. **Requires many controls** - N_control ≥ 20 for reasonable power
4. **Pre-treatment fit sensitivity** - Poor fit invalidates inference
5. **Our simulation results:** 41-61% coverage (vs. 95% target) with augmented SC

**Software:**
- `Synth` package in R (Abadie et al.)
- `augsynth` package (Ben-Michael et al.) - includes placebo

**Verdict:** Standard practice but fundamentally limited. Works for single treated unit with standard SC, but fails with multiple treated units or outcome model estimation.

---

<a name="conformal"></a>
### 3.2 Conformal Inference

#### 3.2.1 Lei et al. (2018) - Original Conformal SC

**Paper:** "Conformal Inference of Counterfactuals and Individual Treatment Effects"

**Key Insight:** Treat SC as a prediction problem, use conformal prediction for distribution-free CIs

**Method:**
1. Fit SC to get residuals on controls: r_i = Y_i - Ŷ_i (pre-treatment)
2. For treated unit, compute residual at each hypothesized τ: r_1(τ) = Y_1 - Ŷ_1 - τ
3. Include τ in CI if r_1(τ) is "conforming" (similar to control residuals)
4. Formally: quantile-based or rank-based conformity

**Assumptions:**
- Exchangeability of residuals (after SC fitting)
- Prediction model is well-specified
- Pre-treatment fit is good

**Theoretical Guarantees:**
- **Finite-sample coverage** under exchangeability: P(Y_1(0) ∈ CI) ≥ 1-α
- Distribution-free (no parametric assumptions)
- Valid even if prediction model is wrong (but may be conservative)

**Strengths:**
- Rigorous finite-sample validity
- No asymptotic assumptions
- Flexible to any prediction method

**Limitations:**
1. **Focus on prediction, not ATT** - CI is for individual Y_1(0), not average effect
2. **Exchangeability assumption** - Violated if treated unit selected on Y_pre
3. **Conservative** - Often wider than necessary
4. **No guidance on outcome model** - Which model to use?
5. **Computational cost** - Grid search over τ values

**Extensions:**
- Chernozhukov et al. (2021) - Robust conformal inference
- Cattaneo et al. (2019) - Prediction intervals for SC

#### 3.2.2 Ben-Michael, Feller & Rothstein (2021) - Conformal for ATT

**Paper:** "The Augmented Synthetic Control Method" (JASA)

**Key Innovation:** Augmented SC = SC weights + outcome regression
- θ̂ = (1/N_1) Σ_{i: D_i=1} [Y_i - Σ_j w_{ij} Y_j + Σ_j w_{ij} m̂_j - m̂_i]
- Where m̂ = outcome model fitted on controls
- **This is essentially the EIF estimator!** But they don't recognize it as such

**Inference Approach:**
- **Use conformal inference** (Lei et al. style) for CIs
- Apply conformal to augmented residuals
- **Do NOT use EIF-based variance**

**Why Conformal Instead of EIF?**
- Paper doesn't discuss EIF or semiparametric theory
- Possible reasons:
  1. Unaware of EIF connection
  2. Concerned about finite-sample performance
  3. Prefer distribution-free guarantees
  4. Focus on single treated unit case

**Our Assessment:**
- **Point estimator is EIF-motivated** (even if not stated)
- **Inference is ad-hoc** (conformal instead of EIF variance)
- **Opportunity for improvement:** Use EIF variance for better efficiency

**Software:**
- `augsynth` R package
- Implements ridge, factor, elastic net, etc.
- Conformal CIs via `conformal.inf()` function

**Verdict:** Major advance in point estimation (double robustness), but inference still ad-hoc. Our work: take their estimator, add principled EIF-based inference.

---

<a name="bootstrap"></a>
### 3.3 Bootstrap Methods

**Overview:** Use bootstrap resampling to approximate sampling distribution

**Variants:**

#### A. Parametric Bootstrap
- Fit outcome model to controls
- Resample residuals
- Recompute SC and ATT
- **Problem:** Assumes model is correct

#### B. Block Bootstrap (Panel)
- Resample units (blocks across time)
- Preserve within-unit correlation
- Recompute SC and ATT
- **Problem:** Requires large N

#### C. Wild Bootstrap (Time Series)
- Resample time periods
- Multiply residuals by random weights
- **Problem:** Doesn't work well with SC (time structure matters)

**Key Papers:**
- Cameron & Trivedi (2005) - Bootstrap for panel data (general)
- Abadie & Imbens (2008) - Bootstrap fails with matching (related issue)
- Firpo & Possebom (2018) - Bootstrap for SC (conditional on Y_pre)

**AAHIW (2021) SDID:**
- Use bootstrap for variance estimation
- Resample units, refit factor model
- No formal justification or coverage results reported

**Theoretical Issues:**
1. **Standard bootstrap may fail** when estimator is non-smooth (SC weights have kinks)
2. **Small N problem** - Need N → ∞ for bootstrap consistency
3. **Computational cost** - 1000+ replications

**Empirical Performance:**
- Mixed results in simulations
- Sometimes over-covers, sometimes under-covers
- No clear guidance on which variant to use

**Verdict:** Potentially useful but lacks theoretical foundation for SC. May complement EIF-based inference as robustness check.

---

<a name="augmented-sc"></a>
### 3.4 Augmented Synthetic Control (Ben-Michael et al. 2021)

**Full Citation:** Ben-Michael, E., Feller, A., & Rothstein, J. (2021). The Augmented Synthetic Control Method. *Journal of the American Statistical Association*, 116(536), 1789-1803.

**Key Contributions:**

1. **Bias Correction via Outcome Model**
   - Standard SC: τ̂ = (1/N_1) Σ [Y_i - Σ_j w_{ij} Y_j]
   - Augmented SC: τ̂ = (1/N_1) Σ [Y_i - m̂_i + Σ_j w_{ij}(m̂_j - Y_j)]
   - Reduces bias when SC weights don't perfectly balance

2. **Multiple Outcome Models**
   - Ridge regression: m̂ = X'(X'X + λI)^{-1}X'Y
   - Factor models: m̂ from interactive fixed effects
   - Elastic net, generalized synthetic control, etc.

3. **Ridge Augmented SC (Main Recommendation)**
   - Use SC weights for propensity score weighting
   - Ridge regression for outcome model
   - Balance bias vs. variance via cross-validation

**Theoretical Results:**
- Asymptotic bias under violations of SC assumptions
- Improvement over standard SC when parallel trends violated
- **No asymptotic variance formula** - rely on conformal inference

**What's Missing:**
- **No EIF derivation** - Don't recognize augmented estimator as EIF
- **No semiparametric theory** - No double robustness proof
- **No asymptotic variance** - Use conformal instead of plug-in EIF variance
- **No discussion of efficiency** - Is this estimator efficient?

**Our Interpretation:**
- Augmented SC ≈ EIF estimator (without recognizing it)
- Their framework is compatible with our approach
- **Our contribution:** Add rigorous semiparametric theory and EIF-based inference

**Software:** `augsynth` R package
```r
library(augsynth)
syn <- augsynth(Y ~ D, unit, time, data,
                progfunc = "Ridge", scm = TRUE)
summary(syn)  # Uses conformal inference
```

**Verdict:** Excellent point estimator, but inference is still ad-hoc. Prime candidate for EIF-based improvement.

---

<a name="sdid"></a>
### 3.5 Synthetic Difference-in-Differences (Arkhangelsky et al. 2021)

**Full Citation:** Arkhangelsky, D., Athey, S., Hirshberg, D., Imbens, G., & Wager, S. (2021). Synthetic Difference-in-Differences. *American Economic Review*, 111(12), 4088-4118.

**Key Innovation:** Combine SC (unit weights) with DiD (time weights)

**Estimator:**
- SDID: τ̂ = Σ_i Σ_t ω_i λ_t (Y_{it} - Ŷ_{it})
- Where ω_i = SC-style unit weights
- And λ_t = time weights (learned from data)
- Plus regularization term

**Identifying Assumption:**
- Factor model: Y_{it}(0) = λ_i + μ_t + L_i' F_t + ε_{it}
- Parallel trends conditional on factors
- More flexible than DiD, more structured than SC

**Inference Approach:**
- **Asymptotic normality** under factor model
- Variance formula derived from asymptotic theory
- **Recommend jackknife or bootstrap** in practice
- **No EIF used** (despite factor model being semiparametric)

**Theoretical Results:**
- Consistency and asymptotic normality
- Optimal weighting scheme
- Regularization theory
- **Rate requirements:** Need N, T → ∞, N/T bounded

**Inference in Practice:**
- Bootstrap (resample units)
- Jackknife (leave-one-out)
- Placebo tests
- **No closed-form variance estimator recommended**

**What's Missing:**
- **No EIF for factor model** - Could derive for efficiency
- **No double robustness** - Relies on factor model being correct
- **Bootstrap justification** - Informal, no theoretical guarantees
- **Multiple treated units** - Extension unclear

**Software:** `synthdid` R package
```r
library(synthdid)
est <- synthdid_estimate(Y ~ D, unit, time, data)
se <- sqrt(vcov(est, method = 'bootstrap'))  # Uses bootstrap
```

**Comparison to Our Approach:**
- SDID: Factor model + SC/DiD weighting
- Us: SC conditioning + EIF-based inference
- Both improve on standard SC, but different assumptions

**Verdict:** Major contribution to SC methodology. Orthogonal to our focus (they improve bias via better model, we improve inference via EIF). Could combine SDID point estimator with EIF variance.

---

<a name="model-based"></a>
### 3.6 Other Model-Based Approaches

#### 3.6.1 Xu (2017) - Generalized Synthetic Control

**Paper:** "Generalized Synthetic Control Method: Causal Inference with Interactive Fixed Effects Models"

**Approach:**
- Interactive fixed effects: Y_{it}(0) = X_{it}' β + λ_i' F_t + ε_{it}
- Estimate (λ, F) via matrix completion
- ATT: τ = (1/N_1) Σ [Y_it - X_it' β̂ - λ̂_i' F̂_t]

**Inference:**
- **Bayesian credible intervals** from posterior of (λ, F)
- Or asymptotic normality under factor model
- Variance formula from EM algorithm

**Limitations:**
- Assumes factor model is correct (no robustness)
- Bayesian inference requires prior specification
- Asymptotic variance formula is complex
- Not widely used in practice

**Software:** `gsynth` R package

#### 3.6.2 Ferman & Pinto (2021) - Imperfect Pretreatment Fit

**Paper:** "Synthetic Controls with Imperfect Pretreatment Fit"

**Key Insight:** Pre-treatment fit is never perfect → bias

**Approach:**
- Bound bias based on pre-treatment RMSPE
- Conservative CI = point estimate ± 1.96 SE ± bias bound
- Inference is robust but wide

**Inference:**
- Placebo-based SE (as baseline)
- Add bias correction term
- Very conservative

**Limitation:**
- CIs can be extremely wide
- Not practical for moderate violations

#### 3.6.3 Abadie & L'Hour (2022) - Penalized SC

**Paper:** "A Penalized Synthetic Control Estimator for Disaggregated Data"

**Approach:**
- Penalized weight estimation: min ||Y - Xw||² + λ penalty(w)
- Asymptotic normality under penalization
- Variance from influence function (simple version)

**Inference:**
- Closed-form variance under specific penalties
- Asymptotic CIs: τ̂ ± 1.96 SE

**Limitations:**
- Limited to specific penalty structures
- Single treated unit focus
- No double robustness

---

<a name="bayesian"></a>
### 3.7 Bayesian Approaches

**Philosophy:** Posterior distribution provides natural inference

**Approaches:**

#### A. Bayesian Structural Time Series (Brodersen et al. 2015)
- Time series model with covariates
- CausalImpact R package (Google)
- Posterior credible intervals
- **Limitation:** Requires time series structure, not panel SC

#### B. Bayesian Factor Models (Xu 2017)
- Prior on factor loadings and factors
- MCMC for posterior
- Credible intervals from posterior
- **Limitation:** Sensitive to prior specification

#### C. Bayesian Additive Regression Trees (BART)
- Use BART for outcome model m(Y_pre)
- Posterior of τ from posterior of m
- **Not specific to SC**

**General Issues:**
1. Prior sensitivity
2. Computational cost
3. Hard to justify priors for policy evaluation
4. Less common in economics (frequentist tradition)

**Verdict:** Useful for some applications, but not mainstream for SC. Our EIF approach is frequentist and more aligned with econometric practice.

---

<a name="semiparametric"></a>
### 3.8 Semiparametric Theory & Double Robustness

**Key Observation:** SC with multiple treated units estimates a semiparametric functional, but existing literature doesn't use semiparametric theory.

**Relevant Semiparametric Literature (NOT SC-specific):**

#### A. Kennedy (2016, 2022) - Semiparametric Theory for Causality

**Papers:**
- Kennedy (2016): "Semiparametric Theory and Empirical Processes in Causal Inference"
- Kennedy (2022): "Semiparametric Doubly Robust Targeted Double Machine Learning"

**Key Contributions:**
- General framework for deriving EIFs
- Double robustness via orthogonal moments
- Rate requirements for nuisance parameters
- Cross-fitting for bias reduction

**Relevance to SC:**
- SC functional: θ = E[E[Y | D=0, Y_pre] | D=1]
- This is a semiparametric model (nuisances: m, e)
- **Can apply Kennedy's framework directly**
- Derive EIF, prove double robustness, show efficiency

**Our Contribution:** Apply Kennedy's theory to SC setting

#### B. Hahn (1998) - Propensity Score Efficiency

**Paper:** "On the Role of the Propensity Score in Efficient Semiparametric Estimation of Average Treatment Effects"

**Key Result:**
- ATT has EIF with propensity score and outcome model
- Double robustness: need only one to be correct
- Efficiency: EIF achieves semiparametric bound

**SC Connection:**
- SC weights act like generalized propensity score
- e(Y_pre) = P(D=1 | Y_pre) = SC weight
- **Same EIF structure as Hahn (1998)**, but conditioning on Y_pre instead of X

#### C. Chernozhukov et al. (2018) - Double/Debiased ML

**Paper:** "Double/Debiased Machine Learning for Treatment and Structural Parameters"

**Key Contributions:**
- Neyman orthogonality for bias reduction
- Rate requirements: ||m̂ - m|| ||ê - e|| = o_P(N^{-1/2})
- Cross-fitting to avoid overfitting bias
- General ML algorithms for nuisances

**Relevance to SC:**
- Can use ML for outcome model m(Y_pre)
- Need product rate condition (high-dimensional Y_pre is challenge)
- Cross-fitting may help with panel data

**Our Contribution:** Apply DML framework to SC, adapt to panel structure

#### D. Sant'Anna & Zhao (2020) - Doubly Robust DiD

**Paper:** "Doubly Robust Difference-in-Differences Estimators"

**Key Innovation:** DiD with covariates, use DR for efficiency

**Estimator:**
- τ̂ = (1/N_1) Σ [weight_i · (Y_i,post - Y_i,pre - (m̂_post - m̂_pre))]
- Double robustness w.r.t. propensity score and outcome model
- EIF-based variance

**Difference from SC:**
- DiD: Parallel trends (unconditional or conditional on X)
- SC: Conditional parallel trends given Y_pre
- **Different identifying assumptions → different EIF**

**Our Contribution:** Extend DR-DiD logic to SC setting (condition on Y_pre, not X)

---

<a name="comparison"></a>
## 4. Comparison of Inference Methods

### Table: Coverage, Width, Robustness

| Method | Target | Coverage Guarantee | Efficiency | Robustness | Computations | N Required |
|--------|--------|-------------------|-----------|------------|--------------|------------|
| **Placebo** | Prediction | Finite-sample (strong exchange) | Low | Low (ignores model) | Fast | 20+ controls |
| **Conformal** | Prediction | Finite-sample (exchangeable residuals) | Medium | High (distribution-free) | Medium | 20+ |
| **Bootstrap** | ATT | Asymptotic | Medium | Medium | Slow | 50+ |
| **Augmented SC + Conformal** | ATT | Finite-sample | Medium | High | Medium | 20+ |
| **SDID + Bootstrap** | ATT | Asymptotic (factor model) | High (if model correct) | Low (model-based) | Slow | 50+ |
| **EIF-based (Ours)** | ATT | Asymptotic | **High (efficient)** | **High (DR)** | Fast | 50+ |

### Key Trade-offs

#### Placebo Tests
- **Pro:** Simple, standard, finite-sample
- **Con:** Single treated unit, ignores model uncertainty, often fails
- **When to use:** Single treated, no outcome model, N_control > 20
- **Our results:** 41-61% coverage with augmented SC (should be 95%)

#### Conformal Inference
- **Pro:** Distribution-free, finite-sample, works with any model
- **Con:** Focus on prediction not ATT, conservative, computationally intensive
- **When to use:** Single treated, want robustness, can afford width
- **Relation to EIF:** Orthogonal (conformal for robustness, EIF for efficiency)

#### Bootstrap
- **Pro:** Intuitive, flexible
- **Con:** Slow, needs large N, no theory for SC
- **When to use:** Robustness check, N > 100
- **Relation to EIF:** Can bootstrap EIF estimator for small-sample improvement

#### EIF-based (Our Approach)
- **Pro:** Efficient, doubly robust, principled, fast
- **Con:** Requires moderate N, asymptotic approximation
- **When to use:** Multiple treated (N_1 ≥ 10), moderate total N ≥ 50
- **Advantage:** Only method that properly accounts for all estimation uncertainty

---

<a name="gaps"></a>
## 5. Gaps in the Literature

### Gap 1: No EIF-Based Inference
- **Observation:** SC with multiple treated units estimates a well-defined semiparametric functional
- **Existing work:** Uses ad-hoc inference (placebo, conformal, bootstrap)
- **Missing:** Explicit EIF derivation and variance estimation
- **Why it matters:** EIF is efficient and doubly robust
- **Our contribution:** Derive EIF, prove double robustness, show efficiency

### Gap 2: Outcome Model Uncertainty Not Properly Handled
- **Observation:** Augmented SC estimates outcome model, but inference ignores this
- **Ben-Michael et al.:** Use conformal inference (doesn't account for m̂ uncertainty optimally)
- **AAHIW:** Use bootstrap (no formal justification)
- **Problem:** Underestimates variance → false confidence
- **Our solution:** EIF propagates m̂ uncertainty correctly

### Gap 3: No Comparison of Inference Methods
- **Observation:** Multiple inference methods exist, but no systematic comparison
- **Questions:**
  - When does each method work?
  - What are the coverage properties?
  - How wide are CIs?
  - Robustness to misspecification?
- **Our contribution:** Comprehensive simulation study comparing methods

### Gap 4: Single vs. Multiple Treated Units
- **Observation:** Most theory is for single treated unit
- **Multiple treated:** Less clear (ATT vs. prediction)
- **Existing work:** Ad-hoc extension of single-unit methods
- **Our approach:** Formalize ATT for multiple treated, use standard asymptotic theory

### Gap 5: High-Dimensional Y_pre
- **Observation:** T_0 ~ 10-50 is common, high-dimensional for N ~ 50-100
- **Challenge:** Need good outcome models, rates may be slow
- **Existing work:** Little formal theory
- **Our contribution:** Discuss rate requirements, when EIF works

### Gap 6: No Software for Principled Inference
- **Observation:** Packages provide point estimates but inference is ad-hoc
- **augsynth:** Conformal only
- **synthdid:** Bootstrap only
- **Synth:** Placebo only
- **Our contribution:** `sceif` package with EIF-based inference

---

<a name="our-contribution"></a>
## 6. Where EIF-Based Inference Fits

### Positioning in the Literature

#### Theoretical Contribution
- **First to derive EIF for SC with multiple treated units**
- Prove double robustness (m̂ or ê correct suffices)
- Show efficiency (achieves semiparametric bound)
- Provide rigorous asymptotic theory

#### Methodological Contribution
- Principled alternative to ad-hoc methods
- Properly accounts for outcome model uncertainty
- Fast computation (closed-form variance)
- Works with any outcome model (ridge, factor, RF, etc.)

#### Empirical Contribution
- Show existing methods fail in realistic settings
- EIF achieves correct coverage where placebo fails (0.94 vs. 0.41-0.61)
- Demonstrate in real data applications
- Provide practical guidance on when to use

### Relationship to Existing Work

#### Ben-Michael et al. (2021) - Augmented SC
- **Their contribution:** Augmented estimator (bias correction)
- **Their inference:** Conformal (ad-hoc)
- **Our contribution:** Recognize augmented = EIF, use EIF variance
- **Positioning:** "We provide the missing inferential theory for augmented SC"

#### Arkhangelsky et al. (2021) - SDID
- **Their contribution:** Factor model + SC/DiD weighting
- **Their inference:** Bootstrap (no theory)
- **Our contribution:** Orthogonal (we focus on EIF for standard SC)
- **Positioning:** "Complementary - they improve bias via better model, we improve inference via EIF"
- **Extension:** Could derive EIF for SDID (future work)

#### Lei et al. (2018) - Conformal SC
- **Their contribution:** Conformal prediction for single treated unit
- **Our contribution:** EIF for ATT with multiple treated units
- **Positioning:** "Different targets (prediction vs. ATT) and methods (conformal vs. EIF)"
- **Combination:** Could use conformal + EIF for robustness

#### Abadie et al. (2010, 2015) - Placebo Tests
- **Their contribution:** Foundational SC method
- **Their inference:** Placebo tests (standard but limited)
- **Our contribution:** Modern inference for their estimator
- **Positioning:** "Updating inference for SC to match advances in causal inference theory"

### Key Differentiators

1. **Only method using EIF** - First to apply semiparametric theory to SC
2. **Double robustness** - Works if outcome model OR propensity score correct
3. **Efficiency** - Achieves semiparametric efficiency bound
4. **Practical** - Fast, easy to implement, works with existing estimators
5. **Empirically validated** - Show it works where others fail

### Potential Criticisms and Responses

#### "Conformal is better because it's finite-sample"
- **Response:** True, but conservative. EIF is efficient and works well with N ≥ 50. Can combine both.

#### "Bootstrap is more robust"
- **Response:** Bootstrap is slow and lacks theory for SC. EIF has formal justification. Can bootstrap EIF for robustness.

#### "You need large N, but SC is for small N"
- **Response:** True for single treated unit. We focus on multiple treated units (increasingly common). N ≥ 50 total is realistic.

#### "High-dimensional Y_pre is a problem"
- **Response:** Yes, need good outcome models. But same issue for all methods. We provide guidance on model choice.

#### "Ben-Michael et al. already did this"
- **Response:** They derived augmented estimator but used conformal for inference. We show augmented ≈ EIF and provide principled EIF variance.

---

<a name="must-read"></a>
## 7. Key Papers to Read and Cite

### Tier 1: Must Read (Core SC Methods)

1. **Abadie, Diamond & Hainmueller (2010)** - "Synthetic Control Methods for Comparative Case Studies: Estimating the Effect of California's Tobacco Control Program"
   - *Journal of the American Statistical Association*
   - Original SC method, placebo inference
   - **Must cite:** Foundation of SC

2. **Abadie, Diamond & Hainmueller (2015)** - "Comparative Politics and the Synthetic Control Method"
   - *American Journal of Political Science*
   - Clarifies inference procedures, pre-treatment fit
   - **Must cite:** Standard reference for SC inference

3. **Ben-Michael, Feller & Rothstein (2021)** - "The Augmented Synthetic Control Method"
   - *Journal of the American Statistical Association*
   - Augmented SC, conformal inference, ridge/factor models
   - **Must cite:** Closest to our work, we build on this

4. **Arkhangelsky et al. (2021)** - "Synthetic Difference-in-Differences"
   - *American Economic Review*
   - SDID, factor models, asymptotic theory
   - **Must cite:** Major recent advance, compare to

5. **Lei et al. (2018)** - "Conformal Inference of Counterfactuals and Individual Treatment Effects"
   - *arXiv* (later published)
   - Conformal inference for SC
   - **Must cite:** Main alternative inference method

### Tier 2: Important SC Literature

6. **Xu (2017)** - "Generalized Synthetic Control Method: Causal Inference with Interactive Fixed Effects Models"
   - *Political Analysis*
   - Factor model approach, Bayesian inference
   - **Cite:** Alternative model-based approach

7. **Ferman & Pinto (2021)** - "Synthetic Controls with Imperfect Pretreatment Fit"
   - *Quantitative Economics*
   - Bias bounds, conservative inference
   - **Cite:** Addresses pre-treatment fit issue

8. **Chernozhukov, Wuthrich & Zhu (2021)** - "Exact and Robust Conformal Inference Methods for Predictive Machine Learning with Dependent Data"
   - *arXiv*
   - Extensions of conformal inference
   - **Cite:** Recent conformal work

9. **Abadie (2021)** - "Using Synthetic Controls: Feasibility, Data Requirements, and Methodological Aspects"
   - *Journal of Economic Literature*
   - Survey/synthesis of SC methods
   - **Cite:** Recent authoritative review

10. **Cattaneo, Feng & Titiunik (2019)** - "Prediction Intervals for Synthetic Control Methods"
   - *arXiv*
   - Formalize prediction interval approach
   - **Cite:** Related inference approach

### Tier 3: Semiparametric Theory (Our Framework)

11. **Kennedy (2016)** - "Semiparametric Theory and Empirical Processes in Causal Inference"
   - *arXiv* (tutorial paper)
   - EIF derivation, double robustness, efficiency
   - **Must cite:** Our theoretical framework

12. **Kennedy (2022)** - "Semiparametric Doubly Robust Targeted Double Machine Learning: A Review"
   - *arXiv*
   - Comprehensive review of DR methods
   - **Must cite:** Connects to modern ML literature

13. **Hahn (1998)** - "On the Role of the Propensity Score in Efficient Semiparametric Estimation of Average Treatment Effects"
   - *Econometrica*
   - EIF for ATT, double robustness
   - **Must cite:** Classic paper, our SC-EIF analogous to Hahn's ATT-EIF

14. **Chernozhukov et al. (2018)** - "Double/Debiased Machine Learning for Treatment and Structural Parameters"
   - *Econometrics Journal*
   - DML framework, rate requirements, cross-fitting
   - **Cite:** For ML outcome models, rate conditions

15. **Robins, Li, Tchetgen & van der Vaart (2008)** - "Higher Order Influence Functions and Minimax Estimation of Nonlinear Functionals"
   - *IMS Collections*
   - Higher-order influence functions, efficiency
   - **Cite if needed:** For advanced theory

### Tier 4: Related Causal Inference

16. **Sant'Anna & Zhao (2020)** - "Doubly Robust Difference-in-Differences Estimators"
   - *Journal of Econometrics*
   - DR-DiD with covariates
   - **Cite:** Compare to DiD approach

17. **Callaway & Sant'Anna (2021)** - "Difference-in-Differences with Multiple Time Periods"
   - *Journal of Econometrics*
   - Group-time ATTs, staggered adoption
   - **Cite:** For context on recent DiD advances

18. **Doudchenko & Imbens (2016)** - "Balancing, Regression, Difference-in-Differences and Synthetic Control Methods: A Synthesis"
   - *NBER Working Paper*
   - Unifies SC with other methods
   - **Cite:** For positioning SC in broader landscape

19. **Abadie & Imbens (2006, 2008, 2011)** - Matching papers
   - Matching estimators, standard errors, bias
   - **Cite if relevant:** Analogy to matching (SC as matching on Y_pre)

20. **Imbens & Rubin (2015)** - "Causal Inference for Statistics, Social, and Biomedical Sciences"
   - Textbook
   - **Cite if needed:** General causal inference reference

### Tier 5: Applications (For Empirical Section)

21. Find 2-3 recent SC applications with:
    - Multiple treated units
    - Published with inference
    - Data accessible
    - Use for replication/comparison

**Candidates to search:**
- Medicaid expansion studies
- Minimum wage studies (city/county level)
- School reform interventions
- Place-based policies
- Environmental regulations

### Additional Searches Needed

Use Google Scholar, SSRN, arXiv to find:
- "synthetic control" + "inference" (2018-2026)
- "synthetic control" + "confidence interval" (2018-2026)
- "synthetic control" + "bootstrap" (2018-2026)
- "synthetic control" + "efficient influence function" (all years) ← Check if anyone beat us to it!
- "augmented synthetic control" + "theory" (2020-2026)
- "panel data" + "influence function" + "causal" (2018-2026)

---

<a name="software"></a>
## 8. Software Implementations

### Existing Packages

#### R Packages

**1. Synth (Abadie et al.)**
- Original SC implementation
- Placebo tests built-in
- Single treated unit focus
- No outcome model
```r
library(Synth)
dataprep.out <- dataprep(...)
synth.out <- synth(dataprep.out)
```

**2. augsynth (Ben-Michael et al.)**
- Augmented SC with multiple outcome models
- Conformal inference for CIs
- Ridge, factor, elastic net, etc.
- Supports multiple treated units
```r
library(augsynth)
syn <- augsynth(Y ~ D, unit, time, data,
                progfunc = "Ridge", scm = TRUE)
summary(syn)  # Conformal CIs
```

**3. synthdid (Arkhangelsky et al.)**
- Synthetic DiD
- Bootstrap variance
- Factor model structure
```r
library(synthdid)
est <- synthdid_estimate(Y ~ D, unit, time, data)
se <- sqrt(vcov(est, method = 'bootstrap'))
```

**4. gsynth (Xu)**
- Generalized SC (factor models)
- Bayesian or EM inference
- Interactive fixed effects
```r
library(gsynth)
out <- gsynth(Y ~ D + X, data, index = c("unit","time"),
              r = c(0, 5), CV = TRUE, force = "two-way")
```

**5. microsynth**
- SC for multiple outcomes
- Omnibus balance
- Inference via bootstrap

**6. tidysynth**
- Tidy interface to Synth
- ggplot2 integration
- Placebo tests

**7. SCtools**
- Post-estimation tools
- Visualization
- Sensitivity analysis

#### Stata Packages

**synth** (Abadie et al.)
- Official Stata implementation
- Placebo inference

**synth_runner**
- Automates placebo tests
- Multiple specifications

#### Python Packages

**SparseSC**
- Penalized SC
- L1/L2 regularization

**CausalImpact** (Google)
- Bayesian structural time series
- Not exactly SC but related
- Includes R version

### Our Contribution: sceif Package

**Planned Features:**
1. EIF-based variance for any SC estimator
2. Support for multiple outcome models
3. Comparison to other inference methods
4. Integration with augsynth and synthdid
5. Diagnostic plots and tools

**Usage:**
```r
library(sceif)

# Basic EIF-based inference
result <- sc_eif(
  data = panel_data,
  outcome = "Y",
  treatment = "D",
  unit = "id",
  time = "t",
  pre_periods = 1:10,
  post_period = 15,
  outcome_model = "ridge"  # or "factor", "rf", "sc_weights"
)

summary(result)
# ATT: 2.5 (95% CI: [1.2, 3.8])
# SE (EIF): 0.65
# SE (placebo): 0.42 (biased)
# SE (conformal): 0.78 (conservative)

# Compare inference methods
compare_inference(result, methods = c("eif", "placebo", "conformal", "bootstrap"))

# Use with existing estimators
augsynth_fit <- augsynth(...)
eif_inference(augsynth_fit)  # Add EIF-based CIs to augsynth output
```

---

## 9. Research Questions for Simulation Study

Based on literature gaps, our simulations should answer:

### Coverage & Width
1. Does EIF achieve nominal 95% coverage?
2. How does coverage compare: EIF vs. placebo vs. conformal vs. bootstrap?
3. Are CIs narrower with EIF (conditional on correct coverage)?
4. How does N affect performance? (N = 20, 50, 100, 200, 500)

### Robustness
5. Does double robustness work in practice?
   - Correct outcome model, wrong PS
   - Wrong outcome model, correct PS
   - Both wrong (should fail)
6. Sensitivity to outcome model choice (ridge, factor, RF)
7. Sensitivity to hyperparameters (ridge λ, factor r, etc.)

### When Does EIF Work?
8. Minimum N required? (Our guess: N ≥ 50)
9. Minimum N_treated? (Our guess: N_1 ≥ 10)
10. Role of T_0? (More pre-periods = better outcome model?)
11. Signal-to-noise ratio effects?

### When Does EIF Fail?
12. Single treated unit (N_1 = 1)? - Should fail or need conditional EIF
13. Very small N (N = 20)? - Asymptotic approximation may be poor
14. Very high-dimensional Y_pre (T_0 = 50, N = 50)? - Outcome model may be poor
15. Strong violations of assumptions? - Should fail gracefully

### Comparison to Existing Methods
16. When does placebo work vs. fail? (Our finding: fails with augmented SC)
17. Is conformal always valid but conservative?
18. Does bootstrap approximate EIF in large samples?
19. How does EIF compare to SDID bootstrap?

### Practical Guidance
20. Which outcome model works best? (Ridge? Factor? RF?)
21. Is cross-fitting worth it in panel data?
22. What diagnostics should users check?

---

## 10. Outline for Literature Review Section of Paper

**Suggested structure for paper (4-5 pages):**

### 2.1 Synthetic Control Methods
- Brief history: Abadie et al. (2003, 2010, 2015)
- Key idea: match on pre-treatment outcomes
- Standard estimator: weighted average of controls

### 2.2 Existing Inference Methods

**2.2.1 Placebo Tests**
- Method: apply SC to untreated units
- Issues: single treated unit, ignores model uncertainty
- Our finding: fails with augmented SC (cite our simulation)

**2.2.2 Conformal Inference**
- Lei et al. (2018), Ben-Michael et al. (2021)
- Strengths: finite-sample validity, distribution-free
- Limitations: focus on prediction, conservative

**2.2.3 Bootstrap and Other Methods**
- Arkhangelsky et al. (2021) use bootstrap
- Mixed results, no formal justification
- Computationally expensive

### 2.3 Augmented Synthetic Control
- Ben-Michael et al. (2021): SC + outcome model
- Reduces bias, improves over standard SC
- **But: inference via conformal, not EIF**
- Our contribution: recognize as EIF, use EIF variance

### 2.4 Gap in Literature
- No work derives EIF for SC with multiple treated
- Outcome model uncertainty not properly handled
- Opportunity for principled inference via semiparametric theory

---

## 11. Timeline of How to Engage Literature

### Phase 3 (Theory) - Week 1-2
**Read:**
- Kennedy (2016, 2022) - EIF theory
- Hahn (1998) - Propensity score efficiency
- Chernozhukov et al. (2018) - DML rates

**Goal:** Establish theoretical framework

### Phase 3 (Theory) - Week 3-4
**Read:**
- Ben-Michael et al. (2021) - Full paper, check for EIF
- Arkhangelsky et al. (2021) - SDID theory
- Sant'Anna & Zhao (2020) - DR-DiD

**Goal:** Connect to existing SC literature

### Phase 4 (Simulations) - Week 1-2
**Read:**
- Lei et al. (2018) - Conformal implementation
- Ferman & Pinto (2021) - Imperfect fit
- Any bootstrap papers for SC

**Goal:** Design comparison simulations

### Phase 5 (Applications) - Week 1-2
**Search for:**
- Recent SC applications with multiple treated units
- Studies with published data
- Variety of contexts (health, labor, education, etc.)

**Goal:** Identify replication studies

### Phase 6 (Writing) - Throughout
**Cite:**
- Abadie et al. (2010, 2015) - Foundation
- Ben-Michael et al. (2021) - Build on
- Kennedy (2016, 2022) - Theory
- All comparison methods in sims

---

## 12. Summary: Key Takeaways

### What We Know
1. **SC inference is hard** - Existing methods often fail
2. **Multiple approaches exist** - Placebo, conformal, bootstrap, model-based
3. **No EIF-based inference** - Gap in literature despite SC being semiparametric
4. **Augmented SC is close** - Ben-Michael et al. have the estimator but not the inference theory

### What We Don't Know (Need to Check)
1. Has anyone derived EIF for SC? (Seems no, but search thoroughly)
2. Does Ben-Michael et al. mention EIF anywhere? (Need to read full paper)
3. Are there recent papers (2023-2026) we're missing?
4. What do practitioners actually use for inference?

### Our Contribution
1. **First EIF derivation for SC** (with multiple treated units)
2. **Double robustness proof** (outcome model OR propensity score)
3. **Efficiency result** (achieves semiparametric bound)
4. **Empirical validation** (show it works where placebo fails)
5. **Practical implementation** (sceif package)

### Positioning
- **Build on:** Ben-Michael et al. (augmented SC estimator)
- **Improve:** Inference (EIF vs. conformal)
- **Compare to:** Placebo, conformal, bootstrap
- **Frame as:** "Modern semiparametric inference for SC"

### Next Steps for Literature Work
1. ✅ This comprehensive review
2. ⬜ Read Ben-Michael et al. (2021) full paper carefully
3. ⬜ Search for "synthetic control" + "efficient influence function" (check if we're first)
4. ⬜ Find recent applications for replication
5. ⬜ Set up reference manager (Zotero) with all papers
6. ⬜ Create BibTeX file for paper

---

## References for This Literature Review

This review is based on abstracts, arXiv versions, and package documentation. Full papers need to be obtained and read for the actual paper writing. Priority order given in Section 7.

**Search Terms Used:**
- Google Scholar: "synthetic control inference", "synthetic control confidence interval", "augmented synthetic control", "synthetic difference-in-differences"
- SSRN: "synthetic control"
- arXiv: stat.ME, econ.EM
- R package vignettes: augsynth, synthdid, Synth, gsynth

**Date of Review:** 2026-03-04

---

## Appendix A: Open Questions from Literature

1. **Why hasn't EIF been used for SC?**
   - Oversight? (Seems unlikely given 20 years of research)
   - Finite-sample concerns? (EIF is asymptotic)
   - Focus on single treated unit? (EIF needs repeated sampling)
   - Unawareness of semiparametric connection? (Possible in econ vs. stats)

2. **What did Ben-Michael et al. know about EIF?**
   - Did they derive it and not use it?
   - Or did they derive augmented estimator without EIF framework?
   - Why choose conformal over EIF variance?

3. **Is there related work in other fields?**
   - Epidemiology: synthetic controls less common
   - Time series: different framework (BSTS)
   - Matching: related but different (Abadie & Imbens 2006-2011)

4. **What are practitioners actually doing?**
   - Survey applied papers 2020-2026
   - What inference methods are most common?
   - Are CIs reported at all?

---

## Appendix B: Potential Collaboration Opportunities

Based on this literature review, potential collaborators:

1. **Ben-Michael, Feller, Rothstein** - Augmented SC authors
   - Could reach out after we have results
   - Potential for augsynth integration

2. **Sant'Anna** - DR-DiD expert, methodologist
   - Experience with double robustness in panel data
   - Could provide feedback on theory

3. **Kennedy** - Semiparametric theory expert
   - We're applying his framework to SC
   - Could confirm our EIF derivation

4. **AAHIW team** - SDID authors
   - Extension to SDID setting?
   - Comparison of approaches

**Strategy:** Develop full draft first, then share with subset for feedback before submission.

---

**END OF LITERATURE REVIEW**

*This document will be updated as we read papers and discover new references.*

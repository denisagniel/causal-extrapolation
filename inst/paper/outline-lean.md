# Lean Paper Outline: "Should We Keep the Policy?"

> **⚠️ PARTIALLY SUPERSEDED (2026-06-30).** This outline predates the audit + Phase-0/1 decisions. Authoritative current decisions live in:
> - `quality_reports/2026-06-30_lean-structure-review.md` (locked structural decisions)
> - memory: `paper-framing-decisions`, `path3-direct-cate-estimation`, `paper-contribution-is-mapping-not-estimation`
>
> **Overrides to the text below:**
> - Title: "Should We Keep the Policy? Forward-Looking Estimands and Identification for Panel Data" (not "Estimating Policy Effects...").
> - Estimands: **FATT + FATU + FATE** family (not "2 estimands FATT+FATE"); FITE/FATS motivation only.
> - **§2.4 first-stage EIF → moved to §5** (§2 is clean setup).
> - **§4 framing = "what is assumed invariant"** (effects / temporal form / conditional effect), NOT a single `h(g,t;γ)` umbrella. Path 3 estimates τ(x) directly (does not pass through θ_gt).
> - **§4 length target ≤6.5pp** (was 7.5–8).
> - §6/§7 numbers PENDING Phases 2–3; placeholder tables until then.
> - Path 3 = covariate **transport** (direct CATE + DR transport EIF), not invert-from-marginals.

**Target:** 20-25 pages main paper + supplement (submission to JASA/Biometrika/JRSSB tier)

**Dual Core Contribution:**
1. **Estimand definition** - Forward-looking future causal effects (FATT/FATU/FATE) for policy decisions
2. **Identification theory** - Three paths differing in what they assume invariant; each plugs an existing estimator into a forward map + propagates its EIF

**Key Design Principles:**
- 3 estimands (FATT/FATU/FATE) as one decision-mapped family
- All proofs in supplement
- All three paths parallel, ≤1.5pp each
- One simulation table (not 5+)
- Streamlined inference (high-level only; all EIFs in §5)
- Honest failure reporting in application

---

## Section 1: Introduction (~4 pages → target 3 pages)

### 1.1 The Tension (0.75 pages)
**Content:**
- Opening: Policy decisions require predicting forward-looking effects
- Problem: Standard DiD/panel methods estimate backward-looking aggregates (ATT over observed periods)
- Tension: Dynamic effects make simple extrapolation non-trivial
- Stakes: If effects change unrestrictedly, historical data can't inform current decisions

**Tone:** Direct and concrete. Lead with policy relevance.

**Key citation clusters:**
- Forward-looking vs backward-looking: Heckman (2001), Sasaki (2023), Forastiere (2025)
- External validity challenge: Egami (2023), Khosrowi (2019), Manski (2013)
- Recent DiD advances: Callaway & Sant'Anna (2021), Sun & Abraham (2021)

**Tighten from current:** Current intro spends ~2 pages on philosophical motivation. Cut to 0.75 pages. Focus on practical problem.

---

### 1.2 Dual Contribution (1 page)

**Content:**

**Contribution 1: Estimand Definition**
- Policy evaluation requires targeting specific future effects
- **Future ATT (FATT):** Effects on treated units at future time p+1
  - Answers: "Should we maintain policy in states that adopted it?"
  - Why standard ATT doesn't suffice: Averages past periods, not future
- **Future ATE (FATE):** Population-level effects at future time p+1
  - Answers: "Should we expand policy to new states?"
  - Connection to generalization literature
- Gap: Current methods give backward-looking estimates; policy needs forward-looking predictions

**Contribution 2: Identification Theory - Three Paths**
- **Path 1 (Time Homogeneity):** Effects constant across event-time
  - Takes dynamics *less* seriously
  - Minimal assumptions, but restrictive
- **Path 2 (Parametric Temporal Models):** Effects follow parametric temporal model
  - Takes dynamics *more* seriously
  - Extrapolates via temporal modeling
- **Path 3 (Covariate Integration):** Structural stability via baseline covariates
  - Takes dynamics *most* seriously
  - Robust to regime change when covariates capture deep parameters
  - Lucas Critique connection

**Key distinction:** Not just "how to identify" but "what to identify" for policy relevance.

---

### 1.3 Methods Contribution (0.75 pages)

**Content:**
- Semiparametric inference via efficient influence function (EIF) propagation
- Model selection for Path 2: Time-series cross-validation framework
  - Tests extrapolation performance, not in-sample fit
  - First systematic framework for model selection in causal extrapolation
- Software: R package `extrapolateATT`

**Distinguish from contribution 2:** This is "how we do inference" not "how we identify."

---

### 1.4 Related Work - Inline Integration (1.5 pages)

**NOT a separate subsection.** Weave into introduction narrative:

**Paragraph 1: Panel data and DiD foundations**
- Recent surveys: Arkhangelsky (2024), de Chaisemartin (2023)
- Group-time ATTs: Callaway & Sant'Anna (2021), Sun & Abraham (2021), Roth (2023)
- Testing parallel trends: Freyaldenhoven (2019), Roth (2022), Rambachan (2023), Dette (2024)
- Note: These focus on backward-looking estimands in observed window

**Paragraph 2: External validity and transportability**
- Egami (2023), Pearl (2022), Bareinboim (2012) - transporting effects
- Cole (2010), Tipton (2013) - generalizing from trials
- Devaux (2022) - robustness to external validity bias
- Khosrowi (2019, 2023), Manski (2013) - extrapolation assumptions

**Paragraph 3: Lucas Critique and structural approaches**
- Lucas (1976), Ericsson (1998), Estrella (1999) - policy invariance
- Heckman (2005) - structural equations for treatment effects
- Pearl (2022), Brodersen (2015) - structural extrapolation

**Paragraph 4: Policy-relevant estimands**
- Heckman (2001), Sasaki (2023) - policy-relevant treatment effects
- Forastiere (2025) - forecasting causal effects of re-implementation
- Gische (2021) - forecasting vs predicting outcomes

**Integration:** Each paragraph connects to one aspect of our contribution, not a separate "related work dump."

---

## Section 2: Setting and Notation (~2 pages)

### 2.1 Panel Data Framework (1 page)

**Content:**
- Units i = 1,...,n; time periods t = 1,...,p
- Policy indicator A_it, outcome Y_it, time-invariant covariates X_i
- Potential outcomes Y_it(a)
- No interference assumption
- Distribution P_t at time t
- Extension to future: P_{p+k} for k ≥ 1

**Streamline:** No "Section 2.1 Context" subsection. Just essential setup.

**Notation table (optional):** Consider small table of key notation for reader reference.

---

### 2.2 Staggered Adoption and Group-Time ATTs (1 page)

**Content:**
- Group indicator G_i = first adoption time
- Group-time ATT: θ_gt = E[Y_it(1) - Y_it(0) | A_it = 1, G_i = g]
- Standard overall ATT: θ = E[Y_it(1) - Y_it(0) | A_it = 1]
- Training period vs future periods
- Observed contrasts (t ≤ p) vs unobserved contrasts (t > p)

**Key point:** Set up temporal extrapolation problem without solving it yet. That's Section 4's job.

---

### 2.3 First-Stage Identification (0.5 pages)

**Content:**
- Brief statement: We assume researcher has identified θ or θ_gt under some design
- Examples: DiD with parallel trends, synthetic control, etc.
- Our contribution: Given identified θ or θ_gt, when and how do they identify FATT/FATE?
- Two-step identification: (a) θ_gt from observables; (b) FATT from θ_gt

**Purpose:** Clarify scope - we're not proposing new first-stage designs, we're connecting them to policy-relevant estimands.

---

## Section 3: Forward-Looking Estimands (~3 pages → target 2.5 pages)

**NEW SECTION - Core contribution 1**

### 3.1 The Policy Evaluation Challenge (0.5 pages)

**Content:**
- Policy decisions are inherently forward-looking
- Question 1: "Should states that adopted policy X maintain it?" → Need effect at time p+1 on treated
- Question 2: "Should states without policy X adopt it?" → Need effect at time p+1 on untreated/population
- Standard ATT: Averages effects over t ≤ p, doesn't directly answer either question
- Gap: Need estimands that target future time periods

**Examples (brief):**
- Healthcare policy: Effects 5 years post-implementation
- Criminal justice reform: Effects in next legislative session
- Education policy: Effects on next cohort

---

### 3.2 Future ATT (FATT) (1 page)

**Definition:**
```
τ_FATT(p+m) = E_{P_{p+m}}[Y_{i,p+m}(1) - Y_{i,p+m}(0) | A_{ip} = 1]
```

**Content:**

**What it is:**
- Average treatment effect at future time p+m for units treated by period p
- Contrast: Y(1) vs Y(0) at future time, among current adopters
- Distribution P_{p+m} governs future time point

**Why it matters for policy:**
- Answers: "What will be the effect of maintaining this policy?"
- Relevant for: States/units that have already adopted
- Forward-looking: Predicts effects beyond training period
- Not just an average over past: Targets specific future period

**Connection to group-time ATTs:**
- FATT aggregates effects across adoption cohorts at future time
- Weighted average of θ_{g,p+m} over groups g
- Weights: Proportion of treated units from each cohort

**Contrast with standard ATT:**
- Standard ATT: E[Y_it(1) - Y_it(0) | A_it = 1] averaged over t ≤ p
- FATT: Targets t = p+m specifically
- If effects constant over time: FATT = ATT
- If effects dynamic: FATT ≠ ATT (extrapolation needed)

**Example:**
Stand-Your-Ground laws adopted 2005-2015. Standard ATT averages effects 2005-2015. FATT(2020) asks: "What is the effect in 2020?" Different question, potentially different answer.

---

### 3.3 Future ATE (FATE) (0.75 pages)

**Definition:**
```
τ_FATE(p+m) = E_{P_{p+m}}[Y_{i,p+m}(1) - Y_{i,p+m}(0)]
```

**Content:**

**What it is:**
- Average treatment effect at future time p+m over entire population
- No conditioning on treatment status
- Population-level effect

**Why it matters for policy:**
- Answers: "What would be the population effect of universal adoption?"
- Relevant for: Deciding whether to expand policy to all units
- Generalization: From treated subsample to full population

**Relationship to FATT:**
- FATE = weighted average of FATT and FATU (future ATT on untreated)
- Weights: Population proportions of treated/untreated
- Can differ if effect heterogeneity correlates with adoption

**When FATE = FATT:**
- No selection on effect heterogeneity
- Or: Effect constant across treated/untreated

**Connection to external validity:**
- FATE requires assumptions about effect transportability
- Links to generalization literature (Cole 2010, Tipton 2013)

---

### 3.4 The Identification Challenge (0.5 pages)

**Content:**

**The problem:**
- FATT and FATE involve P_{p+m} (future distribution)
- We only observe data through period p
- Cannot directly estimate effects at unobserved times

**What's unobserved:**
- Future potential outcomes Y_{i,p+m}(0) and Y_{i,p+m}(1)
- Future covariate distributions (if time-varying covariates)
- Future treated/untreated populations

**Three possible solutions:**
1. Assume effects don't change (Path 1)
2. Model how effects change and extrapolate (Path 2)
3. Model structural heterogeneity via covariates (Path 3)

**Next section:** Formalize each path's assumptions and identification results.

---

## Section 4: Identification via Extrapolation Functions (~9 pages → target 7.5 pages)

### 4.1 General Framework (1.5 pages)

**Content:**

**Extrapolation function:**
- h(g,t;γ) represents group-time effect at arbitrary time t
- For observed times: h(g,t;γ) = θ_gt
- For future times: h(g,t;γ) extrapolates beyond observed data
- Parameter γ: Estimated from observed θ_gt, t ≤ p

**Identification equation:**
```
τ_FATT(p+m) = Σ_g π_g h(g,p+m;γ)
```
where π_g = P(G_i = g | A_{ip} = 1)

**Three paths differ in assumptions about h(·):**
- Path 1: h(g,t;γ) = h(g;γ) (time-invariant)
- Path 2: h(g,t;γ) follows parametric model
- Path 3: h(g,t;γ) = ∫ h(x,g,t) dP_X(x)

**Preview of paths:**
- All three give exact identification under their assumptions
- Trade-offs: Strength of assumptions vs. robustness
- Section structure: One path per subsection

---

### 4.2 Path 1: Time Homogeneity (2.5 pages → target 2 pages)

**Content:**

**Assumption 1 (Strict Time Homogeneity):**
```
θ_gt = θ_g for all g, t
```
Effects constant across calendar time t for each group g.

**Proposition 1 (statement only, proof in supplement):**
Under Assumption 1:
```
τ_FATT(p+m) = Σ_g π_g θ_g
```

**Interpretation:**
- FATT is weighted average of group-specific ATTs
- No time dimension in effects
- Simplest assumption, strongest restriction

**When it applies:**
- Treatment effects stable over time
- Policy implementation doesn't change
- No secular trends in effect magnitude

**Testable implications:**
- Can test H_0: θ_gt = θ_g for t ≤ p
- Compare effects across observed time periods
- Similar to parallel trends testing
- Reference: Dette (2024) equivalence tests

**Weaker version (Assumption 1'):**
Aggregate time homogeneity: ATT constant over time
```
τ_FATT(p+1) = θ
```

**Proposition 1':**
Under Assumption 1', FATT(p+1) = ATT

**Discussion:**
- Assumption 1' weaker than Assumption 1
- Allows group-time variation that averages out
- Common implicit assumption in applied work
- Makes backward-looking ATT policy-relevant

**Connection to current practice:**
- Many papers estimate ATT on historical data
- Then discuss policy implications as if effects stable
- Our framework: Makes this assumption explicit
- Enables testing and sensitivity analysis

---

### 4.3 Path 2: Parametric Temporal Models (2.5 pages → target 2 pages)

**Content:**

**Assumption 2 (Parametric Extrapolation):**
```
θ_gt = f(g,t;γ)
```
for known function f(·) and unknown parameter γ.

**Examples of f(·):**
- Linear trend: f(g,t;γ) = γ_0g + γ_1(t-g)
- Quadratic: f(g,t;γ) = γ_0g + γ_1(t-g) + γ_2(t-g)^2
- Spline: f(g,t;γ) with knots at specified event-times
- Group-specific trends: f(g,t;γ) = α_g + β_g(t-g)

**Proposition 2 (statement only, proof in supplement):**
Under Assumption 2 with γ identified from {θ_gt: t ≤ p}:
```
τ_FATT(p+m) = Σ_g π_g f(g,p+m;γ̂)
```

**Estimation:**
1. Obtain estimates θ̂_gt for t ≤ p from first-stage design
2. Fit model: Estimate γ̂ by regression θ̂_gt on f(g,t;γ)
3. Extrapolate: Predict f(g,p+m;γ̂) for future periods
4. Aggregate: Weight by π̂_g

**When it applies:**
- Effects have recognizable temporal pattern
- Pattern extends beyond observed window
- Functional form approximately correct

**Model selection challenge:**
- Don't know which f(·) is correct
- In-sample fit favors overparameterized models
- Need extrapolation-focused selection
- Preview: Section 5.2 addresses this via time-series CV

**Discussion:**
- More flexible than Path 1
- Still requires strong assumption: Correct functional form
- Misspecification can lead to poor extrapolation
- Trade-off: Flexibility vs. robustness

---

### 4.4 Path 3: Covariate Integration (2.5 pages → target 2 pages)

**Content:**

**Assumption 3 (Structural Covariate Stability):**
Conditional effects θ(x,g,t) stable over time:
```
θ(x,g,t) = θ(x,g) for all x, g, t
```

**Key idea:**
- Effects vary with baseline covariates X
- But for fixed X, effects stable across time
- Integrates over future covariate distribution
- "Deep parameters" in Lucas sense

**Proposition 3 (statement only, proof in supplement):**
Under Assumption 3:
```
τ_FATT(p+m) = Σ_g π_g ∫ θ(x,g) dP_{X|G=g,A_p=1}(x)
```

**Estimation:**
1. Estimate conditional effects θ̂(x,g) from observed data
2. Estimate covariate distribution P̂_X
3. Integrate: Numerical integration or g-computation
4. Aggregate across groups

**When it applies:**
- Effect heterogeneity driven by observables
- Covariates capture structural factors (e.g., poverty rate, demographics)
- Covariate-effect relationship stable even if temporal patterns break

**Lucas Critique connection:**
- Reduced-form temporal patterns may break under regime change
- But if X captures "deep parameters," θ(x) remains stable
- Example: Effect of minimum wage varies with local labor market (X), not calendar time per se

**Advantage over Path 2:**
- Robust to regime change
- Temporal patterns can break without invalidating identification
- Requires: Covariates that capture causal drivers

**Discussion:**
- Most flexible path
- Requires rich covariate data
- Assumes correct conditional model θ(x,g)
- Integrates causal inference with structural modeling tradition

---

### 4.5 Synthesis: Three Paths Compared (0.5 pages)

**Table:**

| Path | Assumption | When Valid | Advantage | Disadvantage |
|------|-----------|------------|-----------|--------------|
| 1 (Homogeneity) | Effects constant over time | Stable treatment, implementation | Minimal assumptions | Very restrictive |
| 2 (Parametric) | Temporal pattern known | Pattern extends to future | Explicit dynamics | Sensitive to misspecification |
| 3 (Covariates) | Structural stability | Covariates are deep parameters | Robust to regime change | Requires rich covariates |

**Guidance:**
- Path 1: Default when time homogeneity plausible
- Path 2: When temporal patterns evident in data
- Path 3: When regime change expected, covariates available

**Not mutually exclusive:**
- Can combine paths (e.g., covariate-specific time trends)
- Can test assumptions for each path
- Can report results under multiple paths (sensitivity analysis)

---

## Section 5: Semiparametric Inference (~4 pages → target 3 pages)

### 5.1 EIF Propagation Framework (2 pages → target 1.5 pages)

**Content:**

**General structure:**
- FATT is functional of θ_gt and extrapolation function
- Standard errors must account for:
  1. Sampling variability in θ̂_gt
  2. Estimation uncertainty in γ̂ (Path 2) or θ̂(x) (Path 3)
  3. Aggregation weights π̂_g

**Efficient Influence Function (EIF):**
- Captures first-order behavior of estimator
- Asymptotic variance: E[ψ²]
- Inference: Normal approximation, bootstrap

**Key insight:**
- EIF of FATT inherits structure from EIF of θ_gt
- Functional delta method propagates through extrapolation
- Chain rule: ∂FATT/∂θ_gt × (EIF of θ_gt)

**Theorem 1 (statement only, proof in supplement):**
Under regularity conditions:
```
√n(τ̂_FATT - τ_FATT) →^d N(0, V)
```
where V = E[ψ_FATT²] and ψ_FATT given by [formula].

**Implementation:**
- R package `extrapolateATT` computes EIF
- One-step estimation: Plug-in first-stage θ̂_gt
- Variance estimation: Sandwich or bootstrap

**Tighten from current:**
- No full EIF derivations (those go in supplement)
- High-level overview of propagation logic
- Statement of main result, not proof

---

### 5.2 Model Selection for Path 2 (2 pages → target 1.5 pages)

**Content:**

**The problem:**
- Multiple candidate models f₁, f₂, ..., f_K
- In-sample fit favors complex models
- Need selection criterion based on extrapolation

**Time-series cross-validation:**
1. Split observed periods: Training (t ≤ p-h) vs validation (p-h < t ≤ p)
2. Fit each model on training periods
3. Predict validation period effects
4. Select model with best out-of-sample prediction

**Coverage-based selection:**
- Not just point prediction error
- Check: Do 95% CIs for validation periods achieve 95% coverage?
- Penalizes overconfident extrapolation
- Balances bias and uncertainty

**Algorithm (high-level):**
```
For each candidate model k = 1,...,K:
  1. Fit γ̂_k on {θ_gt: t ≤ p-h}
  2. Predict θ̃_gt = f_k(g,t;γ̂_k) for p-h < t ≤ p
  3. Compute validation metric (e.g., coverage, MSE)
Select model k* with best validation performance
```

**Details in supplement:**
- Choice of validation window h
- Multiple validation splits
- Computational aspects
- Post-selection inference adjustments

**Novelty:**
- First systematic framework for model selection in causal extrapolation
- Focuses on out-of-sample extrapolation, not in-sample fit
- Connects to literature on forecast evaluation

**Tighten from current:**
- Overview only, not full algorithm
- Details (post-selection inference, CV variants) → supplement

---

## Section 6: Simulations (~3 pages)

### Structure: Three Core Scenarios

**Scenario 1: Time Homogeneity Holds (Path 1 Valid)**
- DGP: θ_gt = α_g (constant over t)
- Truth: FATT = weighted average of α_g
- Methods compared:
  - Path 1: Direct aggregation of θ̂_g
  - Path 2: Fit temporal model (should give similar result)
  - Path 3: Covariate integration
- Expected: All perform well, Path 1 most efficient

**Scenario 2: Parametric Dynamics (Path 2 Valid)**
- DGP: θ_gt = α_g + β(t-g) (linear trend)
- Truth: FATT requires extrapolation
- Methods compared:
  - Path 1: Fails (assumes homogeneity)
  - Path 2 (correct model): Linear extrapolation succeeds
  - Path 2 (wrong model): Quadratic or spline
  - Model selection via CV: Should select linear
- Expected: Path 2 with CV succeeds, Path 1 biased

**Scenario 3: Covariate-Driven Regime Change (Path 3 Valid)**
- DGP: θ(x,g) varies with covariate X, but stable over time
- Regime change: Aggregate θ_gt = ∫ θ(x,g) dP_X(x|t) varies as P_X(x|t) shifts
- Truth: Path 3 identifies FATT
- Methods compared:
  - Path 1: Fails (time trends present)
  - Path 2: Fails (reduced-form pattern breaks)
  - Path 3: Succeeds (structural stability)
- Expected: Only Path 3 robust to regime change

### 6.1 Design (0.5 pages)

**Content:**
- Staggered adoption: n = 500 units, p = 20 periods
- 5 adoption cohorts: G ∈ {5, 8, 11, 14, 17}
- Future period: p+1 = 21 (extrapolate 1 period ahead)
- First-stage: DiD with parallel trends (known to hold in DGP)
- Replications: 1000 per scenario
- Metrics: Bias, RMSE, coverage of 95% CI

**DGP details in supplement:** Full data-generating process equations

---

### 6.2 Results (2 pages)

**Table 1: Simulation Results**

| Scenario | Method | Bias | RMSE | Coverage |
|----------|--------|------|------|----------|
| 1: Homogeneity | Path 1 | 0.01 | 0.12 | 0.95 |
| 1: Homogeneity | Path 2 | 0.02 | 0.14 | 0.94 |
| 1: Homogeneity | Path 3 | 0.03 | 0.16 | 0.95 |
| 2: Linear Dynamics | Path 1 | **-0.45** | 0.48 | 0.76 |
| 2: Linear Dynamics | Path 2 (CV) | 0.03 | 0.19 | 0.94 |
| 2: Linear Dynamics | Path 2 (wrong) | -0.22 | 0.27 | 0.87 |
| 3: Regime Change | Path 1 | **-0.61** | 0.64 | 0.68 |
| 3: Regime Change | Path 2 | **-0.38** | 0.43 | 0.81 |
| 3: Regime Change | Path 3 | 0.05 | 0.21 | 0.93 |

**Discussion:**
- **Scenario 1:** All paths work when homogeneity holds; Path 1 most efficient
- **Scenario 2:** Path 2 with CV succeeds; Path 1 fails; model selection matters
- **Scenario 3:** Only Path 3 robust to regime change; reduced-form extrapolation fails

**Key takeaway:** No universal winner; path choice depends on DGP assumptions

**Additional results in supplement:**
- Small-sample properties (n = 100, 200, 500)
- Sensitivity to misspecification
- Longer extrapolation horizons (p+5, p+10)
- All 6 original scenarios

---

### 6.3 Interpretation (0.5 pages)

**Content:**
- Guidance: When to use each path
- Diagnostic checks: How to assess which assumption plausible
- Sensitivity analysis: Report under multiple paths if uncertain

---

## Section 7: Application - Stand-Your-Ground Laws (~3 pages)

### 7.1 Background (0.5 pages)

**Content:**
- Stand-Your-Ground laws: Adopted by 25+ states, 2005-2015
- Controversy: Impact on homicide rates
- Research question: What would be effect of maintaining laws in 2016-2022?
- Data: State-level homicide rates, 1981-2022
- Training: 1981-2015; Validation: 2016-2022

---

### 7.2 Estimands and Design (0.75 pages)

**Content:**
- Estimands:
  - FATT(2016): Effect on adopting states in 2016
  - FATT(2022): Effect on adopting states in 2022
- First-stage: DiD with parallel trends (Callaway & Sant'Anna 2021 estimator)
- Three paths applied:
  1. Time homogeneity (Path 1)
  2. Linear event-time trend (Path 2)
  3. Baseline covariates: poverty rate, urbanization (Path 3)

---

### 7.3 Results (1.25 pages)

**Table 2: Validation Results - Stand-Your-Ground Laws**

| Year | True Effect | Path 1 | Path 2 | Path 3 |
|------|------------|--------|--------|--------|
| 2016 | 0.45 (0.12) | 0.22 (0.10) | 0.28 (0.13) | 0.31 (0.14) |
| 2017 | 0.52 (0.13) | 0.22 (0.10) | 0.35 (0.14) | 0.38 (0.15) |
| 2018 | 0.58 (0.14) | 0.22 (0.10) | 0.42 (0.15) | 0.44 (0.16) |

**Findings:**
- All three methods underpredict actual effects
- Path 1 assumes constant effects: Most biased
- Path 2 incorporates trend: Better but still off
- Path 3 with covariates: Closest, but still misses

**Discussion:**
- Honest reporting: Methods fail to fully predict validation period
- Possible reasons:
  1. Effects accelerating post-2015 (faster than linear trend)
  2. Regime change not fully captured by covariates
  3. Spillover or general equilibrium effects post-2015
- Lesson: Even with best methods, extrapolation uncertain

---

### 7.4 Interpretation (0.5 pages)

**Content:**
- Limitations of extrapolation
- Value of validation: Reveals when assumptions break
- Policy implications: Uncertainty in forward-looking estimates
- Constitutional compliance: No overselling results (honest failure reporting)

---

## Section 8: Discussion (~2 pages)

### 8.1 Summary (0.75 pages)

**Content:**
- Dual contribution recap:
  1. Formalized forward-looking estimands (FATT, FATE)
  2. Three identification paths with different invariance assumptions
- Path 1: Time homogeneity
- Path 2: Parametric temporal models
- Path 3: Structural covariate stability
- Methods: EIF propagation, model selection via CV
- Application: Honest reporting of prediction failure

---

### 8.2 Guidance for Practice (0.5 pages)

**Content:**

**Choosing a path:**
- Start with Path 1 if time homogeneity plausible
- Use Path 2 when temporal patterns evident
- Use Path 3 when regime change expected

**Diagnostic checks:**
- Test time homogeneity on observed periods
- Compare paths (sensitivity analysis)
- Use validation periods if available

**Reporting:**
- Be explicit about invariance assumptions
- Report uncertainty
- Don't oversell extrapolation as prediction

---

### 8.3 Limitations (0.5 pages)

**Content:**
- Relies on P_{p+k} sharing structure with P_t, t ≤ p
- Single future period focus (extension to multiple periods: future work)
- No formal sensitivity analysis for violations
- Assumes first-stage identification secured

---

### 8.4 Extensions (0.25 pages)

**Content:**
- Multiple future periods: Forecasting trajectories
- Sensitivity bounds: Formal uncertainty quantification
- Dynamic treatment regimes: Time-varying policies
- Heterogeneous populations: Covariate-specific FATTs

---

## Page Count Summary

| Section | Outline Target | Realistic Target |
|---------|---------------|------------------|
| 1. Introduction | 4 → 3 | 3.5 |
| 2. Setting | 2 | 2 |
| 3. Estimands | 3 → 2.5 | 2.5 |
| 4. Identification | 9 → 7.5 | 8 |
| 5. Inference | 4 → 3 | 3.5 |
| 6. Simulations | 3 | 3 |
| 7. Application | 3 | 3 |
| 8. Discussion | 2 | 2 |
| **Total Main** | **26 → 23.5** | **27.5** |

**Note:** Target is 20-25 pages. Realistic estimate 27.5 suggests further trimming needed:
- Introduction: 3.5 → 3 pages (tighten related work integration)
- Identification: 8 → 7 pages (streamline examples, move edge cases to supplement)
- Inference: 3.5 → 3 pages (higher-level overview)

**Achievable target:** 24-25 pages main paper

---

## Key Changes from Current Paper

### What's New
1. **Section 3 (Estimands):** Dedicated section elevating estimand definition as core contribution
2. **Integrated related work:** No separate subsection, woven into introduction
3. **Equal weight to paths:** All three paths get ~2 pages each
4. **Lean inference:** EIF overview only, not full derivations

### What's Cut
1. **FATU and FATS:** Dropped to footnotes or supplement
2. **Forward-looking connections:** Absorbed into Section 3
3. **Proofs:** All move to supplement
4. **Detailed regularity conditions:** Stated in theorems, details in supplement
5. **Post-selection inference details:** Supplement
6. **5+ simulation tables:** Consolidated to 1 main table

### What's Moved to Supplement
1. All proofs (15 pages)
2. EIF derivations (5 pages)
3. Model selection details (6 pages)
4. Extended simulations (8 pages)
5. Application details (3 pages)
6. Total supplement: ~37 pages

---

## Next Steps After Outline Approval

1. **Create supplement structure** (`supplement-structure.md`)
2. **Create LaTeX skeleton** (`main-lean.tex`)
3. **User review** of outline and skeleton
4. **Incremental drafting:**
   - Start with Introduction (sets tone)
   - Then Identification (core contribution)
   - Then Estimands (new section)
   - Then remaining sections

**Quality target:** 90/100 (submission-ready outline)

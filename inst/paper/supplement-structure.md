# Supplement Structure: Organizing Technical Material

**Purpose:** Map all technical content that doesn't fit in the 20-25 page main paper to a well-organized supplement.

**Total supplement target:** ~35-40 pages (appendices A-E)

---

## Supplement Overview

| Appendix | Title | Content | Pages | Source |
|----------|-------|---------|-------|--------|
| A | Proofs | All proposition and theorem proofs | 15 | Main text theorems + new proofs |
| B | EIF Derivations | Detailed efficient influence functions | 5 | Section 5.1 expanded |
| C | Model Selection | CV algorithm, post-selection inference | 6 | Section 5.2 expanded |
| D | Extended Simulations | All 6 scenarios, robustness checks | 8 | Section 6 extended |
| E | Application Details | Data, validation metrics, robustness | 3 | Section 7 extended |
| **Total** | | | **37** | |

---

## Appendix A: Proofs (~15 pages)

### A.1 Regularity Conditions (2 pages)

**Content:**
- Complete formal statement of all regularity conditions
- Conditions for Path 1, 2, 3 identification results
- Conditions for asymptotic normality (Theorem 1)
- Discussion: When conditions are mild vs. restrictive

**Technical assumptions:**
1. **Overlap:** P(A_it = a | X_i) bounded away from 0, 1
2. **Smoothness:** Nuisance functions differentiable with bounded derivatives
3. **Moment conditions:** Finite second moments for Y_it(a)
4. **Consistency rates:** First-stage estimators converge at √n rate
5. **Regularity of f(·;γ):** Path 2 functional form conditions
6. **Covariate support:** Common support for Path 3 integration

**Notation table:** Full notation reference (extended from main text)

---

### A.2 Proof of Proposition 1 (Path 1: Time Homogeneity) (2 pages)

**Theorem statement:**
Under Assumption 1 (strict time homogeneity: θ_gt = θ_g):
```
τ_FATT(p+m) = Σ_g π_g θ_g
```

**Proof strategy:**
1. Expand FATT definition
2. Apply time homogeneity assumption
3. Rearrange and identify with weighted average
4. Show weights π_g are identified

**Full proof:** Step-by-step derivation with all intermediate algebra

**Corollary A.1 (Aggregate homogeneity):**
Under Assumption 1' (aggregate time homogeneity):
```
τ_FATT(p+1) = θ_ATT
```

**Proof:** Special case of Proposition 1 with π_g integrated out

---

### A.3 Proof of Proposition 2 (Path 2: Parametric Extrapolation) (3 pages)

**Theorem statement:**
Under Assumption 2 (θ_gt = f(g,t;γ)) with γ identified from {θ_gt: t ≤ p}:
```
τ_FATT(p+m) = Σ_g π_g f(g,p+m;γ)
```

**Proof strategy:**
1. Expand FATT with extrapolation function
2. Show γ identified by method of moments on observed periods
3. Demonstrate consistency of γ̂
4. Apply continuous mapping theorem

**Full proof:**
- Identification of γ from {θ_gt: t ≤ p}
- Conditions for extrapolation: f(·;γ) smooth, identifiable
- Asymptotic properties of plug-in estimator

**Remark A.1 (Model misspecification):**
If true DGP is θ_gt = f*(g,t) but we fit f(g,t;γ):
- Best approximation: γ* = argmin E[(f*(g,t) - f(g,t;γ))²]
- Bias: E[τ̂_FATT] → Σ_g π_g f(g,p+m;γ*) ≠ τ_FATT
- Implication: Model selection crucial

---

### A.4 Proof of Proposition 3 (Path 3: Covariate Integration) (3 pages)

**Theorem statement:**
Under Assumption 3 (structural covariate stability: θ(x,g,t) = θ(x,g)):
```
τ_FATT(p+m) = Σ_g π_g ∫ θ(x,g) dP_X|G,A(x|g,1)
```

**Proof strategy:**
1. Expand FATT with conditional effects
2. Apply structural stability assumption
3. Integrate over covariate distribution
4. Show θ(x,g) and P_X identified

**Full proof:**
- Identification of conditional effects from observed data
- Integration over P_X: g-computation or doubly robust
- Conditions: Overlap, positivity, correct conditional model

**Remark A.2 (Lucas Critique connection):**
- Reduced form θ_gt may vary even if θ(x,g) stable
- If P_X(x|t) changes (regime shift), aggregate effects change
- Structural model robust if X captures deep parameters

---

### A.5 Proof of Theorem 1 (Asymptotic Normality) (4 pages)

**Theorem statement:**
Under regularity conditions A.1-A.6:
```
√n(τ̂_FATT - τ_FATT) →^d N(0, V)
```
where V = E[ψ_FATT²] with ψ_FATT = [explicit formula].

**Proof strategy:**
1. EIF of θ_gt from first-stage design
2. Functional delta method for aggregation
3. EIF of FATT via chain rule
4. Variance calculation

**Full proof:**
- **Step 1:** Review EIF of θ̂_gt (from literature)
- **Step 2:** FATT is smooth functional of (θ_g1,...,θ_gp, γ, π)
- **Step 3:** Apply functional delta method
- **Step 4:** Derive influence function ψ_FATT
- **Step 5:** Show √n consistency, asymptotic normality

**Technical lemmas:**
- **Lemma A.1:** Functional differentiability of aggregation operator
- **Lemma A.2:** Rate conditions for extrapolation parameter γ̂
- **Lemma A.3:** Variance decomposition across sources

---

### A.6 Additional Technical Results (1 page)

**Lemma A.4 (Identification of weights):**
Weights π_g = P(G_i = g | A_{ip} = 1) identified from observed data

**Lemma A.5 (Extrapolation bias bound):**
Under misspecification, bound on E[τ̂_FATT - τ_FATT] as function of model error

**Lemma A.6 (Uniform convergence):**
Conditions for sup_{m ≤ M} |τ̂_FATT(p+m) - τ_FATT(p+m)| →^p 0

---

## Appendix B: EIF Derivations (~5 pages)

### B.1 General EIF Propagation Framework (2 pages)

**Content:**
- Review: Efficient influence functions for average treatment effects
- Functional delta method: How EIFs propagate through smooth functionals
- Chain rule for EIF: Derivative of outer functional × EIF of inner functional

**Key results:**
- **Proposition B.1:** If Θ = h(θ_1,...,θ_K) smooth, then:
  ```
  ψ_Θ = Σ_k (∂h/∂θ_k) ψ_k
  ```
  where ψ_k is EIF of θ_k

**Examples:**
- Weighted average: EIF of Σ w_k θ_k
- Ratio: EIF of θ_1/θ_2
- Nonlinear aggregation

---

### B.2 EIF for Path 1 (Time Homogeneity) (1 page)

**Derivation:**
```
τ_FATT = Σ_g π_g θ_g
```

**EIF components:**
1. EIF of θ_g from first-stage design
2. EIF of π_g (sample proportion)
3. Product rule for π_g × θ_g
4. Sum over groups

**Result:**
```
ψ_FATT = Σ_g [π_g ψ_{θ_g} + θ_g ψ_{π_g}]
```

**Variance:** V = E[ψ_FATT²]

---

### B.3 EIF for Path 2 (Parametric Extrapolation) (1.5 pages)

**Derivation:**
```
τ_FATT = Σ_g π_g f(g,p+m;γ)
```

**EIF components:**
1. EIF of γ from fitting f(g,t;γ) to {θ_gt: t ≤ p}
2. Derivative ∂f/∂γ at extrapolation point
3. EIF of π_g
4. Product and sum rules

**Result:**
```
ψ_FATT = Σ_g [π_g (∂f/∂γ) ψ_γ + π_g ψ_{f(g,p+m;γ)} + f(g,p+m;γ) ψ_{π_g}]
```

**Key insight:** Extrapolation uncertainty enters via (∂f/∂γ) ψ_γ

**Variance:** Decomposes into:
1. First-stage uncertainty (θ_gt)
2. Extrapolation parameter uncertainty (γ)
3. Weight estimation (π_g)

---

### B.4 EIF for Path 3 (Covariate Integration) (0.5 pages)

**Derivation:**
```
τ_FATT = Σ_g π_g ∫ θ(x,g) dP_X(x)
```

**EIF components:**
1. EIF of conditional effect θ(x,g)
2. Integration operator (expectation over X)
3. EIF of π_g

**Result:**
```
ψ_FATT = Σ_g [π_g E[ψ_{θ(X,g)} | G=g, A=1] + (∫ θ(x,g) dP_X) ψ_{π_g}]
```

**Computational note:** Numerical integration or Monte Carlo for E[ψ_{θ(X,g)}]

---

## Appendix C: Model Selection Details (~6 pages)

### C.1 Time-Series Cross-Validation Framework (2 pages)

**Content:**
- Formal setup: Splitting temporal data
- Validation window choice: h = 1, 2, ..., h_max
- Multiple splits: Rolling window vs. expanding window

**Algorithm (full detail):**
```
Input: {θ̂_gt: g=1,...,G, t=1,...,p}, candidate models {f_1,...,f_K}, validation window h

For each model k = 1,...,K:
  For each validation split s = 1,...,S:
    1. Training: Fit γ̂_k on {θ̂_gt: t ≤ p-h_s}
    2. Validation: Predict θ̃_gt,k = f_k(g,t;γ̂_k) for p-h_s < t ≤ p
    3. Compute validation metric: MSE_s,k = Σ_{g,t∈val} (θ̂_gt - θ̃_gt,k)²
    4. Compute coverage: COV_s,k = Proportion of CIs containing θ̂_gt
  5. Aggregate: MSE_k = mean(MSE_s,k), COV_k = mean(COV_s,k)

Select: k* = argmin MSE_k subject to COV_k ≥ 0.90
```

**Validation metrics:**
- MSE (mean squared error)
- MAE (mean absolute error)
- Coverage (proportion of CIs containing validation estimates)
- Interval width (average uncertainty)

**Choice of h:**
- Trade-off: Larger h → less training data, more realistic validation
- Recommendation: h = p/5 (20% validation)
- Sensitivity: Try multiple h values

---

### C.2 Coverage-Based Selection (1.5 pages)

**Content:**
- Rationale: Point prediction ignores uncertainty
- Coverage criterion: Select model with COV_k ≥ 1-α
- Among valid models, minimize prediction error

**Theorem C.1 (Coverage properties):**
Under correct model specification:
```
P(θ_gt ∈ CI_{1-α}(θ̃_gt)) → 1-α
```

**Advantage over MSE-only:**
- Penalizes overconfident extrapolation
- Balances bias and variance
- More robust to overfitting

**Example:**
- Model A: MSE = 0.10, Coverage = 0.75 (overconfident)
- Model B: MSE = 0.15, Coverage = 0.93 (well-calibrated)
- Selection: Choose Model B

---

### C.3 Post-Selection Inference (1.5 pages)

**Content:**
- Challenge: Selected model k* is random
- Naive inference: Treat k* as fixed → undercoverage
- Adjustments: Bootstrap, data splitting, selective inference

**Approach 1: Sample splitting**
1. Split data: Selection set vs. inference set
2. Select model on selection set
3. Fit and infer on inference set
4. Valid inference but lower power

**Approach 2: Post-selection bootstrap**
1. Select model k* on full data
2. Bootstrap: Resample, reselect, check if same model selected
3. Adjust CI to account for selection variability
4. Better power, more complex

**Theorem C.2 (Selective inference):**
Under conditions, post-selection CI achieves:
```
P(τ_FATT ∈ CI_{1-α,selective}) ≥ 1-α
```

**Practical recommendation:**
- Report results for selected model
- Sensitivity: Show top 3 models
- Honest uncertainty: Wider CIs post-selection

---

### C.4 Implementation Details (1 page)

**Content:**
- Computational considerations
- Parallel computation across candidate models
- Software: R package `extrapolateATT` functions
  - `cv_extrapolation()`: Run time-series CV
  - `select_model()`: Coverage-based selection
  - `post_select_inference()`: Adjusted CIs

**Code example:**
```r
# Fit candidate models
models <- list(
  linear = model_spec("linear"),
  quadratic = model_spec("quadratic"),
  spline = model_spec("spline", knots = c(3, 6))
)

# Cross-validation
cv_results <- cv_extrapolation(
  theta_gt = estimates,
  models = models,
  validation_window = 4
)

# Select best model
best_model <- select_model(cv_results, criterion = "coverage")

# Post-selection inference
fatt_estimate <- extrapolate_fatt(
  model = best_model,
  post_selection = TRUE
)
```

---

## Appendix D: Extended Simulations (~8 pages)

### D.1 Full Simulation Design (2 pages)

**Content:**
- All 6 DGP scenarios (not just 3 in main text)
- Complete parameter specifications
- Data-generating equations

**Scenario 1: Strict time homogeneity**
- DGP: θ_gt = α_g where α_g ~ N(0.5, 0.2)
- Sample sizes: n = 100, 200, 500
- Periods: p = 10, 20, 30
- Cohorts: G ∈ {5, 8, 11, 14, 17}

**Scenario 2: Linear dynamics**
- DGP: θ_gt = α_g + β(t-g) where β = 0.05
- Same sample sizes and periods

**Scenario 3: Quadratic dynamics**
- DGP: θ_gt = α_g + β_1(t-g) + β_2(t-g)²
- β_1 = 0.1, β_2 = -0.005

**Scenario 4: Regime change (time)**
- DGP: θ_gt = α_g + β(t-g) for t ≤ 15
- DGP: θ_gt = α_g + 2β(t-g) for t > 15
- Tests robustness to structural breaks

**Scenario 5: Covariate-driven effects**
- DGP: θ(x,g) = γ_0 + γ_1 x + γ_2 g where x ~ N(0,1)
- Aggregate: θ_gt = ∫ θ(x,g) dP_X(x|G=g,t)
- P_X shifts over time

**Scenario 6: Regime change (covariates)**
- DGP: θ(x,g) stable but P_X(x|t) shifts at t = 15
- Tests Path 3 robustness

**Table D.1:** Complete parameter specifications for all scenarios

---

### D.2 Small-Sample Properties (1.5 pages)

**Content:**
- Results for n = 100 (small), n = 200 (moderate), n = 500 (large)
- All three paths across all scenarios
- Focus: Coverage in finite samples, bias-variance trade-off

**Table D.2:** Results for n = 100

| Scenario | Method | Bias | RMSE | Coverage |
|----------|--------|------|------|----------|
| (All 6 scenarios × 3 methods = 18 rows) |

**Findings:**
- Coverage deteriorates at n = 100 for complex models
- Path 1 maintains coverage even small n (fewer parameters)
- Path 2 and 3 need larger n for asymptotic approximation

---

### D.3 Misspecification Robustness (2 pages)

**Content:**
- What happens when assumptions violated?
- Scenario: True DGP quadratic, fit linear (Path 2 misspecified)
- Scenario: True DGP has time-varying covariates, assume stability (Path 3 misspecified)

**Table D.3:** Misspecification results

**Findings:**
- Misspecification → bias
- Coverage failure: CIs don't account for model error
- Model selection helps but not perfect

**Lesson:** No path dominant under misspecification; sensitivity analysis crucial

---

### D.4 Longer Extrapolation Horizons (1.5 pages)

**Content:**
- Extrapolate to p+1, p+5, p+10
- Uncertainty grows with horizon
- Path performance diverges more at longer horizons

**Table D.4:** Results by extrapolation horizon

| Horizon | Method | Bias | RMSE | Coverage |
|---------|--------|------|------|----------|
| p+1 | Path 1 | 0.01 | 0.12 | 0.95 |
| p+5 | Path 1 | 0.02 | 0.18 | 0.94 |
| p+10 | Path 1 | 0.03 | 0.25 | 0.93 |
| (Similar for Path 2, Path 3) |

**Findings:**
- RMSE increases with horizon (more extrapolation)
- Coverage approximately maintained (asymptotic theory holds)
- Path 2 and 3 degrade more than Path 1 at long horizons (model error accumulates)

---

### D.5 Stress Tests (Section 8 Compliance) (1 page)

**Content:**
- Constitutional requirement (§9): Include regimes where method struggles
- Stress tests:
  1. Near-singularity: Low overlap (propensity scores near 0 or 1)
  2. Heavy tails: Outcome distribution with high kurtosis
  3. Weak signal: Small treatment effects (α_g ~ N(0.05, 0.01))
  4. High noise: Large variance in outcomes

**Table D.5:** Stress test results

**Findings:**
- All methods struggle with near-singularity (large variance)
- Heavy tails: Inference degrades (outliers dominate)
- Weak signal: Low power, wide CIs
- High noise: RMSE increases, but coverage maintained

**Honest reporting:** Methods have limits; no free lunch

---

## Appendix E: Application Details (~3 pages)

### E.1 Data Sources and Construction (1 page)

**Content:**
- Data source: CDC WONDER (homicide rates), US Census (covariates)
- Stand-Your-Ground law adoption dates (from legal database)
- Sample: 50 states + DC, 1981-2022
- Treatment: Indicator for SYG law in effect
- Outcome: Age-adjusted homicide rate per 100,000
- Covariates: Poverty rate, urbanization, unemployment, prior crime rate

**Table E.1:** Descriptive statistics

| Variable | Mean | SD | Min | Max |
|----------|------|-----|-----|-----|
| Homicide rate | 5.2 | 3.1 | 0.8 | 18.2 |
| Poverty rate | 12.3 | 3.4 | 5.2 | 22.1 |
| Urban % | 68.4 | 15.2 | 32.1 | 95.8 |

**Adoption timing:**
- 2005: Florida (first)
- 2006-2010: 12 states
- 2011-2015: 10 states
- Never adopters: 28 states

---

### E.2 Estimation Details (1 page)

**Content:**

**First-stage (DiD):**
- Callaway & Sant'Anna (2021) estimator
- Parallel trends assumption
- Never-adopters as comparison group
- Estimate θ̂_gt for each cohort g, calendar time t

**Path 1 (Time homogeneity):**
- Aggregate θ̂_gt across time for each group
- Weights: Proportion of states in each cohort

**Path 2 (Linear trend):**
- Fit: θ_gt = α_g + β(t-g)
- Extrapolate: θ̂_{g,2016} = α̂_g + β̂(2016-g)

**Path 3 (Covariates):**
- Conditional effects: θ(x,g) = γ_0 + γ_1 x_poverty + γ_2 x_urban
- Integrate over 2016 covariate distribution

**Software:** R packages `did`, `extrapolateATT`

---

### E.3 Validation Metrics and Robustness (1 page)

**Content:**

**Table E.2:** Year-by-year validation

| Year | Observed | Path 1 | Path 2 | Path 3 |
|------|----------|--------|--------|--------|
| 2016 | 0.45 (0.12) | 0.22 | 0.28 | 0.31 |
| 2017 | 0.52 (0.13) | 0.22 | 0.35 | 0.38 |
| 2018 | 0.58 (0.14) | 0.22 | 0.42 | 0.44 |
| 2019 | 0.61 (0.14) | 0.22 | 0.49 | 0.50 |
| 2020 | 0.71 (0.15) | 0.22 | 0.56 | 0.58 |
| 2021 | 0.76 (0.15) | 0.22 | 0.63 | 0.65 |
| 2022 | 0.79 (0.16) | 0.22 | 0.70 | 0.72 |

**Interpretation:**
- All paths underpredict
- Gap widens over time (effects accelerating)
- Path 3 closest but still misses by ~0.15 in 2022

**Robustness checks:**
1. Alternative comparison groups (early adopters vs. never adopters)
2. Different covariate specifications (adding interactions)
3. Alternative outcome definitions (firearm homicides only)
4. Sensitivity to pre-trend violations

**Table E.3:** Robustness results
(Same structure, varying specifications)

**Finding:** Qualitative result robust - all methods underpredict

---

## Content Mapping: Current → Supplement

### From Current Main Text (46 pages → 25 pages main + 37 pages supplement)

**Current Appendix (20 pages) → Supplement:**
- Current proofs → Appendix A (expanded)
- Current EIF derivations → Appendix B (expanded)
- Current regularity conditions → Appendix A.1

**Current Main Text (26 pages) → Selectively Moved:**
- Section 5.2 (Model selection): Overview stays, details → Appendix C
- Section 7.7 (CV simulation): Delete or merge into Appendix C
- Simulation details: Main text gets Table 1 only, rest → Appendix D
- Application tables: Main text gets 1 table, rest → Appendix E

**New Supplement Content:**
- Appendix C (Model selection details): NEW, expanded from main text
- Appendix D.5 (Stress tests): NEW for constitution §9 compliance
- Appendix E (Application details): NEW, expanded from main text

---

## Verification Checklist

After creating supplement:

- [ ] All main text theorems have proofs in Appendix A
- [ ] All EIF formulas have derivations in Appendix B
- [ ] Model selection algorithm fully specified in Appendix C
- [ ] All 6 simulation scenarios documented in Appendix D
- [ ] Stress tests (constitution §9) included in Appendix D.5
- [ ] Application data sources documented in Appendix E.1
- [ ] Robustness checks documented in Appendix E.3
- [ ] Cross-references: Main text cites appendix sections correctly
- [ ] Supplement is self-contained (can read independently)
- [ ] Total length: ~35-40 pages (not >50)

---

## LaTeX Structure

**Supplement file:** `supplement.tex`

**Preamble:**
```latex
\documentclass{article}
\usepackage{amsmath, amsthm, amssymb}
\title{Estimating Policy Effects in the Presence of Heterogeneity: Supplementary Material}
\author{[Authors]}

% Theorem environments
\newtheorem{theorem}{Theorem}
\newtheorem{proposition}{Proposition}
\newtheorem{lemma}{Lemma}
\newtheorem{corollary}{Corollary}

% Appendix numbering
\renewcommand{\thesection}{A\arabic{section}}
\renewcommand{\theequation}{A\arabic{equation}}
```

**Structure:**
```latex
\begin{document}
\maketitle

\section{Proofs}
\subsection{Regularity Conditions}
...
\subsection{Proof of Proposition 1}
...

\section{EIF Derivations}
...

\section{Model Selection Details}
...

\section{Extended Simulations}
...

\section{Application Details}
...

\end{document}
```

---

## Next Steps

1. **User review:** Get feedback on supplement organization
2. **Content extraction:** Pull relevant content from current `main.tex`
3. **Drafting new sections:** Write new supplement sections (C, D.5, E)
4. **Cross-referencing:** Ensure main text and supplement cite each other correctly
5. **Compilation:** Test that supplement compiles standalone

**Quality target:** 90/100 (submission-ready supplement structure)

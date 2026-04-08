# EIF for Synthetic Control: Theoretical Sketch

**Date:** 2026-03-04
**Status:** Draft theory for paper

---

## 1. Setup and Notation

### Data Structure

Panel data: $\{(Y_{it}, D_i, X_i) : i = 1, \ldots, N; t = 1, \ldots, T\}$

- $Y_{it}$: Outcome for unit $i$ at time $t$
- $D_i \in \{0, 1\}$: Treatment indicator (0 = control, 1 = treated)
- $X_i$: Baseline covariates (time-invariant)
- $Y_{i,\text{pre}} = (Y_{i1}, \ldots, Y_{i,T_0})$: Pre-treatment outcomes

**Periods:**
- Pre-treatment: $t = 1, \ldots, T_0$
- Post-treatment: $t = T_0 + 1, \ldots, T$

**Sample sizes:**
- $N_1 = \sum_i D_i$: Number of treated units
- $N_0 = N - N_1$: Number of control units

### Potential Outcomes

- $Y_{it}(1)$: Outcome under treatment
- $Y_{it}(0)$: Outcome under control

**Observed outcome:** $Y_{it} = D_i Y_{it}(1) + (1-D_i) Y_{it}(0)$

### Estimand

For a specific post-treatment period $t > T_0$:

$$\tau_t = \mathbb{E}[Y_{it}(1) - Y_{it}(0) \mid D_i = 1]$$

This is the **average treatment effect on the treated (ATT)** at time $t$.

Since we observe $Y_{it}(1)$ for treated units:

$$\tau_t = \mathbb{E}[Y_{it} \mid D_i = 1] - \mathbb{E}[Y_{it}(0) \mid D_i = 1]$$

The challenge: estimating $\mathbb{E}[Y_{it}(0) \mid D_i = 1]$ (the counterfactual).

---

## 2. Identification

### Assumption 1: Conditional Parallel Trends (SC Identification)

For all $t > T_0$:

$$\mathbb{E}[Y_{it}(0) \mid D_i = 1, Y_{i,\text{pre}}, X_i] = \mathbb{E}[Y_{it}(0) \mid D_i = 0, Y_{i,\text{pre}}, X_i]$$

**Interpretation:** Conditional on pre-treatment outcomes and covariates, treated and control units have the same expected counterfactual outcome.

**Contrast with DiD:** DiD assumes *unconditional* parallel trends:
$$\mathbb{E}[Y_{it}(0) - Y_{is}(0) \mid D_i = 1] = \mathbb{E}[Y_{it}(0) - Y_{is}(0) \mid D_i = 0]$$

SC is weaker (allows violations of unconditional parallel trends) but requires high-dimensional matching on $Y_{i,\text{pre}}$.

### Assumption 2: Common Support

For all $(y_{\text{pre}}, x)$ in the support of $(Y_{i,\text{pre}}, X_i) \mid D_i = 1$:

$$P(D_i = 1 \mid Y_{i,\text{pre}} = y_{\text{pre}}, X_i = x) < 1$$

**Interpretation:** Every treated unit's pre-treatment path has a match among controls.

### Identified Functional

Under Assumptions 1-2:

$$\begin{align}
\mathbb{E}[Y_{it}(0) \mid D_i = 1] &= \mathbb{E}[\mathbb{E}[Y_{it}(0) \mid D_i = 0, Y_{i,\text{pre}}, X_i] \mid D_i = 1] \\
&= \mathbb{E}[\mathbb{E}[Y_{it} \mid D_i = 0, Y_{i,\text{pre}}, X_i] \mid D_i = 1] \\
&= \mathbb{E}[m(Y_{i,\text{pre}}, X_i) \mid D_i = 1]
\end{align}$$

where:
$$m(y_{\text{pre}}, x) = \mathbb{E}[Y_{it} \mid D_i = 0, Y_{i,\text{pre}} = y_{\text{pre}}, X_i = x]$$

**This is the observed data functional that SC estimates.**

---

## 3. Statistical Model

### Semiparametric Model

- **Parametric:** The form of $\tau_t$ (difference in means)
- **Nonparametric:**
  - $m(y_{\text{pre}}, x)$ (outcome model, high-dimensional)
  - $e(y_{\text{pre}}, x) = P(D_i = 1 \mid Y_{i,\text{pre}} = y_{\text{pre}}, X_i = x)$ (generalized propensity score)
  - Distribution of $(Y_{it}, Y_{i,\text{pre}}, X_i, D_i)$

### Nuisance Parameters

$$\eta = (m, e, F_{Y,X \mid D})$$

where $F_{Y,X \mid D}$ is the conditional distribution of outcomes and covariates given treatment.

---

## 4. Efficient Influence Function

### Theorem (EIF for SC Functional)

Under regularity conditions, the efficient influence function for $\theta = \mathbb{E}[m(Y_{i,\text{pre}}, X_i) \mid D_i = 1]$ is:

$$\begin{align}
\psi(O_i; \theta, \eta) &= \frac{D_i}{P(D_i = 1)} \Big[ Y_{it} - m(Y_{i,\text{pre}}, X_i) \Big] \\
&\quad + \frac{(1-D_i) \cdot e(Y_{i,\text{pre}}, X_i)}{(1 - e(Y_{i,\text{pre}}, X_i)) \cdot P(D_i = 1)} \Big[ Y_{it} - m(Y_{i,\text{pre}}, X_i) \Big] \\
&\quad + \frac{D_i}{P(D_i = 1)} \Big[ m(Y_{i,\text{pre}}, X_i) - \theta \Big]
\end{align}$$

where $O_i = (Y_{it}, Y_{i,\text{pre}}, X_i, D_i)$.

### Components

1. **Treated residuals:** $\frac{D_i}{P(D_i=1)} [Y_{it} - m(Y_{i,\text{pre}}, X_i)]$
   - How much do treated outcomes differ from predicted?
   - Scaled by inverse probability of treatment

2. **Control contribution:** $\frac{(1-D_i) \cdot e(\cdot)}{(1-e(\cdot)) \cdot P(D_i=1)} [Y_{it} - m(\cdot)]$
   - Reweighted control residuals (importance sampling)
   - Weight controls by how likely they are to "match" treated units

3. **Centering:** $\frac{D_i}{P(D_i=1)} [m(Y_{i,\text{pre}}, X_i) - \theta]$
   - Makes $\mathbb{E}[\psi] = 0$

### Properties

**Proposition (Double Robustness):**

If either:
- (A) $m$ is correctly specified, OR
- (B) $e$ is correctly specified

Then $\hat{\theta}$ based on $\psi$ is consistent and asymptotically normal with variance $\mathbb{E}[\psi^2]$.

**Proof sketch:** The EIF is the unique mean-zero function satisfying:
$$\mathbb{E}[\psi(O; \theta, \eta)] = 0$$
and
$$\theta = \mathbb{E}[\psi(O; \theta, \eta)] + \theta$$

When $m$ is correct, the residuals $(Y_{it} - m)$ have mean zero conditional on $(Y_{i,\text{pre}}, X_i, D_i)$, so the first two terms vanish in expectation.

When $e$ is correct and $m$ is wrong, the reweighting in the second term compensates for misspecification of $m$.

---

## 5. Connection to SC Methods

### Standard Synthetic Control

SC finds weights $\{w_i\}$ for control units that minimize:

$$\min_{w \geq 0, \sum w_i = 1} \| Y_{\text{treated},\text{pre}} - \sum_{j: D_j = 0} w_j Y_{j,\text{pre}} \|^2$$

Then predicts: $\hat{m}(Y_{i,\text{pre}}, X_i) = \sum_{j} w_{ij} Y_{jt}$

**Interpretation:** SC implicitly estimates $m$ via weighted averaging.

### Augmented Synthetic Control

Augmented SC combines:
1. Outcome model: $\hat{m}$ estimated via regression (e.g., ridge, factor model)
2. SC weights: $\{w_i\}$ for matching

Estimator:
$$\hat{\theta}_{\text{aug}} = \frac{1}{N_1} \sum_{i: D_i=1} \Big[ Y_{it} - \hat{m}(Y_{i,\text{pre}}, X_i) \Big] + \frac{1}{N_1} \sum_{i: D_i=1} \hat{m}(Y_{i,\text{pre}}, X_i)$$

This is the **doubly robust** point estimator.

**Our contribution:** Use the EIF for *inference* (variance estimation), not just point estimation.

---

## 6. Estimation and Inference

### Algorithm

**Step 1:** Estimate nuisances
- Outcome model: $\hat{m}$ via ridge regression, factor models, or SC weights
- Propensity score: $\hat{e}$ (optional, can use empirical distribution)

**Step 2:** Compute ATT
$$\hat{\tau}_t = \frac{1}{N_1} \sum_{i: D_i=1} Y_{it} - \frac{1}{N_1} \sum_{i: D_i=1} \hat{m}(Y_{i,\text{pre}}, X_i)$$

**Step 3:** Compute EIF for each unit
$$\hat{\psi}_i = \frac{D_i}{\hat{P}(D=1)} [Y_{it} - \hat{m}(\cdot)] + \frac{(1-D_i) \hat{e}(\cdot)}{(1-\hat{e}(\cdot)) \hat{P}(D=1)} [Y_{it} - \hat{m}(\cdot)] + \frac{D_i}{\hat{P}(D=1)} [\hat{m}(\cdot) - \hat{\theta}]$$

**Step 4:** Variance estimate
$$\hat{V} = \frac{1}{N} \sum_{i=1}^N \hat{\psi}_i^2$$

**Step 5:** Inference
$$\hat{\tau}_t \pm 1.96 \sqrt{\hat{V}}$$

### Asymptotic Theory

**Theorem:** Under regularity conditions:
1. Rate condition: $\|\hat{m} - m\| \|\hat{e} - e\| = o_P(N^{-1/2})$
2. Consistency of nuisances: $\|\hat{m} - m\| = o_P(1)$, $\|\hat{e} - e\| = o_P(1)$

Then:
$$\sqrt{N}(\hat{\tau}_t - \tau_t) \xrightarrow{d} N(0, \mathbb{E}[\psi^2])$$

and $\hat{V}$ is consistent for $\mathbb{E}[\psi^2]$.

**Key requirement:** Nuisances must converge at rate faster than $N^{-1/4}$ (product limit).

With ridge regression or factor models, this is typically satisfied when:
- $T_0$ (number of pre-treatment periods) is not too large relative to $N$
- Signal-to-noise ratio is reasonable
- $m$ is not too rough (smoothness assumptions)

---

## 7. Comparison to Existing Methods

### Method: Placebo Inference (Abadie et al.)

**Approach:** Apply SC to control units, use placebo distribution for inference

**Problems:**
- Doesn't account for outcome model uncertainty
- Assumes exchangeability (treated and controls have same variance)
- Often undercovers (variance too small)

### Method: Conformal Inference (Lei et al.)

**Approach:** Use conformal prediction intervals

**Pros:** Distribution-free, valid for small $N$

**Cons:**
- Conservative (wider CIs)
- Not efficient (doesn't achieve semiparametric bound)
- Requires strong exchangeability assumptions

### Method: Bootstrap

**Approach:** Resample units, recompute SC

**Problems:**
- Unstable with small $N$
- Doesn't properly account for nuisance estimation
- Computationally intensive

### EIF-Based Inference (Ours)

**Pros:**
- Achieves semiparametric efficiency bound
- Doubly robust (m or e correct suffices)
- Accounts for nuisance estimation uncertainty
- Closed-form variance (fast)

**Cons:**
- Requires moderate $N$ ($N \geq 50$?)
- Asymptotic approximation (may not work for small $N$)
- Requires estimating nuisances well

---

## 8. Open Questions

### Theoretical

1. **Rate requirements for high-dimensional $Y_{i,\text{pre}}$:**
   - With $T_0 \sim 10-50$, how does dimension affect rates?
   - Do we need additional structure (factor models, sparsity)?

2. **Propensity score $e(y_{\text{pre}}, x)$:**
   - Is this identifiable? (density estimation in high dimensions)
   - Can we avoid estimating $e$ explicitly?
   - Alternative: use SC weights as implicit propensity scores?

3. **Single treated unit:**
   - Can we define a conditional EIF given $Y_{1,\text{pre}} = y_0$?
   - Or is this fundamentally a design-based problem?

### Practical

1. **Small $N$ threshold:**
   - When does asymptotic approximation work? $N \geq 50$? $N \geq 100$?
   - Can we use bootstrap + EIF for small $N$?

2. **Cross-fitting:**
   - Is cross-fitting needed to avoid overfitting bias?
   - How to split with panel data?

3. **Staggered adoption:**
   - Extension to multiple treatment times?
   - Does EIF generalize to event study designs?

---

## 9. Next Steps

### Theory (Phase 3)

- Formalize regularity conditions
- Prove asymptotic normality under rate conditions
- Address high-dimensional $Y_{i,\text{pre}}$ (factor model structure?)
- Derive simplified EIF when $e$ is not estimated

### Simulations (Phase 4)

- Vary $N$, $N_1$, $T_0$, signal-to-noise
- Multiple DGPs (parallel trends, violations, misspecification)
- Compare to all existing methods
- Map out when EIF dominates

### Empirics (Phase 5)

- Find applications with multiple treated units
- Reanalyze with EIF-based inference
- Compare to published CIs
- Sensitivity to outcome model choice

---

## References (to add)

- Ben-Michael, Feller, Rothstein (2021) - Augmented SCM
- Arkhangelsky et al. (2021) - SDID
- Kennedy (2016, 2022) - Semiparametric theory
- Chernozhukov et al. (2018) - Double/debiased ML
- Hahn (1998) - Propensity score efficiency
- Abadie, Diamond, Hainmueller (2010, 2015) - SC
- Lei et al. (2018) - Conformal inference for SC

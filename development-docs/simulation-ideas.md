# Simulation ideas: story and operating characteristics

Ideas for simulations that (1) tell a story about the main themes of the paper and (2) illustrate the operating characteristics of the proposed approach (Path 1: time homogeneity; Path 2: parametric extrapolation; EIF-based inference).

**Paper themes to illustrate:**
- Backward-looking ATT (or simple aggregation of group-time effects) can mislead for policy when effects are dynamic.
- Path 1: When time homogeneity holds, backward-looking estimands equal the FATT; when it fails, they are biased for the FATT.
- Path 2: Parametric extrapolation can recover the FATT when the model is correct and can be biased when misspecified.
- EIF-based aggregation/extrapolation gives correct standard errors and coverage when the model and first stage are correct.

---

## 1. Core narrative: backward-looking vs forward-looking

**Goal:** Show that the *target* of estimation matters. The same data can support an unbiased estimate of the backward-looking ATT but a biased “interpretation” of that number as the FATT when effects are time-heterogeneous.

**Setup (sketch):**
- Generate panel data with known group-time effects \(\theta_{gt}\) that vary by event time (e.g., linear or quadratic in \(k = t - g\)).
- Compute the true backward-looking ATT (e.g., average of \(\theta_{gt}\) over the observed \((g,t)\) with appropriate weights) and the true FATT \(\theta_{p+1}\) at \(p+1\).
- When dynamics are present, \(\theta \neq \theta_{p+1}\); the gap is the “bias” if one mistakenly treats the ATT as the FATT.

**Metrics:**
- Plot or table: true ATT vs true FATT as a function of strength of dynamics (e.g., slope of \(\theta_{gt}\) in event time).
- Message: “Interpreting the backward-looking ATT as the policy-relevant effect can be wrong when effects evolve.”

---

## 2. Path 1 (time homogeneity): when it works and when it fails

**Goal:** Demonstrate that under time homogeneity the FATT is identified by the ATT (or by \(\sum_g \omega_g \theta_{g\cdot}\)), and that when time homogeneity fails, using Path 1 yields bias for the FATT.

**Setup (sketch):**
- **Scenario A (time homogeneity):** Set \(\theta_{gt} = \theta_{g\cdot}\) (constant in \(t\) within group). True FATT = convex combination of \(\theta_{g\cdot}\). Estimate backward-looking group-time ATTs (e.g., from a simple DGP or from a DiD-style first stage), then form \(\widehat{\theta}_{p+1} = \sum_g \widehat{\omega}_g \widehat{\theta}_{g\cdot}\). Check bias and coverage for the FATT.
- **Scenario B (dynamics):** Set \(\theta_{gt}\) increasing or decreasing in event time. True FATT at \(p+1\) differs from the Path-1 estimand (which assumes constancy). Use the same Path-1 estimator and report bias relative to the true FATT.

**Metrics:**
- Bias and RMSE of \(\widehat{\theta}_{p+1}\) for the FATT under Scenario A (should be small) and Scenario B (bias illustrates cost of assuming time homogeneity).
- Coverage of Wald CIs (EIF-based) under Scenario A.

**Message:** Path 1 is valid only when time homogeneity holds; otherwise the researcher is estimating the wrong object for policy.

---

## 3. Path 2 (extrapolation): correct specification vs misspecification

**Goal:** Show that parametric extrapolation (Path 2) can perform well when \(f(g,t;\gamma)\) is correct and can be biased when \(f\) is wrong (e.g., linear when truth is quadratic).

**Setup (sketch):**
- **Data:** Group-time effects \(\theta_{gt}\) generated from a known model, e.g. \(\theta_{gt} = \alpha_g + \beta_g (t - g)\) (linear in event time) or \(\theta_{gt} = \alpha_g + \beta_g (t-g) + \delta_g (t-g)^2\).
- **Correct spec:** Fit the same functional form (e.g., linear in event time), estimate \(\gamma\), form \(\widehat{\theta}_{p+1} = \sum_g \omega_g f(g, p+1; \widehat{\gamma})\). Compare to true \(\theta_{p+1}\).
- **Misspec:** Generate data from quadratic model; fit linear model and extrapolate. Report bias and possibly MSE.

**Metrics:**
- Bias, RMSE, and coverage of \(\widehat{\theta}_{p+1}\) under correct and under misspecified \(f\).
- Optional: sensitivity of point estimate and CI to choice of \(f\) (linear vs quadratic) on the same DGP.

**Message:** Path 2 trades robustness for point identification; the choice of \(f\) matters and can be explored via sensitivity or specification checks.

---

## 4. EIF propagation: variance and coverage

**Goal:** Verify that the proposed EIF-based variance estimator and Wald intervals achieve nominal coverage when the first stage and (for Path 2) the extrapolation model are correct.

**Setup (sketch):**
- Use a tractable DGP where first-stage \(\widehat{\theta}_{gt}\) are unbiased (or consistent) with known or simulated influence functions.
- Implement the EIF for Path 1 and Path 2 (e.g., as in the package), compute \(\widehat{\sigma}^2 = n^{-1}\sum_i \widehat{\phi}_i^2\), and build Wald CIs \(\widehat{\theta}_{p+1} \pm z_{\alpha/2} \widehat{\sigma}/\sqrt{n}\).
- Over many replicates, check: (i) empirical variance of \(\widehat{\theta}_{p+1}\) vs average \(\widehat{\sigma}^2/n\); (ii) coverage of 95% CIs.

**Metrics:**
- Ratio of average estimated variance to empirical variance (should be near 1).
- Empirical coverage of 95% (and optionally 90%) CIs.

**Message:** The semiparametric variance and CIs are valid when the model and first stage are correct; this supports the theory in Section 5.

---

## 5. Path 1 vs Path 2 on the same data

**Goal:** On a single DGP that has moderate dynamics, compare (i) Path 1 (treat effects as constant within group) and (ii) Path 2 (fit linear or quadratic in event time and extrapolate). Neither need be perfectly correct; the comparison illustrates the tradeoff.

**Setup (sketch):**
- True \(\theta_{gt}\) with a mild trend in event time (e.g., small slope).
- Path 1: \(\widehat{\theta}_{p+1}^{(1)} = \sum_g \widehat{\omega}_g \widehat{\theta}_{g\cdot}\).
- Path 2: Fit \(\theta_{gt} = f(g,t;\gamma)\) (e.g., linear in event time), extrapolate to \(p+1\), aggregate.
- Report bias and MSE for both, and coverage for both (Path 1 may be biased but still have valid inference for the *Path-1* estimand if desired; clarify target).

**Message:** When dynamics are present, Path 2 can reduce bias for the FATT relative to Path 1; when dynamics are absent, Path 1 is simpler and avoids extrapolation assumptions.

---

## 6. Optional: role of \(\omega_g\) and cohort composition

**Goal:** Show that the FATT depends on the distribution of cohorts among the treated at \(p\) (\(\omega_g = \P(G_i=g|A_{ip}=1)\)). Different cohort mixes give different FATT even for the same set of group-time effects.

**Setup (sketch):**
- Fix \(\theta_{gt}\); vary \(\omega_g\) (e.g., more weight on early vs late adopters). Compute true FATT under each \(\omega\).
- Estimate \(\widehat{\omega}_g\) from data and use it in \(\widehat{\theta}_{p+1}\); compare with a misspecified \(\omega\) (e.g., uniform) to show that correct \(\omega\) matters for both Path 1 and Path 2.

**Message:** Policy-relevant FATT is a weighted average; the weights are identified from the distribution of treatment timing among current adopters.

---

## Suggested order for implementation

1. **Section 1** (backward-looking vs FATT) — establishes the *problem*.
2. **Section 2** (Path 1 under homogeneity vs dynamics) — establishes *when Path 1 is valid*.
3. **Section 3** (Path 2 correct vs misspecified) — establishes *when Path 2 is valid and when it is not*.
4. **Section 4** (EIF variance and coverage) — establishes *operating characteristics of inference*.
5. **Section 5** (Path 1 vs Path 2 comparison) — ties the two paths together.
6. **Section 6** (optional) — deepens the story on \(\omega_g\).

The existing `sims/scripts/demo_linear.R` fits Path 2 with a linear event-time model and could be extended into Section 3 and 4 (and 5) by adding known DGPs, bias/coverage loops, and optional Path-1 comparison.

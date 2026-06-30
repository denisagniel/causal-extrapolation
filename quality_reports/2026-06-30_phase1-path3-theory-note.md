# Phase 1 Theory Note — Path 3 Rewrite (Direct CATE + Transport)

**Status:** DRAFT for review. No edits to `main.tex` yet.
**Goal:** Replace the invert-β-from-marginal-ATTs Path 3 (audit C1/C2) with direct CATE estimation + transport to the future covariate distribution, keeping Path 3 *parallel* to Paths 1–2 (plug in an existing asymptotically-linear estimator → forward map → propagate EIF).

Notation follows `main.tex`: horizon fixed at $k=1$ (write $p+1$); $\mathbf{X}_i$ pre-treatment covariates (forecast to $p+1$ if time-varying); $\mathbb{P}_t$ the period-$t$ superpopulation; FATT $\theta_{p+1}=\mathbb{E}_{\mathbb{P}_{p+1}}\{Y_{i,p+1}(1)-Y_{i,p+1}(0)\mid A_{ip}=1\}$.

---

## 1. The object and the estimand

Define the **conditional ATT (CATE on the treated scale)** at period $t$:
$$\tau_t(x) = \mathbb{E}_{\mathbb{P}_t}\{Y_{it}(1) - Y_{it}(0) \mid \mathbf{X}_i = x,\ \text{treated}\}.$$

The FATT is the future conditional effect averaged over the future treated covariate distribution:
$$\theta_{p+1} = \int \tau_{p+1}(x)\, dF^{p+1}_{\mathbf{X}\mid A_{ip}=1}(x). \tag{1}$$

This is exact by iterated expectations — **no assumption yet**. (1) just says "the marginal future effect is the conditional future effect averaged over the future covariate mix." All identifying content is in getting from observed-data $\tau_t$ to $\tau_{p+1}$ and in accessing $F^{p+1}$.

---

## 2. Assumptions (stated before the result)

**A1 (First-stage conditional identification + nuisance rates).** Under the researcher's design, the relevant nuisances are identified from observed data ($t\le p$) and estimable, with cross-fitting, at rate $o_\mathbb{P}(n^{-1/4})$ in $L_2$.
- *Unconfoundedness design:* conditional unconfoundedness $\{Y_{it}(0),Y_{it}(1)\}\perp A_{it}\mid \mathbf{X}_i$ + overlap. Nuisances: outcome regressions $\mu_a(x)=\mathbb{E}[Y\mid \mathbf{X}=x,A=a]$ and propensity $e(x)=\mathbb{P}(A=1\mid \mathbf{X}=x)$; $\tau(x)=\mu_1(x)-\mu_0(x)$.
- *DiD design:* conditional parallel trends. Nuisances: conditional outcome-change regression and propensity; $\tau(x)$ via the DR-DiD (Sant'Anna–Zhao) construction, conditioned on $x$.

> **Important correction (rate caveat — thanks to DA).** I previously wrote A1 as "$\widehat\tau(\cdot)$ is asymptotically linear with influence function $\varphi_\tau$." **That is wrong in general.** When $\mathbf{X}$ is continuous and $\tau(x)$ is estimated nonparametrically, $\widehat\tau(x)$ converges at the slow rate $n^{-\beta/(2\beta+d)}$ (smoothness $\beta$, dimension $d$) — it is **not** $\sqrt n$-consistent and has **no** influence function. Asymptotic linearity holds for the *scalar functional* $\theta_{p+1}$, **not** for the function $\tau$. The reason $\theta_{p+1}$ can still be $\sqrt n$ is that it is a smooth (pathwise-differentiable) functional estimated by a **Neyman-orthogonal / doubly-robust** estimating equation: orthogonality removes first-order sensitivity to nuisance error, leaving only the **product** bias $\|\widehat\mu-\mu\|\cdot\|\widehat e-e\|=o_\mathbb{P}(n^{-1/2})$, which holds under the $o_\mathbb{P}(n^{-1/4})$ rate in A1. So the parametric/√n-CATE story is a *special case*; the general case requires the DR score in §4, not "$w\cdot\varphi_\tau$." A1 is therefore stated in terms of **nuisance rates**, not asymptotic linearity of $\widehat\tau$.

This is the Path-3 analog of "the researcher has an asymptotically-linear $\widehat\theta_{gt}$" in Paths 1–2 — **we import existing estimators; we do not develop one.** The analogy is at the level of the *target functional* $\theta_{p+1}$ being asymptotically linear, not the first-stage object.

**A2 (Structural stability of the conditional effect).** For all $x$ in the support and all $t\in\{1,\dots,p,p+1\}$,
$$\tau_t(x) = \tau(x).$$
The conditional effect is regime-invariant even though the marginal effect $\theta_t=\int\tau(x)\,dF^t_{\mathbf{X}}(x)$ may move with the covariate mix $F^t_{\mathbf{X}}$. This is the Lucas "deep parameters" content, now correctly attached: invariance is asserted at the *conditional* level, exactly where the structural claim belongs. **A2 is untestable** (concerns $\mathbb{P}_{p+1}$); state it as such, parallel to the untestable $p\!\to\!p\!+\!1$ assumption in Path 1.

**A3 (Access to the future covariate distribution + overlap).** Either (a) a sample $\{\mathbf{X}^*_i\}_{i=1}^{n^*}\sim F^{p+1}_{\mathbf{X}\mid A_{ip}=1}$ is observed, or (b) draws are available via forecast/sampler. The density ratio
$$w(x) = \frac{dF^{p+1}_{\mathbf{X}\mid A_{ip}=1}}{dF^{\text{src}}_{\mathbf{X}}}(x)$$
exists and is bounded, $\|w\|_\infty<\infty$ (or at least $\mathbb{E}_{\text{src}}[w(\mathbf{X})^2]<\infty$), where $F^{\text{src}}$ is the distribution on which $\tau$ is estimated. Bounded $w$ is the overlap/positivity condition for transport; without it the $n^{-1/2}$ rate fails under covariate shift.

---

## 3. Identification result (replaces Prop 3)

> **Proposition 3' (FATT via covariate transport).** Under A1–A3,
> $$\theta_{p+1} = \int \tau(x)\, dF^{p+1}_{\mathbf{X}\mid A_{ip}=1}(x) = \mathbb{E}_{\text{src}}\!\big[w(\mathbf{X})\,\tau(\mathbf{X})\big],$$
> and $\theta_{p+1}$ is identified from observed data.

**Proof.** Start from the exact decomposition (1). By A2, $\tau_{p+1}(x)=\tau(x)$, which by A1 is identified from $t\le p$ data. The integral against $F^{p+1}$ is computable under A3. The reweighting identity $\int \tau\, dF^{p+1} = \int \tau\, w\, dF^{\text{src}} = \mathbb{E}_{\text{src}}[w(\mathbf{X})\tau(\mathbf{X})]$ is change of measure, valid since $w$ exists (A3). $\square$

No injectivity, no inversion of marginals, no group-mean OLS. The fragile RC9 and the `≈` step (audit C1/C2) are **gone** because we never pass through the marginal $\theta_{gt}$.

---

## 4. Influence function (replaces app:eif3)

Write $\psi=\theta_{p+1}=\mathbb{E}_{\text{src}}[w(\mathbf{X})\tau(\mathbf{X})]$. Because $\widehat\tau$ is **not** $\sqrt n$ in general (see A1 rate caveat), the influence function is **not** "$w\cdot\varphi_\tau$"; it is the **doubly-robust transport score** for the functional $\psi$. For the unconfoundedness design,
$$\phi_{\psi}(O_i) = w(\mathbf{X}_i)\big(\tau(\mathbf{X}_i)-\psi\big) \;+\; w(\mathbf{X}_i)\Big[\tfrac{A_i\big(Y_i-\mu_1(\mathbf{X}_i)\big)}{e(\mathbf{X}_i)} - \tfrac{(1-A_i)\big(Y_i-\mu_0(\mathbf{X}_i)\big)}{1-e(\mathbf{X}_i)}\Big] \;+\; r_i, \tag{2}$$
where the first term is covariate-mix variation, the second is the AIPW correction that makes the score Neyman-orthogonal to $(\mu_a,e)$, and $r_i$ is the correction from estimating $w$ when the target is a finite sample (zero when the target covariates are treated as fixed/known). For the DiD design, replace the AIPW bracket with the corresponding DR-DiD score, reweighted by $w$. This score is **orthogonal**: its derivative w.r.t. each nuisance vanishes at the truth, so plug-in nonparametric/ML nuisances at $o_\mathbb{P}(n^{-1/4})$ (A1) leave $\sqrt n(\widehat\psi-\psi)\leadsto N(0,\mathbb{E}[\phi_\psi^2])$. The Chernozhukov et al. (2018) cross-fitting + product-rate result is exactly what licenses this (and adding the cite fixes compile error C5).

**Collapse certificate (the correctness anchor).** If $F^{p+1}=F^{\text{src}}$ then $w\equiv 1$, $r_i=0$, and (2) reduces to
$$\phi_\psi(O_i) = \big(\tau(\mathbf{X}_i)-\psi\big) + \tfrac{A_i(Y_i-\mu_1(\mathbf{X}_i))}{e(\mathbf{X}_i)} - \tfrac{(1-A_i)(Y_i-\mu_0(\mathbf{X}_i))}{1-e(\mathbf{X}_i)},$$
which is exactly the ordinary **AIPW/ATT efficient influence function**. So Path 3 nests the no-shift case as the standard DR estimator — the property to state as a lemma and unit-test in the package.

**Honest limit (state briefly).** The substantive failure mode is **overlap / heavy covariate shift**: if $w$ is unbounded (the future/target covariate support is not covered by the source), variance blows up and inference degrades. This is intrinsic to transport and is exactly the regime Path 3 is meant to navigate, so it belongs in the main text (it motivates A3's bounded-$w$ condition) and is worth one simulation stress regime. The usual DML nuisance-rate requirement ($o_\mathbb{P}(n^{-1/4})$, standard cross-fitting conditions) we just **cite** (Chernozhukov et al. 2018) — it is not the paper's contribution and does not need extended discussion; a one-line "under standard conditions" + citation suffices.

---

## 5. What this changes downstream (flagging, not doing)

- **§4.3 of main.tex:** delete the $m(x;\boldsymbol{\beta})$-from-marginals construction (357–374) and the RC9 injectivity machinery; replace with A1–A3 + Prop 3'. Parametric $m(x;\boldsymbol{\beta})$ becomes an *optional special case* of A1, not the definition.
- **§5 / app:eif3:** replace the chain-rule-through-$\boldsymbol{\beta}$ derivation (825–883) with (2) + the collapse lemma. Add the Path-3 step to the asymptotic-normality proof (audit M5).
- **Package (Phase 2):** `integrate_cate(cate_fit, target_x, source_x, density_ratio=, influence=)`; keep `compute_variance`; delete `estimate_beta_from_groups`/`compute_jacobian_linear`.
- **Application (Phase 3):** fit $\widehat\tau(x)$ on state-year microdata (DR-DiD or causal forest), transport to 2016+ treated covariate distribution.

## 6. Resolutions (2026-06-30)

1. **Generality of A1:** RESOLVED — state Path 3 abstractly (any asymptotically-linear $\widehat\tau$); parametric $m(x;\boldsymbol{\beta})$ + one nonparametric learner (causal forest) as worked examples. Matches mapping-not-estimation framing.
2. **Exposition:** RESOLVED — foreground **Form A** (integrate fitted $\widehat\tau$ over a target covariate sample, $\widehat\theta=\tfrac{1}{n^*}\sum_i\widehat\tau(x^*_i)$); use **Form B** (density-ratio $w(x)$) for the EIF derivation and the collapse certificate. The two are equal by change of measure.
3. **Target distribution / time-varying covariates:** RESOLVED — default target is $\mathbf{X}_p$ (treated units' covariates at end of study) as proxy for $\mathbf{X}_{p+1}$; forecast $\mathbf{X}$ to $p+1$ when time-varying and the shift matters; sometimes $\mathbf{X}_{p+1}$ is directly observed. Main text: $\mathbf{X}_p$ default + forecast option; remark for the time-varying detail.

## 7. Consequence of the FATT+FATU+FATE family (must state)

The three estimands are one fitted $\tau(x)$ integrated over three target distributions:

| Estimand | Target dist. $F^{p+1}$ over | $w$ vs. source (treated)? | Decision |
|----------|-----------------------------|---------------------------|----------|
| FATT | treated units' $\mathbf{X}$ | $w\equiv1$ (time-invariant case) | repeal? |
| FATU | untreated units' $\mathbf{X}$ | nontrivial $w$ | adopt? |
| FATE | population $\mathbf{X}$ | nontrivial $w$ | universal? |

**FATT** needs no covariate shift in the time-invariant case (source = target = treated). **FATU and FATE** integrate the treated-estimated $\tau(x)$ over a *different* covariate distribution, which requires an explicit **CATE transportability assumption**:

> **A2$'$ (cross-group conditional transportability, needed only for FATU/FATE).** For all $x$, the future conditional effect does not depend on observed treatment status given $\mathbf{X}$: $\mathbb{E}_{\mathbb{P}_{p+1}}\{Y(1)-Y(0)\mid \mathbf{X}=x, A_{ip}=1\} = \mathbb{E}_{\mathbb{P}_{p+1}}\{Y(1)-Y(0)\mid \mathbf{X}=x, A_{ip}=0\} = \tau(x)$.

This is the standard external-validity / no-unobserved-effect-modification-beyond-$\mathbf{X}$ assumption. It is the price of FATU/FATE and should be stated as such (FATT does not require it). This is exactly where the density-ratio $w(x)$ (Form B) does real work.

---

# Part II — Proof-hygiene fixes to Paths 1–2 and the shared theorem

These are independent of Path 3 (audit M2, M3, C2/M5). Stated here so all of Phase 1's math is reviewed together before any LaTeX edits.

## 8. M2 — Prop 2 hidden assumption (promote to hypothesis)

**Problem.** The proof of Prop 2 (`main.tex:654–657`) silently invokes a within-group between-state heterogeneity condition (the within-group analog of Assumption `p-to-p-plus-one-heterogeneity`) to swap the conditioning event $A_{ip}=1 \to A_{i,p+1}=1$ within cohort $g$. The proposition statement (`main.tex:278–279`) lists only (i) identification of $\theta_{gt}$ and (ii) injectivity of $\boldsymbol{\gamma}$. Violates "Assumptions First."

**Fix.** Add to Prop 2's hypotheses the within-group version of the limited-between-state-heterogeneity assumption. Restated Prop 2:

> **Proposition 2 (FATT under parametric dynamics).** Suppose (a) $\theta_{gt}$ are identified for $t\le p,\ g\in\mathcal{G}$ under the researcher's design; (b) $\theta_{gt}=f(g,t;\boldsymbol{\gamma})$ with $\boldsymbol{\gamma}$ uniquely determined by $(\theta_{gt})_{g,t\le p}$ (injectivity); **(c) [NEW] within-group limited between-state heterogeneity:** for each $g$, $\mathbb{E}_{\mathbb{P}_{p+1}}\{Y(1)-Y(0)\mid G_i=g, A_{ip}=1\} = \mathbb{E}_{\mathbb{P}_{p+1}}\{Y(1)-Y(0)\mid G_i=g, A_{i,p+1}=1\} = f(g,p+1;\boldsymbol{\gamma})$. Then $\theta_{p+1}=\sum_g \mathbb{P}(G_i=g\mid A_{ip}=1)\, f(g,p+1;\boldsymbol{\gamma})$.

Footnote 197 already acknowledges (c) informally — this just promotes it. No proof change beyond citing (c) where the swap occurs.

## 9. M3 — efficiency overclaims (downgrade to "valid asymptotically-linear IF")

**Problem.** Lines 386, 408, 774, 878 claim the propagated IF "achieves the semiparametric efficiency bound." But the IFs are propagated from *given* first-stage IFs $\phi_{gt}$; the result is the IF of the **plug-in** estimator, efficient only if (i) the supplied first-stage IFs are themselves efficient and (ii) the aggregation weights are the efficient ones (a simple average over $t$, used at lines 493/749, generally is **not** efficient). This also contradicts the mapping-not-estimation framing (we don't claim new efficiency theory).

**Fix (all three paths).** Replace "achieves the semiparametric efficiency bound" with: *"$\widehat\theta_{p+1}$ is asymptotically linear with influence function $\phi_\psi$; it is semiparametric efficient when the first-stage estimators and the aggregation weights are efficient."* Keep the honest conditional-efficiency statement; drop the unconditional claim. (Path 2's line 408 is closest to correct already — make all three consistent with it.)

## 10. C2/M5 — complete the asymptotic-normality theorem for all three paths

**Problem.** `app:prop-asymp` (`main.tex:889–932`) claims Paths 1/2/3 but the proof only writes the Path 1 and Path 2 linearization steps; Path 3 is missing. (C2's `≈` issue is already resolved by Prop 3′.)

**Fix.** State the theorem at the right level (matches the unifying abstraction) and add the Path 3 step:

> **Theorem (asymptotic distribution).** Suppose the first-stage estimator of the relevant object is asymptotically linear with the stated influence function — $\widehat\theta_{gt}$ with $\phi_{gt}$ (Paths 1–2), or $\widehat\tau(\cdot)$ with $\varphi_\tau$ (Path 3) — and the map to $\theta_{p+1}$ is the one in Prop 1 / 2 / 3$'$. Then the plug-in $\widehat\theta_{p+1}$ satisfies $\sqrt{n}(\widehat\theta_{p+1}-\theta_{p+1})\leadsto N(0,\sigma^2)$, $\sigma^2=\mathbb{E}[\phi_\psi^2]$, with $\phi_\psi$ given by $\phi_{\psi_1}$, $\phi_{\psi_2}$, or (2).

> *Path 3 step (new).* $\widehat\tau$ is **not** assumed $\sqrt n$ (A1 rate caveat). Instead, $\psi=\mathbb{E}_{\text{src}}[w\tau]$ is a pathwise-differentiable functional with the orthogonal score (2). Cross-fit the nuisances $(\mu_a,e,w)$; orthogonality + the $o_\mathbb{P}(n^{-1/4})$ rates (A1) make the plug-in bias $o_\mathbb{P}(n^{-1/2})$ (Chernozhukov et al. 2018, Thm. 3.1), so $\widehat\psi=n^{-1}\sum_i \widehat\phi_\psi(O_i)+\psi$ is asymptotically linear with influence function (2). CLT $\Rightarrow$ normality. $\square$

Note the asymmetry vs. Paths 1–2: there the first-stage *object* $\widehat\theta_{gt}$ is itself $\sqrt n$ and the map is a finite-dimensional delta method; here the first-stage *function* $\widehat\tau$ is slow, and √n is recovered at the *functional* level via orthogonality. Same conclusion (asymptotically-linear $\widehat\theta_{p+1}$), different machinery — worth a sentence in the paper so a referee sees we're not conflating the two.

## 11. Minor theorem-adjacent fixes (from audit, do in same pass)

- **`lem:injectivity`** (`982–998`): scope explicitly to Path 2 (it proves rank of the event-time design); it no longer needs to support Path 3.
- **MC remark** (`886`): state $M=M_n\to\infty$ with $M_n/n\to\infty$ so the MC term is $o_\mathbb{P}(n^{-1/2})$; otherwise carry it.
- **Overlap/bounded-$w$** (A3) replaces the absent positivity condition the old Path 3 lacked.

## 12. Phase 1 LaTeX edit checklist (for the single pass, post-approval)

1. §4.3: replace Path 3 (357–388) with §§1–3 here (Prop 3′, A1–A3, A2′ for FATU/FATE); Form A exposition; $\mathbf{X}_p$/forecast remark.
2. §5 / `app:eif3` (825–883): replace with §4 EIF (2) + collapse lemma.
3. Prop 2 (278–279): add hypothesis (c) [§8].
4. Efficiency wording (386, 408, 774, 878): downgrade [§9].
5. `app:prop-asymp` (889–932): theorem restatement + Path 3 step [§10].
6. `lem:injectivity`, MC remark [§11].
7. Estimands §: keep FATT/FATU/FATE as identified family; A2′ gates FATU/FATE; FITE/FATS motivation only.
8. Add missing citation `chernozhukovDoubleDebiasedMachine2018` (also fixes a compile error, audit C5).

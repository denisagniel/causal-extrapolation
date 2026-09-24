# Proof Audit — Proposition `prop:asymp` (Asymptotic distribution of $\widehat\theta_{p+1}$), `inst/paper/main.tex`

**Date:** 2026-09-24 · **Mode:** fresh, independent, adversarial audit via `proof-auditor` subagent. Includes a specific adjudication of a suspected estimator-identity defect (eq. 475 vs. the EIF score $(\ast)$) flagged by the orchestrator before this audit ran.

---

## Verdict and finding counts (read first)

| Path | Verdict |
|---|---|
| **Path 1** | **SOUND WITH CAVEATS** — the one-line delta method is a legitimate compression; two specific worries raised (joint vs. marginal AL; 4th moments) are **unfounded**. Real gaps are conditions-not-stated, not errors. |
| **Path 2** | **SOUND WITH CAVEATS, one Major gap** — existence/consistency of $\widehat{\boldsymbol\gamma}$ as a WLS root is genuinely skipped; IFT alone does not deliver it. |
| **Path 3** | **DEFECTIVE** — four independent Critical defects, not one. |

**Answer to the closing question ("does Prop. `prop:asymp` correctly and completely characterize the asymptotic distribution of the estimator a reader would implement from eq. (475)?"): No.** It characterizes a *different* estimator; and even for that different estimator, the stated variance is anti-conservative and omits the target-sampling term.

**Counts:** 4 Critical, 8 Major, 7 Minor/Suggestion.

**Coverage Manifest.** Received verbatim: the main-text asymptotic-linearity sentence; §3.7 "two ingredients" passage incl. eq. (475); the §3.7 "Path 3 EIF" paragraph incl. score $(\ast)$; `prop:asymp`; the full appendix proof (Steps 1–4); the variance Remark; the pre-proposition variance sentence; RC8; RC10. **Not received** (findings keyed to these are conditional): line ranges; RC1–RC7 verbatim (RC3/RC6/RC7 reach this audit only via the orchestrator's characterization); the Path-1/2/3 EIF appendices (so this audit cannot verify that the $\phi_{\psi_1},\phi_{\psi_2}$ the proof invokes match what Step 2 displays — cross-check separately against the EIF-derivation audit); the identification assumption blocks; the definitions of $w(x)$, $\omega_g$, $\theta_{g\cdot}$, $f(g,t;\gamma)$, and the WLS objective.

---

## Failure localization (emitted first)

| # | Location | Defect | Sev | Minimal fix |
|---|---|---|---|---|
| **C1** | §3.7 eq. (475) vs. proof Step 2 (Path 3), "$\widehat\theta_{p+1}$ solves the estimating equation built from the orthogonal score $(\ast)$" | Two different estimators. Text presents (475) as "**the** FATT estimator"; the proof analyzes the score-based source-sample estimator. | Critical | Define **one** Path-3 estimator. Keep the one-step/estimating-equation estimator as *the* estimator; demote (475) to "the plug-in, valid only under a correctly specified $\sqrt n$-consistent parametric $\hat\tau$." |
| **C2** | Step 2 (Path 3), conjunction of "$\widehat\tau$ need not be $\sqrt n$-consistent" (also RC8) with eq. (475) | (475) has bias $\mathbb{E}_{\rm tgt}[\widehat\tau-\tau]=O_P(\text{rate of }\widehat\tau)\neq o_P(n^{-1/2})$. No augmentation term exists in (475) to debias it, so no orthogonality argument can rescue it. | Critical | Add the augmentation term to the displayed estimator, or restrict (475) to the parametric case and give its (different) delta-method IF. |
| **C3** | Score $(\ast)$, term $w(X_i)(\tau(X_i)-\theta_{p+1})$ | $\tau$-variation term **mislocated**: scored on source units with weight $w$ instead of on target draws with weight 1. Consequences: $(\ast)$ is **not** Neyman-orthogonal in $w$; it is **not** the EIF; $\mathbb{E}[(\ast)^2]$ **understates** the truth (anti-conservative). | Critical | Replace with the two-sample score $\rho_0^{-1}\{\mathbb 1(S{=}0)(\tau(X)-\theta_{p+1})+\mathbb 1(S{=}1)w(X)\,\mathrm{aug}\}$; in the internal-target case this reduces to $(A/\pi)(\tau-\theta_{p+1})+w\cdot\mathrm{aug}$. |
| **C4** | `prop:asymp` ("$\sigma^2=\E[\phi^2]$"), Step 3, Remark, RC10 | No $n^*$ appears anywhere in the variance, yet (475) has variance $\geq \mathrm{Var}_{\rm tgt}(\tau)/n^*$. No rate condition on $n^*/n$ exists; RC10 supplies representativeness, not a rate. | Critical | Either assume $n/n^*\to 0$ **explicitly**, or state $V=V_{\rm src}+\rho^{-1}\mathrm{Var}_{\rm tgt}(\tau)$ with $\rho=\lim n^*/n$ and estimate both pieces. |
| M1 | RC8 vs. Step 2 (Path 3) | RC8 says *products* are $o_P(n^{-1/4})$; the proof concludes bias $o_P(n^{-1/2})$ and parenthesizes "$o_P(n^{-1/4})$ **per nuisance**". RC8 as written is weaker by a factor $n^{-1/4}$ and does **not** support the conclusion. | Major | Restate RC8: each nuisance $o_P(n^{-1/4})$ in $L_2$, equivalently products $o_P(n^{-1/2})$. |
| M2 | Remark, "Cross-fitting (RC7) ... ensures $\|\widehat\theta_{gt}-\theta_{gt}\|\cdot\|\widehat\gamma-\gamma\|=o_P(n^{-1/4})$" | Three errors: cross-fitting does not *ensure* rates (learners do); the target rate is wrong; and this product is not the relevant remainder for Paths 1–2 at all (remainder there is $O_P(\|\widehat\theta-\theta\|^2)=O_P(n^{-1})$, and $\widehat\gamma$ is a *function of* $\widehat\theta$, so pairing the two is conceptually confused). | Major | Split: Paths 1–2 need only $O_P(n^{-1/2})$ first stages; cross-fitting/product-rate language belongs exclusively to Path 3. |
| M3 | Step 2 (Path 2), "By the implicit function theorem and RC4-RC5, $\widehat\gamma$ is AL" | IFT yields a *local* solution map; it does not establish that a WLS root exists, is unique, or that $\widehat\gamma$ eventually lands in the neighborhood. Consistency of $\widehat\gamma$ is a prerequisite, not a corollary. | Major | Add: population criterion uniquely minimized at $\gamma$ (identification), compact $\Gamma$ or convex criterion, ULLN $\Rightarrow$ $\widehat\gamma\to_P\gamma$; *then* IFT/Taylor. Cite van der Vaart Thm 5.23/5.41. |
| M4 | Step 3 "(RC6 for finite variance)" applied to $\phi_{\psi_3}$ | $\mathbb{E}[\phi_{\psi_3}^2]<\infty$ requires **strict overlap** ($e$ bounded away from 0,1) **and** $\mathbb{E}[w^2]<\infty$ (ideally $w$ bounded). RC6 as quoted constrains only $\phi_{gt,i}$. Under poor source/target overlap — the canonical failure of *forecast* target distributions — $\sigma^2=\infty$ and the CLT fails outright. | Major | Add a Path-3 regularity condition: $\epsilon\le e(x)\le 1-\epsilon$, $w$ bounded (or $\mathbb{E}[w^2\sigma_a^2/e]<\infty$), and $\mathbb{E}[w^2(\tau-\theta)^2]<\infty$. |
| M5 | Step 3, "By CLT ... $n^{-1/2}\sum_i\phi_i$" | Panel setting with group-time ATTs: needs units i.i.d. **across $i$** with $\phi_i$ aggregating over $t$ *within* unit. Never stated. If any sum runs over $(i,t)$ pairs the CLT and $\widehat\sigma^2$ are both wrong. | Major | State i.i.d. sampling of units, arbitrary within-unit serial dependence, and that $\widehat\sigma^2$ uses unit-level $\widehat\phi_i$ (unit-clustered). |
| M6 | Remark, "$\sigma^2$ consistently estimated by $\widehat\sigma^2/n$" | Dimensionally wrong: $\widehat\sigma^2/n\to 0$. $\sigma^2$ is estimated by $\widehat\sigma^2$; $\mathrm{Var}(\widehat\psi)$ by $\widehat\sigma^2/n$. The main text gets this right, so the Remark contradicts it. | Major (trivial fix, but a wrong equation) | "$\mathrm{Var}(\widehat\psi)$ estimated by $\widehat\sigma^2/n$, $\widehat\sigma^2=n^{-1}\sum\widehat\phi_i^2$." |
| M7 | `prop:asymp`, "$\sqrt n(\widehat\psi-\psi)$" for Path 2 | If $\gamma$ is the WLS **pseudo-true** value under a misspecified temporal model, the limit is centered at $\sum_g\omega_g f(g,p{+}1;\gamma^*)\neq\theta_{p+1}$. The proposition asserts centering at $\psi=\theta_{p+1}$ without invoking correct specification. | Major | Either add correct specification to Path 2's assumptions, or restate the conclusion as convergence to the pseudo-true extrapoland and flag the bias explicitly. |
| M8 | §3.7, "the **efficient** influence function is the doubly-robust transport score" | Over-claim. For a *known, external* target law, the efficient IF is $w(X)\cdot\mathrm{aug}$ **alone** — $\theta=\int\tau\,dF_{\rm tgt}$ does not depend on $F_{\rm src}$ at all, so the $w(\tau-\theta)$ term is pure added noise. $(\ast)$ is then a valid but **strictly inefficient** IF. | Major | Call $(\ast)$ "an orthogonal score for the normalized source-sample transport estimator," and give the efficient form separately per design (known target / internal target / finite external sample). |

---

## Critical findings in full

Notation: $\mathrm{aug}(O)\equiv \dfrac{A(Y-\mu_1(X))}{e(X)}-\dfrac{(1-A)(Y-\mu_0(X))}{1-e(X)}$, so $\mathbb{E}[\mathrm{aug}\mid X]=0$ and $(\ast)=w(X)(\tau(X)-\theta)+w(X)\mathrm{aug}(O)$. Write $\pi=\Pr(A=1)$, $\rho=\lim n^*/n$.

### C1 — (475) and the estimator implicit in $(\ast)$ are different estimators

$(\ast)$ is an influence function, so it defines an estimator only through its estimating equation $\sum_i\widehat\phi_{\psi_3}(O_i)=0$, whose solution is
$$\widehat\theta^{\,B}=\frac{\sum_i \widehat w(X_i)\widehat\tau(X_i)}{\sum_i \widehat w(X_i)}+\frac{\sum_i \widehat w(X_i)\widehat{\mathrm{aug}}(O_i)}{\sum_i \widehat w(X_i)} ,$$
a Hájek-normalized AIPW transport estimator computed **entirely on source data**. Eq. (475) is $\widehat\theta^{\,A}=(n^*)^{-1}\sum_{i\le n^*}\widehat\tau(X_i^*)$, computed **entirely on target covariates**, with no $w$, no $A_i$, no $Y_i$, no augmentation. They take disjoint inputs and carry different randomness ($\widehat\theta^{\,A}$'s noise includes the $n^*$ draws; $\widehat\theta^{\,B}$'s does not). They share a probability limit; they are not the same statistic.

**Does the "time-invariant covariates" special case rescue the identity? No.** There $\{X_i^*\}=\{X_i:A_i=1\}$, $n^*=n_1$, $w(x)=e(x)/\pi$ by Bayes. Then
$$\sqrt n\,(\widehat\theta^{\,A}-\theta)=\underbrace{\sqrt n\,\Big[n_1^{-1}\textstyle\sum_i A_i(\tau(X_i)-\theta)\Big]}_{\rightsquigarrow\ \text{IF }=\,(A/\pi)(\tau(X)-\theta)}\;+\;\underbrace{\sqrt n\,\Big[n_1^{-1}\textstyle\sum_i A_i(\widehat\tau-\tau)(X_i)\Big]}_{\text{plug-in bias}}.$$
Even in the most favorable case, (475)'s first-order term carries $A/\pi$, whereas $(\ast)$ carries $e(X)/\pi$; and (475) has a plug-in bias term where $(\ast)$ has $w\cdot\mathrm{aug}$. They differ in **both** terms. $(\ast)$ is not the EIF of (475) under any condition the paper states, and no such condition exists — case (b) (forecast/simulated draws) is one of two cases in which the identity fails outright, not an ambiguous exception to an otherwise-valid one.

**Which estimator does Step 2 (Path 3) actually analyze?** Unambiguously $\widehat\theta^{\,B}$. The load-bearing sentence is literal — "$\widehat\theta_{p+1}$ **solves the estimating equation built from the orthogonal score** $(\ast)$" — and every subsequent move (Neyman orthogonality, RC8 product rates, cross-fitting, "plug-in bias ... is $o_P(n^{-1/2})$") is machinery for a score-solving estimator with no purchase on a bare average of $\widehat\tau$ over external draws.

**Is this an internal inconsistency to flag as a defect? Yes.** §3.7 introduces (475) with the definite article ("**The** FATT estimator integrates the first over the second") and spells out its computation in both parametric and nonparametric cases. The proposition then certifies a different object. A reader who implements (475) and reports $\widehat\sigma^2/n$ from $(\ast)$ obtains an interval that is mis-centered at nonparametric rates (C2) and mis-scaled even in the parametric case.

### C2 — (475) is not $\sqrt n$-consistent under the paper's own premise about $\widehat\tau$

$\widehat\theta^{\,A}-\theta=(n^*)^{-1}\sum(\tau(X_i^*)-\theta)+\mathbb{E}_{\rm tgt}[\widehat\tau-\tau]+o_P(\cdot)$. The second term is the plug-in bias. For a nonparametric learner with $L_2$ rate $n^{-\alpha}$, $\alpha<1/2$, it is $O_P(n^{-\alpha})\gg n^{-1/2}$, so $\sqrt n(\widehat\theta^{\,A}-\theta)$ **diverges**. RC8 states affirmatively that "$\widehat\tau(\cdot)$ need not be $\sqrt n$-consistent," and §3.7 explains this is exactly why one must move to the orthogonal-score level — so the paper states the premise that invalidates its own displayed estimator, in the same section, and then proves a theorem about a third object. The debiasing role of $\mathrm{aug}$ is structural: (475) contains no term whose purpose is to cancel $\mathbb{E}_{\rm tgt}[\widehat\tau-\tau]$, so nothing about orthogonality, cross-fitting, or nuisance rates can repair it.

In the parametric special case $\widehat\tau(x)=m(x;\widehat\beta)$ with $\widehat\beta$ $\sqrt n$-consistent and the model correct, (475) *is* $\sqrt n$-consistent — but its influence function is then $(A/\pi)(\tau(X)-\theta)+\pi^{-1}\mathbb{E}[A\nabla_\beta m(X;\beta)]^\top\phi_{\beta}$, a finite-dimensional delta-method object bearing no resemblance to $(\ast)$.

### C3 — $(\ast)$ mislocates the $\tau$-variation term: not orthogonal in $w$, not the EIF, and anti-conservative

**(a) Not Neyman-orthogonal in $w$.** $(\ast)$ is linear in $w$. Its Gateaux derivative in direction $\delta w$ at the truth is $\mathbb{E}\big[\delta w(X)\{(\tau(X)-\theta)+\mathrm{aug}(O)\}\big]=\mathbb{E}\big[\delta w(X)(\tau(X)-\theta)\big]$ (using $\mathbb{E}[\mathrm{aug}\mid X]=0$) — **not zero** for general $\delta w$. The proof's "By Neyman orthogonality of $(\ast)$ with respect to the nuisances $(\mu_0,\mu_1,e,w)$" is **false in the $w$ coordinate**. Errors in $\widehat w$ enter at **first order**: bias $\approx\mathbb{E}[(\widehat w-w)(\tau-\theta)]=O_P(\|\widehat w-w\|)$, uncontrolled by any product-rate condition. Orthogonality holds in $(\mu_0,\mu_1,e)$ only.

**(b) The correct score, and why it is structurally different.** In the pooled two-sample formulation ($S=1$ source, $S=0$ target), the EIF of $\theta=\mathbb{E}[\tau(X)\mid S=0]$ is
$$\phi(O)=\rho_0^{-1}\big\{\mathbb 1(S{=}0)\,(\tau(X)-\theta)\;+\;\mathbb 1(S{=}1)\,w(X)\,\mathrm{aug}(O)\big\},\qquad \rho_0=\Pr(S{=}0).$$
The $\tau$-variation term is scored on **target** draws with weight 1; only the augmentation is scored on source draws with weight $w$. This form *is* orthogonal in $w$ (perturbing $w$ multiplies a conditionally-mean-zero factor). $(\ast)$ is obtained by moving the first term onto the source sample and replacing $\mathbb 1(S{=}0)$ with $w(X)$ — mean-preserving, variance-changing, orthogonality-destroying.

**(c) $(\ast)$ is not the EIF, and the error is anti-conservative.** Internal-target case, $w=e/\pi$, $\theta=\mathbb{E}[\tau(X)\mid A{=}1]$. True EIF (Hahn 1998, ATT; expand $A(Y-\mu_0)=A(Y-\mu_1)+A\tau(X)$):
$$\phi_{\rm ATT}=\tfrac{A}{\pi}(\tau(X)-\theta)+w(X)\,\mathrm{aug}(O),\qquad\text{versus}\qquad (\ast)=\tfrac{e(X)}{\pi}(\tau(X)-\theta)+w(X)\,\mathrm{aug}(O).$$
Both mean zero; both first terms uncorrelated with $w\cdot\mathrm{aug}$ (condition on $X$; $\mathbb{E}[A\cdot\mathrm{aug}\mid X]=0$). Variances differ **only** in the first term:
$$\mathrm{Var}\big(\tfrac{A}{\pi}(\tau-\theta)\big)=\frac{\mathrm{Var}_{\rm tgt}(\tau)}{\pi},\qquad \mathrm{Var}\big(\tfrac{e}{\pi}(\tau-\theta)\big)=\frac{\mathbb{E}[e^2(\tau-\theta)^2]}{\pi^2}.$$
Since $e\le 1$, the second is **strictly smaller** whenever $e<1$ with positive probability. Quantitatively, using $dF_{X\mid A=1}\propto e\,dF_X$: the ratio is $\approx\overline e$ among the treated — with $e\approx0.5$ the $\tau$-term is understated ~2×; with rare treatment $e\approx0.05$, ~20×. Reported Wald intervals are therefore **too narrow** (anti-conservative). A variance *below* the efficiency bound is itself proof $(\ast)$ cannot be an IF for $\theta$ in this model — it is the IF of the *known-$w$* problem. And the paper's hedge, "a correction term when $w$ is estimated from a finite target sample," does not cover this case: here $w=e/\pi$ is estimated from the **source** sample, and the needed correction is precisely $(A-e(X))(\tau(X)-\theta)/\pi$, which **increases** the variance to the bound.

### C4 — the two-sample variance gap

**No assumption anywhere makes it vanish.** $\sigma^2=\mathbb{E}[\phi^2]$ contains no $n^*$, while (475) satisfies, for a $\sqrt n$-consistent $\widehat\tau$ (the only regime with a limit at all — C2):
$$\sqrt n(\widehat\theta^{\,A}-\theta)\rightsquigarrow N\!\big(0,\ \rho^{-1}\mathrm{Var}_{\rm tgt}(\tau)+V_{\rm src}\big),\qquad \rho=\lim n^*/n,$$
the two components independent when the target sample is drawn independently of the source data. Searching `prop:asymp`, Step 3, Step 4, the Remark, the pre-proposition variance sentence, and RC10: **no** rate condition on $n^*/n$ exists. RC10 asserts only *representativeness*, an unbiasedness condition, not a variance condition. $\sigma^2=\mathbb{E}[\phi^2]$ is therefore valid only under the unstated assumption $n/n^*\to0$ — incompatible with the paper's own leading example, where $n^*=n_1=\pi n$, so $\rho=\pi\in(0,1)$.

C3 and C4 are two views of the same structural error: the term that should carry the target-sampling variability has been replaced by a source-sample surrogate with the same mean and a smaller variance. Case (b) of §3.7 (forecast/simulated draws) is where this bites hardest — $n^*$ is a free design choice and the reported SE is insensitive to it: a user who simulates $n^*=50$ target draws gets the same interval as one who simulates $n^*=10^6$.

---

## General audit — checklist items

### 1. Assumption check

Stated-but-unused / used-but-unstated: Path 3 uses, without stating, strict overlap; $\mathbb{E}[w^2]<\infty$; a rate condition on $n^*/n$ (C4); $\sqrt n$-consistency of $\widehat w$ or a correction term (C3a). Path 2 uses, without stating, identification/uniqueness of the WLS minimizer (M3); continuity of $\nabla_\gamma f$ at $\gamma$; correct specification (M7). All paths use, without stating, i.i.d. sampling of units and a fixed finite group index set (M5, m7). Mid-proof assumption introduction: Step 2 (Path 3) introduces "$o_P(n^{-1/4})$ per nuisance" attributed to RC8, which states something weaker (M1).

### 2. Dependency check

Neyman orthogonality invoked for $(\mu_0,\mu_1,e,w)$, fails for $w$ (C3a). IFT invoked without verifying $\widehat\gamma$ is eventually in the neighborhood (M3). CLT invoked with a finite-variance citation (RC6) covering only $\phi_{gt,i}$, not the Path-3 composite or its $w/e$ factors (M4). Hahn's ATT EIF is effectively contradicted by $(\ast)$ without acknowledgement (C3c). No circularity found.

### 3. Rate verification — including the 4th-moments worry raised

**The worry about 4th moments is unfounded — record it as a non-finding.** Lindeberg–Lévy needs only $\mathbb{E}[\phi]=0$, $\mathbb{E}[\phi^2]<\infty$; no fourth moment. And finite variance of the composite follows from finite variance of the pieces: for $\phi_{\psi_1}=\sum_g\omega_g\phi_{\theta_{g\cdot}}+\sum_g\theta_{g\cdot}\phi_{\omega_g}$ over a fixed finite $g$-set with finite constants, $\|\phi_{\psi_1}\|_2\le\sum_g|\omega_g|\|\phi_{\theta_{g\cdot}}\|_2+\sum_g|\theta_{g\cdot}|\|\phi_{\omega_g}\|_2<\infty$ (triangle inequality). **RC3's second moment on $\phi_{\omega_g}$ suffices** — no fourth moment on $\phi_{\omega}$ or the Jacobians is required for the CLT. Same for Path 2 (the extra term is a fixed matrix applied to $\phi_\theta$), provided the Jacobians are finite and $M_\gamma$ nonsingular (an RC5-type condition that must be stated, m2). Fourth moments *are* needed for $\sqrt n$-consistency of $\widehat\sigma^2$, not for the CLT itself; if RC6 exists for that purpose the proof should say so.

Where the rate reasoning **is** wrong: M1 (RC8 too weak by $n^{-1/4}$), M2 (Remark's product-rate statement incoherent for Paths 1–2), C2 (no rate on $\widehat\tau$ saves (475)), C4 (no rate on $n^*$). Correctly handled: the bilinear cross terms in Paths 1–2 are $O_P(n^{-1})=o_P(n^{-1/2})$.

### 4. Edge-case scan

Weak overlap ($e\to0,1$): $\sigma^2=\infty$; $\mathrm{aug}$ explodes (M4). Poor source/target covariate overlap (heavy-tailed $w$): $\mathbb{E}[w^2]=\infty\Rightarrow$ no CLT — the characteristic failure mode of extrapolating to a future/forecast covariate distribution, unaddressed (M4). Small $n^*$: intervals invariant to $n^*$ (C4). Near-singular $M_\gamma$ (flat WLS criterion, short window): $\nabla_\gamma f$ evaluated outside the fitting window can be much larger than in-window, degrading the local linearization at fixed $n$ as horizon grows (asymptotically valid, practically fragile). Rare treatment / small cohorts: small $\pi$ inflates $1/\pi$ factors and shrinks $n^*=n_1$, compounding C4.

### 5. Tightness

Paths 1–2: correct first-order variance given AL first stages once M3/M7 are supplied — nothing over- or under-claimed. Path 3: simultaneously **too strong** (asserts $\sqrt n$-normality for an estimator that lacks it — C2; asserts efficiency for an inefficient score — M8) and **too weak in the wrong direction** (a variance below the bound — C3c). RC8's per-nuisance $n^{-1/4}$ can be relaxed to the product condition $\|\widehat\mu-\mu\|\cdot\|\widehat e-e\|=o_P(n^{-1/2})$, the standard, strictly weaker DML form.

### Minor / Suggestion (compressed)

m1: `prop:asymp`'s "plugging these into $\phi$" does not define an estimator for Path 3 (the wording through which C1 slips in). m2: write $-M_\gamma^{-1}M_\theta$ explicitly with dimensions and nonsingularity of $M_\gamma$ stated. m3: state continuity of $\nabla_\gamma f$ at $\gamma$; note estimated WLS weights don't affect first-order asymptotics at the truth. m4: add a finite-sample caveat on extrapolation-horizon sensitivity of $\nabla_\gamma f(g,p{+}1;\gamma)$. m5: replace "under standard regularity, this does not affect the first-order limit distribution" with the actual condition ($\|\widehat\phi-\phi\|_{L_2}=o_P(1)$, delivered by cross-fitting). m6 (non-finding, record so it is not re-litigated): joint AL follows from the marginal expansions by Cramér–Wold over a common i.i.d. index — fine, provided each $\phi_{gt,i}$ is a function of the full-sample observation. m7: state that $g$ ranges over a fixed finite set independent of $n$.

---

## Cross-reference note for synthesis

This report's C1–C4 should be read together with the EIF-derivations audit's C1 (orthogonality failure in $w$) and M1/M8 (efficiency mis-claim, centering ambiguity) — both audits independently derived the same defect in score $(\ast)$ via different routes (this report via the eq.-475-vs-$(\ast)$ estimator mismatch and the Hahn-EIF exact-identity comparison; the EIF audit via the parametric-submodel re-derivation). The convergence of two independent adversarial passes on the same defect is strong evidence it is real, not an artifact of either audit's framing.
</content>

# Proof Audit — EIF Derivations for Paths 1/2/3, `inst/paper/main.tex` (Appendix E + §sec:eif-derivation)

**Date:** 2026-09-24 · **Mode:** fresh, independent, adversarial audit via `proof-auditor` subagent.
**Scope:** Main-text EIF summaries (Paths 1–3); Appendix E.1 (Path 1 EIF), E.2 (Path 2 EIF), E.3 (Path 3 EIF); Lemma `lem:path3-collapse`.

---

## 0. Verdict and counts (read first)

| Object | Verdict |
|---|---|
| **E.1 — Path 1 EIF** | **SOUND WITH CAVEATS** — IF algebra correct; the *efficiency* claim is unverifiable as stated (no model/tangent space) and is false in the over-identified multi-period model. Main text and appendix give **inconsistent** $\phi_{\omega_g}$. |
| **E.2 — Path 2 EIF** | **SOUND under correct specification; DEFECTIVE as stated under misspecification.** The IFT formula is exactly right iff the residual-Hessian term vanishes. The claim in E.2(5) that "the variance formula remains valid" under misspecification is **false** for any $f$ nonlinear in $\gamma$. |
| **E.3 — Path 3 EIF** | **DEFECTIVE.** $(\ast)$ is **not** Neyman-orthogonal with respect to $w$. RC8 places $w$ in the product-rate nuisance class; that is insufficient, and $r(O)$ is asserted, never derived. Separately, the functional being differentiated is never specified, so the label "efficient" cannot be verified and is false in the nonparametric model. |
| **E.3 DiD transfer $(\ast\ast)$** | **SOUND, but the stated reason is wrong.** Orthogonality in $m_0$ and in $\tau$ both hold — verified below — but by a *different* cancellation than in the unconfoundedness case, and $\tau$ must be counted as a nuisance, which the text explicitly declines to do. |
| **Lemma `lem:path3-collapse`** | **DEFECTIVE.** Algebra of the substitution is right; the *identification of the limit* is wrong. It is the AIPW **ATE** score, not the AIPW **ATT** EIF, and the lemma statement contradicts its own following caveat. |

**Findings: 2 Critical, 9 Major, 5 Minor, 3 Suggestions.**

**Coverage manifest.** Audited from the verbatim bundle supplied (main-text summaries; Appendix E.1/E.2/E.3; `lem:path3-collapse` and its caveat). Two bundle gaps were closed by a targeted read to answer questions about the notation-collision remark and the RC conditions: `main.tex:688–734` (RC3–RC10 verbatim), `main.tex:374, 709, 979, 1031` (Path-2 supporting prose), plus a grep for a notation-collision remark (none found). **Not seen, not audited:** the first-stage $\phi_{gt}$ construction; Propositions 1–3 and their proofs; `score_drdid` source in `R/`; any compile output. Did **not** verify that the package implements the score audited here.

---

## 1. Failure localization (emitted first)

| # | Location | Defect | Sev | Minimal fix |
|---|---|---|---|---|
| **C1** | E.3, orthogonality/rates paragraph; RC8 (`main.tex:720–722`) | Gateaux derivative of $(\ast)$ w.r.t. $w$ is $\mathbb E[h(X)(\tau(X)-\theta)] \ne 0$. $(\ast)$ is *not* orthogonal in $w$. RC8 nonetheless puts $w$ in the $o_P(n^{-1/4})$ product-rate class. $r(O)$ is never derived. | **Critical** | Delete $w$ from RC8's product-rate list. Either (i) add an explicit assumption that $w$ is known/fixed and state $r\equiv0$ as a *consequence*, or (ii) adopt the two-sample transport score (below), which **is** orthogonal in $w$, and derive its variance across both samples. |
| **C2** | E.2 step (3) formula + step (5) misspecification sentence | $\partial\gamma/\partial\theta_{gt} = \mathbf{(H_0 - R)^{-1}}\, w_{gt}\nabla f_{gt}$ with $R := \sum w_{g't'} r_{g't'}(\gamma) \nabla^2 f_{g't'}(\gamma)$. Paper states $H_0^{-1}$. $R=0$ iff residuals vanish (correct specification) or $\nabla^2f\equiv0$ ($f$ linear in $\gamma$). Under misspecification with nonlinear $f$ the IF — hence the variance — is wrong. | **Critical** | Restrict E.2(5) to: "if $f$ is linear in $\gamma$, or under correct specification, the variance formula remains valid for the pseudo-true limit." Otherwise replace $H_0$ by $H_0-R$ and require $H_0-R\succ0$. |
| **M1** | E.3 $(\ast)$ centering term | $w(X)(\tau(X)-\theta)$ is the IF of a **self-normalized** estimator; the un-normalized functional $\mathbb E_{\rm src}[w\tau]$ has centering $w(X)\tau(X)-\theta$; and under RC10's own leading case (target = the study's treated units) the correct centering carries the **hard indicator** $1\{A_{ip}=1\}/\mathbb P(A_{ip}=1)$, whose variance is strictly larger. The functional/model is never specified, so "efficient" is unverifiable. | Major | State the functional and the model explicitly; state which estimator the package implements; if Hájek, call $(\ast)$ "the influence function of the normalized estimator", not the EIF. |
| **M2** | E.1 step (4) | "Attains the bound when the first-stage IFs and $\omega_g$ are themselves efficient" — no model, no tangent space. With PT imposed at all $t\le p$ the observed-data model carries over-identifying restrictions, so the tangent space is a strict subspace of $L^2_0$ and plug-in composition of nonparametrically-efficient pieces need **not** be efficient. | Major | Name the model $\mathcal M$ and tangent space; require all component EIFs to be efficient *in $\mathcal M$*; or downgrade to "attains the bound in the model in which the first-stage IFs are efficient, provided that model's tangent space is unrestricted." |
| **M3** | main text §sec:eif-derivation vs E.1(2) | Two different $\phi_{\omega_g}$. Main: $1\{G=g,A_p=1\}/\mathbb P(A_p=1) - \omega_g$. Appendix: $[1\{G=g,A_p=1\} - \omega_g 1\{A_p=1\}]/\mathbb P(A_p=1)$. Both mean-zero; variances differ by $\omega_g^2(1-\mathbb P(A_p=1))/\mathbb P(A_p=1) \ge 0$. The appendix form is correct for the stated ratio estimator; the main text inflates the variance. | Major | Replace the main-text expression with the appendix form. |
| **M4** | `lem:path3-collapse` | Called "exactly the EIF of the augmented-IPW **ATT**". It is the AIPW **ATE** score. Contradicts the lemma's own caveat two sentences later. | Major | Restate as "the AIPW score for $\mathbb E[\tau(X)]$ over the source population", and keep the caveat. |
| **M5** | RC5 + `rem:rc5-independence` (`main.tex:696–709`) | The remark asserts clause (ii) ($H_0$ nonsingular) "is what the IFT step of App. E.2 requires." True only under correct specification. RC5(i) ("$\gamma_0$ uniquely determined by the group-time ATTs") presupposes exact specification and has no misspecified analogue. | Major | Add: under misspecification, replace (i) by uniqueness of the pseudo-true minimizer $\gamma^*$ and (ii) by $H_0-R\succ0$. |
| **M6** | RC7 (`:717`), RC8 (`:721`) vs E.3 rates paragraph | RC7 sets the **product** $\|\hatθ-θ\|\cdot\|\hatγ-γ\| = o_P(n^{-1/4})$; RC8 reads "rates whose products are $o_P(n^{-1/4})$". A √n expansion needs the product $o_P(n^{-1/2})$. The E.3 prose gets it right ("each $o_P(n^{-1/4}) \Rightarrow$ product $o_P(n^{-1/2})$") and thus contradicts the assumptions it cites. | Major | Change both to $o_P(n^{-1/2})$ for the product (equivalently, each factor $o_P(n^{-1/4})$). |
| **M7** | main text §sec:path3 | Displays the score **without** $r(O)$ and asserts Neyman-orthogonality to $(\mu_a, e, \mathbf w)$. Given C1 this is a stronger and false claim than the appendix's. | Major | Display $+r(O)$ and drop $w$ from the orthogonality list. |
| **M8** | E.2 setup; $\mathcal G := \{g\le p:\omega_g>0\}$ | (a) $\mathcal G$ is data-dependent when $\omega$ is estimated, and it selects which $(g,t)$ enter the WLS objective and $H_0$ — a non-smooth selection the delta method cannot pass through; (b) $w_{gt}$ treated as fixed constants. If $w_{gt}=1/\hat V(\hatθ_{gt})$, an extra term appears — vanishes under correct specification, not under misspecification. | Major | Assume $\mathcal G$ fixed/known and $w_{gt}$ non-random; or add the $\omega$- and weight-derivative terms. |
| **M9** | E.2 notation | Unresolved. $w_{gt}$ (WLS weights) collides with $w(x)$ (density ratio, RC9). No disambiguating remark exists anywhere. Worse: RC5 calls the same weights $\lambda_{gt}$ — the assumption and the derivation it licenses use different symbols. | Major | Rename E.2's weights to $\lambda_{gt}$, matching RC5, and reserve $w(\cdot)$ for the density ratio. |

---

## 2. Critical findings in full

### C1 — $(\ast)$ is not Neyman-orthogonal with respect to $w$ (Path 3)

Perturb $w \to w + s\cdot h(X)$, all else at the truth, in
$$\phi = w(X)(\tau(X) - \theta) + w(X)\Big[\tfrac{A(Y-\mu_1)}{e} - \tfrac{(1-A)(Y-\mu_0)}{1-e}\Big].$$
Then $\frac{d}{ds}\mathbb E[\phi]\big|_{s=0} = \mathbb E[h(X)(\tau(X)-\theta)] + \mathbb E[h(X)\cdot\text{aug}]$. The second term is zero because $\mathbb E[\text{aug}\mid X]=0$. The first is $\mathbb E[h(X)(\tau(X)-\theta)]$, which vanishes only if $\tau(X)\equiv\theta$ a.s. (no heterogeneity — the paper's premise denies this) or $h\perp(\tau-\theta)$ specifically. So "its Gateaux derivative w.r.t. each nuisance — $(\mu_0,\mu_1,e,\mathbf w)$ ... — vanishes at the truth" is **false in the $w$ coordinate**. This is structural: $\psi=\mathbb E_{\rm src}[w\tau]$ is *linear* in $w$, so $w$ is not a nuisance in the double-robustness sense at all — it is part of the estimand, with no bilinear remainder to exploit. Self-normalizing does not help ($\mathbb E[w\tau]/\mathbb E[w]$ has the same derivative).

Consequences:
1. **RC8 is insufficient.** With no orthogonality, a first-order error in $\hat w$ produces a first-order bias $\mathbb E[(\hat w - w)(\tau-\theta)]$. At $\|\hat w - w\| = O_P(n^{-1/4})$ (RC8's contemplated rate), that bias is $O_P(n^{-1/4})$, which **diverges** after √n scaling.
2. **$r(O)$ is load-bearing and undefined.** RC10 does not assume $w$ known — it assumes a representative target sample or a faithful sampler; under RC10(a) the target law *is* estimated, so $r\not\equiv0$, and no derivation, functional form, or variance contribution is given anywhere.
3. **RC10's own leading case makes it worse.** "When the target is the study's treated units under time-invariant covariates" — there $w(x)=e(x)/\mathbb P(A=1)$ is a functional of the sampled law itself, so differentiating $w$ contributes a first-order term even with no separate target sample at all.

**Minimal fix (standard, citable).** Use the two-sample transport score $\phi = \mathbf 1\{S=\text{tgt}\}(\tau(X)-\theta)/\mathbb P(S=\text{tgt}) + \mathbf 1\{S=\text{src}\}\, w(X)\,[\text{aug}]/\mathbb P(S=\text{src})$, which evaluates the plug-in mean *on the target sample* rather than by reweighting the source. Its Gateaux derivative in $w$ vanishes at the truth, restoring double robustness in $(w,\mu)$, and supplies the $r(O)$ term the paper is missing. This is the Rudolph–van der Laan / Dahabreh et al. transport EIF.

### C2 — Path 2 step (3): the IFT formula omits the residual-Hessian term, and E.2(5) is false because of it

Write $S:=\{(g,t):g\in\mathcal G, g\le t\le p\}$, $r_{gt}(\gamma):=\theta_{gt}-f(g,t;\gamma)$, $\nabla f_{gt}:=\partial_\gamma f(g,t;\gamma)$, $\nabla^2 f_{gt}:=\partial^2_{\gamma\gamma^T}f(g,t;\gamma)$. Stated FOC: $M(\gamma,\theta):=\sum_{(g,t)\in S} w_{gt}\,r_{gt}(\gamma)\,\nabla f_{gt}(\gamma)=0$.

**Total differentiation, from scratch.** Along $\gamma=\gamma(\theta)$: $\partial M/\partial\theta_{gt} + (\partial M/\partial\gamma^T)(\partial\gamma/\partial\theta_{gt})=0$.

*Own-index term:* $\partial M/\partial\theta_{gt} = w_{gt}\nabla f_{gt}$ — matches the paper. ✔

*Jacobian in $\gamma$:* for each $(g',t')$, $\partial_{\gamma^T}[r_{g't'}\nabla f_{g't'}] = -\nabla f_{g't'}\nabla f_{g't'}^T + r_{g't'}\nabla^2 f_{g't'}$. Summing: $\partial M/\partial\gamma^T = -(H_0-R)$, $H_0:=\sum_S w\nabla f\nabla f^T$, $R:=\sum_S w_{g't'}r_{g't'}(\gamma)\nabla^2 f_{g't'}(\gamma)$.

*Solve:* $\partial\gamma/\partial\theta_{gt} = (H_0-R)^{-1}\,w_{gt}\nabla f(g,t;\gamma)$.

**Verdict on the presented formula.** Sign correct; cross-terms correctly present, correctly only inside the inverse; own-index factor correct. **The single defect is the omission of $R$.** $H_0$ is the Gauss–Newton approximation; the true Hessian of the WLS criterion is $2(H_0-R)$.

**When $R=0$.** (i) Correct specification: every $r_{gt}=0$, so $R=0$ exactly. (ii) $f$ linear in $\gamma$: $\nabla^2f\equiv0$, so $R=0$ **regardless of specification** — covers `main.tex:1031`'s linear-in-$\gamma$ form and the group-specific event-time model $\alpha_g+\beta_g(t-g)$, and (with a fixed basis) the spline built-in. So the printed formula is exactly right for the paper's linear built-ins, in or out of the model.

**Working through misspecification, as requested.** Does the FOC survive? Yes — $\gamma^*$ is a stationary point of the population WLS criterion, so $M(\gamma^*,\theta)=0$ at the pseudo-true value. Does differentiating that same FOC give the stated $\partial\gamma/\partial\theta_{gt}$? **No.** $\partial_{\gamma^T}[r\nabla f]$ retains $r\cdot\nabla^2 f$, and $r_{g't'}(\gamma^*)\ne0$ by definition of misspecification. The correct Jacobian is $(H_0-R)^{-1}$ with $R\ne0$ whenever $f$ is nonlinear in $\gamma$ and residuals are nonzero — confirming the suspicion that misspecification introduces exactly the extra term generated by the residuals' interaction with the curvature of $f$. Therefore "the variance formula remains valid for the limit distribution of the (possibly biased) estimator" is **false** for nonlinear $f$; the reported SE is wrong by an unsigned amount governed by curvature-weighted residuals.

A second, independent failure of the same sentence: if the WLS weights are estimated ($w_{gt}=1/\hat V(\hatθ_{gt})$), then $\partial M/\partial w_{gt} = r_{gt}\nabla f_{gt}$ — zero under correct specification (the classical adaptivity result, and why the paper's silence on $w_{gt}$ is harmless in-model), nonzero under misspecification (an unaccounted-for extra term).

**On RC4/RC5 (question 2d).** RC4 is exactly what the IFT step needs, and RC4's second-derivative content is precisely the object $R$ that the misspecified case turns on. RC5(ii) ($H_0$ nonsingular) is the right condition under correct specification, where $H_0-R=H_0$; the independence Remark's claim that (ii) "is what the IFT step requires" is correct in-model, incorrect out-of-model. Under misspecification the required condition is $H_0-R\succ0$, and $H_0\succ0$ does **not** imply it ($R$ is not sign-definite; at a local minimum $H_0-R\succeq0$ is automatic, so the genuine extra requirement is strict definiteness). Silently required beyond RC4–RC5: interiority and uniqueness of the pseudo-true $\gamma^*$; non-random $w_{gt}$; fixed $\mathcal G$; nonsingularity in a neighborhood, not only at the point; joint asymptotic linearity of the stacked first stage.

---

## 3. E.1 (Path 1) — detail

**IF algebra: correct.** $\Psi_1=\sum_g\omega_g\theta_{g\cdot}$ is bilinear; the pathwise derivative along any submodel is $\sum_g\omega_g(d\theta_{g\cdot}/d\varepsilon)+\sum_g\theta_{g\cdot}(d\omega_g/d\varepsilon)$, giving the stated gradient. Mean-zero holds termwise.

**$\phi_{\omega_g}$ check.** The appendix form is the correct ratio-estimator IF: with $N_g=\mathbb E[1\{G=g,A_p=1\}]$, $D=\mathbb P(A_p=1)$, the delta method on $N_g/D$ gives $D^{-1}(1\{G=g,A_p=1\}-\omega_g 1\{A_p=1\})$, mean zero, variance $\omega_g(1-\omega_g)/D$. The main text's variant has variance $\omega_g/D-\omega_g^2$ — larger by $\omega_g^2(1-D)/D$ (M3).

**Is composition of efficient components efficient?** True in general, and here is the exact mechanism: fix a model $\mathcal M$ with closed linear tangent space $\mathcal T(P)\subseteq L^2_0(P)$. If $\phi^{\rm eff}_{\theta_{g\cdot}}$ and $\phi^{\rm eff}_{\omega_g}$ are the EIFs in $\mathcal M$, then for any submodel score $s$, $d\Psi_1/d\varepsilon = \langle\sum_g\omega_g\phi^{\rm eff}_{\theta_{g\cdot}}+\sum_g\theta_{g\cdot}\phi^{\rm eff}_{\omega_g},\, s\rangle$, and since each EIF lies in $\mathcal T$ and $\mathcal T$ is a closed linear space, the composite lies in $\mathcal T$ too — a gradient lying in the tangent space is *the* EIF. ✔ **But the claim as printed is unverifiable and, here, false:** (1) same-model requirement is silently violated (E.1 admits $\theta_{g\cdot}$ "as provided by first-stage," an external estimator in an unnamed model, while $\omega_g$'s IF is the nonparametric one); (2) no model is stated anywhere in RC1–RC10 or E.1 — an efficiency claim without a model is not a weak claim, it is not a claim; (3) the natural model here (with PT imposed for all $t\le p$) has over-identifying restrictions, so $\mathcal T(P)$ is a *strict* subspace, and the nonparametrically-efficient $\omega_g$ IF is not in it — so the claim is actually false unless every component is efficient in that same restricted model.

---

## 4. E.3 (Path 3) — detail

### 4a. Re-derivation of the score, term by term

For $\psi(P)=\mathbb E_P[w\cdot\tau_P]$, under a submodel with score $s$:
- *From $\tau$:* reproduces the bracketed augmentation in $(\ast)$ exactly, reweighted by $w$. ✔ Requires overlap (RC9).
- *From the covariate law:* $\int w\tau\,\partial_\varepsilon dF^{\rm src} = \mathbb E[(w(X)\tau(X)-\psi)s]$ — centering $w(X)\tau(X)-\theta$, **not** $w(X)(\tau(X)-\theta)$.

So $(\ast)$ as printed is the gradient of the *self-normalized* functional $\mathbb E[w\tau]/\mathbb E[w]$ (the Hájek/stabilized estimator), not of $\mathbb E[w\tau]$, nor of a genuinely fixed $\int\tau\,dF^{\rm tgt}$ (where the covariate-law term is absent entirely). Under RC10's own leading case (target = treated units, $w=e/\mathbb P(A=1)$ a functional of $P$), the correct centering carries the **hard indicator** $1\{A_{ip}=1\}(\tau-\theta)/\mathbb P(A_{ip}=1)$, whose variance $\mathbb E[e(X)(\tau-\theta)^2]/\mathbb P^2$ strictly exceeds $(\ast)$'s $\mathbb E[e(X)^2(\tau-\theta)^2]/\mathbb P^2$ since $e\le1$ — i.e. **$(\ast)$ understates the variance** in that case.

**Mean-zero check.** $\mathbb E[(\ast)]=0$ (using $\mathbb E_{\rm src}[w]=1$). **Passes — but so do all four candidate centerings above**, so this check has zero power to discriminate among them and should not be cited as evidence $(\ast)$ is correct.

**Is $(\ast)$ the ATT EIF, or something else?** Take the leading case $w=e/\pi$, $\tau=\mu_1-\mu_0$. Using $A(Y-\mu_1)=A(Y-\mu_0)-A\tau$, an exact identity holds: $(\ast) - \phi^{\rm Hahn}_{\rm ATT} = (e(X)-A)(\tau(X)-\theta)/\mathbb P(A=1)$, where $\phi^{\rm Hahn}_{\rm ATT}$ is Hahn's (1998) ATT EIF. The difference is mean-zero but not identically zero. In a nonparametric model the gradient is unique, so $(\ast)$ cannot be *the* gradient there — it is a valid IF only in a *restricted* model where the $A\mid X$ direction is excluded from the tangent space (i.e. $w$/$e$ treated as known). $(\ast)$ is thus a consistent but **inefficient** IF; "efficient" in the section title is not earned by the derivation given.

### 4b. Collapse lemma — algebra verified, label wrong

Substituting $w\equiv1$, $r\equiv0$ into $(\ast)$ gives exactly the displayed expression — algebra correct. But the identity above shows $(\ast)-\phi_{\rm ATT}=(\mathbb P(A=1)-A)(\tau-\theta)/\mathbb P(A=1)\ne0$ at $w\equiv1$, so the collapsed object is the canonical AIPW score for $\mathbb E[\tau(X)]$ — the **ATE** over the source population — not the ATT EIF. "Exactly the EIF of the augmented-IPW ATT" is false, and it contradicts the lemma's own following caveat (which correctly notes the IFs differ and SEs need not match Sant'Anna–Zhao — that caveat is right and should be kept). This lemma sets $w\equiv1$, which is the one value at which all four competing centerings in §4a coincide — so it has zero power to detect M1 either.

### 4c. Does the DiD substitution transfer? (worked explicitly)

For $(\ast\ast)$ with $m_1=m_0+\tau$, $\tau$ fixed:

- *Perturb $m_0\to m_0+sh$ ($\tau$ fixed):* forces $m_1\to m_0+sh+\tau$ (both arms move); centering unaffected. $d/ds = -\mathbb E[wAh/e]+\mathbb E[w(1-A)h/(1-e)] = -\mathbb E[wh]+\mathbb E[wh]=0$. ✔
- *Perturb $\tau\to\tau+sh$ ($m_0$ fixed):* $m_1\to m_0+\tau+sh$, and the centering moves. $d/ds = \mathbb E[wh]-\mathbb E[wAh/e]=\mathbb E[wh]-\mathbb E[wh]=0$. ✔

So $(\ast\ast)$ **is** orthogonal in $m_0$ and in $\tau$, confirming the suspicion about mechanism: in the unconfoundedness case orthogonality in $\mu_1$ comes from a cancellation between the plug-in term and one augmentation term; in the DiD case with $\tau$ held fixed, orthogonality in $m_0$ comes from a cancellation between the two augmentation terms — a different pairing, same zero. "The entire unconfoundedness derivation transfers under the substitution" is therefore not literally true (it survives, but the proof does not transfer verbatim).

**A bookkeeping defect with real consequences.** The text excludes $\tau$ from the nuisance list ("with $\tau$ fixed"), yet the rates paragraph invokes orthogonality-in-$\tau$ implicitly by asserting "$\widehat\tau$ need not be $\sqrt n$-consistent." The honest rate condition is $\|\hat\tau-\tau\|\cdot\|\hat e-e\|=o_P(n^{-1/2})$; with cross-fitted ML for $e$ at $n^{-1/4}$, $\hat\tau$ needs $o_P(n^{-1/4})$ in $L^2$ — a real, weaker-than-√n but nonzero condition, not "no requirement."

### 4d. Main-text vs appendix drift

- Main text displays the score **without** $r(O)$; the appendix displays it with $+r(O)$. Given C1, the main-text display is the stronger and false version (M7).
- Main text says the DiD design "replaces the bracketed augmentation ... reweighted by $w$," while the appendix substitutes $Y\mapsto\Delta Y$, $\mu_a\mapsto m_a$ **throughout**, including in $\tau$ (which under DiD must be $m_1-m_0$, not $\mu_1-\mu_0$). Minor, but exactly the ambiguity that produces implementation bugs.

---

## 5. Minor findings and Suggestions

**Minor.** (m1) E.2 step (1) writes $\otimes$ for a scalar inner product, inconsistent with step (4)'s correct $(\cdot)^T(\cdot)$. (m2) E.1(1)/E.2(4) need **joint** asymptotic linearity of the stacked first stage on a common sample, stated nowhere. (m3) DiD $\tau$-definition ambiguity (§4d). (m4) E.3's derivation never exhibits the submodel/score explicitly — the opacity that let M1 through; a displayed $\int w\tau\,\partial_\varepsilon dF^{\rm src}$ line would have made the centering self-checking. (m5) RC9's two clauses ("$\|w\|_\infty<\infty$" vs "$\mathbb E[w^2]<\infty$") are not interchangeable for the DML remainder analysis with estimated $\hat w$.

**Suggestions.** (s1) Adopt the two-sample transport score (C1) — fixes orthogonality in $w$, supplies $r(O)$ as a derived object, and is citable. (s2) Add one paragraph before Appendix E fixing the model $\mathcal M$ and tangent space $\mathcal T(P)$ for each path — resolves M2, lets M1 be stated as a choice rather than an error, and makes every "efficient" claim checkable. (s3) In E.2, report the formula with $H_0-R$ and note $R=0$ for linear-in-$\gamma$ $f$ or correct specification — strengthens the linear built-ins while making the nonlinear caveat visible instead of buried in an incorrect sentence.

---

## 6. Assumption / dependency / rate / edge-case / tightness summary

**Assumptions.** RC3–RC10 exist and are stated before use. **Not stated anywhere:** the statistical model and tangent space (fatal for every efficiency claim); fixity of $\mathcal G$; non-randomness of the WLS weights; uniqueness of the pseudo-true $\gamma^*$ off-model; joint AL of the first stage. E.2 step (3) tacitly assumes correct specification ($r=0$) and step (5) then explicitly denies it.

**Dependencies.** Delta method and IFT invoked by name with conditions traceable to RC4–RC5, and RC5's companion Remark correctly identifies clause (ii) as the IFT requirement — unusually careful, but only in-model. Hahn's ATT EIF is effectively contradicted by $(\ast)$ without acknowledgement. No circularity found.

**Rates.** RC7/RC8 set products at $o_P(n^{-1/4})$ where $o_P(n^{-1/2})$ is required (M6); E.3's prose states it correctly and thus contradicts the assumptions it cites. The $w$-rate issue is not a rate problem but an orthogonality problem (C1).

**Edge cases.** Overlap handled (RC9 + $\eta$-bound discussion). Weak overlap: score variance $\sim\eta^{-1}$; large $w$ compounds this. Heavy tails: RC6 gives fourth moments for $\phi_{gt}$ but no moment condition on $w(\tau-\theta)$ or $w/e$. Near-singularity: $H_0$ nonsingular assumed only pointwise at $\gamma_0$, not uniformly in a neighborhood (needed for the IFT). Boundary regime $\omega_g\downarrow0$ is the $\mathcal G$-selection non-smoothness of M8.

**Tightness.** Path 1's IF is sharp given the first stage; only the efficiency *label* over-reaches. Path 2's IF is sharp in-model and exactly right off-model for linear $f$ — RC5(i) could be weakened to pseudo-true uniqueness at no cost, widening rather than narrowing the result. Path 3's $(\ast)$ is strictly *inefficient* (§4a), so the result is weaker than claimed; the two-sample form would be both efficient and robust in $w$ — the fix strictly improves the theorem.
</content>

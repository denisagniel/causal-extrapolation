# Notation and Assumption Registry — `What we estimate when we estimate dynamic causal effects in panel data`

**Instance path:** `inst/paper/notation.md`
**Governed by:** `.claude/rules/paper-protocol.md`
**Status:** current as of 2026-09-25

> **Why this file exists.** Notation drift and assumption drift are *document-level*
> properties. This file converts them into local artifact-diffing, so a reviewer diffs the
> manuscript against this file rather than holding the whole document in context.
>
> **Construction note.** This registry is a **backfill**: every row was seeded by reading
> `main.tex` directly (the introduction, setting, estimands, all three identification-path
> subsections, the EIF section, and the regularity-conditions/proofs appendix). No symbol,
> assumption, or estimand below is new content — all of it is already in the manuscript.
>
> **Mid-restructuring staleness flag (2026-09-25).** `main.tex` was restructured the same day
> to match the story-first `outline.md` (see that file's §2 content-migration table): sections
> were renamed, promoted from subsections to top-level sections, and reordered (Path 2 and
> Path 3 are now their own top-level sections; the two "connecting" subsections were merged and
> reordered into one weakening-then-strengthening argument). For that restructuring, **no
> symbol or assumption's mathematical content changed** — every formula was verbatim correct,
> only relocated — but every `main.tex:NNN` line-number citation in §§1-2 below (the symbol and
> assumption registries) was written against the pre-restructuring line numbers and has **not**
> been individually re-verified against the new numbering in this pass, unlike `claims.md`'s
> table 2, which was. The `\label{}` names themselves (e.g. `strict-time-homogeneity`, `RC5`,
> `prop:path2`) are unaffected by line shifts and remain the reliable cross-reference; treat
> every bare line number here as approximate until a dedicated re-anchoring pass greps each
> label's current line, the way `claims.md`'s update did.
>
> **Genuinely new content added, same day, later pass (Item 2).** §1a and RC11 below (and
> `main.tex`'s new `sec:md-aggregation` subsection, `prop:md-aggregation`,
> `rem:md-efficiency`, `rem:md-omega`) are **not** restructured pre-existing content — this is
> new theory, added after the restructuring pass above, with fresh line-number citations
> verified against the current `main.tex` at the time of writing (not subject to the staleness
> flag above).

**Environment name(s) in use:** `assumption` (via `\newtheorem{assumption}{Assumption}`,
`main.tex:24`). A single shared counter runs across the body and Appendix B — this is why RC1
follows Assumption `assump:cross-group` numerically rather than restarting.

---

## 1. Symbol registry

| Symbol | Meaning | Defined at | Notes / forbidden variants |
|---|---|---|---|
| $\theta_{p+1}$ | **The estimand.** Future ATT (FATT) at horizon 1: $\theta_{p+k}=\E_{\P_{p+k}}\{Y_{i,p+k}(1)-Y_{i,p+k}(0)\mid A_{ip}=1\}$, specialized to $k=1$ per `main.tex:150` ("In the remainder of the paper we take $k=1$"). | `main.tex:142` (general $k$), `main.tex:150` (fixes $k=1$) | The paper defines the general-horizon family first, then fixes $k=1$ for the body. Do not confuse $\theta_{p+1}$ (future) with $\theta$ (backward-looking ATT, below) or $\theta_{gt}$ (group-time ATT). |
| $\theta$ | Backward-looking ATT: $\E_\P\{Y_{it}(1)-Y_{it}(0)\mid A_{it}=1\}$. | `main.tex:95` | Bare $\theta$ is *not* the estimand — it is the object Path 1 identifies the estimand *with*, under Assumption `strict-time-homogeneity`. |
| $\theta_{gt}$ | Group-time ATT: $\E_{\P_t}\{Y_{it}(1)-Y_{it}(0)\mid A_{it}=1, G_i=g\}$. | `main.tex:101` | The finite-dimensional first-stage object for Paths 1-2. |
| $\theta_{g,p+1}$ | Group-time ATT evaluated at the future period $p+1$: $\E_{\P_{p+1}}\{Y_{i,p+1}(1)-Y_{i,p+1}(0)\mid A_{i,p+1}=1, G_i=g\}$. | `main.tex:228` | Used in Lemma~2 (Exact aggregation). |
| $A_{it}$ | Treatment/policy indicator for unit $i$ at time $t$. | `main.tex:91` | |
| $Y_{it}$ | Observed outcome; $Y_{it}(a)$ the potential outcome under $A_{it}=a$. | `main.tex:91` | |
| $\bX_{it}$ (or $\bX_i$) | Pre-treatment covariates, possibly time-varying. | `main.tex:91` | $\bX_i$ used when time-invariant or period is clear from context, per the manuscript's own notational note at `main.tex:91`. |
| $G_i$ | Cohort/adoption time: $G_i=\min\{t:A_{it}=1\}$ ($\infty$ if never treated). | `main.tex:101` | |
| $\omega_g$ | Cohort weight: $\P(G_i=g\mid A_{ip}=1)$. | `main.tex:173`, restated `main.tex:226` | Appears in every path's aggregation/extrapolation formula. |
| $\cG$ | The finite set of cohorts with positive weight, $\{g\le p:\omega_g>0\}$. | `main.tex:226` | |
| $\tau_{i,p+k}$ | Future individual treatment effect (FITE): $Y_{i,p+k}(1)-Y_{i,p+k}(0)$. | `main.tex:129` | Not itself a target of identification — motivates the population estimands. |
| $\tau_{i,p+k}(\eta;\rho)$ | Future average treatment effect among similar units (FATS). | `main.tex:135` | Localized version of the population estimands, not a separate object. |
| $\tau_{p+k}$ | Future ATE (FATE). | `main.tex:141` | |
| $\omega_{p+k}$ | Future ATU (FATU). | `main.tex:143` | **Collision risk:** this symbol reuses `$\omega$`, which elsewhere denotes cohort weights ($\omega_g$). Recorded here per the symbol-collision rule below. |
| $f$ | Generic extrapolation function, $\theta_{gt}=f(g,\mathcal{I}_t;\btheta)$. | `main.tex:167` | The general-framework device; `main.tex`'s own header comment (`main.tex:1-11`) flags this framing as stale for Path 3 — see `outline.md`'s provenance note. |
| $\mathcal{I}_t$ | Information set available at time $t$ (varies by path: group index only, (group,time), or the covariate distribution $F_{\bX}^t$). | `main.tex:167`, Table~1 (`main.tex:177-190`) | |
| $\gamma_g$ | Path 1's extrapolation function: constant-in-$t$, group-specific. | `main.tex:271` | |
| $f(g,t;\bgamma)$ | Path 2's parametric extrapolation function of group and time. | `main.tex:362` | |
| $\bgamma$ | Path 2's finite-dimensional temporal parameter. | `main.tex:367` | |
| $\tau_t(x)$ | Period-$t$ conditional ATT among the treated: $\E_{\P_t}[Y_{it}(1)-Y_{it}(0)\mid \bX_i=x, A_{it}=1]$. | `main.tex:401-403` | |
| $\tau(x)$ | Common value of $\tau_t(x)$ across periods, under Assumption `assump:struct-stab`. | `main.tex:403` | **Path 3's estimand-level object** — do not confuse with the scalar FATT $\theta_{p+1}$, which is $\tau(x)$ integrated over a target distribution. |
| $F_{\bX}^t$ | Covariate distribution at time $t$. | `main.tex:396`, `main.tex:406` | |
| $F_{\bX\mid A_{ip}=1}^{p+1}$ | Covariate distribution of treated units at the future period $p+1$ (Path 3's transport target for the FATT). | `main.tex:406` | |
| $w(x)$ | Density ratio $dF_{\bX\mid A_{ip}=1}^{p+1}/dF_{\bX}^{\mathrm{src}}(x)$. | `main.tex:430` | Overloaded across the two Path-3 regimes: in Regime (i), $w(x)=q(x)/\rho$ is *implied* by the target-membership indicator's propensity; in Regime (iii), $w$ is the object itself, supplied or known. See the blanket note in §2e. |
| $m(x;\bbeta)$ | Parametric special case of $\tau(x)$ (e.g. linear-in-covariates). | `main.tex:454` | |
| $T_i$ | Regime (i)'s observed target-membership indicator (a subpopulation of the source sample). | `main.tex:476` | For the FATT under time-invariant covariates, $T_i=A_i$ (`main.tex:526`). |
| $\rho$ | $\P(T_i=1)$ (Regime i) or the normalizing constant $\E_P\{w(\bX)\}=1$ (Regime iii, `main.tex:1420-1426`). | `main.tex:478`, `main.tex:1425` | Symbol reused across the two regimes with related but distinct roles — flagged per the collision rule. |
| $q(x)$ | $\P(T_i=1\mid \bX_i=x)$, Regime (i)'s target-membership propensity. | `main.tex:480` | For the FATT, $q=e$ (`main.tex:526`). |
| $\mu_a(x)$ | Outcome regression $\E[Y_{it}\mid \bX_i=x, A_{it}=a]$, $a\in\{0,1\}$. | `main.tex:413` | |
| $e(x)$ | Propensity score $\P(A_{it}=1\mid \bX_i=x)$. | `main.tex:413` (implicit via "doubly-robust CATE learner"); explicit at `main.tex:1144` | |
| $\operatorname{aug}(O_i;\mu_0,\mu_1,e)$ | The augmented-inverse-propensity-weighted (AIPW) residual term shared by both Path-3 regimes. | `main.tex:484-489` | |
| $\phi_{gt}$ | Influence function of the first-stage estimator $\widehat\theta_{gt}$. | `main.tex:599` | |
| $\phi_{\psi_1}, \phi_{\psi_2}$ | EIFs for the FATT under Path 1 and Path 2 respectively. | `main.tex:607`, `main.tex:613` | |
| $\phi_{\mathrm{int}}$ | Regime (i)'s EIF (internally defined target). | `main.tex:517-523` (general form); `main.tex:528-546` (FATT specialization, labeled $\phi_{\psi_3}^{\mathrm{ATT}}$) | |
| $\phi_{\mathrm{fix}}$ | Regime (iii)'s EIF (known/fixed density ratio). | `main.tex:577-584` (labeled $\phi_{\psi_3}^{\mathrm{fix}}$) | |
| $\sigma^2$ | Semiparametric variance bound, $\E[\phi^2]$. | `main.tex:628`, `main.tex:637` | |

**Symbol-collision flags recorded per the rules below:**

- **$\omega$** is used for two distinct roles: cohort weight $\omega_g$ (`main.tex:173`) and the
  FATU estimand $\omega_{p+k}$ (`main.tex:143`). Listed twice above per the collision rule.
- **$\rho$** is used for two related-but-distinct roles across the two Path-3 regimes (Regime i:
  a probability; Regime iii: a normalizing constant equal to 1 at the true law). Listed once
  with both roles noted, since the two uses do not co-occur within a single regime's formulas.

**Rules for this table**

- **The estimand gets a row, and it is the first row.** Done above ($\theta_{p+1}$).
- **Symbol-scope inclusion test applied.** Loop indices ($i$, generic $g$, $t$) are omitted;
  they surface only in prose narration or as subscripts, not as free symbols in a numbered
  result's statement.
- No symbol is redefined in an appendix in a way that conflicts with its body definition; the
  appendix (`app:eif3`) introduces $S_{\mathrm{src}}, S_{\mathrm{tar}}, \rho_{\mathrm{src}},
  \rho_{\mathrm{tar}}$ as a *general* stacked-population device that specializes to the body's
  $T_i, \rho, q(x)$ (Regime i) and to Regime (iii) — this is deliberate scoping, not a defect.

### 1a. Added 2026-09-25 (Item 2, `sec:md-aggregation`)

| Symbol | Meaning | Defined at | Notes / forbidden variants |
|---|---|---|---|
| $\cC$ | The finite, fixed set of observed group-time cells, $\cC := \{(g,t): g\in\cG, g\le t\le p\}$. | `main.tex:568` | Distinct from $\cG$ (cohorts) and from any per-cohort period set; not the same object as `rem:last-cohort`'s informal $\cT_g$ (Oracle's design note flagged these as reconcilable but left unreconciled to avoid scope creep on an existing remark). |
| $J$ | $J := \abs{\cC}$, the number of observed cells (dimension of the stacked score vector). | `main.tex:568` | Same role as the package's `J` in `build_score_matrix()`/`estimate_score_cov()` — this is the one place the paper's and package's notation were deliberately kept identical. |
| $\bphi_i$ | The stacked per-unit cell-score vector, $\bphi_i := (\phi_{gt,i})_{(g,t)\in\cC} \in \R^J$. | `main.tex:570` | Not to be confused with any single-cell $\phi_{gt,i}$ (already registered above); the bold face is the paper's existing convention for stacked vectors (matches $\btheta$, $\bgamma$, $\bomega$). |
| $\bSigma$ | $\bSigma := \Var(\bphi_i)$, the $J\times J$ covariance of the stacked cell scores (per-unit scale, matching the paper's $\Var(\phi)/n$ convention). | `main.tex:571` | Governed by Assumption RC11 below. |
| $X$ | The $J\times d$ design matrix of rows $\bx_{gt}^\top$ encoding the path's linear restriction $\btheta = X\bgamma$. | `main.tex:576` (this subsection); first introduced at `cor:linear-rank` in the appendix, now also used in the body | This symbol is **reused**, not newly minted — `cor:linear-rank`/`lem:injectivity` already used $X$ for exactly this object in the appendix; `sec:md-aggregation` is the first *body* use. |
| $\bx_{gt}$, $\bx_{p+1}$ | Row of $X$ for cell $(g,t)$; $\bx_{p+1} := \sum_{g\in\cG}\omega_g\bx_{g,p+1}$, the target's coefficient vector, so $\theta_{p+1}=\bx_{p+1}^\top\bgamma$. | `main.tex:579` | Path 1 specializes $\bx_{gt}=\be_g$ (cohort indicator), $\bx_{p+1}=\bomega$; Path 2 (linear $f$) specializes to `cor:linear-rank`'s $\bx_{gt}$. |
| $H$ | $H := X^\top\bSigma^{-1}X$ ($d\times d$); $H_n$ its finite-sample, $\bSigmahat$-plugged-in analogue. | `main.tex:594` | Nonsingularity of $H$ is Assumption~\ref{RC5}(ii) with $\Lambda=\bSigma^{-1}$ — not a new rank condition (see RC11's entry below). |
| $\blambda^*$ | The GMM/minimum-distance-optimal combination weights, $\blambda^* := \bSigma^{-1}XH^{-1}\bx_{p+1} \in \R^J$; $\widehat\theta_{p+1} = \blambda^{*\top}\bthetahat$. | `main.tex:598` | The direct generalization of the (never-formalized-in-the-paper) diagonal inverse-variance weighting the R package's `gls_weights()` already implemented; Proposition~\ref{prop:md-aggregation}(iv) states the diagonal special case explicitly. |

---

## 2. Assumption registry

**Environment name(s) in use:** `assumption` (all numbered assumptions in `main.tex` use this
single environment; no alternate names like `assum`/`cond`/`hyp` appear in this manuscript).

### 2a. Formal — explicitly numbered in the paper

#### `Absorbing adoption` — `\label{absorbing-adoption}`
- **Stated at:** `main.tex:105`
- **Statement:** For every unit $i$ and $t\in\{1,\ldots,p\}$, $A_{it}=1 \implies A_{is}=1$ for
  all $s\in\{t+1,\ldots,p+1\}$.
- **Discharges:** (ii) a named identification step — it pins down $G_i=\min\{t:A_{it}=1\}$ as a
  single transition date, which is the premise of Lemma 1 (Cohort persistence) and Lemma 2
  (Exact aggregation).
- **Role:** Rules out repeal/reinstatement within the study window; without it, $G_i$ and the
  cohort-based aggregation of Lemma 2 are not well-defined.
- **When reasonable:** Policies that, once adopted, are rarely repealed within the study window
  (most state-level regulatory adoptions).
- **When unreasonable:** Settings with policy reversals or sunset provisions inside the panel.
- **Verifiable from data?** Yes, partially — observable within the sample window, though not at
  $p+1$.
- **Used by:** Lemma 1, Lemma 2, and (by inheritance through those lemmas) every downstream
  identification result: Propositions 1-3, the within-group corollary.
- **Cited as a range anywhere?** No.
- **Declared in:** body.

#### `Strict ATT time homogeneity` — `\label{strict-time-homogeneity}`
- **Stated at:** `main.tex:276`
- **Statement:** $\exists$ scalar $\theta$ s.t. $\theta_{gt}=\theta$ for every $g\in\cG$ and
  $t$ with $g\le t\le p+1$.
- **Discharges:** (i) a named term — collapses the entire cohort/time-varying decomposition of
  Lemma 2 to a single constant.
- **Role:** Path 1's core identifying assumption; without it, the FATT is not identified by the
  backward-looking ATT.
- **When reasonable:** No meaningful dynamics or between-cohort heterogeneity documented in the
  observed window.
- **When unreasonable:** Any evidence of event-time trends or cohort-specific effect
  differences.
- **Verifiable from data?** Partially — testable across observed periods/cohorts
  (`main.tex:301`, Remark `rem:testable`); its extension to $t=p+1$ is untestable.
- **Used by:** Proposition 1.
- **Declared in:** body.

#### `No future between-state ITE heterogeneity` — `\label{strict-between-homogeneity}`
- **Stated at:** `main.tex:308`
- **Statement:** $\tau_{i,p+1}=\tau_{j,p+1}$ for all $i,j$.
- **Discharges:** (i) — collapses the FATE/FATU/FATS/FITE family onto $\theta$ under Assumption
  `strict-time-homogeneity`.
- **Role:** Together with `strict-time-homogeneity`, delivers full equivalence of every
  forward-looking estimand to the backward-looking ATT.
- **When reasonable:** Near-homogeneous-effects settings (rare, stated as restrictive by the
  manuscript itself, `main.tex:315`).
- **When unreasonable:** Any documented cross-unit effect heterogeneity.
- **Verifiable from data?** No — see §2e blanket statement.
- **Used by:** the equivalence display at `main.tex:311-314` (not itself a labeled numbered
  result, but the mechanism behind the "connecting other forward-looking estimands" material
  §4.4 owns).
- **Declared in:** body.

#### `Strict time homogeneity under $\cC_t$` — `\label{general-strict-time-homogeneity}`
- **Stated at:** `main.tex:319`
- **Statement:** $\E_{\P_t}\{Y_{it}(1)-Y_{it}(0)\mid\cC_t\}=\E_{\P_s}\{Y_{is}(1)-Y_{is}(0)\mid\cC_s\}$
  for a conditioning event $\cC_t$ and all $s,t\in\{1,\ldots,p+1\}$.
- **Discharges:** (ii) — the generic identification step underlying Path 1, restated for an
  arbitrary conditioning event so it specializes to ATU/ATE/ATS equivalences.
- **Role:** Generalizes `strict-time-homogeneity` to arbitrary $\cC_t$.
- **When reasonable/unreasonable:** Same as `strict-time-homogeneity`, at the level of whichever
  $\cC_t$ is chosen.
- **Verifiable from data?** Partially, same structure as `strict-time-homogeneity`.
- **Used by:** the FATU/FATE/FATS equivalence results at `main.tex:330` (§4.4).
- **Declared in:** body.

#### `Limited between-state heterogeneity under $\cC_t$` — `\label{general-p-to-p-plus-one-heterogeneity}`
- **Stated at:** `main.tex:325`
- **Statement:** $\E_{\P_{p+1}}\{\cdot\mid\cC_p\}=\E_{\P_{p+1}}\{\cdot\mid\cC_{p+1}\}$.
- **Discharges:** (i) — generalizes `strict-between-homogeneity` to arbitrary $\cC_t$.
- **Role:** paired with the assumption above to deliver FATU/FATE equivalences; not required
  for the FATS (`main.tex:330`).
- **When reasonable/unreasonable:** Same structure as `strict-between-homogeneity`.
- **Verifiable from data?** No — see §2e.
- **Used by:** `main.tex:330` display.
- **Declared in:** body.

#### `Strict within-group ATT time homogeneity` — `\label{within-group-strict-time-homogeneity}`
- **Stated at:** `main.tex:336`
- **Statement:** For every $g\in\cG$, $\exists$ scalar $\theta_{g\cdot}$ s.t. $\theta_{gt}=\theta_{g\cdot}$
  for $g\le t\le p+1$.
- **Discharges:** (i) — relaxes `strict-time-homogeneity`'s cross-cohort restriction while
  keeping within-cohort constancy.
- **Role:** Path 1's weaker-sufficient-condition variant; delivers a cohort-weighted-average
  FATT rather than collapsing to a single scalar.
- **When reasonable:** Cohort-specific effects may differ in level, but each cohort's effect is
  stable over its own post-adoption window.
- **When unreasonable:** Within-cohort dynamics (event-time trends).
- **Verifiable from data?** Partially, same structure as `strict-time-homogeneity`.
- **Used by:** Corollary (Identification of the FATT under within-group time homogeneity).
- **Declared in:** body.

#### `Parametric temporal model` — `\label{assump:parametric}`
- **Stated at:** `main.tex:366`
- **Statement:** $\exists$ known $f$ and $\bgamma\in\Gamma\subseteq\R^d$ s.t.
  $\theta_{gt}=f(g,t;\bgamma)$ for $g\in\cG$, $g\le t\le p+1$, with $\bgamma$ the unique
  parameter matching the observed window.
- **Discharges:** (ii) a named identification step (Path 2's central identifying content) plus
  (iv) a named nuisance/identifiability requirement (the uniqueness clause, restated formally
  as RC5).
- **Role:** Substitutes a functional-form assumption for Path 1's time-constancy assumption;
  without it, $\bgamma$ is not identified from the observed window and cannot be extrapolated.
- **When reasonable:** Effects plausibly follow a smooth, known functional form in event time
  (e.g. linear or spline decay/growth).
- **When unreasonable:** Regime change or structural breaks that a smooth reduced-form trend
  cannot capture — this is exactly what motivates Path 3.
- **Verifiable from data?** Partially — the first clause's fit to $t\le p$ is testable; the
  extension to $t=p+1$ is not (`main.tex:1000`).
- **Used by:** Proposition 2.
- **Declared in:** body.

#### `Identifiability and local rank for $\bgamma$` — `\label{RC5}`
- **Stated at:** `main.tex:828` (Appendix B)
- **Statement:** Two clauses: (i) global identifiability — $\bgamma\mapsto(f(g,t;\bgamma))$
  injective on $\Gamma$; (ii) local rank — the Jacobian $J_0$ has full column rank $d$
  (equivalently the weighted Gram matrix $H_0=J_0^\top\Lambda J_0$ is nonsingular).
- **Discharges:** (iii) a named rate/order condition — the implicit-function-theorem step of the
  Path 2 EIF derivation (Appendix `app:eif2`) requires clause (ii) specifically.
- **Role:** Restates and formalizes `assump:parametric`'s uniqueness clause with the exact rank
  condition the EIF chain-rule derivation needs. Remark `rem:rc5-independence` (`main.tex:840`)
  proves by explicit counterexample ($f=\gamma^3 c_{gt}$) that clause (i) does **not** imply
  clause (ii) — a genuine necessity argument, not an assertion.
- **When reasonable:** Every cohort observed at $\ge 2$ periods (Lemma `lem:injectivity`
  characterizes this exactly for the group-specific linear model).
- **When unreasonable:** A cohort adopting at $g=p$ (last-adopting cohort, Remark
  `rem:last-cohort`, `main.tex:1697`) contributes only one group-time ATT and cannot support a
  cohort-specific slope.
- **Verifiable from data?** Yes — clause (ii) is a rank condition on the observed design, fully
  checkable.
- **Used by:** the Path 2 EIF derivation (`app:eif2`) and, via that, Proposition (Asymptotic
  distribution).
- **Cited as a range anywhere?** As part of `Assumptions~\ref{RC1}--\ref{RC10}` — see the range
  note below.
- **Declared in:** appendix — and **used by a body result** (Proposition, asymptotic
  distribution, stated at `main.tex:617` in the body). This is the forward-dependency defect
  `outline.md` §3 flags.

#### `First-stage conditional identification` — `\label{assump:cond-ident}`
- **Stated at:** `main.tex:410`
- **Statement:** $\tau_t(x)$ is identified from observed data ($t\le p$) and estimable with
  cross-fitting at nonparametric rates; two leading cases given (unconfoundedness;
  conditional parallel trends).
- **Discharges:** (ii) a named identification step — the conditional-level analog of taking
  $\theta_{gt}$ as identified in Paths 1-2.
- **Role:** Supplies the first-stage $\tau(x)$ that Path 3 transports.
- **When reasonable:** Whenever a doubly-robust CATE learner or conditional DiD estimator is
  applicable to the researcher's design.
- **When unreasonable:** Insufficient overlap in $\bX$, or a design under which $\tau_t(x)$ is
  not point-identified conditionally.
- **Verifiable from data?** Depends on the design (standard unconfoundedness/parallel-trends
  verifiability caveats apply; not separately re-derived here).
- **Used by:** Proposition 3.
- **Declared in:** body.

#### `Structural stability of conditional effects` — `\label{assump:struct-stab}`
- **Stated at:** `main.tex:420`
- **Statement:** $\tau_t(x)=\tau(x)$ for all $x$ in the support of $\bX$ and all
  $t\in\{1,\ldots,p,p+1\}$.
- **Discharges:** (i) a named term — the conditional-level analog of `strict-time-homogeneity`,
  replacing the unobserved $\tau_{p+1}(x)$ with the identified $\tau(x)$ in the proof of
  Proposition 3 (Step 2).
- **Role:** Path 3's Lucas-Critique "deep parameters" condition; the substantive content the
  whole path rests on.
- **When reasonable:** Effect heterogeneity is well-explained by $\bX$ and $\bX$ captures the
  structural drivers (`main.tex:427`: "if early adopters differ systematically... in observed
  $\bX$, this can hold even when marginal $\theta_t$ varies").
- **When unreasonable:** Unobserved time-varying factors driving effect heterogeneity not
  captured by $\bX$.
- **Verifiable from data?** Partially — testable across observed periods where $\tau_t(x)$ is
  identified at two or more periods; the extrapolation to $p+1$ is untestable.
- **Used by:** Proposition 3.
- **Declared in:** body.

#### `Access to target covariate distribution and overlap` — `\label{assump:target-dist}`
- **Stated at:** `main.tex:429`
- **Statement:** Either a sample from $F_{\bX\mid A_{ip}=1}^{p+1}$ is observed, or draws are
  available via forecast/simulation; and the density ratio $w(x)$ exists and is bounded.
- **Discharges:** (i) named term (existence of $w$) and (iii) a named rate/order
  condition — boundedness is the overlap condition Assumption RC9 restates formally.
- **Role:** Supplies the target-distribution access and the change-of-measure validity for
  Proposition 3's Step 3.
- **When reasonable:** Future covariate support is covered by the historical (source) sample.
- **When unreasonable:** Heavy covariate shift into regions the historical data do not cover
  (`main.tex:433`) — the manuscript's own stated substantive limit of Path 3.
- **Verifiable from data?** No — it is a statement about $F_{\bX}^{p+1}$, an unobserved future
  distribution.
- **Used by:** Proposition 3.
- **Declared in:** body.

#### `Cross-group conditional transportability` — `\label{assump:cross-group}`
- **Stated at:** `main.tex:458`
- **Statement:** $\E_{\P_{p+1}}\{Y(1)-Y(0)\mid \bX=x, A_{ip}=1\}=\E_{\P_{p+1}}\{Y(1)-Y(0)\mid
  \bX=x, A_{ip}=0\}=\tau(x)$ for all $x$.
- **Discharges:** (ii) a named identification step, specifically for extending Path 3 beyond
  the FATT.
- **Role:** "Needed only for FATU/FATE" per its own label — the standard external-validity
  condition (no effect modification beyond $\bX$).
- **When reasonable:** Treatment-status is not itself an effect modifier beyond what $\bX$
  already captures.
- **When unreasonable:** Selection into treatment correlated with unmeasured effect modifiers.
- **Verifiable from data?** No.
- **Used by:** the FATU/FATE extension discussed at `main.tex:456-465` (not itself a separately
  numbered proposition in the body, but is the identifying condition for that extension).
- **Declared in:** body.

#### `Identification of first-stage` — `\label{RC1}`
- **Stated at:** `main.tex:808`
- **Statement:** $\theta_{gt}$ identified under the researcher's design, all $g\in\cG$, $t\le p$.
- **Discharges:** (v) — restates the paper's own scope boundary (first-stage identification is
  *taken as given*, per `story.md`'s scope boundary), not a term in a decomposition.
- **Role:** Formalizes the "first stage is the researcher's problem" boundary as a regularity
  condition for the asymptotic-normality proposition.
- **When reasonable/unreasonable:** Depends entirely on the researcher's chosen first-stage
  design; not evaluated here.
- **Verifiable from data?** No — see §2e.
- **Used by:** Proposition (Asymptotic distribution).
- **Declared in:** appendix, used by a body result — see the RC1-RC10 forward-dependency flag
  above.

#### `Asymptotic linearity of first-stage` — `\label{RC2}`
- **Stated at:** `main.tex:812`
- **Statement:** $\sqrt n(\widehat\theta_{gt}-\theta_{gt})=n^{-1/2}\sum_i\phi_{gt,i}+o_\P(1)$,
  mean-zero, finite second moment.
- **Discharges:** (iv) a named nuisance-estimation requirement.
- **Role:** The regularity condition making EIF propagation for Paths 1-2 valid.
- **Verifiable from data?** No — see §2e.
- **Used by:** Proposition (Asymptotic distribution), Steps 1-2 of its proof.
- **Declared in:** appendix, used by a body result.

#### `Weight identification` — `\label{RC3}`
- **Stated at:** `main.tex:820`. **Discharges:** (iv). **Role:** Makes $\widehat\omega_g$
  asymptotically linear when estimated. **Verifiable from data?** No — see §2e. **Used by:**
  Proposition (Asymptotic distribution). **Declared in:** appendix, used by a body result.

#### `Smoothness of $f$` — `\label{RC4}`
- **Stated at:** `main.tex:824`. **Statement:** $f(g,t;\bgamma)$ twice continuously
  differentiable in $\bgamma$ near $\bgamma_0$. **Discharges:** (iii) — needed for the
  delta-method/implicit-function-theorem step. **Verifiable from data?** No — regularity
  condition on the researcher's chosen $f$, not the data. **Used by:** Proposition 2's EIF
  derivation (`app:eif2`) and Proposition (Asymptotic distribution). **Declared in:** appendix,
  used by a body result.

#### `Bounded moments` — `\label{RC6}`
- **Stated at:** `main.tex:844`. **Statement:** $\E[\phi_{gt,i}^4]<\infty$ for all $g,t$.
  **Discharges:** (iii) — the CLT's moment requirement. **Verifiable from data?** Partially
  (empirically checkable via the estimated influence functions). **Used by:** Proposition
  (Asymptotic distribution), Step 3 of its proof. **Declared in:** appendix, used by a body
  result.

#### `Donsker or rate conditions for cross-fitting` — `\label{RC7}`
- **Stated at:** `main.tex:848`. **Statement:** flexible first-stage estimators either satisfy
  stochastic-equicontinuity conditions or are cross-fitted with every second-order product
  $o_\P(n^{-1/2})$. **Discharges:** (iii). **Verifiable from data?** No, see §2e. **Used by:**
  Proposition (Asymptotic distribution), Path 1-2 steps. **Declared in:** appendix, used by a
  body result.

#### `Nuisance estimation rates (Path 3)` — `\label{RC8}`
- **Stated at:** `main.tex:860`. **Statement:** cross-fitted Path-3 nuisance estimators satisfy
  $o_\P(n^{-1/2})$ product-rate conditions, stated separately for Regime (i) and Regime (iii)
  (Regime iii's $w$ carries **no** sampling-rate requirement since it is not estimated).
  **Discharges:** (iii). **Role:** the rate condition that makes the Path-3 EIF's second-order
  remainder negligible — this is the assumption the 2026-09-24 fix rewrote to distinguish the
  two regimes; see `claims.md` table 2's revision note on Proposition 3 / the Path-3 EIF
  results. **Verifiable from data?** No, see §2e. **Used by:** Proposition (Asymptotic
  distribution), Path-3 step; the post-proof audit at `main.tex:1487,1490`. **Declared in:**
  appendix, used by a body result (the Path-3 EIF derivation and estimation regime descriptions,
  §4.7, are in the body).

#### `Overlap for transport (Path 3)` — `\label{RC9}`
- **Stated at:** `main.tex:910`. **Statement:** strict overlap in $e(\bX)$ and $\rho\ge\rho_{\min}>0$
  (Regime i); $\E_{\mathrm{src}}\{w(\bX)^2\}<\infty$, sufficiently $\|w\|_\infty<\infty$ (Regime
  iii). **Discharges:** (iii) — the overlap/finite-variance condition. **Verifiable from data?**
  Partially — overlap in $e$ is checkable; boundedness of $w$ requires target-distribution
  access, which is itself unverifiable (inherits from `assump:target-dist`). **Used by:**
  Proposition (Asymptotic distribution) Step 3 (CLT), the EIF mean-zero/orthogonality proofs in
  `app:eif3`. **Declared in:** appendix, used by a body result.

#### `Target information for Path 3` — `\label{RC10}`
- **Stated at:** `main.tex:924`. **Statement:** two information regimes — (i) internally
  observed target membership with $q(x)/\rho=w(x)$ holding automatically; (iii) $w$ known or
  externally supplied and fixed, in which case the estimator is asymptotically linear for
  $\theta(\widetilde w)$ rather than $\theta_{p+1}$ unless $\widetilde w=w$. **Discharges:**
  (v) — states which functional the estimator targets under each regime, a scope condition
  rather than a rate/decomposition term. **Role:** This is the assumption that names the
  two-regime taxonomy itself — the direct product of the 2026-09-24 rewrite. **Verifiable from
  data?** No — the choice of regime is a design decision, not a testable condition; whether
  $\widetilde w = w$ (Regime iii, external case) is generally unverifiable. **Used by:**
  Proposition (Asymptotic distribution), Path-3 step; explicitly discussed at `main.tex:1651`
  (external-ratio bias). **Declared in:** appendix, used by a body result.

#### `Nonsingular and estimable score covariance` — `\label{RC11}` (added 2026-09-25, Item 2)
- **Stated at:** `main.tex:951` (appendix, immediately after RC10). **Statement:** (i)
  $\bSigma := \Var(\bphi_i) \succ 0$ for the stacked cell-score vector $\bphi_i$ over the fixed
  cell set $\cC$ — no nontrivial linear combination of cell scores is degenerate; (ii) a
  consistent estimator $\bSigmahat \to_\P \bSigma$ exists (e.g. the sample covariance of the
  aligned per-cell scores). **Discharges:** makes $\bSigma^{-1}$ and $X^\top\bSigma^{-1}X$ well
  defined; **explicitly does not introduce a new rank condition** — the assumption's own text
  notes that Assumption~\ref{RC5}(ii) already covers full-column-rank of $X$ for *any* positive
  weight matrix $\Lambda$, and $\Lambda=\bSigma^{-1}$ is one instance. **Also explicitly does
  not introduce a joint-asymptotic-linearity condition** — the assumption's prose states that
  joint normality of the stacked vector follows from the existing marginal Assumption~\ref{RC2}
  via Cram\'er--Wold, since every $\phi_{gt,i}$ is a function of the same i.i.d.\ unit $i$. This
  is the formal resolution of the "4th-moment/joint-vs-marginal-asymptotic-linearity" question
  the 2026-09-24 proof-audit had already answered informally (see `session_notes/2026-09-24.md`,
  13:20 entry: "confirmed unfounded... joint AL follows from marginal AL by Cram\'er-Wold over a
  common i.i.d. index") but never transcribed into the manuscript's own regularity apparatus
  until now. **Verifiable from data?** (i) is partially checkable — a near-singular sample
  $\widehat{\bSigma}$ is directly observable and is exactly what `estimate_score_cov()` (the
  package implementation) flags via its condition-number diagnostic; (ii) is a standard
  consistency condition, not separately testable. **Used by:** Proposition
  `prop:md-aggregation` (both steps of its proof use clause (i); clause (ii) is used only in
  Step 2 to justify replacing $\bSigmahat$ by $\bSigma$ inside an already-$O_\P(n^{-1/2})$
  product — no rate beyond consistency is required). **Declared in:** appendix, used by a body
  result (§6, `sec:md-aggregation`) — the same appendix-before-body-citation pattern already
  flagged for RC1-RC10 below, not newly introduced by RC11.

**RC1-RC11 range citation, expanded:** `Assumptions~\ref{RC1}--\ref{RC11}` (cited at
`main.tex:634`, the asymptotic-normality proposition's premise, and again at `main.tex:1589` as
the appendix's own restatement — **both updated together in the 2026-09-25 pass, closing the
exact "restatement lags the main-text fix" failure mode the 2026-09-24 session note recorded
happening once already for `prop:asymp`**) now expands to **all eleven**: RC1 (first-stage
identification), RC2 (asymptotic linearity), RC3 (weight identification), RC4 (smoothness of
$f$), RC5 (identifiability/local rank), RC6 (bounded moments), RC7 (Donsker/cross-fitting rate),
RC8 (Path-3 nuisance rates), RC9 (Path-3 overlap), RC10 (Path-3 target information), RC11
(nonsingular/estimable score covariance, Item 2). **The mutability warning below is now
realized, not just anticipated:** RC11 was appended *after* RC10 specifically so this range
citation's endpoint moves (RC10→RC11) rather than its interior silently absorbing a new
condition — the safer of the two ways an insertion could have gone, and the one this note's
prior draft flagged as the risk to avoid. `Assumptions~\ref{RC8}--\ref{RC10}` (cited at
`main.tex:560`, the Path-3 EIF section) is unaffected by the insertion and still correctly
expands to RC8, RC9, RC10 only.

### 2b. Implicit — carried in constraints or prose, not numbered

| Assumption | Where it hides | Role | Should it be promoted to formal? |
|---|---|---|---|
| Covariates unaffected by the policy (no causal path from treatment to $\bX$) | `main.tex:91` (setting, prose: "we further assume throughout that the covariates... are unaffected by the policy") | Underlies every covariate-adjustment step in the paper, and binds hardest for Path 3's transport target (`main.tex:437`) | Arguably yes — it is load-bearing for Path 3 specifically and is currently stated only in prose in §2 (Setting), then re-invoked in prose again in §4.7. A single formal statement, cited by reference from §4.7 rather than re-argued, would remove the current duplication. Recorded as a finding, not fixed (no `.tex` edits in scope). |
| No interference (each unit's potential outcomes depend only on that unit's own treatment) | `main.tex:91` | Standard SUTVA-type condition underlying the entire potential-outcomes setup | No — this is universal boilerplate in the literature and not specific to this paper's contribution; formalizing it would not aid a reader. |
| $\rho_{\mathrm{src}}>0$, $\rho_{\mathrm{tar}}>0$ (stacked-population regularity, Appendix EIF derivation) | `main.tex:1138` | Needed for the quotient-rule differentiation in `app:eif3` to be well-defined | No — this is a technical restatement of Regime (i)'s $\rho>0$ (already formal, in RC9) and Regime (iii)'s implicit $w$-boundedness; promoting it separately would duplicate RC9. |

### 2c. Regularity conditions — technical requirements

| Condition | Stated at | Role | Relaxable? |
|---|---|---|---|
| $\bgamma_0$ in the interior of $\Gamma$ | `main.tex:829` (part of RC5) | Needed for the implicit-function-theorem step | Not discussed in the manuscript; presumably relaxable to boundary cases with different (non-standard) asymptotics, not addressed here. |
| Square integrability of all Path-3 scores | `main.tex:1138` | Needed for the pathwise-derivative argument in `app:eif3` to have finite variance | Tied directly to RC9's overlap/moment conditions; not independently relaxable. |

### 2d. Summary — what is assumed and why

| Assumption(s) | Role / why needed |
|---|---|
| Absorbing adoption | Makes $G_i$ a well-defined single transition date; premise of every aggregation/identification result. |
| Strict/within-group time homogeneity (Path 1) | Substitutes constancy-in-time for an explicit temporal model; buys the FATT for free from the backward-looking ATT (or a cohort-weighted average of it). |
| Parametric temporal model + RC4-RC5 (Path 2) | Substitutes a known functional form for constancy; buys extrapolation to $p+1$ at the cost of correct specification and a rank/identifiability condition. |
| Conditional identification + structural stability + target-distribution access (Path 3) | Substitutes covariate-conditional invariance for temporal invariance; buys robustness to regime change at the cost of correct conditional-effect specification and covariate overlap. |
| RC1-RC11 | The full regularity apparatus making the asymptotic-normality proposition rigorous across all three paths; RC8-RC10 specifically distinguish Path 3's two information regimes; RC11 (added 2026-09-25) makes the correlated-cell aggregation of `sec:md-aggregation` well-posed by requiring the stacked score covariance to be nonsingular and estimable. |

### 2e. Blanket statements — one claim covering a set of assumptions

| Statement | Covers (assumption labels) | Stated at | Reason |
|---|---|---|---|
| Not empirically verifiable — concerns the unobserved future distribution $\P_{p+1}$ | `strict-between-homogeneity`, `general-p-to-p-plus-one-heterogeneity`, `assump:target-dist`, `assump:cross-group` | `main.tex:150`, `main.tex:301` (Remark `rem:testable`), `main.tex:427` (analogous remark for Path 3), `main.tex:433` | These all concern $\P_{p+1}$, "not merely unobserved but wholly unknown" (`story.md` S1) — the manuscript states this reasoning once per path (Remarks `rem:testable` for Path 1, the parallel discussion at `main.tex:427` for Path 3) rather than as a single cross-path blanket statement; recorded here as one registry row so the shared reasoning is visible even though the manuscript itself states it per-path. |
| Purely regularity/technical, not substantive | RC2, RC3, RC4, RC6, RC7 | `main.tex:812-858` | These are the standard asymptotic-linearity/moment/Donsker apparatus, not identifying content; the manuscript's own remark at `main.tex:935` groups RC1-RC3+RC6 as governing the first-stage and RC4-RC5 as Path-2-specific, which this row makes explicit as a blanket categorization. |

**Why this is a section and not a convention.** The manuscript's Remark at `main.tex:935` is
itself close to a blanket statement grouping RC1-RC3, RC6 (general first-stage regularity),
RC4-RC5 (Path 2), and RC8-RC10 (Path 3) — recorded above so a reviewer diffing assumption-by-
assumption does not miss that this grouping already exists in the prose.

---

## 3. Identification status

- **Point-identified from observed data alone:** the backward-looking ATT $\theta$; the
  group-time ATTs $\theta_{gt}$ for $t\le p$ (both *taken as identified* under the researcher's
  first-stage design, per RC1 — this paper does not supply that identification itself, per
  `story.md`'s scope boundary).
- **Partially identified, given nothing further in this paper:** none — the paper is explicitly
  point-identification-only (`story.md` scope boundary: "It point-identifies rather than
  bounds").
- **Not identified without further assumptions:** the FATT $\theta_{p+1}$ (and FATU/FATE/FATS)
  without an extrapolation assumption — requires one of: Assumption `strict-time-homogeneity`
  (or its within-group variant) for Path 1; Assumption `assump:parametric` for Path 2; or
  Assumptions `assump:cond-ident` + `assump:struct-stab` + `assump:target-dist` for Path 3. The
  future individual treatment effect ($\tau_{i,p+1}$, FITE) is **never** identified in this
  paper — stated explicitly as out of scope (`main.tex:131`, `story.md` scope boundary).

**If an assumption fails, what happens?**

| Assumption | If it fails | Consequence for the estimand |
|---|---|---|
| `strict-time-homogeneity` (or within-group variant) | Time-varying or cross-cohort-heterogeneous effects persist into $p+1$ | Path 1's $\widehat\theta_{p+1}$ is inconsistent for the true FATT; bias direction depends on the actual dynamics. |
| `assump:parametric` (functional form) | True $\theta_{gt}$ does not follow the posited $f$ | "The estimator converges to the wrong number" (`story.md` S4) — not merely inflated variance, a genuine inconsistency. |
| `assump:struct-stab` (Path 3) | Conditional effect $\tau(x)$ itself drifts over time | Path 3 fails in the same direction as Paths 1-2 — the manuscript states this symmetrically (`main.tex:467`: "Path~3 will fail just as Paths~1 and~2 do"). |
| `assump:target-dist` (bounded $w$) | Heavy covariate shift beyond source-sample support | Transport is "not credible," estimator variance degrades (`main.tex:433`). |
| RC10's regime choice, Regime (iii) case | Supplied $\widetilde w\ne w$ | Estimator is consistent/asymptotically linear for a different functional $\theta(\widetilde w)$, not $\theta_{p+1}$; the resulting bias $\theta(\widetilde w)-\theta_{p+1}$ is not accounted for by the stated variance (`main.tex:587`, `main.tex:1651`). |

---

## 4. Maintenance contract

- **A drafting or editing skill that introduces a symbol, an assumption, or a numbered result
  updates this file in the same turn.** A registry updated later is a registry that is wrong
  in between.
- **Reviewers diff, they do not re-derive.** Compare the manuscript against this file and
  report divergences.
- **Divergence is a finding, not a cue to silently sync.** Report which is right — do not
  overwrite one from the other.
- **Do not narrate registry corrections in the manuscript.** `paper-protocol.md` §1: a paper
  has no earlier drafts, only its argument.

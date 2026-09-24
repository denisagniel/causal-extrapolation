# Proof Audit — Path 2 / Path 3 Identification + Regularity Conditions + Technical Lemmas, `inst/paper/main.tex`

**Date:** 2026-09-24 · **Mode:** fresh, independent, adversarial audit via `proof-auditor` subagent.
**Scope:** Assumption `assump:parametric`; Prop. `prop:path2` + proof; Assumptions `assump:cond-ident`, `assump:struct-stab`, `assump:target-dist`; Prop. `prop:path3` + proof; Assumption `assump:cross-group`; RC1–RC10; Lemma `lem:injectivity`; Corollary `cor:linear-rank`; Remark on the last-adopting cohort.

---

## 0. Verdict and counts (read first)

| Result | Verdict |
|---|---|
| Prop. `prop:path2` (Path 2 identification) | **SOUND WITH CAVEATS** — core logic valid; quantifier defect in its own hypothesis, unstated population/positivity conditions |
| Prop. `prop:path3` (covariate transport) | **DEFECTIVE as written** (one Critical, one-line fix); SOUND WITH CAVEATS after fix |
| Lemma `lem:injectivity` | **SOUND** |
| Corollary `cor:linear-rank` | **SOUND WITH CAVEATS** (one "only if" direction silently uses `int Γ ≠ ∅`) |
| RC5 + its independence Remark | **SOUND WITH CAVEATS** (claims true; one asserted-not-proved, one half-proved, one mislabeled as necessary) |
| RC7, RC8 (rate conditions) | **DEFECTIVE** — stated rate is too weak by a factor $n^{1/4}$, in both |
| Remark on last-adopting cohort (three fixes) | **SOUND WITH CAVEATS** (third fix fails in an edge case; none verified) |

**Findings: 1 Critical, 9 Major, 11 Minor, 3 Suggestions — 24 total.**

**Short-form answers:**

- **RC5 counterexample:** correct as far as it goes (both legs verified), but it proves only (i) ⇏ (ii) while the Remark claims *independence*. Second counterexample supplied (m1).
- **Weight-independence:** true, and true in the strong both-directions form suspected — it is a two-line kernel argument the paper does not give. Sharp version supplied (m2).
- **Clause (ii) necessary for the IFT step:** sufficient (RC4's "near $γ_0$" does cover the neighborhood-continuity worry), but **not necessary for $\sqrt n$-estimability of the FATT** — the paper's own $γ^3$ example is the counterexample (M2). And the IFT cannot be applied to the system as the Remark describes it, because the system is overdetermined (M3).
- **RC9/unbounded $w$:** Prop 3's identity survives unbounded $w$ intact; only absolute continuity plus $L^1$ is needed. RC9 is mis-placed as an identification hypothesis (M5).
- **RC5(i) in Prop 2:** never invoked. It is a strict *strengthening* of `assump:parametric`'s second clause, not a redundancy — and it is load-bearing for estimation, not identification (§7).

---

## 1. Coverage Manifest

Audited, verbatim: `assump:parametric`; `prop:path2` + appendix proof (Steps 1–4) + following remark; the Path 3 setup line defining $τ_t(x)$; `assump:cond-ident`, `assump:struct-stab`, `assump:target-dist`; `prop:path3` + appendix proof (Steps 1–3) + following remark; `assump:cross-group`; RC1–RC10; `lem:injectivity` + proof; `cor:linear-rank` + proof; the last-adopting-cohort remark.

**Not supplied, and therefore not audited:**

1. Line ranges / file offsets for any excerpt.
2. The statement and proof of Lemma "Exact aggregation" — verified only that its advertised hypotheses (absorbing adoption alone) are available at the point of use in Prop 2 Step 2, and identified two conditions it must be carrying that are nowhere visible (M6, M8). Not certified.
3. The Path 2 EIF derivation containing the implicit-function-theorem step — M3 is **conditional** on which of two forms it takes (exactly-identified system vs. FOC of a minimum-distance criterion).
4. The verbatim absorbing-adoption assumption and the definition of the period-$t$ population $\mathbb P_t$ (M6 turns on this).

---

## 2. Failure localization and the Critical finding

### C1 — Prop 3, Step 1: the "identity, no assumption needed" claim is false as written

**Location.** Path 3 setup line (definition of $τ_t$) read with `prop:path3` proof, Step 1.

**Defect.** The setup defines $τ_t(x)=\mathbb E_{\mathbb P_t}[Y_{it}(1)-Y_{it}(0)\mid \mathbf X_i=x,\;A_{it}=1]$, so at $t=p+1$ the conditioning event is $\{A_{i,p+1}=1\}=\{G_i\le p+1\}$. The FATT conditions on $\{A_{ip}=1\}=\{G_i\le p\}$. Iterated expectations gives $θ_{p+1}=\int \mathbb E[Δ\mid \mathbf X=x,\;A_{ip}=1]\,dF^{p+1}_{\mathbf X\mid A_{ip}=1}(x)$, and the integrand is **not** $τ_{p+1}(x)$ unless the two conditioning events coincide, i.e. unless $\mathbb P(G_i=p+1)=0$. The units at issue are exactly the cohort newly adopting at $p+1$; they satisfy $A_{ip}=0$. Equating $\mathbb E[Δ\mid x,A_{i,p+1}=1]$ with $\mathbb E[Δ\mid x,A_{ip}=1]$ is precisely a special case of `assump:cross-group` restricted to $\{G_i=p+1\}$.

Consequently: (a) Step 1 is not assumption-free; (b) the label on `assump:cross-group` — "needed only for FATU/FATE" — is **false** whenever $\mathbb P(G_i=p+1)>0$, for the FATT itself.

**Severity.** Critical. It sits in the one step the paper advertises as requiring nothing, and it mislabels the scope of a named assumption. The repair is one line.

**Minimal fix.** Define the target conditional effect on the correct subpopulation: $τ_{p+1}(x):=\mathbb E_{\mathbb P_{p+1}}[Y_{i,p+1}(1)-Y_{i,p+1}(0)\mid \mathbf X_i=x,\;A_{ip}=1]$ — i.e. break the $A_{it}=1$ pattern at $t=p+1$ deliberately and say so. Then `assump:struct-stab` must be restated as linking the source-period $τ_t$ ($t\le p$, conditioning on $A_{it}=1$) to this redefined $τ_{p+1}$. Alternative fix: add $\mathbb P(G_i=p+1)=0$ ("no new adoption in the forecast period") as an explicit assumption, and note it is substantive, not innocuous.

### Other localized failures with minimal fixes

**M1 (Major) — quantifier defect in `assump:parametric` clause 2, propagated to RC1 and Prop 2's hypothesis.** Clause 1 asserts $θ_{gt}=f(g,t;\bgamma)$ only for $g\le t\le p+1$. Clause 2 quantifies over "all $g\in\cG$ and all $t\le p$" — including pre-treatment cells $t<g$. Read literally this can be **unsatisfiable**: for $f=α_g+β_g(t-g)$, requiring $f(g,t;\bgamma')=θ_{gt}=0$ at $t<g$ forces $α_g=β_g=0$ for any cohort with two or more pre-periods, contradicting clause 1 whenever post-treatment effects are nonzero. RC1 repeats the error; Prop 2's hypothesis and Step 1 inherit it. Note RC5(i) and `lem:injectivity` both use the correct window $g\le t\le p$. **Fix:** replace "all $t\le p$" with "all $t$ with $g\le t\le p$" in `assump:parametric` clause 2, RC1, and Prop 2's hypothesis.

**M6 (Major) — under which population are the weights $ω_g$ taken, and are they identified?** The FATT is $\mathbb E_{\mathbb P_{p+1}}[\cdot\mid A_{ip}=1]$; a valid decomposition requires $ω_g=\mathbb P_{p+1}(G_i=g\mid A_{ip}=1)$. Step 4 asserts identification because "the weights are functionals of the observed adoption pattern" — that requires cohort shares to be **stable from the observed population to $\mathbb P_{p+1}$**, an assumption, not a tautology, unless $\mathbb P_{p+1}$ is literally the same units advanced one period. The asymmetry with Path 3 (which builds a whole transport apparatus for $F_{\mathbf X}$ to drift) is conspicuous. **Fix:** subscript $ω_g$ with $\mathbb P_{p+1}$, and either add a cohort-share stability condition or state the same-units equivalence once, globally.

**M5 (Major) — Prop 3 cites strictly more than it uses.** Step 3 uses only the *existence* of $w$ (i.e. $F^{p+1}\ll F^{\mathrm{src}}$), not its boundedness, and does not use `assump:target-dist` clauses (a)/(b) at all — those are estimation inputs, duplicated at RC10. Likewise `assump:cond-ident`'s rate clause is unused in identification, duplicated at RC8. **Fix:** split `assump:target-dist` into absolute continuity (cited by Prop 3) and boundedness (folded into RC9, cited only by the asymptotic results).

**M9 (Major) — `assump:struct-stab` smuggles cross-cohort homogeneity and is stronger than the proof needs.** Quantified over all $t$, it equates $τ_t(x)$ across conditioning events $\{G_i\le t\}$ whose cohort composition differs by $t$ — implying, under mild non-degeneracy, cross-cohort homogeneity within $\mathbf X$-strata (overlapping `assump:cross-group`'s territory). Prop 3 needs stability only between the estimation periods and $t=p+1$. **Fix:** state which subpopulation each $τ_t$ conditions on; restrict to periods used; state the cross-cohort implication explicitly.

**M7 (Major) — identification relative to *what* observed-data distribution?** Under time-varying $\mathbf X$, $F^{p+1}_{\mathbf X\mid A_{ip}=1}$ is not a functional of the observed panel — identification is relative to an augmented data structure or an assumption about the analyst's information. $F^{\mathrm{src}}_{\mathbf X}$ is also never defined (which periods? which units? pooled?). **Fix:** define $F^{\mathrm{src}}$ explicitly; state the observed-data distribution the claim is relative to.

**M8 (Major) — well-definedness conditions absent throughout both paths.** Needed and nowhere stated: $\mathbb P(A_{ip}=1)>0$; $\mathbb E|Y_{i,p+1}(a)|<\infty$ and $\int|τ|\,dF^{p+1}<\infty$; "for all $x$" should read "for $F$-a.e. $x$". **Fix:** one regularity condition, cited by both propositions; switch to a.e. quantifiers.

**M4 (Major) — RC7 and RC8 state the wrong rate.** Both require products $=o_P(n^{-1/4})$. For a $\sqrt n$-scaled expansion the remainder must be $o_P(n^{-1/2})$; the standard DML condition is each rate $o_P(n^{-1/4})$, giving product $o_P(n^{-1/2})$. As written, $\sqrt n\cdot o_P(n^{-1/4})=o_P(n^{1/4})$ does not vanish. **Fix:** RC7 → $\|\hatθ_{gt}-θ_{gt}\|=o_P(n^{-1/4})$ uniformly; RC8 → products of nuisance $L^2$ rates $=o_P(n^{-1/2})$, each $o_P(n^{-1/4})$.

**M3 (Major, conditional) — the IFT does not apply to the system the Remark names.** The system $f(g,t;γ)=θ_{gt}$ over $\{(g,t)\}$ is overdetermined once the number of cells exceeds $d$ (the generic case). The step must instead run on the FOC of a criterion $Q(γ,θ)=\sum λ_{gt}\{f(g,t;γ)-θ_{gt}\}^2$; then $\nabla^2_{γγ}Q(γ_0,θ_0)=2H_0$ only because residuals vanish at $θ_0$ — which is why RC4's $C^2$ matters. **Fix:** name the criterion and weights $λ_{gt}$ explicitly, and add compactness/well-separation + global continuity for consistency of $\hatγ$ (missing prerequisite, distinct from RC5).

**M2 (Major) — RC5(ii) is stronger than what the EIF actually requires.** At $γ_0=0$ in the $γ^3c_{gt}$ example, RC5(ii) fails, but reparameterizing $ψ:=γ^3$ makes the model linear and $\sqrt n$-consistent, and the target FATT is $\sqrt n$-estimable with an ordinary influence function — at exactly the point where RC5(ii) fails. What fails there is $\sqrt n$-estimability of $γ$ itself, an artifact of a non-regular parameterization, not a property of the FATT. **Fix:** state RC5(ii) as a condition on the chosen parameterization, and note it can sometimes be restored by reparameterization.

---

## 3. Assumption check

### Prop 2

Assumptions genuinely used: absorbing adoption (via exact aggregation, Step 2); `assump:parametric` clause 2 (Step 1); clause 1 at $(g,p+1)$ (Step 3); identification of $θ_{gt}$ on the observed window (Step 1). Nothing from RC4–RC7 is used, and the proposition correctly does not cite them. No RC5 is used anywhere (see §7).

Worth stating explicitly: Step 1 *is* a valid identification argument — two observationally equivalent model-consistent laws solve the *same* system, and clause 2's uniqueness forces their parameters equal.

### Prop 3

See M5, M7, M9, M8 above and C1. No extra assumption smuggled in beyond those already flagged.

### Lemma `lem:injectivity` / Corollary `cor:linear-rank`

Assumptions used are exactly those stated; nothing smuggled. See §6 for boundary/degenerate cases and m3 for the one place the corollary's proof leans on an uncited part of RC5's preamble.

---

## 4. Dependency check

**Exact aggregation, at the point of use (Prop 2 Step 2).** Hypotheses (absorbing adoption alone) are available; internal consistency of the two conditioning sets checks out ($\{G_i=g,A_{i,p+1}=1\}=\{G_i=g\}\subseteq\{A_{ip}=1\}$ for $g\in\cG$; $\sum_{g\le p}\mathbb P(G_i=g\mid A_{ip}=1)=1$). Two silently-carried conditions flagged (M6, M8). Lemma itself not certified (not supplied).

**Prop 3 Step 1.** Answered in C1 (substantive failure) and M8 (residual measurability/integrability). Not assumption-free as written; true after the one-line redefinition plus a positivity-and-integrability condition.

**Prop 2 Step 3.** "Fix $g\in\cG$, so $g\le p$ and hence $g\le p+1\le p+1$" is garbled (m6) but correct: the real check is $g\le t=p+1\le p+1$, which holds because $g\le p<p+1$.

---

## 5. RC5 scrutiny, re-derived from scratch

### The counterexample is correct — both legs verified independently

$d=1$, $f(g,t;γ)=γ^3c_{gt}$, not all $c_{gt}=0$.

*Injectivity.* If $γ^3c_{gt}=γ'^3c_{gt}$ for all $(g,t)$, pick $(g,t)$ with $c_{gt}\ne0$; then $γ^3=γ'^3$, and since $x\mapsto x^3$ is injective on $\mathbb R$, $γ=γ'$. ✓

*Jacobian.* $\partial_γ f=3γ^2c_{gt}$, vanishing identically at $γ_0=0$. So $J_0=0$, $H_0=0$ for every $Λ$. ✓

So (i) ⇏ (ii) is established.

**m1 (Minor) — but the Remark claims the clauses are "independent," proving only one direction.** Second counterexample, in the paper's own format: $d=1$, $Γ=\mathbb R$, $f(g,t;γ)=c_{gt}(γ^3-3γ)$, true $γ_0=2$. Since $γ^3-3γ-2=(γ-2)(γ+1)^2$, the map takes the value 2 at both $γ=2$ and $γ=-1$, so (i) fails; while $\partial_γf=c_{gt}(3γ^2-3)=9c_{gt}\ne0$ at $γ_0=2$, so (ii) holds. Two counterexamples, one per direction, and the Remark's independence claim is then earned.

**m5 (Minor) — two omissions around the existing counterexample.** $Γ$ unspecified (RC5 needs $γ_0\in\operatorname{int}Γ$, so state $0\in\operatorname{int}Γ$). And $γ_0=0$ means $θ_{gt}\equiv0$ — the degeneracy sits exactly at the no-effect null, worth promoting in the text.

### Is clause (ii) necessary and sufficient for the IFT step?

**Sufficiency:** covered by RC4's neighborhood $C^2$, but the Remark's stated mechanism (IFT on $f(g,t;γ)=θ_{gt}$ directly) is wrong — see M3. Running the IFT correctly on the FOC of the WLS criterion, RC4 + RC5(ii) suffice, with $\partial γ/\partial θ = H_0^{-1}J_0^{\mathsf T}Λ$. What's still missing: consistency prerequisites (compactness/well-separation, global continuity) — RC5(i) alone does not deliver a well-separated minimum on a noncompact $Γ$.

**Necessity: RC5(ii) is necessary for *this route*, not for the *result*** — see M2's reparameterization counterexample.

### The weight-independence claim

**m2 (Minor) — true, in a stronger both-directions form than stated, asserted rather than proved.** Clean statement: for $Λ\succ0$, $\ker(J_0^{\mathsf T}ΛJ_0)=\ker J_0$ exactly (via $Λ^{1/2}$), so $H_0$ nonsingular for **one** $Λ\succ0$ $\iff$ nonsingular for **every** symmetric $Λ$. Refinements: (a) sharp sufficient condition is $Λ$ PD on $\operatorname{range}(J_0)$, weaker than $Λ\succ0$; (b) with some $λ_{gt}=0$ (dropping a cell), $Λ\succeq0$ only and the equivalence fails (counterexample: $d=2$, $J_0=I_2$, $Λ=\operatorname{diag}(1,0)$, $H_0$ singular despite $J_0$ full rank). Also flag: if $\hatΛ$ is estimated, RC1–RC10 nowhere require $\hatΛ\to_pΛ\succ0$.

---

## 6. Edge-case scan

**Path 3 with $w$ unbounded.** Right as suspected: $F^{p+1}\ll F^{\mathrm{src}}$ is all Step 3 needs; the change-of-variables identity holds a.e. for any $ν$-integrable $h$ with no boundedness of the density ratio. So Prop 3's equality survives a.e.-finite-but-unbounded $w$ intact; the only requirement beyond $\ll$ is $τ\in L^1(F^{p+1})$. Boundedness only buys finite asymptotic variance and DML remainder control downstream (M5).

**`lem:injectivity` at $g=p-1$ (minimal case).** Correct. Determinant of the two-row block $\ne0$; rank 2. The lemma is **SOUND** as stated and proved, "iff" genuine in both directions.

**$|\cG|=1$.** Both results specialize correctly; degenerate $\cG=\emptyset$ gives a vacuous $0\times0$ rank condition, excluded once $\mathbb P(A_{ip}=1)>0$ is assumed (M8).

**m4 (Minor) — the last-adopting-cohort remark's third fix fails when $\cG=\{p\}$.** Then $\cG'=\emptyset$ and the renormalization divides by zero; require $\cG'\ne\emptyset$. The other two fixes (pooled slope: full rank $q+1$ iff **some** $g\le p-1$; event time alone: rank 2 iff some $g\le p-1$) are correct but unproved — both genuinely work except in the fully degenerate design where every cohort adopts at $p$.

---

## 7. Tightness

**RC5(i) is never invoked in Prop 2.** Not redundant with `assump:parametric` clause 2 — RC5(i) is a strictly stronger, all-$θ$ statement; clause 2 is a single-fibre statement, sufficient for identification alone. RC5(i) is needed for consistency of $\hatγ$, which needs more than RC5(i) anyway (missing compactness/well-separation, M3). The paper's own cubic example shows identification and regular estimability coming apart at $γ_0=0$.

**Recommendation.** State each condition once, at the point it's needed, and label the role: clause 2 (or RC5(i)) ⇒ identification; RC5(i) + compactness/well-separation + global continuity ⇒ consistency; RC4 + RC5(ii) ⇒ asymptotic linearity via the FOC-IFT. At present clause 2 and RC5(i) state overlapping content and **have already diverged** — over the index set (M1).

---

## 8. Remaining Minor findings and Suggestions

- **m3.** `cor:linear-rank`'s clause-(i) "only if" is not valid for arbitrary $Γ$ (counterexample: $Γ$ a coordinate subspace). Rescued by `int Γ ≠ ∅`, not cited in the proof.
- **m6.** Prop 2 Step 3's garbled inequality; should read $g\le t=p+1\le p+1$.
- **m7.** RC10 does not relate $n^*$ to $n$; with $n^*$ fixed no $\sqrt n$ statement is available; add $n^*/n\to c\in(0,\infty]$.
- **m8.** RC6's fourth moments not tied to any use; RC2 already gives finite variance for the CLT.
- **m9.** `assump:cond-ident` case (b) is a pointer to an estimator, not a stated condition.
- **m10.** RC9's "$\|w\|_\infty<\infty$, or at least $\mathbb E[w^2]<\infty$" presented as interchangeable; they are not (L² suffices for variance, but the DML remainder with estimated $\hat w$ generally needs a uniform bound/trimming).
- **m11.** Prop 3's "unlike Paths 1/2" injectivity remark may over-state — Path 1 (constant-in-$t$) likely needs no injectivity either; outside this pass's scope, flagged for check.
- **s1.** Prop 2's misspecification remark would be sharper naming the pseudo-true limit explicitly.
- **s2.** Note the finite index set means RC4 needs no uniformity over $(g,t)$, unlike RC7.
- **s3.** Record explicitly why Prop 2 Step 1 is a valid identification argument.

---

## 9. What could not be certified

- The exact-aggregation lemma itself (not supplied).
- M3's diagnosis is conditional on the form of the Path 2 EIF derivation (not supplied) — if it already runs the IFT on the WLS FOC, M3 reduces to the missing consistency prerequisites; if it applies the IFT to the system directly, M3 is a hard logical defect.
- Line-anchored locations (no line ranges provided).
</content>

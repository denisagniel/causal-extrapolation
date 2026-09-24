# Proof Audit — `inst/paper/main.tex` §§3.2–3.5 (Lemmas 1–2, Prop. 1, Cor. 1, Assumptions 1–6)

**Date:** 2026-09-24 · **Mode:** fresh, independent, adversarial audit via `proof-auditor` subagent.
**Scope:** Assumption "Absorbing adoption"; §3.2 "Cohort structure of the FATT" (Lemma persistence, Lemma aggregation); §3.3 "Path 1" (Assumption strict-time-homogeneity, Prop. 1 + proof, remarks); §3.4 "Connecting other forward-looking estimands to backward-looking estimands"; §3.5 "Connecting the FATT to sub-ATTs" (Assumption within-group-strict-time-homogeneity, Cor. 1 + proof).

---

## 0. Summary and verdict counts

**Overall: SOUND WITH CAVEATS for the §3.2–3.3/§3.5 core (Lemma persistence → Lemma aggregation → Prop. 1 → Cor. 1); DEFECTIVE for §3.4 as written.**

The load-bearing chain is correct and non-circular. Its arithmetic is right, its dependency order is right, and one subtle detail (the positivity caveat on `P(G_i=g)>0` being attached to the conditional-expectation clause only, not to the event equality) is handled correctly — see §3 below. The defects are concentrated in (a) unstated regularity/positivity/measure-theoretic scaffolding that the proofs silently use, (b) a scope over-claim about assumption-freeness, and (c) §3.4, where three equivalences are asserted with no proof and at least one of them does not follow from the stated assumptions as written.

**Finding counts (for the audit performed, not for the text emitted):**

| Severity | Count |
|---|---|
| Critical | 3 |
| Major | 9 |
| Minor | 9 |
| Suggestion | 4 |

**Per-result verdicts:**

| Result | Verdict |
|---|---|
| Assumption 1 (absorbing adoption) | SOUND WITH CAVEATS |
| Lemma 1 (cohort persistence) | SOUND WITH CAVEATS |
| Lemma 2 (exact aggregation) — as mathematics | SOUND WITH CAVEATS |
| Lemma 2 — as advertised ("identity in $\P$") | **DEFECTIVE** |
| Remark (scope of the decomposition) | SOUND WITH CAVEATS |
| Remark (the last observed period) | **SOUND** |
| Proposition 1 + appendix proof | SOUND WITH CAVEATS |
| Remark (a weaker sufficient condition) | SOUND WITH CAVEATS |
| Remark (FATU analogue) | **DEFECTIVE** |
| §3.4 chain $\theta=\omega_{p+1}=\tau_{p+1}=\tau_{i,p+1}(\eta;\rho)=\tau_{i,p+1}$ | **DEFECTIVE** |
| §3.4 ATU=FATU claim | SOUND WITH CAVEATS (correct but unproved and non-minimal) |
| §3.4 ATE=FATE claim | SOUND WITH CAVEATS |
| §3.4 ATS=FATS claim | **DEFECTIVE** |
| Corollary 1 (within-group) | SOUND WITH CAVEATS |

---

## 1. Coverage manifest

**Received verbatim** (treated as authoritative per the request):

| Excerpt | Stated location |
|---|---|
| Assumption "Absorbing adoption" + prose gloss | main.tex:105, :107 |
| §3.2 Lemma persistence + proof; Lemma aggregation + proof; Remarks `aggregation-scope`, `boundary` | main.tex:204–264 |
| §3.3 Assumption `strict-time-homogeneity`; Prop. 1 statement; Remarks `aggregate-homogeneity`, FATU analogue | main.tex:265–330 |
| Appendix "Proof of Proposition 1" (restated in full) | main.tex, Appendix |
| §3.4 Assumption `strict-between-homogeneity`; FATU/FATE/FATS definitions; Assumptions `general-strict-time-homogeneity`, `general-p-to-p-plus-one-heterogeneity`; three equivalence claims | main.tex:305–331 |
| §3.5 Assumption `within-group-strict-time-homogeneity`; Cor. 1 + proof | main.tex:332–355 |

**Received as paraphrase, explicitly declared out of audit scope:** the shared setting (units/periods, $A_{it}$, $Y_{it}(a)$, $X_{it}$, $G_i$, $\theta_{gt}$, $\theta_{p+1}$, $\omega_g$, $\cG$, $\P_t$).

**Not received:** main.tex §§1–2 as written (the actual setup/notation section); any formal definition of "identified" or of the observed-data distribution; the statement of the researcher's design (parallel trends etc.); §5 (EIF/estimation); the "matching pair of homogeneity assumptions" the FATU remark invokes.

**Consequence for this audit, stated plainly.** The in-scope excerpts are verbatim and self-contained enough to audit the proofs, so I proceed. But three of my findings (M1, M2, and the integrability component of C1) concern exactly the material I did *not* receive — the measure-theoretic construction of $\P_t$, the index set of the minimum defining $G_i$, and moment conditions. For those I report **what the in-scope proof steps require**, and flag that if §2 already supplies it, the finding degrades from "missing" to "used non-locally, cite it at the point of use." I cannot discharge them myself and do not pretend to.

**Line-range inconsistency in the bundle:** §3.3 is given as 265–330 and §3.4 as 305–331. These overlap by 26 lines, so I cannot confirm the section boundary. Immaterial to the mathematics; noted for traceability.

---

## 2. Failure localization (protocol item 6 — emitted first, before items 1–5)

| # | Exact location | Specific defect | Sev | Minimal fix |
|---|---|---|---|---|
| C1 | Lemma aggregation, final sentence of statement: "the display is an identity in $\P$" | False as a scope claim. The display holds only for $\P$ that satisfy Assumption 1 **and** $\P(A_{ip}=1)>0$ **and** $\E_{\P_{p+1}}\lvert\tau_{i,p+1}\rvert<\infty$. As written it asserts unconditional validity. | **Critical** | Replace with: "an identity in every $\P$ satisfying Assumption~\ref{absorbing-adoption} with $\P(A_{ip}=1)>0$ and $\E_{\P_{p+1}}\lvert Y_{i,p+1}(1)-Y_{i,p+1}(0)\rvert<\infty$." Add both conditions to the lemma hypotheses. |
| C2 | §3.4, third equivalence claim ("$\cC_t=\{\rho(X_i,X_j)\le\eta\}$ yields ATS=FATS ... without needing `general-p-to-p-plus-one-heterogeneity`") | Instantiating $\cC_t$ into Assumption `general-strict-time-homogeneity` yields a statement about **unit $i$'s** effect conditional on a pairwise event; FATS is defined as **unit $j$'s** effect. Type mismatch — the instantiation produces a different functional. Separately, the exemption from the second assumption is valid only if $\cC_t$ is constant in $t$, which fails for time-varying $X_{it}$. No proof is given. | **Critical** | State a pairwise version of the assumption explicitly ($X_i$ held fixed, $j$ an independent draw), and state time-invariance of the matching event (or of $X$) as a hypothesis. Then the exemption argument is one line: $\cC_p=\cC_{p+1}$ makes the second assumption an identity. |
| C3 | §3.4, chain "$\theta=\omega_{p+1}=\tau_{p+1}=\tau_{i,p+1}(\eta;\rho)=\tau_{i,p+1}$ for all $i,\rho,\eta$" | Does not follow from Assumption `strict-between-homogeneity` as literally stated. "$\tau_{i,p+1}=\tau_{j,p+1}$ for all $i,j$" permits a **common random** effect; conditional expectations of a random variable under different events need not agree. Counterexample below. | **Critical** | Restate as: there is a non-random constant $\tau$ with $\tau_{i,p+1}=\tau$ a.s. for all $i$. Or add the i.i.d.-units premise and the one-line degeneracy argument. Add positivity of each conditioning event. |
| M1 | Lemma aggregation Step 2; Lemma persistence's conditional clause | $\E_{\P_{p+1}}\{\cdot \mid A_{ip}=1\}$ is not well defined if $\P_{p+1}$ is literally the period-$(p+1)$ marginal — $A_{ip}$ is not a function of the period-$(p+1)$ coordinates. The law of total probability also requires the weights $\omega_g$ (written under unsubscripted $\P$) and the outer expectation to be taken under the **same** measure. | Major | One sentence in §2: $\P$ is the joint law of $\{(A_{it},X_{it},Y_{it}(0),Y_{it}(1))\}_{t\le p+1}$; $\P_t$ its period-$t$ marginal; all multi-period functionals are under $\P$. Then write $\E_\P\{\cdot\mid A_{ip}=1\}$, or define the notation explicitly. |
| M2 | Lemma persistence, "for every cohort $g\le p+1$"; Remark `aggregation-scope`, "$\{A_{i,p+1}=1\}=\{G_i\le p+1\}$" | The index set of $\min$ in $G_i=\min\{t:A_{it}=1\}$ is never pinned down. Under the setting's literal "$t=1..p$", $\{G_i=p+1\}=\varnothing$, so Lemma persistence's range is partly vacuous and Remark `aggregation-scope`'s central claim is **false** (a unit adopting at $p+1$ has $G_i=\infty$ but $A_{i,p+1}=1$). | Major | Define $G_i=\min\{t\ge 1: A_{it}=1\}$ on a process defined for $t=1,\dots,p+1$, with $G_i=\infty$ if the set is empty. |
| M3 | Lemma persistence proof: "since $t\ge g$, Assumption~\ref{absorbing-adoption} gives $A_{it}=1$" | Assumption 1 quantifies $t\in\{1,\dots,p\}$. In the boundary case $g=t=p+1$ the assumption is invoked outside its range. (The conclusion still holds — trivially, since $A_{ig}=1$ *is* $A_{it}=1$ — so this is an invocation error, not a false step.) | Major | Case-split: "if $t=g$ the claim is $A_{ig}=1$; if $t>g$ then $g\le p$ and Assumption 1 applies at $t=g$." |
| M4 | §3.4, the three equivalence claims taken as a unifying framework | §3.4 does **not** subsume §3.3. With $\cC_t=\{A_{it}=1\}$, the framework would require `general-p-to-p-plus-one-heterogeneity` to reach the FATT, which §3.3 provably does not need. The asymmetry is an artifact of letting $\cC$ vary with $t$, not a feature of the estimands. | Major | Formulate the general assumption with the conditioning event **fixed at $p$**: $\E_{\P_t}\{\tau_{it}\mid\cC_p\}$ constant in $t$. Then ATT/ATU/ATE/ATS are one theorem and no second assumption is needed anywhere. |
| M5 | §3.3 FATU remark: "identifying the FATU still requires a substantive assumption about who newly adopts on $(p,p+1]$" | Incorrect for the FATU **as defined in §3.4** ($\omega_{p+k}=\E_{\P_{p+k}}\{\tau_{i,p+k}\mid A_{ip}=0\}$), which conditions on a period-$p$ event and is therefore exactly as future-adoption-free as the FATT. Also $\theta^U=\E_\P\{\cdot\mid A_{it}=0\}$ carries a free index $t$, and the "matching pair of homogeneity assumptions" is never stated. | Major | Pick one FATU definition. If it conditions on $A_{ip}=0$, delete the asymmetry claim — Remark `boundary` applies symmetrically. If it conditions on $A_{i,p+1}=0$, say so and keep the claim. |
| M6 | Prop. 1 statement ("the backward-looking ATT $\theta$"); Remark `aggregate-homogeneity` | $\theta$ is introduced in Assumption `strict-time-homogeneity` as the common *sub*-ATT value. Prop. 1's identification premise is about the *aggregate* backward ATT $\E_{\P_p}\{\tau_{ip}\mid A_{ip}=1\}$. Their equality follows from Remark `boundary` + homogeneity but is never stated. Under the remark's weaker aggregate condition no common scalar exists, so $\theta$ must be *redefined* as the aggregate — and the appendix proof (which uses pointwise $\theta_{g,p+1}=\theta$ at Step 2) is then not a proof of it. | Major | Insert one line in Prop. 1's proof: "by Remark~\ref{rem:boundary} and Assumption~\ref{strict-time-homogeneity}, $\E_{\P_p}\{\tau_{ip}\mid A_{ip}=1\}=\sum\omega_g\theta=\theta$." Give Remark `aggregate-homogeneity` its own two-line proof with $\theta$ explicitly defined as the aggregate. |
| M7 | §3.4, "$\theta=\omega_{p+1}=\dots$" | Notation collision: $\omega_g$ is the cohort weight $\P(G_i=g\mid A_{ip}=1)$ in Lemma aggregation; $\omega_{p+k}$ is the FATU here. $\omega_{p+1}$ is genuinely ambiguous — Remark `aggregation-scope` two pages earlier discusses precisely "the cohort adopting at $p+1$." | Major | Rename the FATU (e.g. $\theta^U_{p+k}$ or $\upsilon_{p+k}$). |
| M8 | Assumption `general-strict-time-homogeneity` | Ill-formed as stated: "for some conditioning event $\cC_t$ defined on $\P_t$ and all $s,t$" mixes quantifiers (should be "for a given family $\{\cC_t\}_{t\le p+1}$, and all $s,t$"); "defined on $\P_t$" is not meaningful (events live on a $\sigma$-algebra, not a distribution); positivity $\P(\cC_t)>0$ is unstated and required. | Major | Rewrite with the family fixed first and $\P(\cC_t)>0$ assumed for every $t$ used. |
| M9 | Cor. 1, final clause ("If in addition each $\theta_{g\cdot}$ ... is identified ... the FATT is identified") | Omits that the weights $\omega_g$ must also be identified. They are (functionals of the within-window $A$ path), but unlike Prop. 1 — where the weights cancel — Cor. 1 genuinely needs them. Two substantive companions also go unmentioned: cohort $g=p$ has exactly one in-window period, so $\theta_{p\cdot}$ rests on a single period and the assumption is untestable for it; and in staggered DiD, if all units adopt by $p$ no not-yet-treated comparison remains at $t=p$, so the premise can fail systematically at the window boundary. | Major | Add "$\omega_g$ is identified from the observed treatment paths"; add a sentence on the boundary cohort. |

---

## 3. Assumption check (protocol item 1)

**Lemma persistence.** Uses exactly Assumption 1 and the definition of $G_i$. No extra assumption — with the M3 caveat that the invocation strays outside the assumption's quantifier range at $g=t=p+1$, and the M2 caveat that the range "$g\le p+1$" presupposes a $G_i$ whose domain reaches $p+1$.

**Does the event equality itself need $\P(G_i=g)>0$?** **No.** The equality $\{A_{it}=1,G_i=g\}=\{G_i=g\}$ is purely set-theoretic — both inclusions are established pointwise on the sample space. The lemma is therefore **correct** to attach the positivity caveat only to the conditional-expectation consequence. This hinges on Assumption 1 being stated *surely* ("For every unit $i$") rather than almost surely; under an a.s. version the equality would hold only up to a null set, and Lemma aggregation Step 1's boast of "an empty event rather than merely a null one" would fail. That the paper gets this right is worth preserving explicitly — a future weakening of Assumption 1 to a.s. form would silently break it.

**Lemma aggregation.** Claims to use Assumption 1 "and nothing further." In fact the proof additionally requires, silently:
1. $\P(A_{ip}=1)>0$ — otherwise $\omega_g$, $\cG$, and $\theta_{p+1}$ are all undefined, and the asserted $\sum_{g\in\cG}\omega_g=1$ is false (empty sum $=0$).
2. $\E_{\P_{p+1}}\lvert Y_{i,p+1}(1)-Y_{i,p+1}(0)\rvert<\infty$ — Step 2's finite-partition tower property needs it. A heavy-tailed effect distribution (Cauchy $\tau$) breaks the display with no homogeneity or parametric assumption violated. This is exactly the failure mode the lemma's own boast invites a referee to probe.
3. A single joint law on which both $G_i$ (a period-$\le p$ functional) and $Y_{i,p+1}(a)$ live, with $\omega_g$ computed under that same law (M1).
4. Assumption 1's reach to $s=p+1$ — i.e. no repeal on $(p,p+1]$, an untestable condition on the unobserved period. Its **only** use is to make $\{A_{i,p+1}=1,G_i=g\}=\{G_i=g\}$ in Step 3, which matters only because $\theta_{g,p+1}$ is *defined* by conditioning on $A_{i,p+1}=1$. See the tightness section for the fix that removes this dependence entirely.

**Prop. 1 / appendix proof.** Uses Lemma aggregation (hence everything above) plus Assumption `strict-time-homogeneity` **at $t=p+1$ only**. The assumption's content at $g\le t\le p$ is never used in the proof; it earns its place only by making the premise "$\theta$ is identified from the observed data" plausible. Worth saying so — it clarifies that the in-window content of the assumption is doing *identification* work, not *extrapolation* work. The $\theta$-vs-aggregate-ATT bridge is the one genuinely missing step (M6).

**Cor. 1.** Uses Lemma aggregation + Assumption `within-group-strict-time-homogeneity` at $t=p+1$ only. Correct; incomplete identification clause (M9).

**§3.4.** Assumption `strict-between-homogeneity` is misnamed ("No future *between-state* ITE heterogeneity") — it states $\tau_{i,p+1}=\tau_{j,p+1}$ for *all* $i,j$, i.e. no heterogeneity whatsoever, within states as well as between. The strength is needed for the claimed chain, so this is a labeling defect, not a mismatch. Assumptions `general-*` are stated for all $(s,t)$ but used only at $(p,p+1)$ — over-strong relative to use.

**Stated-but-unused:** none outright. Assumption `strict-time-homogeneity`'s $t<p+1$ content and the `general-*` assumptions' $(s,t)\neq(p,p+1)$ content are unused *within the proofs*; both have a defensible external role (identification, generality). Flag as scope-tightening opportunities, not as dead hypotheses.

---

## 4. Dependency check (protocol item 2)

**No circularity.** Lemma persistence is proved from Assumption 1 and the definition of $G_i$ alone; it cites nothing downstream. Lemma aggregation cites persistence (twice, at $t=p$ and $t=p+1$). Prop. 1 cites aggregation. Cor. 1 cites aggregation. Remark `boundary` cites the *proof* of aggregation. Remark `aggregate-homogeneity` cites aggregation + `boundary`. The dependency graph is a DAG.

**Hypotheses verified at each point of use:**

- Aggregation Step 1, "$G_i\le p\Rightarrow A_{ip}=1$ by Assumption 1": applies the assumption at $t=G_i\le p$ — inside its range. ✓ (Contrast M3, where the range is exceeded.)
- Aggregation Step 3, persistence at $t=p$: needs $g\le p\le p+1$; holds since $g\in\cG$. ✓
- Aggregation Step 3, persistence at $t=p+1$: needs $g\le p+1$; the proof correctly flags "admissible since $g\le p<p+1$." ✓
- Aggregation Step 3 then equates two *conditional expectations*, which invokes persistence's positivity-caveated clause. Needed: $\P(G_i=g)>0$. Available: $\omega_g>0$, which gives $\P(G_i=g)>0$ **only because $\P(A_{ip}=1)>0$** — the condition never assumed (C1/M1). This is the one place where the missing positivity is not merely vacuity-avoidance but an actual unmet hypothesis at a point of use.
- Prop. 1 Step 2: needs $g\le p+1\le p+1$ for $g\in\cG$; the proof verifies it. ✓
- Cor. 1: same check. ✓
- Remark `boundary`'s "applies verbatim with $p+1$ replaced by $p$": verified. $\omega_g$ and $\cG$ are defined by conditioning on $A_{ip}=1$ and so are *unchanged* by the substitution — this is precisely why "the same weights appear on both sides," and the remark is right that this is what makes the extrapolation continuous at $t=p$. The only difference is that the two persistence applications collapse to one ($t=p$ twice). **Sound, and the most quietly important result in the excerpt** — Remark `aggregate-homogeneity`, Prop. 1's $\theta$-bridge, and the M5 correction all route through it.

**A structural dependency the text does not acknowledge:** §3.4 is presented as generalizing §3.3, but as shown in M4 it does not contain it. Instantiating the general framework at $\cC_t=\{A_{it}=1\}$ yields a *strictly stronger* hypothesis set than Prop. 1 requires. A reader tracing the logical order will find the "general" section weaker than the special case it claims to generalize.

---

## 5. Edge-case scan (protocol item 3)

**$\cG=\varnothing$.** Equivalent to $\P(A_{ip}=1)=0$: if $\P(A_{ip}=1)>0$ then, $\cG\subseteq\{1,\dots,p\}$ being finite with weights summing to one, some $\omega_g>0$. So the only way to get $\cG=\varnothing$ is the degenerate no-treated-units case — in which $\theta_{p+1}$, $\omega_g$, and $\cG$ are all undefined and Lemma aggregation's "$\sum_{g\in\cG}\omega_g=1$" is false. Vacuous in content but a genuine falsity in the statement. **Fix: assume $\P(A_{ip}=1)>0$ in §2.** (C1.)

**$\omega_g=0$ for some $g\le p$ — does persistence's positivity caveat bite downstream?** **No, and the paper's bookkeeping is correct here.** For $g\le p$, $\{G_i=g\}\subseteq\{A_{ip}=1\}$, so $\omega_g=\P(G_i=g)/\P(A_{ip}=1)$ and $\omega_g=0\iff\P(G_i=g)=0$. Null cohorts are therefore exactly the ones excluded from $\cG$, exactly the ones for which persistence's conditional clause is inapplicable, and exactly the ones on which Assumptions `strict-time-homogeneity` and `within-group-strict-time-homogeneity` (both quantified over $g\in\cG$) impose nothing. The three restrictions line up with no gap. This is a genuine correctness point in the paper's favour and should be stated in one sentence rather than left for the reader to verify.

**Cohort $g=p$.** In $\cG$, admissible everywhere it is used. Two substantive consequences the text omits: (i) within-group homogeneity for this cohort relates one observed period to one unobserved one, so it has no falsifiable content for that cohort; (ii) in a staggered DiD design, $\theta_{pp}$ is the hardest sub-ATT to identify — if every unit has adopted by $p$, the not-yet-treated comparison group is empty. Cor. 1's premise "each $\theta_{g\cdot}$ is identified" is thus most likely to fail precisely at the window boundary that the extrapolation leans on. (M9.)

**Never-treated units ($G_i=\infty$).** Correctly excluded: $\infty\not\le p$, so $\infty\notin\cG$; and $\{G_i=\infty\}\cap\{A_{ip}=1\}=\varnothing$. ✓

**Cohort $g=p+1$.** Ill-posed under the setting's literal $G_i$ domain (M2). Correctly excluded from $\cG$ by Step 1 once $G_i$ is defined over $\{1,\dots,p+1\}$.

**Heavy tails.** $\E_{\P_{p+1}}\lvert\tau_{i,p+1}\rvert=\infty$ defeats Lemma aggregation Step 2 while satisfying every stated hypothesis. The most damaging edge case for the "identity in $\P$" claim. (C1.)

**Degenerate FATS conditioning.** $\tau_{i,p+1}(\eta;\rho)$ requires $\P(\rho(X_i,X_j)\le\eta)>0$ given $X_i$ — fails for continuous $X$ and $\eta=0$, and can fail on a positive-measure set of $X_i$ values for small $\eta$. Unstated. The claim quantifies "for all $i,\rho,\eta$," which as written includes the undefined cases.

**$\cC_t=\varnothing$ for the ATE instantiation.** Literally the impossible event; conditioning on it is undefined. The intended object is $\cC_t=\Omega$ (no conditioning).

---

## 6. Tightness (protocol item 4)

**Is Assumption 1 doing exactly the necessary work?** Almost. Two observations:

1. *Within $\{1,\dots,p\}$ it is tight, not over-strong.* The proofs need only "$G_i=g\Rightarrow A_{it}=1$ for $t\in[g,p+1]$," i.e. absorption from the adoption date forward. The stated version (absorption from *every* $t$ with $A_{it}=1$) is **equivalent** given the definition of $G_i$ — if $A_{it}=1$ then $G_i\le t$, and absorption from $G_i$ delivers the rest. No slack.

2. *Its reach to $s=p+1$ is avoidable, and removing it strengthens the paper's headline claim.* That reach is used at exactly one place — Step 3's second persistence application — and only because $\theta_{g,p+1}$ is *defined* by conditioning on $A_{i,p+1}=1$. **Minimal fix with real payoff: define $\theta_{g,p+1}:=\E_{\P_{p+1}}\{\tau_{i,p+1}\mid G_i=g\}$.** Then Lemma aggregation needs Assumption 1 only on $\{1,\dots,p\}$ — entirely within the observed window — and Remark `aggregation-scope`'s claim that the decomposition needs "no assumption on future adoption" becomes true without qualification. As currently written that claim is defensible only under the narrow reading "future *new* adoption": the proof does assume no *repeal* on $(p,p+1]$, which is an untestable restriction on future treatment status. Note that $\theta_{p+1}$ itself is a well-defined potential-outcome contrast regardless of who is treated at $p+1$, which is what makes this fix costless.

**Is Remark `aggregate-homogeneity` correct as stated?** **Yes — the weaker condition genuinely suffices — but not via the printed proof, and the remark's $\theta$ silently changes meaning.** Working it through:

- The claimed weaker condition is $\sum_{g\in\cG}\omega_g\theta_{g,p+1}=\sum_{g\in\cG}\omega_g\theta_{gp}$ with common weights.
- Lemma aggregation gives $\theta_{p+1}=\sum\omega_g\theta_{g,p+1}$; Remark `boundary` gives $\E_{\P_p}\{\tau_{ip}\mid A_{ip}=1\}=\sum\omega_g\theta_{gp}$. The condition therefore yields $\theta_{p+1}=\E_{\P_p}\{\tau_{ip}\mid A_{ip}=1\}$, and if that aggregate is identified, so is the FATT. ✓ The remark cites exactly this route ("By Lemma~\ref{lem:aggregation} and Remark~\ref{rem:boundary}"), so the *logic* is right.
- **But the appendix proof of Prop. 1 does not cover it.** Step 2 substitutes pointwise, $\theta_{g,p+1}=\theta$ for each $g$, which the aggregate condition does not license — cancellation across cohorts is precisely the case where no pointwise equality holds. The weaker claim is a *different theorem* needing its own (two-line) proof, which the paper does not supply.
- **And the symbol $\theta$ must be redefined.** Under the aggregate condition there is no common scalar; $\theta$ can only mean the aggregate backward ATT. Since Prop. 1 already conflates the assumption's scalar with the aggregate (M6), the remark inherits that ambiguity and compounds it.
- The non-necessity claim is correct, and by two independent routes: cross-cohort cancellation when $\lvert\cG\rvert\ge2$, and — even when $\lvert\cG\rvert=1$ — the fact that the aggregate condition constrains only $t\in\{p,p+1\}$ while Assumption `strict-time-homogeneity` constrains all $t\ge g$ (e.g. $\theta_{gp}=\theta_{g,p+1}=5$, $\theta_{gg}=3$). The remark should mention the second route; it is the cleaner argument and it survives the single-cohort case.

**Over-strong assumptions elsewhere.** Assumption `strict-time-homogeneity` includes $t=g$, ruling out *all* dynamic effects — no ramp-up, no anticipation-adjacent dynamics — which is considerably stronger than "time homogeneity" suggests; and it imposes equality across cohorts as well as across time, so the name understates it (Cor. 1 is the cohort-heterogeneous version, so the paper clearly knows this). The `general-*` assumptions are stated for all $(s,t)$ but used only at $(p,p+1)$.

**A strengthening the paper is leaving on the table.** Under Remark `aggregate-homogeneity`'s condition, only the *aggregate* backward ATT need be identified — strictly weaker than Cor. 1's requirement that every $\theta_{g\cdot}$ be identified. And since the within-window sub-ATTs $\theta_{gt}$, $t\le p$, are identified under the design, strict homogeneity has *testable implications inside the window*. Both points are free and both strengthen the method's standing.

---

## 7. Unproved claims — §3.4 (protocol item 5)

**(a) ATU = FATU — a correct two-line corollary, worth showing, and non-minimal.** With $\cC_t=\{A_{it}=0\}$: `general-strict-time-homogeneity` at $(s,t)=(p,p+1)$ gives $\E_{\P_{p+1}}\{\tau_{i,p+1}\mid A_{i,p+1}=0\}=\E_{\P_p}\{\tau_{ip}\mid A_{ip}=0\}=\mathrm{ATU}_p$; `general-p-to-p-plus-one-heterogeneity` then gives $\E_{\P_{p+1}}\{\tau_{i,p+1}\mid A_{ip}=0\}=\E_{\P_{p+1}}\{\tau_{i,p+1}\mid A_{i,p+1}=0\}$, and the left side is the FATU as defined. So FATU $=\mathrm{ATU}_p$. ✓ Requires $\P(A_{ip}=0)>0$ and $\P(A_{i,p+1}=0)>0$, unstated. **Verdict: trivial, but show the two lines.** Note the route is non-minimal: homogeneity under the *fixed* event $\{A_{ip}=0\}$ delivers the same conclusion with no second assumption at all (this is the M4/M5 point).

**(b) ATE = FATE — trivial, and the paper mis-attributes the exemption.** With $\cC_t=\Omega$, `general-strict-time-homogeneity` gives $\E_{\P_{p+1}}\tau_{i,p+1}=\E_{\P_p}\tau_{ip}$ directly. Moreover `general-p-to-p-plus-one-heterogeneity` becomes an **identity** (both sides are $\E_{\P_{p+1}}\tau_{i,p+1}$), so the ATE case does not need it either. The text singles out ATS as the exempt case; **ATE is equally exempt**, and for the same structural reason — $\cC_t$ does not vary with $t$. One line to fix, but as written it misdescribes the assumption economy of its own framework. (Plus the $\cC_t=\varnothing$ notation error.)

**(c) ATS = FATS — a real gap, two distinct defects.**

- *The exemption argument is right for the right reason, but rests on an unstated hypothesis.* `general-p-to-p-plus-one-heterogeneity` is vacuous whenever $\cC_p=\cC_{p+1}$, so if the matching event is time-invariant the exemption is immediate. **But the setting defines covariates as $X_{it}$ — time-varying.** With $\cC_t=\{\rho(X_{it},X_{jt})\le\eta\}$ the event *does* move with $t$, the second assumption is *not* vacuous, and the claimed exemption fails. The claim is therefore valid only under an unstated time-invariance of $X$ (or of the matching set), which the notation $\rho(X_i,X_j)$ — dropping the $t$ subscript that §2 carries — silently presumes.
- *A second, independent defect: the instantiation yields the wrong functional.* Assumption `general-strict-time-homogeneity` is written as $\E_{\P_t}\{Y_{it}(1)-Y_{it}(0)\mid\cC_t\}$ — **unit $i$'s** effect. FATS is defined as $\E_{\P_{p+1}}\{Y_{j,p+1}(1)-Y_{j,p+1}(0)\mid\rho(X_i,X_j)\le\eta\}$ — **unit $j$'s** effect, with $i$'s covariate held fixed as the centre of the matching ball. Substituting $\cC_t=\{\rho(X_i,X_j)\le\eta\}$ into the assumption produces $\E_{\P_t}\{\tau_{it}\mid\rho(X_i,X_j)\le\eta\}$, which is not the ATS. Repairing this needs a genuinely different object: a pairwise-conditioned functional with $X_i$ fixed (non-random) and $j$ an independent draw from the superpopulation, plus exchangeability/i.i.d. units to license the relabeling. None of this is stated.
- Also unstated: $\P(\rho(X_i,X_j)\le\eta)>0$.

**(d) The chain $\theta=\omega_{p+1}=\tau_{p+1}=\tau_{i,p+1}(\eta;\rho)=\tau_{i,p+1}$ — fails under a literal reading.** Assumption `strict-between-homogeneity` says $\tau_{i,p+1}=\tau_{j,p+1}$ for all $i,j$, which permits a **common random** effect. Counterexample: let $\tau_{i,p+1}=Z$ for every $i$, with $Z$ a non-degenerate random variable correlated with treatment status. The assumption holds exactly as written; yet $\E\{Z\mid A_{ip}=1\}\neq\E\{Z\mid A_{ip}=0\}$ in general, so FATT $\neq$ FATU and the chain breaks — and the final equality to the realized FITE $\tau_{i,p+1}$ fails outright, since an expectation cannot equal a non-degenerate random variable. Under an i.i.d.-units superpopulation the assumption *does* force a.s. constancy (independent copies that coincide a.s. are degenerate), so the chain is recoverable — but that argument is nowhere given, and it is the only thing standing between the stated assumption and the counterexample. **Fix: state $\tau_{i,p+1}=\tau$ a.s. for a non-random constant $\tau$, or supply the i.i.d.-degeneracy line.** Also needed: positivity of each of the four conditioning events, and the $\omega$ collision resolved (M7).

**Summary answer:** (a) and (b) are trivial-but-should-be-shown; (c) and (d) hide real gaps. (c) is the one that would not survive a careful referee.

---

## 8. Suggestions (non-blocking)

1. State $A_{it}=\mathbf{1}\{G_i\le t\}$ once in §2 as the *definition* and derive Lemma persistence, Step 1, and Remark `aggregation-scope` from it uniformly. Several findings above (M2, M3, and part of M5) collapse into this single act of bookkeeping.
2. Add one sentence to Lemma aggregation noting that null cohorts ($\omega_g=0$), persistence's positivity caveat, and the $g\in\cG$ quantifier in the homogeneity assumptions align exactly. It is correct and currently invisible.
3. Advertise the within-window falsification test: $\theta_{gt}$ for $t\le p$ is identified under the design, so strict/within-group homogeneity is *testable* on the observed window even though the extrapolation step is not.
4. Restructure §3.4 around a conditioning event fixed at $p$ (M4). One theorem then covers ATT/ATU/ATE/ATS, `general-p-to-p-plus-one-heterogeneity` disappears, the false asymmetry in the FATU remark disappears with it, and §3.4 genuinely contains §3.3.
</content>

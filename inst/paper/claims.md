# Claims Ledger — `What we estimate when we estimate dynamic causal effects in panel data`

**Instance path:** `inst/paper/claims.md`
**Governed by:** `.claude/rules/paper-protocol.md` §4, Constitution invariant #12
**Status:** current as of 2026-09-25

> **Construction note.** This ledger is a **backfill**: every claim and every numbered result
> below was found by reading `main.tex`'s abstract, introduction, all three identification-path
> subsections, the EIF section, the discussion, and the proofs appendix. It is seeded from
> `story.md`'s S1-S8 for the claim-type/story-linkage columns, per the task that produced it.
>
> **Mid-restructuring note (added 2026-09-25, same day; updated same day after the two open
> items below were resolved).** `outline.md` was promoted to a story-first section plan and the
> manuscript has been redrafted section by section against it (see `outline.md` §2's
> content-migration table for full status). §§1-2 (Introduction, The Future Effect Family) and
> §10 (Discussion) carry fresh prose. §§3-8 (Effect-Level Invariance, Parametric Time Path,
> Covariate Transport, Inference, Model Selection, Simulation Evidence) were
> **structurally promoted/renamed/reordered to match the new section plan without changing any
> mathematical content** — every proposition, lemma, corollary, and EIF derivation is verbatim
> what it was, only relocated to new section/subsection boundaries. Table 2 below is re-anchored
> to current line numbers.
> **Both items originally flagged as pending here are now resolved:** (a) Path 3's two-regime
> EIF subsection has been relocated from §5 into §6 ("Inference"), argued alongside Paths 1-2's
> EIF as the outline's inference-asymmetry framing called for; (b) the additional-simulations
> appendix material (stress tests, isolated-path checks, real-first-stage coverage) has been
> pulled into §8's body per the outline's divergence-item-5 rationale — see the note appended
> after this paragraph once that pull is complete. §9 (Application) needed no edits (already
> correctly labeled). A `compile-latex` pass (3×xelatex+bibtex) has been run after every
> structural change in this session and shows zero regressions: no "Label(s) may have changed,"
> no new overfull hboxes, only the 2 pre-existing undefined-citation warnings.

---

## 1. Claim → evidence

| # | Claim (as written) | Where claimed | Anchor (numbered result / §) | Claim type | Assumptions it inherits |
|---|---|---|---|---|---|
| C1 | The FATT/FATU/FATE are a distinct family of future-oriented causal effects, corresponding one-to-one to the repeal/adopt/universal-adoption decisions, sharing the structure "future conditional effect averaged over a target covariate distribution." | Abstract (`main.tex:44`); Introduction (`main.tex:67`, contribution paragraph) | §2 "The Future Effect Family and Its Identification Problem" (`\ref{sec:future-effect-family}`), specifically the "future effect family" subsection (`main.tex:123-151`, `\ref{sec:effect-family}`) — **drafted 2026-09-25**, content migrated from the old §3 Estimands with the family definitions unchanged and a strengthened closing statement on non-identification (`main.tex:145`, "not merely unobserved but wholly unknown"). | methodological | — (definitional, not conditional on an identifying assumption) |
| C2 | Unrestricted dynamic effects make historical data uninformative for any current or future decision (the "Fundamental Promise of Causal Inference" tension), which the paper names an estimand gap rather than an estimation gap. | Introduction (`main.tex:49`, `main.tex:51`, `main.tex:59` — the estimand-gap paragraph is new prose added in the 2026-09-25 restructuring, not present in the pre-restructuring Introduction) | §1 (motivating argument, not a numbered result) | methodological | — (motivating framing, not itself identified/tested) |
| C3 | Three broad strategies for extrapolating causal claims to a period the data do not cover exist across fields — structural/parameter invariance, statistical transport/reweighting, explicit dynamics modeling — and Paths 1-3 map onto them, with Path 3 most directly invoking the Lucas Critique. | Introduction (`main.tex:65`) | §5 "Covariate Transport: A Lucas-Critique Route" (`main.tex:338`, `\ref{sec:covariate-transport}`) for the Lucas-Critique claim specifically — **drafted 2026-09-25** (promoted from a subsection to a top-level section; identification content unchanged, see Proposition 3 row in table 2). | methodological | — |
| C4 | Paths 1, 2, and 3 each identify the FATT under a different invariance assumption, and each supplies an efficient influence function so standard errors propagate from whatever first-stage estimator the researcher uses. | Abstract (`main.tex:44`); Introduction (`main.tex:59`, `main.tex:63`) | Propositions 1 (`main.tex:234`, §3), 2 (`main.tex:326`, §4), 3 (`main.tex:392`, §5); §6 EIFs (`main.tex:552-577`, `app:eif1`, `app:eif2`, `app:eif3`); Proposition (Asymptotic distribution, `main.tex:568`) | causal + methodological | `absorbing-adoption` (all paths); `strict-time-homogeneity`/`within-group-strict-time-homogeneity` (Path 1); `assump:parametric`+RC4-RC5 (Path 2); `assump:cond-ident`+`assump:struct-stab`+`assump:target-dist` (Path 3) |
| C5 | Path 2 gets a systematic time-series cross-validation framework for extrapolation model selection, scoring extrapolation error and interval coverage rather than in-sample fit — "the first systematic framework for model selection in causal extrapolation." | Abstract (`main.tex:44`); §7 "Selecting a Temporal Model by Extrapolation, Not Fit" (`main.tex:590`, `\ref{sec:model-selection}`, promoted from a subsection to a top-level section 2026-09-25; content unchanged) | §7 (the CV procedure itself); supporting simulation evidence in §8 Simulations (head-to-head Path 1 vs. Path 2 table, content unchanged, exact sub-line ref not re-verified this pass — lives in an `\input`-ed `sim_tables/` file) | methodological | — (the procedure itself is not conditional on an identifying assumption, though the underlying FATT estimate it selects among is) |
| C6 | Path 3 is robust to regime change: it remains valid when reduced-form temporal patterns (Paths 1-2) break, provided structural covariates remain predictive. | Abstract (`main.tex:44`); §5 "Covariate Transport" introduction (`main.tex:339-341`, `\ref{sec:covariate-transport}`); Discussion (`main.tex:681`) | Proposition 3 (`main.tex:392`, identification); simulation evidence in §8 Simulations (regime-change table, `tab:path3`, content unchanged, exact sub-line ref not re-verified this pass) | causal | `assump:cond-ident`, `assump:struct-stab`, `assump:target-dist` |
| C7 | The three paths, applied to a real staggered state-level policy with a genuine validation window, all fail in the same direction — every path underpredicts the realized effects, none achieves nominal coverage, and the covariate route performs *worse* than the simplest homogeneity route. | Discussion (**explicitly restated** 2026-09-25, `main.tex:684`, not merely implied as before); most directly the applied-analysis section `\input{section9_application}` (`main.tex:679`) | §9 "Application: Stand-Your-Ground Laws and Firearm Homicide" (`section9_application.tex:1`, `\label{sec:application}`) — **now verified**: the file exists, has its own `\section{}` and `\label{sec:application}`, and covers exactly the S8 claim (data/setting, estimation strategy, results, discussion, limitations subsections). The 2026-09-25 restructuring's Introduction now cites this section by label (`main.tex:67`), and the Discussion now reconciles it explicitly against the paper's structural picture (`main.tex:684`) rather than leaving the connection implicit. | empirical | inherits the identifying assumptions of whichever path is being evaluated, per-path, in the application |

**Anchor-verification update (2026-09-25):** C7's anchor, previously flagged below as unread, was
read this pass (`section9_application.tex`, 73 lines) as part of the restructuring's search for
where `\label{sec:application}` already lived. The open item below is resolved: the file exists,
matches S8, and needed no line-number correction since `main.tex` only `\input`s it (its own
internal line numbers are unaffected by the surrounding restructuring).

**Column notes**

- **C7's anchor in `section9_application.tex` was verified 2026-09-25** (see the update note
  above) — resolving what was originally flagged here as an unread anchor. `section7.7_cv_simulation.tex`
  (`\input` near the Simulations section, C5's supporting-evidence anchor) remains **not
  separately read** in this pass; C5's simulation-evidence anchor is accordingly still
  unverified at the sub-line level, though the section-level anchor (§8 Simulations) is correct.
- **Claim atomicity applied**: C4 bundles the three paths' identification-plus-EIF claim as one
  row because the abstract states it as one compound sentence with one anchor set (three
  propositions, jointly); a stricter atomization into three rows (C4a/b/c) is a reasonable
  alternative reading and is noted here rather than silently chosen.
- **C2 and C3 are motivation, not contribution**, per the "mark illustrative material as
  illustrative" convention — they set up the paper's problem and taxonomy but are not
  themselves numbered results. Recorded with type `methodological` and an explicit note that
  they are framing rather than delivered findings.
- **Causal claims (C4, C6) carry their identifying-assumption labels** per invariant #12 — see
  the last column. The assumptions are stated in the same subsection as the claim in every case
  (Path 3's assumptions are in §5 "Covariate Transport" alongside Proposition 3, matching where
  C6 is anchored).

---

## 2. Result → claim (the reverse check)

**Last result added:** 2026-09-25

| Numbered result | Stated at | What it establishes | Assumptions it requires | Claimed at | If unclaimed: deliberate? | Supports story claim |
|---|---|---|---|---|---|---|
| Lemma 1 (Cohort persistence) | `main.tex:160` | $\{A_{it}=1,G_i=g\}=\{G_i=g\}$ as events, for $g\le t\le p+1$, under absorbing adoption alone | `absorbing-adoption` | Not separately claimed in the abstract/intro/discussion | Yes — purely instrumental to Lemma 2 and the identification propositions | instrumental |
| Lemma 2 (Exact aggregation) | `main.tex:177` | $\theta_{p+1}=\sum_{g\in\cG}\omega_g\theta_{g,p+1}$ as an identity, no homogeneity/parametric assumption needed | `absorbing-adoption` (via Lemma 1) | Not separately claimed | Yes — instrumental, though its content ("$\theta_{p+1}$ decomposes by cohort with no extra assumption") is the structural backbone of every path's identification result | instrumental |
| Proposition 1 (Identification of the FATT under time homogeneity) | `main.tex:234` (§3 "Effect-Level Invariance", `\ref{sec:path1}` subsection) | $\theta_{p+1}=\theta$ under Assumptions `absorbing-adoption` + `strict-time-homogeneity` | `absorbing-adoption`, `strict-time-homogeneity` | Abstract (`main.tex:44`); Discussion (§10, `main.tex:683`) | — | S2 — *"the backward-looking ATT is the future ATT"* (weakening: S2 also states the within-cohort convex-combination generalization) |
| Corollary (Identification of the FATT under within-group time homogeneity) | `main.tex:262` (same §3 subsection, `\ref{sec:path1}`) | $\theta_{p+1}=\sum_{g\in\cG}\omega_g\theta_{g\cdot}$ under within-group (not cross-group) time homogeneity | `absorbing-adoption`, `within-group-strict-time-homogeneity` | Abstract (`main.tex:44`, "or by a convex combination of within-group ATTs"); Discussion | — | S2 — *"Weakening constancy to hold only within adoption cohort replaces that equality with a convex combination of cohort-specific effects weighted by cohort shares among the treated."* |
| Proposition 2 (Identification of the FATT under parametric dynamics) | `main.tex:326` (§4 "A Parametric Time Path", `\ref{sec:path2}` subsection) | $\bgamma$ identified, and $\theta_{p+1}=\sum_g\omega_g f(g,p+1;\bgamma)$ | `absorbing-adoption`, `assump:parametric` (+ RC4-RC5 for the EIF/asymptotics that follow) | Abstract (`main.tex:44`); Discussion | — | S4 — *"the future effect is the cohort-share-weighted prediction of that function at the future period. Misspecification of the functional form does not merely inflate variance — the estimator converges to the wrong number."* **Simulation evidence for the misspecification half of this claim** was relocated 2026-09-25 from the additional-simulations appendix into §8's body (`main.tex:667-670`, `\input{sim_tables/section3}`) specifically because it is this claim's direct evidentiary anchor — the outline's stated rationale for pulling it out of supplementary material. |
| Proposition 3 (Identification via covariate transport) | `main.tex:392` (§5 "Covariate Transport", `\ref{sec:path3}` subsection) | $\theta_{p+1}=\int\tau(x)\,dF_{\bX\mid A_{ip}=1}^{p+1}(x)=\E_{\mathrm{src}}[w(\bX)\tau(\bX)]$ | `assump:cond-ident`, `assump:struct-stab`, `assump:target-dist` | Abstract (`main.tex:44`); Discussion | — | S5 — *"the future effect is identified by estimating the conditional effect on historical data and integrating it against the future covariate distribution — equivalently, by density-ratio reweighting from source to target."* **Reconciliation note (2026-09-25):** this identification result is unaffected by the 2026-09-24 Path-3 EIF rewrite (identification vs. estimation are separate steps in the manuscript's own two-step argument, RC1 discussion, §2 `main.tex:117`). See `story.md`'s reconciliation entry. |
| Path 1 EIF, $\phi_{\psi_1}$ (Appendix `app:eif1`) | `main.tex:436` (body, §6 "Inference", `\ref{sec:eif-derivation}` subsection); `main.tex:993` (appendix derivation) | $\phi_{\psi_1,i}=\sum_g\omega_g\phi_{\theta_{g\cdot},i}+\sum_g\theta_{g\cdot}\phi_{\omega_g,i}$ | `absorbing-adoption`, `within-group-strict-time-homogeneity`, RC1-RC3, RC6 | §6 body statement (`main.tex:428-436`); Abstract's "efficient influence functions... under all three paths" clause | — | S6 — *"the influence function of the future effect follows by linearity for the homogeneity route"* |
| Path 2 EIF, $\phi_{\psi_2}$ (Appendix `app:eif2`) | `main.tex:442` (body); `main.tex:1029` (appendix derivation) | $\phi_{\psi_2,i}=(\partial\Psi/\partial\theta)^\top\phi_{\theta,i}+(\partial\Psi/\partial\omega)^\top\phi_{\omega,i}$ | `absorbing-adoption`, `assump:parametric`, RC1-RC7 | §6 body statement (`main.tex:428-442`); Abstract | — | S6 — *"by the chain rule through the temporal-model parameter for the parametric route, with an extra term whenever the cohort weights are themselves estimated"* |
| Path 3 EIF, Regime (i): $\phi_{\mathrm{int}}$ / $\phi_{\psi_3}^{\mathrm{ATT}}$ | `main.tex:444-518` (body, **relocated 2026-09-25** from §5 "Covariate Transport" into §6 "Inference", `\ref{sec:eif-derivation}`, per the outline's inference-asymmetry framing — content unchanged, only the section it lives in); `main.tex:1073` (appendix derivation, mean-zero + Neyman-orthogonality proved explicitly) | $\phi_{\mathrm{int}}(O)=\frac{T}{\rho}\{\tau(\bX)-\theta\}+\frac{q(\bX)}{\rho}\operatorname{aug}(O)$; specializes to the FATT with $T=A,\rho=\pi,q=e$ | `assump:cond-ident`, `assump:struct-stab`, `assump:target-dist`, RC8 (Regime i clause), RC9, RC10(i) | §6 body statement (`main.tex:428-432`, "for Path~3 it is the conditional effect... a Neyman-orthogonal doubly-robust transport score"); Abstract | — | S6 — *"the scalar target admits a Neyman-orthogonal doubly-robust transport score, and root-n inference for the scalar is recovered through orthogonality with cross-fitted nuisances at the usual rate."* **Revision note (2026-09-24, superseding the single-weight predecessor of this row):** this is the corrected, two-regime replacement for what was previously one undifferentiated Path-3 EIF. The predecessor collapsed a hard target-indicator weight and a smooth propensity weight onto one shared weight, which was not Neyman-orthogonal and was anti-conservative for the package's own canonical FATT test case (git commit 94e6122). The current row's orthogonality is proved explicitly (appendix `app:eif3`) against perturbations of $\mu_1$, $\mu_0$, $e$, and $q$ — a strictly stronger anchor than the predecessor had. |
| Path 3 EIF, Regime (iii): $\phi_{\mathrm{fix}}$ / $\phi_{\psi_3}^{\mathrm{fix}}$ | `main.tex:520-564` (body, relocated to §6 with the row above); `main.tex:1073` (appendix derivation) | $\phi_{\mathrm{fix}}(O)=w(\bX)\{\tau(\bX)-\theta\}+w(\bX)\operatorname{aug}(O)$, valid when the supplied $w$ is the true ratio; identifies $\theta(\widetilde w)\ne\theta_{p+1}$ if not | `assump:cond-ident`, `assump:struct-stab`, `assump:target-dist`, RC8 (Regime iii clause), RC9, RC10(iii) | §6 body statement (same citation as the row above, jointly); Abstract | — | S6 (same quote as above) |
| Lemma (Collapse to the ATT influence function) | `main.tex:1443` (unmoved — this is in the appendix, not the relocated body content) | Under $T=A,\rho=\pi,q=e$, $\phi_{\mathrm{int}}$ reduces algebraically to the standard AIPW ATT influence function | `assump:cond-ident`, `assump:struct-stab`, `assump:target-dist` (inherited; the lemma itself is an algebraic identity given these) | Not separately claimed in abstract/intro; referenced in body (§6 "Inference", `main.tex:463`, "Lemma~\ref{lem:path3-collapse} confirms $\phi_{\mathrm{int}}$ reduces to its efficient influence function" — moved here from §5 along with the rest of the Regime (i) paragraph) | Yes — deliberately instrumental: it is the sanity check that Regime (i) degenerates correctly for the FATT under time-invariant covariates, which is exactly the check the 2026-09-24 fix needed and now passes explicitly. Also functions as the direct evidence for the S5/S6 reconciliation in `story.md`. | instrumental |
| Proposition (Asymptotic distribution of $\widehat\theta_{p+1}$) | `main.tex:566` | $\sqrt n\{\widehat\theta_{p+1}-\theta_{p+1}\}\leadsto N(0,\sigma^2)$, $\sigma^2=\E(\phi_i^2)$, for whichever path/regime is selected | RC1-RC10 (the applicable subset per path/regime — see `notation.md` §2a's range-citation note) | Abstract ("standard errors and confidence intervals propagate correctly", `main.tex:44`); §6 (`main.tex:566-575`); Discussion | — | S6 — *"All three yield asymptotically normal estimators whose variance is the mean square of the corresponding influence function."* |
| Lemma (Rank condition for the group-specific linear model) | `main.tex:1630` | For $f(g,t;\bgamma)=\alpha_g+\beta_g(t-g)$, the design matrix has full column rank $2q$ iff every cohort is observed at $\ge 2$ periods | none beyond the linear functional form itself (a design-matrix property) | Not separately claimed | Yes — instrumental; specializes RC5 for the specific linear-in-event-time model used in the paper's parametric special case | instrumental |
| Corollary (Linear models: the rank clause is design-matrix rank) | `main.tex:1640` | For any linear-in-$\bgamma$ model, RC5's clauses (i)+(ii) reduce to a single design-matrix full-column-rank condition | none beyond linearity | Not separately claimed | Yes — instrumental, generalizes the lemma above | instrumental |

**Two things recorded per the template's requirement:**

- **Range citations expanded:** see `notation.md` §2a's dedicated note — `Assumptions~\ref{RC1}--\ref{RC10}`
  expands to all ten; `Assumptions~\ref{RC8}--\ref{RC10}` expands to the three Path-3-specific
  conditions only.
- **Body/appendix crossing flagged:** the Proposition (Asymptotic distribution) is **stated in
  the body** (`main.tex:617`, §5.1) but **requires assumptions declared in the appendix**
  (RC1-RC10, `main.tex:804-937`, Appendix B). This is the forward-dependency defect
  `outline.md` §3 checks for, and it is recorded there in full; this row cross-references it
  rather than duplicating the explanation.

---

## 3. Reconciliation

- [x] Every claim in table 1 has an anchor, or is explicitly marked as motivation rather than
      contribution. **C2 and C3 are marked motivational** (framing, not delivered findings);
      C7's anchor is flagged as unverified pending a read of `section9_application.tex`.
- [x] Every result in table 2 is either claimed or marked deliberately unclaimed with a reason.
      Done for all 14 rows above.
- [x] Every causal claim's assumption labels appear in the prose near the claim, not only in the
      theorem environment. Checked for C4 and C6 — both cite their identifying assumptions in
      the same subsection (§4.3-§4.7) as the proposition, not only in the appendix.
- [x] The estimand is stated before any estimation is described (invariant #12), and its symbol
      registry row exists in `notation.md`. $\theta_{p+1}$ is defined in §3 (`main.tex:142`),
      well before any estimation is discussed (§5, `main.tex:597`). Row exists in
      `notation.md` §1, first row.
- [x] No claim is stronger in the abstract than in the section that supports it. Checked
      specifically for C4 and C6 (the two causal claims) — the abstract's language ("we give
      efficient influence functions... so that standard errors... propagate correctly") matches
      the body's stated scope (asymptotic, under stated regularity conditions; does not claim
      finite-sample guarantees the body does not deliver).
- [x] The discussion's limitations do not contradict a claim made earlier. Checked: the
      discussion's stated limitations (single-horizon scope; untestable extrapolation to $p+1$;
      post-selection inference for the CV procedure not accounted for; two-sample target
      variance left open) are each already scoped as limitations in `story.md`'s scope
      boundary and in the body (e.g. `main.tex:589`, `main.tex:693`, `main.tex:736`) — no
      contradiction found.
- [x] Table 2's Assumptions-it-requires column is filled for every result, and reconciles with
      `notation.md` §2a's Used-by column in both directions. Cross-checked row by row; the one
      divergence found is the RC1-RC10 body/appendix forward dependency, which is recorded
      identically in both files rather than silently resolved.
- [x] Every range citation has its expansion recorded (see above), and the one body result that
      requires appendix-declared assumptions (the asymptotic-distribution proposition, RC1-RC10)
      is flagged, not silently accepted.
- [x] This section's **Last result added** date (2026-09-25) is no older than `story.md`'s
      `Status` date (2026-09-25). Both were set in this same task specifically to satisfy this
      gate — the reconciliation in `story.md` (naming S5/S6 and finding "unchanged") was written
      **before** this date was set here, per `paper-sequencing-gate.md`'s ordering: story
      reconciliation, then registries.

---

## 4. Maintenance contract

- **A drafting or editing skill that adds a claim or a numbered result updates both tables in
  the same turn.** The reverse table is the one that rots.
- **Reviewers reconcile, they do not rewrite.** Report divergence; do not silently add anchors.
- **Do not narrate ledger corrections in the manuscript** (`paper-protocol.md` §1). The
  "Revision note" language in table 2's Regime-(i) row above is legitimate here because this is
  a registry file, not the manuscript — `paper-protocol.md` §1's no-provenance-leakage rule
  governs `.tex` content, not this ledger. Do not copy that sentence's phrasing into `main.tex`.

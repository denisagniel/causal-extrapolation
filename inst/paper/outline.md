# Paper Outline (Story-First) — `extrapolateATT`

**Instance path:** `inst/paper/outline.md`
**Governed by:** `.claude/rules/paper-protocol.md`, `.claude/rules/paper-sequencing-gate.md`
**Status:** current as of 2026-09-25 — **promoted** from `outline-from-story.md` by explicit
user decision to restructure the paper around this story-first section plan and draft it from
scratch, rather than continue evolving the prior `main.tex`-grounded structure.

**Provenance.** This file was drafted directly from `story.md`'s Framing/Contribution/Scope
boundary and its labeled major claims S1-S8, without reading `main.tex`'s body content, as a
from-first-principles answer to "if we were structuring this paper from scratch to deliver
exactly the argument in `story.md`, what would the section list be." It was built and checked
side-by-side against the prior `main.tex`-grounded outline (preserved, untouched, at
`outline-superseded-2026-09-25.md`) — see §4 below for the itemized rationale for every place
the two disagree. Now that it is promoted, this file is the live working outline every
`/draft-paper-section` invocation reads; §4's comparison is kept as the record of *why* the
paper is being restructured, not as a currently-open decision.

**What "drafting from scratch" means in practice.** The manuscript's already-proven
mathematical content — the identification propositions, lemmas, EIF derivations, regularity
conditions, and proofs in the current `main.tex`, most of it re-audited and fixed as recently as
2026-09-24/25 (Props 1/2/RC5, the Path-3 two-regime EIF rewrite) — is not being re-derived. What
changes is the section structure and prose: content is redistributed into the section plan
below, reframed per `story.md`'s narrative, and rewritten section by section via
`/draft-paper-section`. A numbered result moving to a new section number, or being restated to
fit a new section's framing, is not a mathematical change and does not by itself require
re-auditing the proof; a result whose *statement* changes does.

---

## 1. Fixed before drafting

| Field | Value |
|---|---|
| **Venue class** | **methods-theory**. Determined via step 1 of `paper-protocol.md`'s chain: `CLAUDE.md` carries the line `**Type:** Methods / Causal Inference` (project header, under "Project:" / "Branch:" / "Type:"), which maps to `methods-theory` per the table in "Venue class, and when it helps." |
| **Target venue** | Not specified in `story.md` or `CLAUDE.md`; not fixed here. (`CLAUDE.md` names top stat/biostat journals for this project type generically, not a specific outlet.) |
| **Estimand, in one sentence** | The future ATT/ATU/ATE — the causal effect of a policy at a period beyond the observed panel, for the currently-treated, currently-untreated, or whole population respectively — each expressible as the future conditional effect averaged over a different target covariate distribution (`story.md` S1). |

**Contribution and scope boundary live in `story.md`** and are not restated here. Every
section row below cites the Framing/Contribution/Scope-boundary content it is responsible
for delivering, per this file's own convention.

---

## 2. Section plan

Ten top-level sections (Introduction, eight substantive sections, Discussion), matching the
206-paper corpus median of 10 top-level sections (`paper-protocol.md`, "Descriptive
baselines") — this is incidental, not a target that was aimed at; it fell out of mapping
S1–S8 plus Framing/Contribution one-to-one onto sections and only merging where two claims
are genuinely one route (S2+S3) or genuinely inseparable in scope (S7 alongside the route it
qualifies).

| § | Working title | Owns (`story.md` content) | One-paragraph description | Page budget |
|---|---|---|---|---|
| 1 | Introduction | **Framing** (the estimand gap; the Fundamental Promise of Causal Inference; the organizing move of choosing what is held invariant); **Contribution** (the three-route family, EIF propagation, the CV criterion) | Opens with the staggered-adoption literature's success at disaggregating dynamic effects into group-time ATTs, and argues that this success left the *target* undefined at any period the data does not cover: every existing estimand is backward-looking, while the policy decisions the literature is used to justify (repeal, adopt, extend) are forward-looking. Names the resulting gap an estimand gap, not an estimation gap, and states the paper's organizing move — the researcher must choose what is held invariant across the observed-to-future transition (the effect level, its parametric time path, or the covariate-conditional effect function) — as the device that turns three otherwise-unrelated identification strategies into one framework. Closes with the contribution paragraph, anchored to the sections that deliver it. | 2.0–2.5 pp |
| 2 | The Future Effect Family and Its Identification Problem | **S1** | Defines the future ATT, ATU, and ATE at a horizon beyond the panel, states their one-to-one correspondence to the repeal/adopt/universal-adoption decisions, and shows all three share one identification structure: each is the future conditional effect averaged over a different target covariate distribution. States, before any assumption is introduced, why none of the three is identified from observed data alone — the future period's covariate and outcome distributions are not merely unobserved but unknown — motivating every assumption introduced in §§3–5 as a different way of buying that missing distribution from historical data. Also states, briefly, why the future individual effect and the future similar-units effect are set aside (scope boundary: not identifiable in general / a localization rather than a separate object) rather than developed further, so the reader is not left wondering. | 1.5–2.0 pp |
| 3 | Effect-Level Invariance: Weakening and Strengthening Dynamics | **S2**, **S3** | Develops the homogeneity route as a spectrum rather than a single assumption. Shows that assuming the marginal treated effect is constant across periods, plus a period-to-period composition condition on which units get treated, recovers the backward ATT as the future ATT exactly — making explicit the assumption applied practice makes implicitly when it reads a historical estimate as today's effect. Weakens constancy to within-cohort constancy and shows the exact answer degrades to a share-weighted convex combination, with the time-constancy half testable in-sample and the composition half resting on an untestable transport across time. Then runs the assumption the other direction: strengthening to rule out cross-unit heterogeneity collapses the *entire* future family — treated, untreated, population, similar-units, even unit-level — onto the single backward ATT, stated once, generically, over an arbitrary conditioning event, so the ATU and ATE cases fall out of the same argument rather than needing separate proofs. Two directions of the same assumption belong in one section because the strengthening result is the limiting case of the weakening spectrum, not an independent idea. | 2.5–3.0 pp |
| 4 | A Parametric Time Path for the Group-Time Effects | **S4** | Develops the route that trades the homogeneity assumption for a functional-form assumption: if group-time effects follow a known function of cohort and time up to a finite-dimensional parameter, and the map from that parameter to the observed-window effects is injective, the future effect is the cohort-share-weighted prediction of that function at the future period — identified without any time-constancy assumption. States plainly, before moving to estimation, that misspecification here is qualitatively worse than in a homogeneity route: the estimator converges to the wrong number, not merely a noisier one, which motivates §7's cross-validation criterion later in the paper rather than treating model choice as an afterthought. | 1.5–2.0 pp |
| 5 | Covariate Transport: A Lucas-Critique Route | **S5** | Develops the route that abandons temporal invariance assumptions entirely: if the covariate-conditional effect is stable across periods while the covariate *distribution* shifts, all temporal variation in marginal effects is compositional, and the future effect is identified by estimating the conditional effect on historical data and reweighting it to the future covariate distribution (equivalently, density-ratio transport from source to target). States the two structural payoffs explicitly, as the section's main point rather than a footnote: no injectivity condition is needed, because the conditional effect is estimated directly rather than inverted out of marginal aggregates; and for the future ATT specifically the route is inert under time-invariant covariates, collapsing exactly to the time-homogeneity answer of §3 — a connection worth stating in both directions. Extending the route to the untreated or population estimands requires an additional external-validity (no unmeasured effect modification) condition, stated here as the price of that extension. | 2.0–2.5 pp |
| 6 | Inference: Propagated, Not Re-Derived | **S6** | States the paper's inference posture up front: given any asymptotically linear first-stage estimator, the influence function of the future effect follows by linearity for the homogeneity route and by the chain rule through the temporal-model parameter for the parametric route (with an extra term when cohort weights are themselves estimated) — no route-specific asymptotic theory is re-derived from scratch. Then states, as the section's central structural point rather than an aside, why the covariate route cannot be handled the same way: the conditional effect function it relies on is generally not root-n estimable, so no influence function is propagated for it. Develops instead the Neyman-orthogonal doubly-robust transport score for the *scalar* target, and the cross-fitting argument that recovers root-n inference for the scalar despite the non-root-n object underneath it. Closes by stating that all three routes deliver asymptotically normal estimators whose variance is the mean square of the relevant influence function or score — same destination, two different mechanisms to get there, and the paper says so rather than obscuring the asymmetry. | 2.5–3.0 pp |
| 7 | Selecting a Temporal Model by Extrapolation, Not Fit | **S7** | Argues that choosing among candidate temporal models (§4's parametric route) by in-sample fit is misaligned with the task the model is asked to do, and proposes a cross-validation scheme built from the panel's own time structure: withhold late periods, fit candidates on the earlier ones, score both squared prediction error and interval coverage on the held-out periods, and average over several holdout horizons. States the limitation as sharply as the proposal: this procedure tests extrapolation *within* the observed window and is silent about the regime change that motivates §5's covariate route in the first place — if the future period's distribution genuinely departs from the observed ones, even the CV-selected model is biased. This section sits immediately after §4 rather than being folded into it, because it is itself a claim (S7) with its own limitation, not a subroutine of estimation. | 1.5–2.0 pp |
| 8 | Simulation Evidence | Scope-boundary bullets on simulation design (isolating aggregation/extrapolation from a real first stage; the one end-to-end validation against `did::att_gt()`) | Reports the stress-testing evidence supporting §§3–6: most simulations inject noise into known group-time effects and construct matching influence functions, deliberately isolating the aggregation-and-extrapolation step from any particular first-stage design — because the paper's claims are about that step, not about difference-in-differences estimation generally. One simulation is the deliberate exception, validating EIF-based inference end-to-end against a real first-stage estimator (`did::att_gt()`) to confirm the propagated variance achieves nominal coverage when the EIFs come from an actual semiparametric estimator rather than injected noise. Where the homogeneity route is right and where the parametric route is wrong under misspecification (§§3–4's claims) get direct simulation confirmation here; the paper does not defer this evidence to an appendix, because these are the paper's own numbered claims being checked, not supplementary detail. | 2.5–3.5 pp |
| 9 | Empirical Application: A Validation Exercise | **S8** | Applies all three routes to a staggered state-level policy with a genuine out-of-sample validation window, and reports that all three fail in the same direction: every route systematically underpredicts the realized post-window effect, none attains nominal interval coverage, and the covariate route performs *worse* than the simplest homogeneity route — evidence that baseline covariates carried little explanatory power for effect heterogeneity in this setting. Frames this explicitly, in its opening paragraph rather than only in the discussion, as a validation exercise rather than a substantive policy finding (scope boundary), so the reader does not read more into the case study than the paper claims: the methodological lesson is that the framework makes the extrapolation assumption explicit and partially testable, not that it makes extrapolation safe. | 2.0–2.5 pp |
| 10 | Discussion | Synthesis of S1–S8; the scope-boundary items as explicit limitations (no first-stage design; one-period-ahead only; covariates unaffected by treatment; point identification not bounds; no post-selection-inference correction) | Synthesizes the paper's central move — that "current practice" (S2/S3), a parametric alternative (S4), and a covariate-based alternative (S5) are not three unrelated estimators but three different invariance assumptions plugged into the same forward map, with inference that follows the same propagate-don't-rederive logic in two of the three cases and an honestly-flagged exception in the third (S6) — and reconciles that structural picture against §9's failure result: the framework's job is to make the assumption explicit and partly checkable, which is a different promise than making extrapolation succeed. States the scope boundary's limitations as the paper's own stated boundaries, not as reviewer-anticipated hedges: no new first-stage identification strategy, one-period-ahead only (longer horizons named as analogous but not carried through), covariates assumed unaffected by treatment, point identification rather than bounds, and no correction for the randomness that a cross-validated model choice (§7) introduces into the propagated inference. | 1.5–2.0 pp |

**Total estimated length:** roughly 20–25 pages of body text before bibliography, consistent
with a methods-theory paper carrying three identification routes, a propagated-inference
section, a model-selection criterion, simulation evidence, and an application — above the
corpus's *typical* paper (which usually develops one route, not three) but proportionate to
what this paper's own claim count requires. Deviating from the corpus median in this
direction is not itself a finding; `paper-protocol.md`'s baselines are orientation, not a
target, and a paper covering three structurally distinct identification arguments plus their
asymmetric inference story is expected to run longer than one that develops a single
estimator.

**Theorem-family environments**, if drafted as this outline suggests: at minimum one
identification proposition per route (§§3–5, generically stated in §3 to cover S2 and S3 at
once) plus one inference proposition per route (§6) — roughly 5–6, above the corpus median of
3, for the same reason as the page budget: three routes each need their own identification
and inference result, and the paper's contribution paragraph (S1–S8) claims results in both
categories for all three.

**Content-migration note (populated as each section is drafted).** The mathematical content
this new structure redistributes already exists, proven, in the superseded `main.tex` (see
`outline-superseded-2026-09-25.md` for its section-by-section map). As each §1–10 row above is
drafted, record here which numbered result(s) from the superseded structure it reuses, so the
migration is traceable and nothing is silently dropped or silently re-derived:

| New § | Reuses from superseded `main.tex` | Status |
|---|---|---|
| 1 | Introduction prose (`main.tex:47-67`), reframed per `story.md` Framing/Contribution. Related Work subsection (`main.tex:69+`) left unchanged. | **drafted 2026-09-25** (`unblessed`). New prose: estimand-gap paragraph, explicit invariance-choice paragraph, re-anchored contribution paragraph. |
| 2 | Estimands section (old `main.tex:124-151`) + Setting/context (old `main.tex:89-123`, Absorbing Adoption, two-step identification argument), merged into one section with two subsections (`\ref{context}` "Setting", `\ref{sec:effect-family}` "The future effect family"). | **drafted 2026-09-25** (`unblessed`, `main.tex:95-151`). Math/definitions verbatim; connective prose added (explicit "not merely unobserved but wholly unknown" framing, explicit forward-pointers to §§3-5) and the two dead commented-out paragraph blocks removed. |
| 3 | Cohort structure (Lemmas 1-2, old `main.tex:204-263`, unchanged) + Path 1 (Prop 1 + Corollary, old `main.tex:265-354`) + the two "connecting" subsections, **reordered** (weakening/within-group now precedes strengthening/collapse-to-ATT, matching S2-then-S3) and merged into two subsections under one section. | **drafted 2026-09-25** (`unblessed`, `main.tex:152-337`). All propositions/lemmas/corollaries verbatim; only the connective prose between them and the block order changed. The old stale "general framework" `theta_gt=f(g,I_t;theta)` device and its table (flagged SEMI-DEPRECATED in `main.tex`'s own former header) were **removed**, not migrated — resolving that long-standing flag rather than carrying it forward. |
| 4 | Path 2 (Prop 2, old `main.tex:356-386`), promoted from a subsection to its own top-level section by inserting a `\section{}` wrapper immediately before the unchanged `\subsection{Path 2...}` (avoids touching the internal `\subsubsection`, so no orphan-heading-level risk). | **drafted 2026-09-25** (`unblessed`, `main.tex:305-337`). Zero change to any formula, assumption, or proof. |
| 5 | Path 3 (Prop 3, old `main.tex:388-467`) promoted the same way as §4. The "Semiparametric estimation and EIF" subsection has been **relocated to §6** (see that row) rather than staying here, per the outline's inference-asymmetry framing. | **drafted 2026-09-25** (`unblessed`, `main.tex:338-424`). Identification content (Prop 3 + assumptions) fully migrated, unchanged. A short "When to use Path~3" paragraph (merged from what was two near-duplicate paragraphs) now closes the section with a forward-pointer to §6 for estimation/inference. |
| 6 | EIF section (old `main.tex:471-637`), retitled and re-labeled (`\label{sec:eif}\label{sec:inference}`, both kept — `sec:eif` because dozens of appendix proof cross-references depend on it). **Now also contains Path 3's two-regime EIF material**, relocated from §5 as a third `\paragraph` alongside Path 1's and Path 2's, argued once across all three paths per the outline's stated inference-asymmetry point. | **drafted 2026-09-25** (`unblessed`, `main.tex:424-586`). Content (EIF formulas, asymptotic-normality proposition, Path 3's two-regime derivation) verbatim from its prior location; only the section title, the addition of `sec:inference`, the intro paragraph (rewritten to state the propagate-vs-not-propagate asymmetry as the section's organizing point), and the physical relocation of the Path-3 paragraph changed. One internal appendix cross-reference (`app:eif3`'s "as displayed in Section~\ref{sec:path3}") was updated to `\ref{sec:eif-derivation}` to follow the move. |
| 7 | Model selection / CV (old `main.tex:590-644`), promoted from a subsection of the EIF section to its own top-level section (no internal `\subsubsection`, so promotion was a direct rename with zero orphan-heading risk). | **drafted 2026-09-25** (`unblessed`, `main.tex:590-644`). Zero content change. |
| 8 | Simulations (old `main.tex:695-729`), retitled "Simulation Evidence" with `\label{sec:simulations}` added. **Now also contains the Path-2 misspecification check** (`main.tex:667-670`, "correct specification versus misspecification"), pulled from the additional-simulations appendix because it is the direct evidentiary check for S4's numbered claim ("the estimator converges to the wrong number") — the outline's stated rationale for this divergence. | **drafted 2026-09-25** (`unblessed`, `main.tex:644-679`). Title/label changed; misspecification-check paragraph and `\input{sim_tables/section3}` relocated here verbatim from the appendix, with the appendix's own opening paragraph and the body's Figure~\ref{fig:backward-vs-fatt} transition sentence updated to match. **Deliberately not pulled** (left as supplementary appendix material, per proportionality — the outline itself allows page-budget pressure to leave some material out): Path~1's isolation check, the synthetic-first-stage EIF-coverage duplicate of the real-first-stage check already in the body, the cohort-weights robustness check, the three stress tests (non-smooth dynamics, unobserved effect modifiers, small-sample extrapolation), and the CV robustness check — none of these is the direct evidentiary anchor for a `story.md` `S`n the way the misspecification check is for S4; they remain genuine robustness/isolation detail, which is exactly what an appendix is for. |
| 9 | Application section (external `section9_application.tex`) — **already had its own `\section{}` and `\label{sec:application}`**, discovered while resolving the Introduction's forward reference; needed no edits. | **verified 2026-09-25** (no change needed; not separately `unblessed`-logged since no region was touched). |
| 10 | Discussion (old `main.tex:730-753`, now redrafted) — strengthened opening synthesis (explicit "one framework, three invariance choices" tying back to the Introduction's organizing move), a new paragraph reconciling the application's failure result (§9) against that structural picture, and expanded scope-boundary restatements (no first-stage ID strategy; covariates unaffected by policy) per this row's description. Title, label (`\label{sec:discussion}`), and the two-sample-variance/model-selection/bounds-vs-point-id paragraphs unchanged. | **drafted 2026-09-25** (`unblessed`, `main.tex:681-701`). |
| App. | Regularity conditions, proofs, EIF derivations (old `main.tex:800-1704`, now shifted to `main.tex:751-1652` by the body edits above) — retained as an appendix per divergence item 6. All internal `\ref`s to body sections (e.g. `\ref{sec:path1}`, `\ref{sec:path2}`, `\ref{sec:path3}`, `\ref{sec:eif-derivation}`, `\ref{sec:model-selection}`) were kept as the **same labels**, deliberately, specifically so this appendix needed **zero edits** — every cross-reference resolves to wherever that label now lives. | **unchanged, verified resolving** (LSP diagnostics show 0 undefined references into the appendix after the restructuring, confirmed 2026-09-25). |

**Verification performed 2026-09-25 (this pass):** editor diagnostics on `main.tex` showed
exactly 2 errors throughout, both pre-existing and unrelated to this restructuring (undefined
citation keys `tibshiraniExactPostselectionInference2016`/`chenValidInferenceModel2021` at the
Model Selection section's post-selection-inference paragraph — present before this session
started). Every forward reference introduced by the Introduction's contribution paragraph now
resolves. **`compile-latex` was run** (3×xelatex + bibtex, from `inst/paper/`): compiles cleanly,
59-page PDF, zero "Label(s) may have changed" after the third pass, zero overfull hboxes, only
the same 2 pre-existing undefined-citation warnings (missing `.bib` entries, not a restructuring
defect) and 2 pre-existing underfull hboxes in an unrelated sim-table caption. No LaTeX-
correctness regression from the section restructuring.

---

## 3. Ownership check

Every one of S1–S8, plus Framing, Contribution, and every scope-boundary bullet, is assigned
to at least one section:

| Story content | Assigned to | Notes |
|---|---|---|
| Framing | §1 | |
| Contribution | §1 (stated); delivered by §§2–7 | |
| S1 | §2 | |
| S2 | §3 | |
| S3 | §3 | |
| S4 | §4 | |
| S5 | §5 | |
| S6 | §6 | |
| S7 | §7 | |
| S8 | §9 | |
| Scope: no first-stage ID strategy | §2 (stated as a framing move — ATT/group-time ATTs/conditional effect function taken as identified), §10 (restated as a limitation) | |
| Scope: unit-level / similar-units effects not identified | §2 | |
| Scope: one-period-ahead only | §2 (scope stated), §10 (restated as limitation) | |
| Scope: covariates unaffected by policy | §5 (assumption stated where it bites — the covariate route is exactly where this assumption matters), §10 | |
| Scope: point identification, not bounds | §10 | No natural home earlier; this is a global posture statement, appropriately left to the discussion. |
| Scope: no post-selection inference correction | §7 (stated as the CV section's own limitation), §10 | |
| Scope: most simulations don't exercise a real first stage; one exception validates against `did::att_gt()` | §8 | |
| Scope: empirical section is validation, not a policy finding | §9 (stated in its opening paragraph, not deferred to discussion) | |

**Nothing from `story.md` failed to map to a section.** The one item that does not have an
obvious *early* home — point identification vs. bounds — is a deliberate global framing
choice rather than a technical result, and every methods-theory paper of this shape defers
that kind of posture statement to the discussion; it is not a gap, it is the right place for
it.

---

## 4. Rationale: why this structure differs from the superseded `main.tex`

Structural section list of the superseded `main.tex` (full record at
`outline-superseded-2026-09-25.md`):

```
Introduction (+ Related work subsection)
Setting and context (+ Identification of the backward-looking ATT subsection)
Estimands
Identification via Extrapolation Functions
  General framework / Cohort structure of the FATT /
  Path 1: Time-homogeneous functions /
  Connecting other forward-looking estimands to backward-looking estimands /
  Connecting the FATT to sub-ATTs /
  Path 2: Temporal parametric functions /
  Path 3: Covariate-distribution functions /
  Semiparametric estimation and EIF
Semiparametric Estimation and Inference
  Efficient influence functions / Model selection for extrapolation
Simulations (+ Data generation)
Discussion
[Appendix] Additional Simulations
  Path 1 in isolation / Path 2 in isolation / EIF coverage under synthetic first stage /
  Role of cohort weights / Stress tests: where the methods fail
[Appendix] Proofs and Technical Details
  Regularity Conditions / Proofs of Propositions 1-3 /
  Derivation of EIFs (Path 1/2/3) / Proof of Asymptotic Distribution / Technical Lemmas
```

**Genuine divergences, each with a one-line rationale — now the accepted structure, not an
open comparison:**

1. **This outline splits the three identification routes into three separate top-level
   sections (§§3–5); the superseded structure nested all three as subsections inside one
   section ("Identification via Extrapolation Functions").** Rationale: `story.md` treats S2/S3,
   S4, and S5 as three claims of comparable weight, each with its own assumption structure,
   its own failure mode, and (per S6) its own inference story. Subordinating all three to one
   section subordinates the claims to a shared "general framework" framing that `story.md`
   does not itself foreground as a separate claim — the general framework is connective
   tissue for the three routes, not a fourth thing the story asserts. Promoting the routes to
   top-level sections makes each route's assumption-to-failure-mode argument visible in the
   table of contents, which is where a reader deciding "do I trust the parametric route or the
   covariate route for my application" would look first.

2. **This outline gives S7 (temporal-model cross-validation) its own top-level section (§7);
   the superseded structure nested it as a subsection ("Model selection for extrapolation")
   inside the inference section.** Rationale: `story.md` states S7 as a numbered major claim on
   equal footing with S1–S8, with its own stated limitation (blind to regime change) — the same
   status S4, S5, and S6 have, all of which get top-level sections here. Treating it as a
   subordinate clause of "Semiparametric Estimation and Inference" undersells a claim the
   story itself elevates.

3. **This outline places the "connecting backward to forward estimands" content (S2/S3)
   inside §3, argued once generically over an arbitrary conditioning event; the superseded
   structure split this across two separate subsections** ("Connecting other forward-looking
   estimands to backward-looking estimands" and "Connecting the FATT to sub-ATTs") that sat
   *between* Path 1 and Path 2. Rationale: `story.md`'s own statement of S3 is explicit that the
   generic, arbitrary-conditioning-event argument is the point — "stated generically... the same
   pair of assumptions delivers the backward-to-forward equivalence one estimand at a time" —
   which argues for one section making that generic argument once, not two subsections that read
   as if the ATU and ATE cases needed separate treatment. This also removes the awkward sandwich
   position these subsections occupied, wedged between Path 1 and Path 2 as if they were a
   continuation of Path 1 rather than a structurally separate claim.

4. **This outline promotes the EIF/inference material to its own section immediately after
   all three routes are identified (§6), argued once across all three routes and explicit
   about the Path 3 asymmetry as the section's organizing point; the superseded structure split
   inference into a "Semiparametric estimation and EIF" subsection embedded at the end of the
   identification section, plus a separate top-level "Semiparametric Estimation and Inference"
   section afterward, plus EIF derivations again in an appendix.** Rationale: S6 is explicit
   that the Path 1/Path 2 vs. Path 3 asymmetry ("the paper says so rather than papering over
   it") is itself the claim, not a derivational detail — burying half of that argument inside
   the identification section's last subsection and the other half in a later section split
   across two homes makes the asymmetry harder to see as one coherent point. One section
   stating the propagate-don't-rederive posture and then the one genuine exception reads as a
   single argument; the superseded structure's split reads as two different topics that happen
   to share subject matter.

5. **This outline gives simulations one section (§8) that reports the stress-testing evidence
   inline, including the misspecification and real-first-stage results that the superseded
   structure deferred to an "Additional Simulations" appendix; that structure's appendix/body
   split separated the main simulation section (data generation + headline results) from stress
   tests, isolated-path checks, and the real-first-stage coverage check.** Rationale:
   `story.md`'s scope-boundary bullets on simulation design are stated as part of the paper's
   *evidentiary* posture for its main claims (S3's homogeneity result, S4's misspecification
   claim, S6's coverage claim) — not as supplementary robustness checks. An appendix is the
   right place for material a reader may skip; the real-first-stage validation and the
   misspecification stress test are each direct evidence for a *numbered major claim* in
   `story.md`, which argues for keeping them in the body rather than an appendix, whatever
   page-budget pressure eventually pushes some of it back out. This divergence is the most
   consequential of the five: it is a call about what counts as central evidence versus
   robustness checking, and `story.md`'s own scope-boundary language ("One simulation is the
   exception... confirming that the propagated variance achieves nominal coverage") reads as
   describing a result the paper leans on, not a check the paper runs quietly in the back.

6. **This outline places regularity conditions, proofs, and EIF derivations in an appendix
   without commenting further on their internal split; the superseded structure's appendix
   split this material into "Additional Simulations" and "Proofs and Technical Details," with
   regularity conditions declared inside the latter and at least one body proposition citing
   regularity conditions the appendix declares after it (see §5's flag in
   `outline-superseded-2026-09-25.md`).** This outline does not have an opinion on the
   *appendix's internal organization* because `story.md` says nothing about proof mechanics —
   proofs and regularity conditions are not claims, they are how S1–S8's claims are established.
   What this outline does imply structurally is that **regularity conditions should be declared
   before the first body result that cites them** — the forward-dependency defect the
   superseded outline flagged and did not fix. Drafting §6 (Inference) against this outline is
   the point at which that defect should actually be resolved (either move the relevant
   regularity conditions earlier, or restate the affected result's premises locally), rather
   than carried forward unfixed into the new structure.

**Where this outline does *not* diverge from the superseded structure:**

- **Overall section count and rough ordering (Introduction → estimand definition →
  identification → inference → model selection → simulation → application →
  discussion) match.** `story.md`'s own Framing paragraph and Contribution paragraph narrate
  almost exactly this sequence — problem, estimand family, three routes, inference, CV,
  application — so an outline built from the story alone reproduces the macro-order
  independently rather than by copying it. The divergences above are about *section boundaries
  within* that order (how finely to split, what counts as a top-level section vs. a subsection,
  body vs. appendix), not about reordering the argument.
- **A Discussion section closing the paper, synthesizing results and stating limitations, is
  common to both.**
- **The superseded structure's stale "SEMI-DEPRECATED" self-description and the
  appendix-ordering forward dependency** are copy-editing/cross-reference defects, not
  content-distribution questions, and are not resolved by this outline either; they remain
  findings for whoever drafts the affected section (Introduction for the first; §6/Appendix
  for the second).

---

## 5. Explicitly not planned here

Recording these so a later reader does not mistake absence for oversight. `paper-protocol.md`
measured all of them and declined to prescribe — carried forward from the superseded outline
since nothing in `story.md` changes them:

- **Whether to include a roadmap paragraph** — 49% overall, unsafe to pool (53-point spread).
  Author's choice.
- **Whether to have a related-work section, and where** — 25% have one at all; when present,
  `subsection` matches practice (§1.1 in this plan follows that convention).
- **Whether every assumption carries a `[Name]`** — optional aid only.
- **Hedging verbs** — not a defect. Not separately audited here.

If you want one of these to become a rule, measure it first — argument alone already produced
three wrong rules.

---

## 6. Maintenance contract

- **Structure changes mid-draft → stop drafting, update this file, then resume.** Same hard
  gate the grant pipeline uses, and for the same reason.
- **Revision is the dominant mode.** Keep this file current through revisions, not just for
  this first construction.
- **Update the content-migration table in §2 as each section is drafted.** This is the
  mechanism that keeps "drafting from scratch" from silently becoming "re-deriving from
  scratch" — every row should end up citing what superseded-`main.tex` material it reused.

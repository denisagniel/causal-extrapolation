# Paper Story — `what-we-estimate`

**Instance path:** `inst/paper/story.md`
**Governed by:** `.claude/rules/paper-protocol.md`
**Status:** draft as of 2026-09-25. Reconciled against the simulation suite as of 2026-09-23
(Section 4b added a real-first-stage validation; the simulations-section scope-boundary bullet
below is updated accordingly), and against the Path-3 EIF rewrite as of 2026-09-25 (see
reconciliation note below). No major claim (S1-S8) changed by either revision.

## Reconciliation: 2026-09-25, Path-3 two-regime EIF rewrite

The commit rewriting Path 3's estimator/EIF, RC7-RC10, the asymptotic-normality proof's Path-3
step, and the collapse lemma into a two-regime taxonomy (internally-defined target vs.
known/fixed density ratio) does not change what **S5** or **S6** can honestly claim.

- **S5** ("The covariate route breaks the dependence on temporal patterns entirely... the
  future effect is identified by estimating the conditional effect on historical data and
  integrating it against the future covariate distribution — equivalently, by density-ratio
  reweighting from source to target.") is stated at the identification level: the FATT equals
  $\int \tau(x)\,dF^{p+1}_{\bX\mid A_{ip}=1}(x) = \E_{\mathrm{src}}[w(\bX)\tau(\bX)]$
  (Proposition~3, `main.tex:441`). This identity is unchanged by the rewrite — the two-regime
  split concerns *estimation and inference for* $\theta_{p+1}$, not its identification. Verdict:
  **S5 unchanged.**
- **S6** ("Inference is not re-derived per design; it is propagated... the scalar target admits
  a Neyman-orthogonal doubly-robust transport score, and root-n inference for the scalar is
  recovered through orthogonality with cross-fitted nuisances at the usual rate.") is stated at
  the same level of abstraction. The rewrite replaces a single (defective, non-orthogonal)
  weighting scheme with two regimes, each carrying its own Neyman-orthogonal doubly-robust
  score (`main.tex:1296-1487`, orthogonality verified explicitly against $\mu_1$, $\mu_0$, $e$,
  and $q$) and each recovering root-$n$ inference for the scalar via the same cross-fitted,
  $o_\P(n^{-1/2})$-product-rate mechanism (Assumption~RC8, `main.tex:860`). "A" Neyman-orthogonal
  score becomes "one of two," which is a strengthening of the delivered result, not a change to
  what S6 asserts. Verdict: **S6 unchanged.**

Neither claim asserted a specific single-weight functional form, so neither needed correction. What
changed is downstream of both claims: the *particular* score object Section 4/5 exhibits as the
witness for S5/S6 was defective (anti-conservative, not orthogonal) before this rewrite and is
correct after it. This is recorded in `claims.md` table 2 as a revision to the anchor for
Proposition 3 and the EIF results in Appendix~C.3, not as a change to `story.md`.

## Framing

Panel-data causal inference has spent a decade taking dynamic treatment effects seriously, and
in doing so has quietly severed the link between what it estimates and what anyone wants to know.
The modern staggered-adoption literature exists because two-way fixed effects contaminates the ATT
by comparing units treated at different times; the fix was to disaggregate into group-time effects
indexed by adoption cohort and calendar (or event) time, then aggregate them back into an "overall"
number. But every one of those objects — the group-time effect, the overall ATT, any weighted
aggregate of them — is defined on the distribution of the data at some observed period. It is a
statement about what already happened. The decisions that motivate the estimation are not: a state
legislature asks whether to keep a law it passed, or to pass one it has not, next session. If
effects can drift arbitrarily with time, no amount of care about the observed window licenses that
step, and the field's implicit warrant — that effects estimated on past data inform present
decisions, what this paper calls the Fundamental Promise of Causal Inference — has been assumed
away by the very assumption that motivated the methodological advance.

The gap is therefore not an estimation gap but an estimand gap, and it is invisible so long as the
target is never written down for a period outside the sample. Applied work closes it informally:
an ATT estimated on historical adopters is discussed as though it were the effect of the policy
now. That move is an assumption, it is usually unstated, and it is sometimes wrong in a direction
that matters. What is missing is a family of estimands located at a future period, a statement of
exactly which invariance assumption buys each one from historical data, and inference that carries
the first-stage uncertainty through the extrapolation instead of discarding it. This paper's
organizing move is to insist that the researcher choose *what is held invariant* — the level of
the effect, the shape of its time path, or the conditional effect function — and to show that each
choice is a different extrapolation function plugged into the same forward map, with a
correspondingly different failure mode.

## Contribution

The paper defines a family of future causal effects at a horizon beyond the observed panel — the
future ATT, ATU, and ATE, which map one-to-one onto the repeal, adopt, and universal-adoption
decisions — and gives three identification routes to them that differ only in what they assume
invariant: the marginal effect level, a parametric time path for the group-time effects, or the
covariate-conditional effect function transported to a future covariate distribution. For each
route it supplies the efficient influence function, so that standard errors propagate from
whatever first-stage estimator the researcher already uses, and for the parametric route it adds a
time-series cross-validation criterion that scores candidate temporal models on extrapolation
error and interval coverage rather than in-sample fit.

## Scope boundary

- **It proposes no first-stage identification strategy.** The ATT, the group-time ATTs, or the
  conditional effect function are *taken as identified* under whatever design the researcher
  brings — parallel trends, unconfoundedness, synthetic control. The paper's assumptions are
  extrapolation assumptions layered on top; the identification argument is explicitly two-step,
  and only the second step is new.
- **It does not identify the unit-level or similar-units effects.** The future individual
  treatment effect and the future average effect among covariate-similar units are defined to
  motivate the policy question and are then set aside — the first as not identifiable in general,
  the second as a localization of the population estimands rather than a separate object.
- **It develops only the one-period-ahead case in the body.** Longer horizons are stated to be
  analogous and are not carried through; the extra assumptions required to project further are
  named as a limitation, not discharged.
- **It assumes covariates are unaffected by the policy.** Time-varying covariates that lie on a
  causal path from treatment to outcome would require g-methods; that case is excluded by
  assumption and deferred.
- **It point-identifies rather than bounds.** Partial identification, monotone-class bounds, and
  formal sensitivity analysis for violations of the invariance assumptions are named as the
  alternative the paper is *not* taking, and left to other work.
- **It does not solve post-selection inference.** The influence functions condition on the chosen
  temporal model; the randomness introduced by selecting that model via cross-validation is
  acknowledged and not accounted for.
- **Most of the simulations do not exercise a real first stage.** They inject noise into known
  group-time effects and construct matching influence functions, deliberately isolating the
  aggregation and extrapolation step from any particular difference-in-differences estimator.
  One simulation is the exception: the paper validates EIF-based inference end-to-end against a
  real first-stage estimator (`did::att_gt()`), confirming that the propagated variance achieves
  nominal coverage when the EIFs come from an actual semiparametric estimator rather than
  injected noise.
- **The empirical section is a validation exercise, not a substantive policy finding.** It reports
  a prediction failure and does not advance a causal claim about the law it studies.

## Major claims

- **S1:** The policy-relevant target is a causal effect at a period the study does not observe,
  and it is a different object from every backward-looking estimand in the panel-data literature.
  Three such future effects — on current adopters, on current non-adopters, and on the whole
  population — correspond exactly to the three decisions available to a policymaker, and they
  share a single identification structure: each is the future conditional effect averaged over a
  different target covariate distribution. Nothing about them is identified from observed data
  without an added invariance assumption, because the future period's distribution is not merely
  unobserved but wholly unknown.

- **S2:** Taking dynamics *less* seriously recovers current practice as a special case and makes
  its hidden assumption explicit. If the marginal effect on the treated is constant across
  periods, and if the units treated by the end of the panel have the same future effect as the
  units that will be treated one period later, then the backward-looking ATT *is* the future ATT.
  Weakening constancy to hold only within adoption cohort replaces that equality with a convex
  combination of cohort-specific effects weighted by cohort shares among the treated. The
  time-constancy half of this is testable in the observed window; the period-to-period
  composition half is not, because it concerns the unobserved future distribution — so this route
  always rests on an untestable transport across time.

- **S3:** Strengthening the homogeneity assumption to rule out cross-unit effect heterogeneity
  collapses the entire future family — treated, untreated, population, similar-units, and even
  unit-level — onto the single backward-looking ATT. Stated generically over an arbitrary
  conditioning event, the same pair of assumptions delivers the backward-to-forward equivalence
  one estimand at a time: conditioning on non-adoption gives the ATU-to-future-ATU link,
  conditioning on nothing gives the ATE-to-future-ATE link. This is what applied practice is
  implicitly asserting when it reads a historical ATT as today's effect.

- **S4:** Taking dynamics *more* seriously via a parametric time path identifies the future effect
  without any time-constancy assumption, but substitutes a functional-form assumption and an
  identifiability condition. If the group-time effects follow a known function of cohort and time
  up to a finite-dimensional parameter, and if the map from that parameter to the observed-window
  effects is injective, the future effect is the cohort-share-weighted prediction of that function
  at the future period. Misspecification of the functional form does not merely inflate variance —
  the estimator converges to the wrong number.

- **S5:** The covariate route breaks the dependence on temporal patterns entirely, and this is a
  Lucas-critique argument rather than a technical convenience. If the covariate-conditional effect
  is invariant across periods while the covariate *distribution* shifts, then all temporal
  variation in the marginal effects is compositional, and the future effect is identified by
  estimating the conditional effect on historical data and integrating it against the future
  covariate distribution — equivalently, by density-ratio reweighting from source to target. Two
  structural points follow. No injectivity condition is needed here, because the conditional
  effect is estimated directly from unit-level data rather than inverted out of the marginals. And
  for the future ATT specifically this route only does work when covariates are time-varying: with
  time-invariant covariates the density ratio is identically one and the route reduces to the
  time-homogeneity answer. Extending it to the untreated or the full population requires the
  additional external-validity condition that there is no effect modification beyond the measured
  covariates.

- **S6:** Inference is not re-derived per design; it is propagated. Given any asymptotically linear
  first-stage estimator, the influence function of the future effect follows by linearity for the
  homogeneity route and by the chain rule through the temporal-model parameter for the parametric
  route, with an extra term whenever the cohort weights are themselves estimated. The covariate
  route is structurally different and the paper says so rather than papering over it: the
  conditional effect function is generally not root-n estimable, so no influence function is
  propagated for it; instead the scalar target admits a Neyman-orthogonal doubly-robust transport
  score, and root-n inference for the scalar is recovered through orthogonality with cross-fitted
  nuisances at the usual rate. All three yield asymptotically normal estimators whose variance is
  the mean square of the corresponding influence function.

- **S7:** Choosing a temporal model by in-sample fit is misaligned with the task, and a
  cross-validation scheme aligned with it can be built from the panel's own time structure:
  withhold late periods, fit candidates on the earlier ones, and score both squared prediction
  error and interval coverage on the held-out periods, averaged over several holdout horizons.
  The limitation is stated as sharply as the proposal — this procedure tests extrapolation
  *within* the observed window, and is therefore silent about exactly the regime change that
  motivates the covariate route; if the future period's distribution departs from the observed
  ones, even the cross-validation-selected model is biased.

- **S8:** Applied to a staggered state-level policy with a genuine out-of-sample validation window,
  all three routes fail in the same direction, and the paper reports the failure rather than a
  favorable subset. Every path systematically underpredicts the realized post-window effects and
  none attains any interval coverage; the covariate route performs *worse* than the simplest
  homogeneity route, indicating that baseline covariates carried almost no explanatory power for
  effect heterogeneity in this setting. The methodological lesson is that the framework makes the
  extrapolation assumption explicit and testable-in-part, not that it makes extrapolation safe:
  when training-period structure does not persist, no path rescues the prediction.

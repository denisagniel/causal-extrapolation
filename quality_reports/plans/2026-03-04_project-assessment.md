# Project Assessment and Adversarial Review: causal-extrapolation

**Date:** 2026-03-04
**Status:** APPROVED (for implementation)
**Type:** Comprehensive assessment + adversarial review

---

## Context

User requested a comprehensive assessment of the causal-extrapolation project, including an adversarial review of the paper. This project develops methods for extrapolating future average treatment effects (ATTs) using efficient influence functions (EIFs). It includes:
- LaTeX paper: "What we estimate when we estimate dynamic causal effects in panel data"
- R package: `extrapolateATT`
- Simulation suite: 6 completed validation studies
- Development docs tracking progress

The project recently integrated the agent-assisted-research-meta workflow infrastructure. This assessment evaluates current state, identifies gaps, and provides critical feedback to guide completion.

---

## Executive Summary

**Project Status: ~75% Complete**

**Strengths:**
- Novel, well-motivated problem formulation
- Sound technical approach (two-path identification framework)
- Functional R package with correct EIF propagation
- Comprehensive simulation validation (all 6 sections complete)
- Clear exposition and good structure

**Critical Gaps Blocking Publication:**
1. **No formal proofs** - Proposition stated without rigorous derivation; EIF derivations use informal arguments
2. **No real applications** - Only toy simulations (n=500, 3 groups, 5 periods)
3. **Model selection unaddressed** - Path 2 requires choosing f(g,t;γ) with no guidance; paper explicitly punts on post-selection inference
4. **Untestable assumptions** - Relies on unknowable future distribution P_{p+1}
5. **Time homogeneity paradox** - Path 1 assumes what DiD literature rejects

**Verdict:** Paper needs major revision before submission to top venue (JASA, JRSS-B, Biometrika).

---

## Paper Assessment

### Current State (from latex/Estimating_policy_effects_in_the_presence_of_heterogeneity/main.tex)

**Complete Sections:**
- ✓ Introduction: Excellent motivation, clear problem statement
- ✓ Estimands (Section 3): FATT, FATU, FATE, FATS well-defined
- ✓ Path 1: Time Homogeneity (Section 4): Identification via stable effects
- ✓ Path 2: Parametric Extrapolation (Section 5): Identification via model f(g,t;γ)
- ✓ Simulations (Section 6): Results integrated with narrative
- ✓ Discussion: Limitations acknowledged
- ✓ Abstract: Clear and concise

**Technical Details:**
- 292 lines LaTeX source
- 51 bibliography entries in `heterogeneous-policy-effects.bib`
- Citations include Callaway & Sant'Anna, Roth & Sant'Anna, Egami & Hartman, Sun & Abraham, and others
- One Proposition (lines 238-240) with informal derivation
- At least one simulation table integrated (line 256)

**Bibliography Status:** Better than development docs suggest:
- Callaway & Sant'Anna (2021) IS cited (contrary to earlier notes)
- 51 references (not 22 - that was citation count, not bib entries)
- Still missing: Pearl/Bareinboim (transportability), some recent DiD papers

---

## Adversarial Review (Detailed)

### MAJOR CONCERNS (Publication Blockers)

#### 1. Insufficient Mathematical Rigor - Critical Gap for Theory Paper

**Issue:** Proposition stated (lines 238-240) but not formally proven. EIF derivations (lines 224-236) use informal "by linearity" and "by chain rule" arguments without:
- Enumerating regularity conditions
- Verifying differentiability
- Establishing rate conditions
- Proving asymptotic linearity under two-step procedure

**Specific examples:**
- Line 224: "derive the efficient influence function" - derives by linearity, no formal proof
- Line 232-236: Path 2 Jacobian ∂Ψ/∂θ with ∂γ/∂θ_gt never computed explicitly
- Line 242: "Under standard regularity conditions" - never enumerated
- Line 242: "rate conditions (e.g., $o_P(n^{-1/4})$)" - not derived

**Impact:** Reviewer cannot verify correctness. For a semiparametric inference paper targeting top journals, this is severely limiting.

**Required:** Mathematical appendix with:
- Full EIF derivations using functional delta method
- Regularity conditions (Donsker classes, rate conditions, boundedness)
- Formal proof of Proposition
- Verification of asymptotic linearity under composition
- Cross-fitting analysis

---

#### 2. Model Specification Problem - The Central Challenge Punted

**Core Issue:** Path 2 requires choosing f(g,t;γ) (linear? quadratic? splines?). Paper explicitly admits (line 242):
> "formal treatment of post-selection inference or misspecification is beyond this paper's scope"

**Why This is Fatal:**
- Simulation Section 3 shows misspecification → inconsistency (not just inefficiency)
- Coverage collapses under misspecification
- No guidance on model selection, specification tests, or post-selection inference
- Practitioners will fit multiple models and pick "best" - invalidating inference

**What's Missing:**
- Model selection criteria (AIC, BIC, cross-validation?)
- Specification tests
- Post-selection inference corrections
- Sensitivity analysis framework
- Bounds under model uncertainty

**Impact:** Path 2 is theoretically correct but practically unusable. This is THE central statistical problem and paper sidesteps it.

**Required:** Either (a) rigorous treatment of model selection, or (b) honest discussion that Path 2 assumes researcher knows correct f, limiting applicability.

---

#### 3. No Real Applications - Only Toy Simulations

**Current Evidence:**
- All simulations: n=500, 3 groups, 5 periods
- Known DGPs (linear, quadratic)
- No real policy data
- No connection to substantive domain

**Why This Matters:**
- Cannot assess assumption plausibility in practice
- No demonstration method works with real `did` output
- No comparison to existing practice
- No guidance on which path to use in real settings

**Top journals require:** At least one substantive application showing method matters.

**Impact:** Reads like technical report, not publishable paper.

**Required:** Real data application (even brief) demonstrating:
- Both paths applied to actual policy
- Assumption testing
- Comparison of results
- Discussion of practical considerations

---

#### 4. Circular Identification - Requires Unknowable P_{p+1}

**The Problem:**
All identification results condition on knowing P_{p+1} (future distribution). But:
- P_{p+1} is unobserved by definition (it's the future)
- Paper admits this but doesn't address consequences
- No guidance on forming beliefs about P_{p+1}

**This Undermines Both Paths:**
- **Path 1:** Requires P_{p+1}(Y | A_ip=1) ≈ P_p(Y | A_ip=1) - but how to verify?
- **Path 2:** Requires f(g, p+1; γ) holds at unobserved future time - but what if environment changes?

**Fundamental Issue:** Conflates identification (logical) with estimation (empirical). Assumptions involve unobservable counterfactuals at unobserved times.

**Impact:** Less "causal identification" than "causal prophecy."

**Required:** Honest discussion of what can/cannot be learned. Consider sensitivity analysis or partial identification approaches.

---

#### 5. Time Homogeneity Paradox

**Path 1 Requires:** E_P_t{Y_it(1) - Y_it(0) | A_it=1} constant over all t

**But:** The entire recent DiD literature (Callaway & Sant'Anna, Sun & Abraham) exists BECAUSE this fails.

**Logical Trap:**
- If time homogeneity holds → just use ATT (Path 1)
- If time homogeneity fails → use Path 2 (but no model selection guidance)
- Result: Neither path is satisfying

**Paper's Contradiction:**
- Section 4.3 acknowledges "recent literature... has explicitly rejected this assumption"
- Then offers Path 1 which requires it!

**Testability Claim is Weak:**
- Can compare θ_gt across t, but test has low power with small p
- Rejection doesn't help - still need to pick f for Path 2

**Impact:** Path 1 is robust but applies when problem is already solved. Path 2 is flexible but requires solving hardest problem.

---

### MODERATE CONCERNS (Need Addressing)

#### 6. EIF Propagation Under-Justified

**Issue:** Chain rule for EIFs assumes:
- First-stage θ_gt asymptotically linear (given)
- Smooth Jacobian ∂Ψ/∂θ (asserted)
- Two-step procedure preserves asymptotic properties (not proven)

**Missing:**
- Convergence rates for γ estimation via nonlinear least squares
- Rate conditions for cross-fitting (mentioned as o_P(n^{-1/4}) but not derived)
- Behavior with ML-based first stage

**Code Issue:** `extrapolate_ATT.R` uses numerical derivatives (`numDeriv::grad`) if analytical Jacobian unavailable - approximation error never discussed.

**Required:** Formal treatment of estimation procedure, rate conditions, and cross-fitting.

---

#### 7. Conditional Integration is Placeholder

**Package Reality:** `integrate_covariates.R` lines 24-36:
```r
# Placeholder: If x_target provided, we simply average group-level results using weights.
# Without a conditional model τ_{p+m}(X), we fallback to overall aggregation.
```

**Paper Claims:** Methods for integrating "conditional effects over a target covariate distribution"

**Gap:** Function does nothing beyond marginal aggregation.

**Impact:** Oversells package capabilities. Credibility issue.

**Required:** Either (a) implement conditional integration with EIF propagation, or (b) remove claim from paper.

---

#### 8. Sparse Testing - Only 4 Tests Total

**Current Tests:**
- `test_linear.R`: 2 tests (basic sanity)
- `test_event_time.R`: 2 tests (mock extrapolation)

**Missing:**
- EIF propagation correctness
- Variance computation accuracy
- Edge cases (small n, unbalanced groups, missing g-t cells)
- Integration with real `did` output
- Numerical stability

**Impact:** Cannot trust implementation matches theory.

**Required:** Comprehensive test suite covering:
- Full workflow (estimate → extrapolate → variance)
- Edge cases
- Numerical accuracy
- Integration tests with `did` package

---

#### 9. Limited Simulation Stress Testing

**Current Simulations:**
- Linear/quadratic DGPs only
- Normal noise, balanced design
- Equal weights ω_g = 1/q
- No measurement error, time-varying confounding, or dynamic treatments

**Missing Stress Tests:**
- Large extrapolation distance (p+5 instead of p+1)
- Unbalanced groups (some observed briefly)
- Heterogeneous variances
- "Almost" linear models (small misspecification)

**Impact:** Validates happy path but not robustness.

**Required:** Extended simulations with:
- Realistic designs (unbalanced, late-treated cohorts)
- Larger extrapolation horizons
- Sensitivity to mild violations

---

### MINOR ISSUES (Polish)

#### 10. Limited Citations

Key omissions per development-docs (some addressed, others remain):
- ✓ Callaway & Sant'Anna (2021) - now cited
- ✗ Pearl/Bareinboim - transportability (still missing)
- ✓ Roth & Sant'Anna - cited
- ✓ Egami & Hartman - cited

**Required:** Complete bibliography per development-docs/citation-gaps-and-outline.md

---

#### 11. No Pre-Trends Testing Discussion

Path 1 relies on time homogeneity. Standard practice: test pre-trends.

**Paper mentions:** "testable implications" in Remark

**Never discusses:**
- How to test in practice
- Connection to pre-trends diagnostics
- Power with small p
- What to do if test rejects

**Required:** Practical guidance on testing time homogeneity.

---

#### 12. Heavy Notation - Accessibility Concern

Symbol soup: P_t, P_{p+1}, θ, θ_gt, θ_{g·}, θ_{p+1}, ψ_1, ψ_2, φ_gt, φ_future, C_t

**Issue:** Barrier for applied researchers.

**Recommendation:** Simplify notation in main text; lead with concrete example; relegate general framework to appendix.

---

#### 13. Package Vignettes Missing

`README.md`: "See `vignettes/` for an end-to-end example (to be expanded)"

Reality: `package/vignettes/` directory does not exist.

**Impact:** Package unusable for practitioners.

**Required:** At least one vignette showing:
- Worked example with `did` package
- Both Path 1 and Path 2
- Variance computation and CIs
- Interpretation

---

### STRENGTHS (To Be Fair)

#### 1. Excellent Problem Formulation
- Clear conceptual contribution: backward-looking vs forward-looking estimands
- FATT, FATU, FATE, FATS systematically defined
- Genuine gap in literature

#### 2. Elegant Two-Path Framework
- Path 1 (robustness) vs Path 2 (flexibility) cleanly organizes tradeoffs
- Clarifies assumptions researchers are making

#### 3. Sound EIF Propagation Idea (If Proven)
- Chain rule for aggregation/extrapolation is conceptually correct
- Technical contribution if rigorously established

#### 4. Methodologically Sound Simulations
- Good design: correct spec, misspec, homogeneity violation
- Focus on bias, RMSE, coverage
- 1000 replicates, results integrated into paper
- All 6 simulation sections complete

#### 5. Clean R Package Code
- Modular structure: estimate → extrapolate → variance
- Roxygen documentation
- Readable implementation
- 9 core R files, functional workflow

---

## R Package Assessment

### Implementation Status

**Location:** `package/`

**Core Functions (All Working):**
- `estimate_group_time_ATT()` - Wrapper around `did::att_gt()` extracting EIFs
- `extrapolate_ATT()` - Apply temporal model h_g, propagate EIFs via chain rule
- `path1_aggregate()` - Time homogeneity approach
- `compute_variance()` - Semiparametric variance, SE, CIs
- `hg_linear()`, `hg_quadratic()` - Built-in temporal models with Jacobians

**Dependencies:** `did`, `dplyr`, `tibble`, `purrr`, `numDeriv`, `rlang`, `stats`

**Code Quality:** Clean, modular, readable

**Alignment with Paper:** Notation matches, EIF propagation correct, both paths implemented

**Validation:** Simulations confirm package methods achieve nominal coverage when assumptions hold

---

### Critical Gaps

1. **Sparse Testing:** Only 4 tests (2 files); missing integration tests, edge cases, error handling
2. **Conditional Integration:** `integrate_covariates()` is placeholder (lines 24-36)
3. **No Vignettes:** Directory doesn't exist; cannot demonstrate end-to-end workflow
4. **Missing Temporal Models:** AR(1), splines mentioned in README but not implemented
5. **No Model Selection Tools:** No utilities for comparing specifications
6. **No Diagnostic Functions:** No checks for numerical stability, assumption violations

---

## Simulation Assessment

### Status: Complete (All 6 Sections)

**Section 1:** Backward-looking ATT vs FATT - Shows divergence under dynamics ✓
**Section 2:** Path 1 under homogeneity vs dynamics - Validates theory ✓
**Section 3:** Path 2 correct spec vs misspec - Shows consistency requires correct f ✓
**Section 4:** EIF variance and coverage - Validates inference ✓
**Section 5:** Path 1 vs Path 2 comparison - Shows tradeoffs ✓
**Section 6:** Omega sensitivity - Shows weight choice matters ✓

**Results:** All integrated into paper with clear narrative interpretation

**Quality:** Methodologically sound, validates core claims

**Limitations:**
- Toy DGPs (linear, quadratic only)
- Small scale (n=500, 3 groups, 5 periods)
- No stress tests: unbalanced designs, large extrapolation distance, realistic violations

---

## Development Status

### From development-docs/

**Completed:**
- ✓ Simulations (all 6 sections)
- ✓ Abstract
- ✓ Discussion/Conclusion
- ✓ R package (core functions)

**In Progress:**
- ⚠ Bibliography (mostly done, 4 key refs per citation-gaps doc may be missing)
- ⚠ Related Work (in place but could expand)
- ⚠ Section 5 expansion (needs gamma estimation details, concrete f example)

**Not Started:**
- ✗ Formal proofs/appendix
- ✗ Real application
- ✗ Model selection framework
- ✗ Vignettes
- ✗ Extended testing

---

## Critical Path to Publication

### REQUIRED (Blocking Publication)

**Priority 1: Mathematical Rigor**
- **Add appendix with formal proofs**
  - Formal proof of Proposition (lines 238-240)
  - EIF derivations using functional delta method (not just "by chain rule")
  - Regularity conditions enumerated (Donsker, rate conditions, boundedness)
  - Rate conditions for cross-fitting derived
  - Asymptotic linearity under two-step procedure proven
- **Estimated effort:** 2-3 weeks
- **Critical files:** `latex/Estimating_policy_effects_in_the_presence_of_heterogeneity/main.tex` (add appendix section)

**Priority 2: Real Application**
- **Add substantive application section**
  - Apply both paths to actual policy data
  - Demonstrate assumption testing
  - Compare results and discuss implications
  - Show method works with real `did` output
- **Estimated effort:** 1-2 weeks (if data available)
- **Critical files:**
  - `latex/.../main.tex` (add application section)
  - `sims/` (add application script)

**Priority 3: Model Selection**
- **Address Path 2 specification problem**
  - Option A: Formal treatment with post-selection inference (ambitious, 4-6 weeks)
  - Option B: Honest discussion of limitations and sensitivity analysis (realistic, 1-2 weeks)
  - Option C: Partial identification bounds under model uncertainty (research contribution, 4-6 weeks)
- **Estimated effort:** 1-2 weeks (Option B), 4-6 weeks (Option A/C)
- **Critical files:**
  - `latex/.../main.tex` (add model selection section)
  - `package/R/` (add model comparison utilities)

---

### STRONGLY RECOMMENDED (Quality)

**Priority 4: Complete Bibliography**
- Verify Pearl/Bareinboim transportability references
- Double-check all citations per citation-gaps-and-outline.md
- Run bibtex and verify no errors
- **Estimated effort:** 1 day
- **Critical files:** `latex/.../heterogeneous-policy-effects.bib`, `main.tex`

**Priority 5: Expand Testing**
- Add integration tests (full workflow)
- Add edge case tests (small n, unbalanced, missing cells)
- Add numerical accuracy checks
- Test with real `did` output
- **Estimated effort:** 3-5 days
- **Critical files:** `package/tests/testthat/`

**Priority 6: Create Vignettes**
- End-to-end example with `did` package
- Both Path 1 and Path 2 demonstration
- Interpretation of results
- **Estimated effort:** 2-3 days
- **Critical files:** `package/vignettes/` (create directory)

**Priority 7: Polish**
- Expand Section 5 (gamma estimation, concrete f example)
- Add pre-trends testing discussion
- Consider notation simplification
- **Estimated effort:** 2-3 days
- **Critical files:** `latex/.../main.tex`

---

## Alignment with Research Constitution

### Constitution §12: Definition of "Finished"

**Checklist for methods paper:**
- ✓ Scientific claim sharply stated (FATT identification via two paths)
- ⚠ Method's operating regime understood (partially - needs model selection)
- ⚠ Failure modes documented (simulations show, but limited)
- ⚠ Software reliable (needs testing)
- ⚠ Another researcher could apply correctly (needs vignettes)
- ✗ Analysis code, R package, paper in agreement (conditional integration claim mismatch)

**Preprint Policy:** Methods papers → preprints before/alongside submission

**Current Status:** NOT ready for preprint. Needs Priority 1-3 items complete.

---

### Constitution §9: Simulation Invariants

**Requirements:**
- ✓ Include regimes where method should struggle (Section 2B, Section 3 misspec)
- ⚠ Avoid parameter settings that quietly favor method (mostly good, but limited scope)

**Assessment:** Simulations follow spirit but need stress tests.

---

### Constitution §3: Core Principles

**Relevant principles:**
- ✓ Identification before optimization (paper prioritizes clear estimands)
- ✓ Theory and practice inform each other (two-path framework balances)
- ⚠ Stress-testing is part of method (simulations present but limited)
- ⚠ Reproducibility is infrastructure (package exists but needs vignettes)

---

## Recommended Action Plan

### Phase 1: Critical Gaps (6-8 weeks)

**Week 1-3: Mathematical Appendix**
- Draft formal proof of Proposition
- Full EIF derivations with functional delta method
- Enumerate regularity conditions (Donsker classes, rate conditions)
- Verify asymptotic linearity of two-step procedure
- Derive cross-fitting rate conditions

**Week 4-5: Real Application**
- Identify policy dataset (firearms? state policy? education?)
- Apply both paths
- Test assumptions
- Write application section (4-6 pages)

**Week 6-8: Model Selection**
- Choose approach:
  - Option B (honest discussion + sensitivity) if time-constrained
  - Option A (formal treatment) if aiming for top venue
- Implement model comparison utilities in package
- Add to paper (2-4 pages)

### Phase 2: Quality Improvements (2-3 weeks)

**Week 9: Bibliography & Polish**
- Verify all citations per citation-gaps doc
- Expand Section 5 (gamma estimation, concrete f)
- Add pre-trends discussion

**Week 10-11: Package Completion**
- Comprehensive testing suite (20+ tests)
- Create vignettes (at least 1)
- Fix or remove conditional integration
- Add diagnostic functions

### Phase 3: Verification & Preprint (1 week)

**Week 12: Final Checks**
- Use `/review-paper` skill for manuscript review
- Use verifier agent before finalizing
- Run paper-done-checklist.md
- Run preprint-checklist.md
- Post preprint

---

## Critical Files Reference

**Paper:**
- `latex/Estimating_policy_effects_in_the_presence_of_heterogeneity/main.tex` (292 lines) - Main document
- `latex/.../heterogeneous-policy-effects.bib` (51 entries) - Bibliography

**Package:**
- `package/R/extrapolate_ATT.R` - Core extrapolation logic
- `package/R/integrate_covariates.R` - Placeholder (needs fix)
- `package/tests/testthat/` - Sparse (2 files, 4 tests)
- `package/vignettes/` - Missing (directory doesn't exist)

**Simulations:**
- `sims/scripts/sim_section*.R` - All 6 sections complete
- `sims/run_all.R` - Master script

**Development Tracking:**
- `development-docs/paper-next-steps.md` - Current roadmap
- `development-docs/citation-gaps-and-outline.md` - Bibliography audit
- `development-docs/simulation-ideas.md` - Completed

---

## Verdict

**Current State:** Promising but incomplete manuscript with ~75% of required work done.

**Strengths:** Novel problem, clean framework, sound implementation, good simulations

**Blocking Issues:**
1. Insufficient mathematical rigor (no formal proofs)
2. No real applications
3. Model selection unaddressed (explicitly punted)

**Recommended Path:**
1. Complete Priority 1-3 items (6-8 weeks) → Ready for preprint
2. Complete Priority 4-7 items (2-3 weeks) → Ready for submission
3. Target venue: JASA, JRSS-B, Biometrika (after revisions)

**Alignment with Constitution:** Needs work on §12 (finished definition) - particularly:
- Failure mode documentation (more stress testing)
- Software reliability (testing)
- Reproducibility infrastructure (vignettes)
- Code-paper-package alignment (conditional integration)

**Next Immediate Action:** User should decide on critical path priority:
- **Fast track:** Priority 1 (proofs) + Priority 2 (application) + Option B for Priority 3 (6-7 weeks to preprint)
- **Rigorous track:** Full Priority 1-3 with Option A (formal model selection) (10-12 weeks to submission-ready)

---

## Verification Steps

After implementation, verify:
1. LaTeX compiles cleanly (no errors, all refs resolved)
2. R package passes `R CMD check` with no errors/warnings
3. All simulations reproduce reported results
4. Vignettes render successfully
5. Paper-package-code alignment per `.claude/rules/code-paper-package-alignment.md`

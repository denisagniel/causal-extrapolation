# Session Log: Project Assessment and Adversarial Review

**Date:** 2026-03-04
**Session Type:** Comprehensive assessment + adversarial review
**Plan:** quality_reports/plans/2026-03-04_project-assessment.md
**Status:** In progress

---

## Goal

Conduct comprehensive assessment of causal-extrapolation project including:
1. Current state evaluation (paper, package, simulations)
2. Adversarial review of paper identifying critical gaps
3. Actionable recommendations for completion
4. Alignment check with research constitution

---

## Approach

**Assessment methodology:**
1. Read paper main file (main.tex, 292 lines)
2. Examine package structure (9 R files, 2 test files)
3. Verify simulation status (all 6 sections)
4. Check development docs for known gaps
5. Conduct adversarial review using high standards for top journals
6. Provide structured feedback with priorities

**Key verification:**
- Paper claims vs actual implementation
- Bibliography status (51 entries confirmed)
- Test coverage (4 tests across 2 files)
- Simulation integration (Table 1 at line 256 confirmed)
- Package-paper alignment

---

## Key Findings

### Strengths Identified

**Problem formulation:**
- Novel forward-looking estimands (FATT, FATU, FATE, FATS)
- Clear gap: backward-looking estimands don't answer policy questions
- Elegant two-path framework (time homogeneity vs parametric extrapolation)

**Technical implementation:**
- R package functional with correct EIF propagation
- 6 simulation studies complete and integrated into paper
- Clean modular code structure
- Sound semiparametric approach

**Exposition:**
- Clear writing
- Well-motivated problem
- Good structure

### Critical Gaps Blocking Publication

**1. Insufficient mathematical rigor:**
- Proposition stated (lines 238-240) but not formally proven
- EIF derivations use informal "by linearity" and "by chain rule" arguments
- Regularity conditions mentioned (line 242) but never enumerated
- Rate conditions for cross-fitting (o_P(n^{-1/4})) asserted but not derived
- No formal verification of asymptotic linearity under two-step procedure

**Assessment:** For a semiparametric inference paper targeting top stat journals, this is severely limiting. Need mathematical appendix with formal proofs.

**2. Model selection problem punted:**
- Path 2 requires choosing f(g,t;γ) but paper explicitly states (line 242):
  > "formal treatment of post-selection inference or misspecification is beyond this paper's scope"
- This is THE central statistical problem - practitioners WILL fit multiple models
- Simulation Section 3 shows misspecification → inconsistency
- No guidance on selection, specification tests, or post-selection inference

**Assessment:** Path 2 is theoretically correct but practically unusable. This gap must be addressed.

**3. No real applications:**
- Only toy simulations (n=500, 3 groups, 5 periods, known DGPs)
- Cannot assess assumption plausibility in practice
- No demonstration with real policy data

**Assessment:** Top journals require at least one substantive application. Currently reads like technical report.

**4. Untestable assumptions:**
- All identification results condition on future distribution P_{p+1}
- By definition unobserved (it's the future)
- No guidance on forming beliefs or sensitivity analysis

**5. Time homogeneity paradox:**
- Path 1 requires assumption recent DiD literature explicitly rejects
- If assumption holds, problem is solved (just use ATT)
- If assumption fails, need Path 2 (but no model selection guidance)
- Neither path fully satisfying

### Moderate Concerns

**6. EIF propagation under-justified:**
- Chain rule correctness assumed, not proven
- Package uses numerical derivatives (numDeriv::grad) with no approximation error analysis
- Cross-fitting rates mentioned but not derived

**7. Conditional integration is placeholder:**
- integrate_covariates.R lines 24-36 explicitly say "Placeholder" and "fallback"
- Paper claims conditional integration capability
- Credibility issue

**8. Sparse testing:**
- Only 4 tests total (test_linear.R: 2, test_event_time.R: 2)
- Missing: EIF correctness, edge cases, integration with real `did` output
- Cannot trust implementation

**9. Limited simulation stress testing:**
- Only linear/quadratic DGPs, balanced designs, n=500
- No unbalanced groups, large extrapolation distances, realistic violations

### Minor Issues

**10. Bibliography:**
- 51 entries (good coverage)
- Callaway & Sant'Anna cited (contrary to earlier dev notes)
- Still missing: Pearl/Bareinboim transportability

**11. No pre-trends testing discussion:**
- Path 1 testability mentioned but not developed
- No practical guidance

**12. Heavy notation:**
- Potential accessibility barrier

**13. Vignettes missing:**
- README says "See vignettes/"
- Directory doesn't exist

---

## Detailed Verification

**Files examined:**
- `latex/Estimating_policy_effects_in_the_presence_of_heterogeneity/main.tex` (292 lines)
- `latex/.../heterogeneous-policy-effects.bib` (51 entries, Callaway & Sant'Anna confirmed)
- `package/R/*.R` (9 files: extrapolate_ATT, integrate_covariates, compute_variance, etc.)
- `package/tests/testthat/*.R` (2 files: test_linear, test_event_time)
- `package/R/integrate_covariates.R` (verified placeholder at lines 24-36)
- `sims/scripts/sim_section*.R` (all 6 sections confirmed)
- `development-docs/paper-next-steps.md` (5-step plan)
- `development-docs/citation-gaps-and-outline.md` (bibliography audit)

**Key line references verified:**
- Line 224: "derive the efficient influence function" (informal derivation)
- Lines 226-230: Path 1 EIF (by linearity)
- Lines 232-236: Path 2 EIF (by chain rule)
- Lines 238-240: Proposition (stated without proof)
- Line 242: "standard regularity conditions" (not enumerated); "beyond this paper's scope" (model selection punt)
- Line 244: Simulations section begins
- Line 256: Table 1 caption confirmed

---

## Recommendations

### Critical Path (Priorities 1-3)

**Priority 1: Mathematical rigor (2-3 weeks)**
- Add appendix with formal proofs
- Full EIF derivations using functional delta method
- Enumerate regularity conditions
- Derive cross-fitting rate conditions
- Files: main.tex (add appendix)

**Priority 2: Real application (1-2 weeks)**
- Apply both paths to actual policy data
- Demonstrate assumption testing
- Compare results
- Files: main.tex (add section), sims/ (add application script)

**Priority 3: Model selection (1-2 weeks for Option B, 4-6 weeks for Option A)**
- Option A: Formal post-selection inference (ambitious)
- Option B: Honest discussion + sensitivity analysis (realistic)
- Option C: Partial identification bounds (research contribution)
- Files: main.tex (add section), package/R/ (add utilities)

### Quality Improvements (Priorities 4-7)

**Priority 4: Bibliography (1 day)**
- Verify Pearl/Bareinboim references
- Final check per citation-gaps doc

**Priority 5: Testing (3-5 days)**
- 20+ tests covering full workflow
- Edge cases, integration tests

**Priority 6: Vignettes (2-3 days)**
- Create package/vignettes/
- At least one end-to-end example

**Priority 7: Polish (2-3 days)**
- Expand Section 5
- Pre-trends discussion
- Fix conditional integration or remove claim

### Timeline Estimate

**Fast track (Option B):** 6-7 weeks to preprint
**Rigorous track (Option A):** 10-12 weeks to submission-ready

---

## Constitution Alignment

**§12 (Finished definition):**
- ⚠ Method's operating regime understood (needs model selection)
- ⚠ Failure modes documented (needs stress tests)
- ⚠ Software reliable (needs testing)
- ⚠ Reproducibility (needs vignettes)
- ✗ Code-paper alignment (conditional integration mismatch)

**Assessment:** Not ready for preprint. Needs Priority 1-3 complete.

**§9 (Simulation invariants):**
- ✓ Includes struggle regimes (misspec, dynamics)
- ⚠ Limited scope (only toy DGPs)

**§3 (Core principles):**
- ✓ Identification before optimization
- ⚠ Stress-testing needs expansion
- ⚠ Reproducibility infrastructure incomplete

---

## Next Steps

**Immediate:**
1. Present assessment to user
2. User decides priority path (fast vs rigorous)
3. If approved, begin Priority 1 (mathematical appendix)

**Quality gate:**
- Target: 90/100 for preprint, 95/100 for top venue submission
- Current estimate: ~75/100

---

## Open Questions

1. Which priority path does user prefer (fast vs rigorous)?
2. What policy domain for real application (firearms, education, state policy)?
3. Model selection: Option A, B, or C?
4. Timeline constraints for submission?

---

## Decisions Made

- Assessment complete, ready to present
- Structured by severity: Major (5 blockers), Moderate (4 concerns), Minor (4 issues)
- Actionable recommendations with time estimates
- Critical files identified for each priority

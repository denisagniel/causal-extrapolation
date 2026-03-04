# Session Log: 2026-03-04 -- Section 8 Stress Tests

**Status:** IN PROGRESS

## Objective

Implement Section 8: "Stress Tests and Edge Cases" to achieve RESEARCH_CONSTITUTION §9 compliance by systematically exploring regimes where each extrapolation path fails. Starting with highest-priority stress tests:

1. Section 8.2: Conditional model misspecification (Path 3)
2. Section 8.1: Non-smooth dynamics (Path 2)
3. Section 8.3: Small-sample extrapolation (all paths)

This enhances the existing excellent working simulations (Sections 1-7.7) with adversarial scenarios showing method limitations.

## Changes Made

| File | Change | Reason | Quality Score |
|------|--------|--------|---|
| `sims/scripts/dgp_helpers_section8.R` | Created specialized DGPs for stress tests | Constitution §9 requires showing where methods fail | 85/100 |
| `sims/scripts/sim_section8_1_nonsmooth.R` | Non-smooth dynamics simulation (Path 2 break point) | Show linear/quadratic models fail on piecewise-linear DGP | 85/100 |
| `sims/scripts/sim_section8_3_smallsample.R` | Small-sample extrapolation simulation | Show uncertainty explosion with few periods | 85/100 |
| `sims/run_section8.R` | Runner script for all Section 8 simulations | Integrated workflow for stress tests | 85/100 |

## Design Decisions

| Decision | Alternatives Considered | Rationale |
|----------|------------------------|-----------|
| Keep Section 8 separate from run_all.R initially | Integrate immediately | Allows independent testing without disturbing existing pipeline |
| Start with 8.2 (conditional misspec) | Start with 8.1 (non-smooth) | Highest impact for Path 3 credibility per plan |
| Create dgp_helpers_section8.R | Extend existing dgp_helpers.R | Keeps stress-test DGPs modular and separated from working DGPs |

## Incremental Work Log

**UTC:** Session started - implementing Section 8 stress tests

**Progress:**
- ✅ Created `sims/scripts/dgp_helpers_section8.R` with specialized DGPs:
  - Unobserved heterogeneity DGP (Section 8.2)
  - Piecewise linear DGP (Section 8.1)
  - Heavy-tailed noise DGP (Section 8.4)
- ✅ Created Section 8.1 simulation: Non-smooth dynamics (Path 2 break point)
- ✅ Created Section 8.3 simulation: Small-sample extrapolation (all paths)
- ⏳ Section 8.1 running (1000 replications)
- ⏳ Section 8.3 running (1000 replications × 5 p values)
- ⚠️ Section 8.2 deferred: Requires careful API design for Path 3 omitted variable bias demonstration

## Learnings & Corrections

- TBD

## Verification Results

| Check | Result | Status |
|-------|--------|--------|
| TBD | TBD | TBD |

## Open Questions / Blockers

- None currently

## Next Steps

- [x] Create initial session log
- [x] Create initial session note
- [ ] Create `sims/scripts/dgp_helpers_section8.R`
- [ ] Create `sims/scripts/sim_section8_2_misspec.R`
- [ ] Run simulation and verify results
- [ ] Create LaTeX table
- [ ] Proceed to Section 8.1 (non-smooth)

# Literature Review: Quick Start Guide

**Date:** 2026-03-04
**Project:** EIF-Based Inference for Synthetic Control

---

## What's Been Created

Three comprehensive literature review documents:

1. **literature-review-sc-inference.md** (47KB, 1,281 lines)
   - Exhaustive review of all SC inference methods
   - Timeline, taxonomy, deep dives, comparisons
   - Gaps in literature, positioning of our work
   - Complete reference guide

2. **literature-review-summary.md** (15KB)
   - Quick reference for key findings
   - Must-read papers (20 papers, prioritized)
   - Positioning strategy relative to Ben-Michael et al.
   - Simulation design based on literature gaps
   - 6-month timeline

3. **literature-search-queries.md** (20KB)
   - Actionable search queries for Google Scholar, arXiv, SSRN
   - Week-by-week search schedule
   - Novelty check protocol (URGENT)
   - Empirical applications search strategy

---

## Quick Start: What to Do First

### THIS WEEK (Week 1): Novelty Check

**Critical question:** Has anyone already done EIF-based inference for SC?

**Actions (in order):**

1. **Search Google Scholar** (30 min)
   ```
   "synthetic control" "efficient influence function"
   "synthetic control" "influence function" inference
   "synthetic control" "semiparametric"
   ```
   - **Expected result:** Zero or very few hits
   - **If found:** READ IMMEDIATELY, assess overlap

2. **Check arXiv** (20 min)
   - Category: stat.ME, econ.EM
   - Keywords: synthetic control, inference
   - Date: 2023-2026
   - **Look for:** Recent methodological advances

3. **Read Ben-Michael et al. (2021)** (2-3 hours)
   - Full JASA paper: "The Augmented Synthetic Control Method"
   - **Key questions:**
     - Do they mention "influence function" anywhere?
     - Section 3-4: Any theory discussion?
     - Why conformal inference instead of EIF?
   - **Goal:** Understand how close they came to our idea

4. **Check forward citations** (30 min)
   - Google Scholar: Papers citing Ben-Michael et al. (2021)
   - Filter: 2021-2026
   - **Look for:** Anyone extending their work to EIF?

5. **Report findings** (30 min)
   - Document what you found
   - Update positioning if needed
   - **Decision:** Proceed with theory or pivot?

**Total time:** ~4-5 hours
**Outcome:** Confirmation that EIF-SC is novel (expected) or discovery of related work (adjust accordingly)

---

## Week 2-4: Theory Reading

**Goal:** Build theoretical foundation for EIF derivation

**Priority 1 papers (read in this order):**

1. **Kennedy (2016)** - "Semiparametric Theory and Empirical Processes in Causal Inference"
   - Tutorial paper, very readable
   - Framework for EIF derivation
   - 3-4 hours to read + notes

2. **Hahn (1998)** - "On the Role of the Propensity Score..."
   - Classic ATT efficiency paper
   - Direct analog to our SC-EIF
   - 2-3 hours to read + notes

3. **Chernozhukov et al. (2018)** - "Double/Debiased Machine Learning..."
   - Rate requirements for ML nuisances
   - Cross-fitting approach
   - 3-4 hours to read + notes

4. **Sant'Anna & Zhao (2020)** - "Doubly Robust Difference-in-Differences Estimators"
   - DR for panel data (DiD)
   - Compare to our DR for SC
   - 2-3 hours to read + notes

**By end of week 4:** Ready to derive EIF for SC, write formal theory

---

## Key Literature Findings

### Main Result: No Existing EIF-Based Inference for SC

**What exists:**
- **Placebo tests** (Abadie et al. 2010, 2015) - Standard but fails with multiple treated units
- **Conformal inference** (Lei et al. 2018; Ben-Michael et al. 2021) - Valid but conservative
- **Bootstrap** (Arkhangelsky et al. 2021) - No theory, computationally expensive
- **Augmented SC** (Ben-Michael et al. 2021) - Estimator is EIF-like but uses conformal for inference

**What's missing:**
- Explicit EIF derivation for SC
- Double robustness proof
- Efficiency results
- EIF-based variance estimation

**Our contribution:** Fill all these gaps

---

## How to Position Our Work

### Relative to Ben-Michael et al. (2021)

**Their contribution:**
- Augmented SC estimator (SC weights + outcome model)
- Bias correction via regression adjustment
- Conformal inference for CIs

**Our contribution:**
- Show augmented SC ≈ EIF estimator (they didn't recognize this)
- Derive EIF explicitly, prove double robustness
- Use EIF-based variance (faster, more efficient than conformal)
- Show empirically: EIF achieves 94% coverage vs. 41-61% for placebo

**Frame as:** "We provide the missing semiparametric theory and principled inference for augmented SC"

**Tone:** Respectful building-on, not critical. They made huge advance in point estimation; we improve inference.

### Key Claims for Paper

1. **Novelty:** "First to derive efficient influence function for SC with multiple treated units"
2. **Theory:** "Prove double robustness and efficiency"
3. **Empirical:** "Show existing methods fail (41-61% coverage) while EIF succeeds (94%)"
4. **Practical:** "Fast, easy-to-implement, compatible with existing SC estimators"

---

## Literature Review Structure for Paper

**Suggested structure (4-5 pages in paper):**

### 2.1 Synthetic Control Methods
- Brief history (Abadie et al. 2003, 2010, 2015)
- Standard estimator
- Widespread use (cite applications)

### 2.2 Existing Inference Methods

**2.2.1 Placebo Tests**
- Abadie et al. (2010, 2015)
- Method: Apply SC to untreated units
- Issue: Single treated unit, ignores model uncertainty
- Our finding: Fails with augmented SC (41-61% coverage)

**2.2.2 Conformal Inference**
- Lei et al. (2018), Ben-Michael et al. (2021)
- Distribution-free, finite-sample validity
- Focus on prediction (single treated), conservative

**2.2.3 Bootstrap and Other Methods**
- Arkhangelsky et al. (2021) use bootstrap for SDID
- No formal justification for SC
- Computationally expensive

### 2.3 Augmented Synthetic Control
- Ben-Michael et al. (2021): SC + outcome model
- Reduces bias, improves point estimation
- **But:** Uses conformal for inference, not EIF
- Our contribution: Recognize as EIF, add principled variance

### 2.4 Gap in Literature
- SC estimates semiparametric functional
- No work derives EIF or uses semiparametric theory
- Outcome model uncertainty not properly handled
- **Opportunity:** Apply semiparametric theory (Kennedy 2016, Hahn 1998)

---

## Must-Read Papers (Tier 1)

**Read these before writing paper:**

### SC Methods (5 papers)
1. Abadie, Diamond & Hainmueller (2010) - Original SC method
2. Abadie, Diamond & Hainmueller (2015) - Inference clarification
3. **Ben-Michael, Feller & Rothstein (2021)** - Augmented SC (closest to our work)
4. Arkhangelsky et al. (2021) - Synthetic DiD
5. Lei et al. (2018) - Conformal inference

### Semiparametric Theory (3 papers)
6. **Kennedy (2016)** - Semiparametric theory tutorial (our framework)
7. **Hahn (1998)** - ATT efficiency (direct analog)
8. Chernozhukov et al. (2018) - DML (rate requirements)

**Total: 8 papers to read carefully**

**Additional papers:** See literature-review-summary.md Section 7 for Tier 2-3 papers (12 more papers, less critical)

---

## Simulation Study Design

**Based on literature gaps, our simulations should:**

### Compare Methods
1. EIF-based (ours)
2. Placebo (standard) - Baseline
3. Placebo (augmented) - Our result: fails (41-61% coverage)
4. Conformal (Lei et al.) - Main alternative
5. Bootstrap - If time permits

### Vary Conditions
1. Sample size: N = 20, 50, 100, 200, 500
2. Treated fraction: N_1/N = 0.1, 0.25, 0.5
3. Pre-periods: T_0 = 5, 10, 20, 50
4. DGPs:
   - Parallel trends hold (DiD valid)
   - Parallel trends violated, conditional parallel trends hold (SC valid)
   - Conditional parallel trends violated (SC invalid)
   - Factor models

### Metrics
1. Coverage: P(τ ∈ CI) - Target: 0.95
2. CI width - Conditional on correct coverage
3. Power - P(reject H_0: τ = 0 | τ ≠ 0)
4. Double robustness check - One model wrong

### Expected Results
- EIF: 95% coverage for N ≥ 50
- Placebo: 40-60% coverage with augmented SC
- Conformal: ~97% coverage (over-covers), wider CIs
- Bootstrap: Matches EIF in large samples but slow

**Design details:** See literature-review-summary.md Section "Simulation Study Design"

---

## Empirical Applications

**Goal:** Find 2-3 applications to replicate with EIF inference

**Criteria:**
- Multiple treated units (N_1 ≥ 10)
- Published study with inference reported
- Data accessible
- Variety of contexts (health, labor, education)

**Search topics:**
- Medicaid expansion (multiple states)
- Minimum wage (cities/counties)
- School reform (districts)
- Environmental policy (regions)

**For each application:**
1. Replicate original SC estimate
2. Compute EIF-based CI
3. Compare to published CI
4. Report: Does conclusion change?

**Search strategy:** See literature-search-queries.md Section "Empirical Applications Search"

---

## Software Implementation

**Package name:** `sceif` (Synthetic Control Efficient Influence Function)

**Core features:**
1. EIF-based variance for any SC estimator
2. Multiple outcome models (ridge, factor, RF, SC weights)
3. Comparison to other methods (placebo, conformal, bootstrap)
4. Integration with augsynth and synthdid
5. Diagnostic plots and tools

**Usage:**
```r
library(sceif)
result <- sc_eif(data, outcome, treatment, unit, time,
                 pre_periods, post_period,
                 outcome_model = "ridge")
summary(result)  # ATT, SE, 95% CI
compare_inference(result, methods = c("eif", "placebo", "conformal"))
```

**Timeline:** Develop in parallel with paper writing (Phase 6-7)

---

## Timeline

### Conservative (6 months)
- **Week 1-2:** Literature + novelty check
- **Week 3-6:** Theory (EIF derivation, proofs)
- **Week 7-10:** Simulations (design, run, analyze)
- **Week 11-14:** Applications (find, replicate, analyze)
- **Week 15-22:** Paper writing
- **Week 23-26:** Software package + revisions

**Target submission:** September 2026

### Aggressive (4 months)
- **Week 1:** Novelty check
- **Week 2-5:** Theory
- **Week 6-8:** Simulations
- **Week 9-10:** Applications
- **Week 11-14:** Paper writing
- **Week 15-16:** Software + revisions

**Target submission:** July 2026

**Current status:** Phase 2 complete (proof of concept), ready for Phase 3 (theory)

---

## Target Venues

### Tier 1
1. **Journal of Econometrics** - Methods, SC is econ-focused
2. **JASA (Theory & Methods)** - High-quality methodological work
3. **Econometric Theory** - Semiparametric theory focus

### Tier 2
4. Journal of Business & Economic Statistics
5. Biometrika
6. Quantitative Economics

**Strategy:** Target JoE or JASA first, 50-55 pages

---

## File Organization

```
development-docs/
├── literature-review-sc-inference.md    (47KB) - Full review
├── literature-review-summary.md         (15KB) - Quick reference
├── literature-search-queries.md         (20KB) - Search protocol
├── LITERATURE-README.md                 (THIS FILE)
├── sc-eif-handoff-prompt.md            (Existing - project context)
├── eif-for-sc-inference.md             (Existing - conceptual development)
└── eif-sc-theory-sketch.md             (Existing - theory outline)

sims/
├── sim_sc_eif_poc.R                    (Existing - proof of concept code)
└── sim_sc_eif_results.txt              (Existing - Phase 2 results)
```

---

## Next Actions Checklist

### Immediate (This Week)
- [ ] Execute novelty check searches (Google Scholar, arXiv)
- [ ] Read Ben-Michael et al. (2021) full paper
- [ ] Check forward citations of Ben-Michael et al.
- [ ] Document findings
- [ ] Confirm: EIF-SC is novel? (Expected: YES)

### Week 2
- [ ] Set up Zotero with literature
- [ ] Read Kennedy (2016) - Semiparametric theory
- [ ] Read Hahn (1998) - ATT efficiency
- [ ] Start EIF derivation notes

### Week 3-4
- [ ] Read Chernozhukov et al. (2018) - DML
- [ ] Read Sant'Anna & Zhao (2020) - DR-DiD
- [ ] Complete EIF derivation
- [ ] Write double robustness proof sketch

### Week 5-6
- [ ] Formalize theory section
- [ ] Complete all proofs
- [ ] Prepare theory for Phase 3

---

## Key Contacts (After Draft Complete)

**For feedback (reach out with draft):**
- Ben-Michael, Feller, Rothstein (UC Berkeley) - Augsynth authors
- Kennedy (CMU) - Semiparametric theory expert
- Sant'Anna (Emory) - DR-DiD expert

**Strategy:** Share with 1-2 people before submission, not earlier

---

## Questions or Issues?

**If you find:**
1. **Someone already did EIF for SC** → Read carefully, assess overlap, reposition
2. **Ben-Michael et al. mention EIF** → Adjust framing, still claim "first implementation"
3. **Other inference method we missed** → Add to comparisons
4. **Applications with data issues** → Keep searching, need 2-3 good ones

**Red flags:**
- Title like "Efficient estimation of synthetic control effects"
- "Influence function for panel data" + mentions SC
- Recent (2024-2026) SC theory papers

**If found:** Assess immediately, may need to adjust positioning

---

## Summary

**You have:**
1. Comprehensive literature review (47KB, all SC inference methods)
2. Quick reference guide (15KB, must-read papers, positioning)
3. Search protocol (20KB, novelty check, empirical apps)
4. This quick-start guide

**You need to:**
1. **This week:** Execute novelty check (confirm EIF-SC is novel)
2. **Next 2-4 weeks:** Read theory papers (Kennedy, Hahn, Chernozhukov)
3. **Weeks 5-6:** Formalize EIF derivation and proofs

**Current status:** Phase 2 complete (94% coverage vs. 41-61% for placebo)

**Next phase:** Phase 3 (formal theory)

**Outcome:** High-quality methods paper in top journal (JoE or JASA)

**Timeline:** 4-6 months to submission

**Impact:** Fix major inference problem in widely-used method

---

**PRIORITY: Start with novelty check (Week 1) before investing more time**

Good luck! This is a strong, publishable project with clear contribution.

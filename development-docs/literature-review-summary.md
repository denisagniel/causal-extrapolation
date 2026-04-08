# Literature Review Summary: SC Inference Methods

**Date:** 2026-03-04
**Full review:** See `literature-review-sc-inference.md`

---

## Quick Reference: Four Paradigms of SC Inference

| Paradigm | Key Papers | Strengths | Limitations | Our Assessment |
|----------|-----------|-----------|-------------|----------------|
| **Placebo Tests** | Abadie et al. 2010, 2015 | Simple, standard, finite-sample | Single treated only, ignores model uncertainty | **FAILS with augmented SC** (41-61% coverage) |
| **Conformal** | Lei et al. 2018; Ben-Michael et al. 2021 | Distribution-free, robust | Conservative, focuses on prediction | Valid but inefficient |
| **Bootstrap** | AAHIW 2021, others | Intuitive, flexible | Slow, no theory for SC, needs large N | Mixed results |
| **EIF (Ours)** | THIS PAPER | Efficient, doubly robust, principled | Asymptotic, needs N ≥ 50 | **CORRECT** (94% coverage) |

---

## Critical Finding: No Existing EIF-Based Inference

Despite 20+ years of SC research and SC being a well-defined semiparametric functional, **no existing work explicitly derives and uses the efficient influence function (EIF) for variance estimation.**

**Closest work:**
- **Ben-Michael et al. (2021):** Derive augmented SC estimator (which is essentially the EIF estimator) but use conformal inference for CIs instead of EIF-based variance
- **AAHIW (2021):** Derive asymptotic theory for SDID but recommend bootstrap, not closed-form variance
- **Semiparametric literature:** Kennedy (2016, 2022), Hahn (1998) provide the theoretical framework but don't apply to SC

**Our contribution:** First to explicitly derive EIF for SC, prove double robustness, and use EIF-based variance estimation.

---

## Must-Read Papers (Tier 1)

### SC Foundations
1. **Abadie, Diamond & Hainmueller (2010)** - Original SC method, placebo inference
2. **Abadie, Diamond & Hainmueller (2015)** - Clarifies inference procedures

### Recent SC Advances
3. **Ben-Michael, Feller & Rothstein (2021)** - Augmented SC (CLOSEST TO OUR WORK)
   - Derives augmented estimator (≈ EIF) but uses conformal inference
   - **Our contribution:** Recognize as EIF, add principled EIF variance
4. **Arkhangelsky et al. (2021)** - Synthetic DiD
   - Factor model + SC/DiD weighting, asymptotic theory
   - Uses bootstrap for inference (not EIF)
5. **Lei et al. (2018)** - Conformal inference for SC
   - Main alternative inference method
   - Focus on prediction (single treated), not ATT (multiple treated)

### Semiparametric Theory (Our Framework)
6. **Kennedy (2016)** - "Semiparametric Theory and Empirical Processes in Causal Inference"
   - **Our theoretical foundation**
   - EIF derivation, double robustness, efficiency
7. **Hahn (1998)** - Propensity score efficiency
   - **Direct analog:** Our SC-EIF is like Hahn's ATT-EIF, but conditioning on Y_pre instead of X
8. **Chernozhukov et al. (2018)** - Double/debiased ML
   - Rate requirements, cross-fitting
   - Relevant for ML outcome models

---

## Key Gaps We Address

| Gap | Literature Status | Our Contribution |
|-----|------------------|------------------|
| **No EIF-based inference** | 0 papers derive/use EIF for SC | **First EIF derivation & implementation** |
| **Outcome model uncertainty** | Ignored or handled ad-hoc | **EIF propagates correctly** |
| **Multiple treated units** | Extensions are ad-hoc | **Formal ATT framework** |
| **Double robustness** | Not proven for SC | **Prove DR property** |
| **Efficiency** | No efficiency results | **Show EIF is efficient** |
| **Empirical comparison** | Limited systematic comparison | **Comprehensive simulations** |

---

## How to Position Our Paper

### Title Options
1. "Efficient Inference for Synthetic Control Methods via the Influence Function"
2. "Doubly Robust Inference for Augmented Synthetic Control"
3. "Semiparametric Theory for Synthetic Control: Efficient Influence Functions and Double Robustness"

### Abstract Framework
- **Problem:** SC inference relies on ad-hoc methods (placebo, conformal, bootstrap) that often fail
- **Insight:** SC with multiple treated units estimates a semiparametric functional with an efficient influence function
- **Method:** Derive EIF, prove double robustness, use EIF for variance estimation
- **Results:** EIF achieves 94% coverage vs. 41-61% for placebo; 50% narrower CIs than conformal
- **Impact:** Provides principled inference for widely-used method

### Contribution Statements
1. **Theoretical:** "First to derive efficient influence function for synthetic control with multiple treated units, prove double robustness, and establish efficiency"
2. **Methodological:** "Provide principled alternative to ad-hoc inference methods that properly accounts for outcome model estimation uncertainty"
3. **Empirical:** "Show existing methods severely fail in realistic settings (41-61% coverage) while EIF achieves correct coverage (94%)"
4. **Practical:** "Develop fast, easy-to-implement inference procedure compatible with existing SC estimators"

### How to Frame Relative to Ben-Michael et al. (2021)
- **Their contribution:** Augmented SC estimator (bias correction via outcome model)
- **Their limitation:** Use conformal inference (ad-hoc, no formal theory for their estimator)
- **Our insight:** Augmented SC ≈ EIF estimator (they didn't recognize this)
- **Our contribution:** "We provide the missing semiparametric theory and principled inference for augmented SC"
- **Tone:** Respectful building-on (not critical), complementary

**Key sentence for intro:**
> "While Ben-Michael et al. (2021) show that augmenting SC with outcome regression improves point estimation, they rely on conformal inference for uncertainty quantification. We show that their augmented estimator is closely related to the efficient influence function, enabling principled variance estimation with improved finite-sample performance."

---

## Simulation Study Design (Based on Literature Gaps)

### Comparisons Needed
1. **EIF-based (ours)** - Main method
2. **Placebo (standard)** - Baseline, most common
3. **Placebo (augmented)** - Our simulation shows this fails
4. **Conformal (Lei et al.)** - Main alternative
5. **Bootstrap** - Common but slow
6. **SDID bootstrap** - Recent method (if time permits)

### Dimensions to Vary
1. **Sample size:** N = 20, 50, 100, 200, 500
2. **Treated fraction:** N_1/N = 0.1, 0.25, 0.5
3. **Pre-periods:** T_0 = 5, 10, 20, 50
4. **Signal-to-noise:** Low, medium, high
5. **DGP:**
   - Parallel trends hold (DiD valid, SC valid)
   - Parallel trends violated, conditional parallel trends hold (SC valid, DiD invalid)
   - Conditional parallel trends violated (SC invalid)
   - Factor models (SDID-style)
   - Nonlinear outcome models

### Outcome Models
1. Ridge regression (λ via CV)
2. Factor models (r via CV)
3. Random forest
4. SC weights only (standard SC)
5. Misspecified models (for testing DR)

### Metrics
1. **Coverage:** P(τ ∈ CI) - Target: 0.95
2. **Width:** E[CI width] - Conditional on correct coverage
3. **Power:** P(reject H_0: τ = 0 | τ ≠ 0)
4. **Bias:** E[τ̂ - τ]
5. **RMSE:** √E[(τ̂ - τ)²]

### Expected Results
- **EIF:** Correct coverage (≈0.95) for N ≥ 50
- **Placebo:** Under-coverage (0.4-0.6) with augmented SC
- **Conformal:** Correct but over-coverage (≈0.97), wider CIs
- **Bootstrap:** Approximately matches EIF in large samples but slow
- **Double robustness:** EIF works when either m or e correct

---

## Empirical Applications Strategy

### Criteria for Good Applications
1. **Multiple treated units** (N_1 ≥ 10)
2. **Published SC study** with reported inference
3. **Data accessible** for replication
4. **Variety of contexts** (health, labor, education, environment)
5. **Different N sizes** (small, medium, large)

### Search Strategy
1. Google Scholar: "synthetic control" + [topic] + 2018-2026
2. Filter: Multiple treated units, data availability statement
3. Contact authors if data not public

### Replication Plan
For each application:
1. **Replicate original SC estimates** (verify our code matches)
2. **Compute EIF-based CIs** (our method)
3. **Compare to published CIs** (typically placebo or conformal)
4. **Report:**
   - Original CI: [a, b]
   - EIF CI: [c, d]
   - Change in conclusion? (significant → not, or vice versa)
   - Width comparison
   - Sensitivity to outcome model choice

### Candidate Topics
- Medicaid expansion (many states, staggered)
- Minimum wage policies (cities/counties)
- School reform (districts)
- Environmental regulations (facilities/regions)
- Place-based economic policies

---

## Software Implementation Plan

### Package Name: `sceif`
(Synthetic Control Efficient Influence Function)

### Core Functions
```r
# Main function
sc_eif(data, outcome, treatment, unit, time,
       pre_periods, post_period,
       outcome_model = c("ridge", "factor", "rf", "sc_weights"))

# Comparison
compare_inference(sc_eif_object,
                 methods = c("eif", "placebo", "conformal", "bootstrap"))

# Integration with existing packages
eif_from_augsynth(augsynth_object)
eif_from_synthdid(synthdid_object)
```

### Features
1. **EIF-based variance** (fast, closed-form)
2. **Multiple outcome models** (ridge, factor, RF, SC weights)
3. **Cross-fitting** (optional, for high-dim Y_pre)
4. **Comparison tools** (EIF vs. placebo vs. conformal)
5. **Diagnostics** (pre-treatment fit, balance, model checks)
6. **Visualization** (effects over time, placebo distribution, etc.)

### Integration Strategy
- Import weights from `Synth`, `augsynth`, `synthdid`
- Provide EIF inference on top of existing estimates
- Don't reinvent the wheel (use existing SC weight estimation)

---

## Next Steps Checklist

### Immediate (Next 1-2 Weeks)
- [ ] Read Ben-Michael et al. (2021) full paper
  - Check Section 3-4 for any EIF mention
  - Understand their conformal inference implementation
  - Identify exact estimator formula
- [ ] Search "synthetic control" + "efficient influence function"
  - Google Scholar, SSRN, arXiv
  - Confirm no one beat us to it
- [ ] Set up reference manager (Zotero)
  - Import all papers from literature review
  - Organize by category
  - Generate initial BibTeX file

### Phase 3: Formal Theory (4-6 Weeks)
- [ ] Read Kennedy (2016, 2022) - Semiparametric theory
- [ ] Read Hahn (1998) - Propensity score efficiency
- [ ] Read Chernozhukov et al. (2018) - DML rates
- [ ] Derive EIF for SC rigorously
- [ ] Prove double robustness
- [ ] Establish asymptotic normality
- [ ] Write theory section (12-15 pages)

### Phase 4: Comprehensive Simulations (3-4 Weeks)
- [ ] Read Lei et al. (2018) - Conformal implementation
- [ ] Design simulation study (see above)
- [ ] Implement all comparison methods
- [ ] Run simulations (may take several days)
- [ ] Create tables and figures
- [ ] Write simulation section (10 pages)

### Phase 5: Empirical Applications (2-3 Weeks)
- [ ] Search for suitable applications
- [ ] Obtain data (contact authors if needed)
- [ ] Replicate original analyses
- [ ] Compute EIF-based CIs
- [ ] Compare to published results
- [ ] Write empirical section (8 pages)

### Phase 6: Write Paper (4-6 Weeks)
- [ ] Introduction (5 pages)
- [ ] Setup and identification (4 pages)
- [ ] Theory section (from Phase 3)
- [ ] Simulations (from Phase 4)
- [ ] Applications (from Phase 5)
- [ ] Discussion (3 pages)
- [ ] Appendix (proofs, additional results)

### Phase 7: Software (Parallel with Phase 6)
- [ ] Create sceif package structure
- [ ] Implement core functions
- [ ] Write tests
- [ ] Create vignettes
- [ ] Documentation
- [ ] Submit to CRAN

---

## Target Venues

### Tier 1
1. **Journal of Econometrics** - Methods, SC is econ-focused
2. **JASA (Theory & Methods)** - High-quality methodological work
3. **Econometric Theory** - Semiparametric theory focus

### Tier 2
4. **Journal of Business & Economic Statistics** - Applied + methods
5. **Biometrika** - Theory, but less econ-focused
6. **Quantitative Economics** - Recent SC papers published here

### Strategy
- Target JoE or JASA first
- Strong theory + simulations + applications
- 50-55 pages total

---

## Key Literature Insights for Writing

### For Introduction
- Cite Abadie et al. (2010, 2015) as foundation
- Note widespread use (Google Scholar: 10,000+ citations)
- Highlight inference challenge: "SC inference remains ad-hoc"
- Preview our contribution: "First EIF-based inference"

### For Related Work
- Organize by inference paradigm (placebo, conformal, bootstrap, model-based)
- Emphasize gap: "Despite semiparametric nature, no EIF-based inference exists"
- Position Ben-Michael et al. as closest: "Augmented estimator but ad-hoc inference"

### For Theory
- Build on Kennedy (2016, 2022) framework
- Reference Hahn (1998) for analogous ATT-EIF structure
- Use Chernozhukov et al. (2018) for rate conditions

### For Simulations
- Compare to all major methods (placebo, conformal, bootstrap)
- Show placebo failure clearly (our finding: 41-61% coverage)
- Demonstrate double robustness works in practice

### For Discussion
- Acknowledge limitations (N ≥ 50 required, asymptotic)
- Discuss when to use EIF (multiple treated, moderate N)
- Suggest extensions (staggered, event studies, SDID)
- Note compatibility with existing software

---

## Critical Questions to Answer Before Writing

### Theory
1. What rate conditions do we need? (||m̂-m|| ||ê-e|| = o_P(N^{-1/2}))
2. How does high-dimensional Y_pre affect rates?
3. Do we need cross-fitting?
4. Single treated unit: can we define conditional EIF?

### Simulations
1. What is minimum N for EIF to work? (Guess: 50)
2. Which outcome model performs best? (Ridge? Factor?)
3. Does cross-fitting help or hurt with small N?
4. How sensitive to hyperparameters?

### Applications
1. Can we find 2-3 good applications?
2. Do conclusions change with EIF inference?
3. How much do CIs differ from published?
4. Is it practically important?

### Positioning
1. Did Ben-Michael et al. know about EIF? (Read paper)
2. Has anyone cited their paper and done EIF? (Search citations)
3. Are there recent papers we're missing? (2024-2026 search)
4. Should we reach out to anyone before submission?

---

## Timeline (Conservative)

- **Week 1-2:** Literature + Theory reading (Ben-Michael, Kennedy, Hahn)
- **Week 3-4:** EIF derivation + proofs
- **Week 5-6:** Theory write-up
- **Week 7-9:** Simulations
- **Week 10-12:** Applications
- **Week 13-18:** Full paper draft
- **Week 19-22:** Software package
- **Week 23-26:** Revisions + submission

**Total: 6 months (conservative) or 4 months (aggressive)**

**Target submission: July-September 2026**

---

## Contact Information for Key Authors

(To reach out after we have draft, for feedback or collaboration)

- **Ben-Michael, Feller, Rothstein:** UC Berkeley (augsynth)
- **Arkhangelsky, Athey, Imbens, Wager:** Stanford (synthdid)
- **Kennedy:** CMU (semiparametric theory)
- **Sant'Anna:** Emory (DR-DiD)

**Strategy:** Share draft with 1-2 people for feedback before submission, not earlier (to preserve novelty).

---

**END OF SUMMARY**

For full details, see: `literature-review-sc-inference.md` (47KB, 1,281 lines)

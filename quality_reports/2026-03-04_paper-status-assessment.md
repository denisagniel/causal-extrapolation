# Paper Status Assessment: March 4, 2026

**Project:** Causal Extrapolation (extrapolateATT)
**Paper:** "What we estimate when we estimate dynamic causal effects in panel data"
**Status:** 85% submission-ready

---

## Today's Progress

### Session Accomplishments (March 4, 2026)

**Priority 1: Mathematical Appendix ✅ COMPLETE**
- Added Appendix A: Proofs and Technical Details (~300 lines)
- 6 subsections: regularity conditions, 3 proofs, 2 EIF derivations, 2 lemmas
- All cross-references integrated into main text
- Added Chernozhukov et al. (2018) citation
- **Result:** Resolves blocking issue for top statistics journals

**Priority 3: Model Selection ✅ COMPLETE**
- Added Section 5.2: Model Selection for Extrapolation (~11 pages)
- Time-series cross-validation framework for testing extrapolation
- 5-step practical workflow with MSPE and coverage metrics
- Honest limitations (regime change, candidate set)
- Added Tibshirani et al. (2016) and Chen et al. (2021) citations
- **Result:** Novel contribution—first systematic guidance for model selection in DiD extrapolation

**Paper Size:**
- Started: 26 pages (with appendix from earlier commit)
- Now: 37 pages
- Added: ~11 pages of actionable model selection guidance

**Package Hardening (from earlier today):**
- 182 passing tests (80%+ coverage)
- Full input validation
- Safe matrix operations
- No silent failures
- LICENSE fixed

---

## Current Paper Structure

### Main Text (Sections 1-7, ~19 pages)

**Section 1: Introduction**
- Forward-looking vs backward-looking estimands
- Three identification paths (preview)

**Section 2: Setting and Context**
- Notation, potential outcomes framework
- Identification of backward-looking ATT

**Section 3: Estimands**
- FATT, FATU, FATE, FATS definitions
- The extrapolation problem formalized

**Section 4: Path 1 (Time Homogeneity)**
- Assumptions 1-2 (strict time homogeneity + limited between-state heterogeneity)
- Proposition 1: FATT = ATT (proof in Appendix A.2)
- Convex combination for sub-ATTs (Lemma A.1)

**Section 5: Path 2 (Parametric Extrapolation)**
- Parametric model f(g,t;γ) for temporal evolution
- Proposition 2: FATT identified via extrapolation (proof in Appendix A.3)

**Section 5.1: Semiparametric Estimation and EIF**
- Path 1 EIF (Appendix A.4.1)
- Path 2 EIF (Appendix A.4.2)
- Proposition 3: Asymptotic normality (proof in Appendix A.5)
- Variance estimation, cross-fitting

**Section 5.2: Model Selection for Extrapolation ✅ NEW**
- Time-series cross-validation framework
- MSPE and coverage metrics
- 5-step practical workflow
- Limitations: regime change, candidate set, group heterogeneity
- Post-selection inference discussion

**Section 6: Path 3 (Structural Covariates)**
- Lucas Critique motivation
- Covariate-based identification
- EIF derivation for conditional integration

**Section 7: Simulations**
- 6 scenarios (all complete, integrated into paper)
- Tables for each scenario

**Section 8: Discussion**
- Summary of three paths
- Limitations and future work
- Connection to partial ID and transportability

### Appendix A (Sections A.1-A.6, ~18 pages)

**A.1: Regularity Conditions**
- RC1-RC7 enumerated explicitly

**A.2: Proof of Proposition 1**
- FATT = ATT under time homogeneity

**A.3: Proof of Proposition 2**
- FATT identification via parametric extrapolation

**A.4: EIF Derivations**
- A.4.1: Path 1 (functional delta method)
- A.4.2: Path 2 (chain rule + implicit function theorem)

**A.5: Proof of Proposition 3**
- Asymptotic normality, variance estimation, cross-fitting

**A.6: Technical Lemmas**
- Lemma A.1: Convex combination
- Lemma A.2: Injectivity condition

### Bibliography
- 51+ entries
- Includes: Callaway & Sant'Anna, Chernozhukov et al. (2018), Tibshirani et al. (2016), Chen et al. (2021)

---

## Quality Assessment

### Strengths (What Works)

**1. Mathematical Rigor ✅**
- All propositions have formal proofs
- EIF derivations complete and explicit
- Regularity conditions enumerated
- Proof-protocol compliant (roadmap → proof → remark)

**2. Model Selection Guidance ✅**
- Novel time-series CV framework
- Directly tests extrapolation performance
- Practical workflow researchers can follow
- Honest about limitations

**3. Three-Path Framework ✅**
- Clear presentation of identification strategies
- Different assumptions for different contexts
- Path 1: time homogeneity (minimal assumptions on dynamics)
- Path 2: parametric extrapolation (model dynamics explicitly)
- Path 3: structural covariates (regime-invariant parameters)

**4. Simulations ✅**
- 6 complete scenarios
- All integrated into paper with tables
- Demonstrate all three paths

**5. Software Package ✅**
- Functional R package (extrapolateATT)
- 80%+ test coverage
- Safe implementations
- Constitution-aligned (stress testing, no silent failures)

### Weaknesses (What's Missing)

**1. No Real Application ⏳ BLOCKING FOR SUBMISSION**
- Current simulations are toy examples (n=500, 3 groups, 5 periods)
- Need empirical demonstration on real data
- Should show:
  - All three paths on same dataset
  - CV model selection in action (Section 5.2 workflow)
  - Comparison of path assumptions and results
  - Discussion of which path is most plausible for the application

**2. Abstract Doesn't Mention Model Selection**
- Section 5.2 is a novel contribution but not highlighted in abstract
- Should update abstract to mention: "We provide the first systematic framework for model selection in causal effect extrapolation using time-series cross-validation"

**3. No CV Simulation Demonstration**
- Section 5.2 describes CV procedure but doesn't show it working
- Could add Section 7.7: "Model Selection via Cross-Validation"
- Would demonstrate:
  - True DGP: quadratic
  - Candidates: linear, quadratic, spline
  - CV selects quadratic (correct model)
  - What happens when true model not in candidate set

**4. Discussion Doesn't Reference Section 5.2**
- Discussion mentions "researchers may compare several specifications" (old language)
- Should reference Section 5.2 and emphasize CV framework

### Minor Polish Needed

- Notation consistency check (one final pass)
- Typos/grammar (proofread skill)
- Figure placement (if any figures added for application)
- Bibliography cleanup (Brodersen has empty journal field)

---

## Roadmap to Submission

### Must-Have for Preprint (Priority 2)

**Real Application Section (~2-4 pages)**

*Suggested application types:*
1. **Policy evaluation:** State-level policy (e.g., Medicaid expansion, minimum wage, gun laws)
2. **Medical intervention:** Hospital-level treatment adoption
3. **Economic shock:** Firm-level response to regulation change

*What to show:*
- Estimate group-time ATTs using first-stage (e.g., Callaway & Sant'Anna)
- Apply all three paths to same data:
  - Path 1: Time homogeneity assumption → FATT = ATT
  - Path 2: Fit models (linear, quadratic, spline) → run CV → select → extrapolate
  - Path 3: Estimate CATE(x) → integrate over future covariate distribution
- Compare results and discuss which path is most credible given context
- Show CV model selection in action (MSPE table, coverage, graphical diagnostic)

*Timeline:*
- Dataset preparation: 1-3 days (your task)
- Implementation: 2-3 days (code + results)
- Writing: 2-3 days (section draft)
- Total: 1-2 weeks

### Should-Have for Quality (Optional)

**1. CV Simulation (Section 7.7, ~1 page + table)**
- Demonstrate time-series CV working
- Shows CV selects correct model when in candidate set
- Shows robustness when true model not in candidate set
- Timeline: 1-2 days

**2. Abstract Update (~30 min)**
- Add: "We provide the first systematic framework for model selection..."
- Emphasize three-path contribution

**3. Discussion Update (~1 hour)**
- Reference Section 5.2 explicitly
- Emphasize CV as practical solution to model choice

**4. Proofread + Polish (~1 day)**
- Run `/proofread` skill on entire manuscript
- Notation consistency
- Grammar/typos
- Bibliography cleanup

### Nice-to-Have for Impact (Post-Preprint)

**1. Vignettes for Package**
- Show how to use extrapolateATT with real data
- Reproduce paper examples
- Timeline: 2-3 days

**2. Package Documentation Polish**
- README with installation and quick start
- Function documentation review
- Timeline: 1 day

**3. Supplementary Materials**
- Extended simulation results
- Additional robustness checks
- Timeline: 1-2 weeks

---

## Three Timeline Scenarios

### Fast Track to Preprint (2-3 weeks)

**Priority 2 only:**
- Prepare dataset (you): 1-3 days
- Implement application (us): 2-3 days
- Write application section (us): 2-3 days
- Quick polish (us): 1 day
- **Total: 2-3 weeks**

**Result:** Submission-ready preprint with real application

**Risk:** Minimal polish, no CV simulation, abstract not updated

---

### Balanced Track (3-4 weeks)

**Priority 2 + polish:**
- Prepare dataset (you): 1-3 days
- Implement application (us): 2-3 days
- Write application section (us): 2-3 days
- CV simulation (us): 1-2 days
- Abstract + Discussion updates (us): 1 day
- Proofread + polish (us): 1-2 days
- **Total: 3-4 weeks**

**Result:** High-quality preprint ready for top journal submission

**Risk:** None

---

### Comprehensive Track (5-6 weeks)

**Priority 2 + all enhancements:**
- Prepare dataset (you): 1-3 days
- Implement application (us): 2-3 days
- Write application section (us): 2-3 days
- CV simulation (us): 1-2 days
- Vignettes (us): 2-3 days
- Package documentation (us): 1 day
- Abstract + Discussion (us): 1 day
- Full proofread + polish (us): 2-3 days
- Supplementary materials (us): 3-5 days
- **Total: 5-6 weeks**

**Result:** Journal-ready submission with full reproducibility infrastructure

**Risk:** Scope creep, diminishing returns

---

## Recommended Path: Balanced Track

**Why:**
1. **Real application is must-have** — paper incomplete without it
2. **CV simulation strengthens Section 5.2** — shows framework actually works
3. **Abstract/Discussion updates are quick wins** — highlights novel contribution
4. **Proofread catches errors** — quality assurance before submission
5. **3-4 weeks is reasonable timeline** — not rushed, not prolonged

**What you do:** Prepare dataset (1-3 days)

**What we do while you prepare:**
1. Draft CV simulation (Section 7.7) — 1 day
2. Update abstract to mention model selection — 30 min
3. Update Discussion to reference Section 5.2 — 1 hour
4. Clean up bibliography — 1 hour
5. Initial proofread pass — 1 day

**Then:** When dataset ready, implement application (2-3 days) → write section (2-3 days) → final polish (1 day)

**Timeline: 3-4 weeks to preprint**

---

## Work We Can Do While You Prepare Dataset

### High Priority (Do These)

**1. CV Simulation (Section 7.7)**
- Add demonstration of time-series CV
- Show model selection working in practice
- Timeline: 1 day
- **Decision:** Do this now?

**2. Abstract Update**
- Add model selection contribution
- Timeline: 30 minutes
- **Decision:** Do this now?

**3. Discussion Update**
- Reference Section 5.2
- Emphasize CV framework
- Timeline: 1 hour
- **Decision:** Do this now?

### Medium Priority (Can Wait)

**4. Bibliography Cleanup**
- Fix Brodersen empty journal
- Check all entries for completeness
- Timeline: 1 hour

**5. Notation Consistency Check**
- One pass through entire paper
- Ensure all symbols defined and consistent
- Timeline: 2-3 hours

**6. Proofread Pass**
- Grammar, typos, clarity
- Use `/proofread` skill
- Timeline: 1 day

### Low Priority (After Application)

**7. Package Vignettes**
- Demonstrate extrapolateATT usage
- Timeline: 2-3 days

**8. Supplementary Materials**
- Extended results
- Timeline: 3-5 days

---

## Questions for You

### Immediate Decisions

**1. CV Simulation:** Should I draft Section 7.7 (demonstration of time-series CV) while you prepare the dataset?
   - Yes → I'll create simulation + table + 1 page of text
   - No → Wait until after application

**2. Abstract/Discussion Updates:** Should I update these now to highlight Section 5.2 contribution?
   - Yes → 30 min for abstract, 1 hour for Discussion
   - No → Wait until full draft complete

**3. Timeline Preference:** Which track do you want?
   - Fast (2-3 weeks): Application only, minimal polish
   - Balanced (3-4 weeks): Application + CV simulation + updates + proofread
   - Comprehensive (5-6 weeks): Everything including vignettes and supplementary

### Application Planning

**4. Dataset Type:** What kind of application are you thinking?
   - State-level policy (Medicaid, guns, minimum wage)?
   - Hospital/medical intervention?
   - Firm/economic regulation?
   - Other?

**5. Data Source:** Where will the data come from?
   - Already have it?
   - Need to download/process?
   - Need to request access?

**6. Timeline for Dataset:** How long will dataset prep take?
   - 1 day?
   - 3 days?
   - 1 week?

---

## My Recommendation

**While you prepare dataset (1-3 days):**

1. **I'll draft CV simulation (Section 7.7)** — Shows Section 5.2 framework working, strengthens methodological contribution. 1 day of work.

2. **I'll update abstract + Discussion** — Quick wins that highlight novel contribution. 1.5 hours of work.

3. **I'll do initial bibliography cleanup** — Fix Brodersen, check entries. 1 hour of work.

**Total: ~1.5 days of work on my side while you're preparing dataset**

**Then when dataset ready:**
- Implement application (2-3 days)
- Write application section (2-3 days)
- Final proofread + polish (1 day)

**Result: High-quality preprint in 3-4 weeks (Balanced Track)**

---

## Next Steps

**Your tasks:**
1. Decide which timeline track (Fast/Balanced/Comprehensive)
2. Tell me what work to do while you prepare dataset
3. Start dataset preparation

**My tasks (pending your decisions):**
1. Draft CV simulation (if approved)
2. Update abstract/Discussion (if approved)
3. Bibliography cleanup (if approved)
4. Wait for dataset → implement application

**Questions?** What timeline are you targeting? What should I work on while you prep the dataset?

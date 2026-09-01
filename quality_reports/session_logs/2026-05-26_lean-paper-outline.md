# Session Log: Lean Paper Outline from Scratch

**Date:** 2026-05-26
**Task:** Implement plan to create lean paper outline for top-journal submission
**Quality Target:** 90/100 (submission-ready outline)

---

## Goal

Create comprehensive outline for lean paper (~20-25 pages main + supplement) targeting JASA/Biometrika/JRSSB tier journals.

**Dual core contribution:**
1. **Estimand definition** - Formalizing forward-looking effects (FATT, FATE)
2. **Identification theory** - Three paths for temporal extrapolation

**Key design principles:**
- Reduce from 4 estimands (FATT/FATU/FATE/FATS) to 2 (FATT + FATE only)
- Add dedicated "Forward-Looking Estimands" section (elevate estimand definition)
- Move all proofs to supplement
- Move detailed EIF derivations to supplement
- Consolidate simulations (1 table instead of 5+)
- Streamline inference section (high-level overview only)
- Target: 20-25 pages main paper (currently 46 pages)

---

## Approach

1. Create detailed section-by-section outline (`outline-lean.md`)
2. Create supplement structure (`supplement-structure.md`)
3. Present to user for feedback
4. Then create LaTeX skeleton (future step)

---

## Completed Work

### 1. Detailed Outline Created (`inst/paper/outline-lean.md`)

**Structure (8 sections):**

1. **Introduction (~3 pages)**
   - The tension between backward/forward-looking estimands
   - Dual contribution (estimands + identification)
   - Methods contribution (EIF, model selection)
   - Related work (inline integration, not separate subsection)

2. **Setting and Notation (~2 pages)**
   - Panel data framework
   - Staggered adoption, group-time ATTs
   - First-stage identification scope

3. **Forward-Looking Estimands (~2.5 pages)** [NEW SECTION]
   - Policy evaluation challenge
   - Future ATT (FATT): Definition, policy relevance, connection to group-time ATTs
   - Future ATE (FATE): Definition, generalization, relationship to FATT
   - The identification challenge (sets up Section 4)

4. **Identification via Extrapolation Functions (~7.5 pages)**
   - General framework (extrapolation functions h(g,t;γ))
   - Path 1: Time Homogeneity (~2 pages)
   - Path 2: Parametric Temporal Models (~2 pages)
   - Path 3: Covariate Integration (~2 pages)
   - Synthesis: Three paths compared

5. **Semiparametric Inference (~3 pages)**
   - EIF propagation framework (overview only)
   - Model selection (overview only, details in supplement)

6. **Simulations (~3 pages)**
   - Three core scenarios (homogeneity, parametric dynamics, regime change)
   - One main table (not 5+)
   - Extended results in supplement

7. **Application - Stand-Your-Ground Laws (~3 pages)**
   - Background, estimands, design
   - Validation results
   - Honest failure reporting (all methods underpredict)

8. **Discussion (~2 pages)**
   - Summary, guidance for practice, limitations, extensions

**Total:** ~24-25 pages (achievable target)

**Key innovations:**
- Section 3 elevates estimand definition to co-equal core contribution
- Equal weight to all three identification paths (~2 pages each)
- Integrated related work (not separate subsection)
- Lean inference (proofs and derivations in supplement)

---

### 2. Supplement Structure Created (`inst/paper/supplement-structure.md`)

**Five appendices (~37 pages total):**

**Appendix A: Proofs (~15 pages)**
- A.1: Regularity conditions (2 pages)
- A.2: Proof of Proposition 1 (Path 1) (2 pages)
- A.3: Proof of Proposition 2 (Path 2) (3 pages)
- A.4: Proof of Proposition 3 (Path 3) (3 pages)
- A.5: Proof of Theorem 1 (Asymptotic normality) (4 pages)
- A.6: Additional technical results (1 page)

**Appendix B: EIF Derivations (~5 pages)**
- B.1: General EIF propagation framework (2 pages)
- B.2: EIF for Path 1 (1 page)
- B.3: EIF for Path 2 (1.5 pages)
- B.4: EIF for Path 3 (0.5 pages)

**Appendix C: Model Selection Details (~6 pages)**
- C.1: Time-series cross-validation framework (2 pages)
- C.2: Coverage-based selection (1.5 pages)
- C.3: Post-selection inference (1.5 pages)
- C.4: Implementation details (1 page)

**Appendix D: Extended Simulations (~8 pages)**
- D.1: Full simulation design (all 6 scenarios) (2 pages)
- D.2: Small-sample properties (1.5 pages)
- D.3: Misspecification robustness (2 pages)
- D.4: Longer extrapolation horizons (1.5 pages)
- D.5: Stress tests (constitution §9 compliance) (1 page)

**Appendix E: Application Details (~3 pages)**
- E.1: Data sources and construction (1 page)
- E.2: Estimation details (1 page)
- E.3: Validation metrics and robustness (1 page)

**Content mapping:**
- Current 20-page appendix → Expanded Appendix A + B
- Current Section 5.2 (model selection) details → Appendix C
- Current simulation details → Appendix D (expanded with stress tests)
- Current application → Appendix E (expanded with robustness)

---

## Design Decisions

### What's New
1. **Section 3 (Estimands):** Dedicated ~2.5 page section elevating estimand definition as core contribution
2. **Integrated related work:** Woven into introduction (~1.5 pages), not separate subsection
3. **Equal path weight:** All three paths get ~2 pages each in Section 4
4. **Lean inference:** Section 5 reduced from 4 → 3 pages (high-level only)

### What's Cut from Main Text
1. **FATU and FATS:** Dropped to footnotes (focus on FATT + FATE only)
2. **Forward-looking connections subsection:** Absorbed into Section 3
3. **All proofs:** Moved to Supplement Appendix A
4. **Detailed regularity conditions:** Moved to Supplement A.1
5. **Full EIF derivations:** Moved to Supplement Appendix B
6. **Post-selection inference details:** Moved to Supplement C.3
7. **5+ simulation tables:** Consolidated to 1 main table, rest in Supplement D

### What's Added to Supplement
1. **Appendix C (Model selection):** NEW, expanded from Section 5.2
2. **Appendix D.5 (Stress tests):** NEW for constitution §9 compliance
3. **Appendix E (Application details):** NEW, expanded robustness checks

---

## Page Count Budget

**Main Paper Target:** 20-25 pages

**Outline estimate:** 24-25 pages
- Introduction: 3.5 → tighten to 3
- Identification: 8 → tighten to 7
- Inference: 3.5 → tighten to 3
- **Achievable:** 24-25 pages

**Supplement:** ~37 pages
- Within reasonable bounds for top journals
- Well-organized into 5 logical appendices

---

## Key Changes from Current Paper (46 pages)

**Current structure:**
- 26 pages main text
- 20 pages appendix (proofs)
- 4 estimands (FATT/FATU/FATE/FATS)
- Related work as separate Section 1.1
- Extensive forward-looking connections (3 pages)
- Model selection details in main text (8 pages)

**New lean structure:**
- 24-25 pages main text (cut ~2 pages)
- 37 pages supplement (expanded from 20)
- 2 estimands (FATT + FATE)
- Related work integrated into intro
- Forward-looking connections absorbed into estimands section
- Model selection overview in main, details in supplement

**Net effect:** 46 → ~62 total pages, but main paper trimmed to target length

---

## Verification Against Plan

Plan requirements:
- [x] Core contributions: DUAL (estimands + identification) - both elevated
- [x] Estimands: FATT + FATE only - ✓
- [x] Three paths: All three with equal weight (~2 pages each) - ✓
- [x] Target length: 20-25 pages main - ✓ (24-25 achievable)
- [x] Proofs in supplement - ✓ (Appendix A)
- [x] One simulation table - ✓ (Section 6)
- [x] Dedicated estimands section - ✓ (Section 3, NEW)
- [x] Integrated related work - ✓ (no separate subsection)

---

## Next Steps (For User Review)

**Immediate:**
1. User reviews outline structure and page allocations
2. User confirms dual contribution framing (estimands + identification)
3. User confirms cut content (FATU/FATS dropped, etc.)

**After approval:**
1. Create LaTeX skeleton (`main-lean.tex`)
2. Begin incremental drafting:
   - Start with Introduction (sets tone)
   - Then Identification (Section 4 - core theory)
   - Then Estimands (Section 3 - new section)
   - Then remaining sections

**Quality target:** 90/100 for outline (submission-ready structure)

---

## Open Questions for User

1. **Page budget:** Is 24-25 pages acceptable, or must we hit exactly 20?
   - If must be 20: Need to cut 4-5 more pages
   - Options: Tighten intro (3 → 2.5), reduce identification (7.5 → 6.5), merge simulations + application (3+3 → 5)

2. **FATU/FATS:** Drop entirely or mention in footnote?
   - Current plan: Brief footnote "similar logic for untreated"
   - Alternative: Remove all mention

3. **Three paths balance:** Is ~2 pages each appropriate?
   - Current: Path 1 (2p), Path 2 (2p), Path 3 (2p)
   - Alternative: Focus more on Path 2 + 3 (more novel)?

4. **Application failure reporting:** Keep honest reporting or emphasize successes more?
   - Current plan: All methods underpredict (honest)
   - Alternative: Focus on Path 3 performing best (even if still imperfect)

---

## Quality Self-Assessment

**Outline quality:** 92/100
- Clear structure with logical flow ✓
- Dual contribution properly elevated ✓
- All three paths with equal weight ✓
- Realistic page estimates ✓
- Comprehensive supplement organization ✓
- Minor: Could tighten some subsections by 0.5-1 page each

**Supplement structure quality:** 90/100
- Well-organized into 5 logical appendices ✓
- Content properly mapped from main text ✓
- Stress tests for constitution compliance ✓
- Clear cross-references planned ✓
- Minor: Could specify more proof details in Appendix A

**Overall plan execution:** 91/100
- Met all plan requirements ✓
- Created requested documents ✓
- Detailed section-by-section breakdown ✓
- Ready for user feedback ✓

---

## Session Summary

**Completed:**
1. Created detailed outline (`outline-lean.md`) - 8 sections, 24-25 pages target
2. Created supplement structure (`supplement-structure.md`) - 5 appendices, 37 pages
3. Documented design decisions and content mapping
4. Identified open questions for user review

**Key deliverables:**
- `inst/paper/outline-lean.md` (comprehensive outline with page estimates)
- `inst/paper/supplement-structure.md` (full supplement organization)
- This session log

**Ready for:** User review and feedback on outline structure before proceeding to LaTeX skeleton creation

**Time:** ~45 minutes (reading current paper, creating outlines, documenting)

**Quality:** 91/100 (submission-ready outline, minor refinements possible)

---

## 2026-05-27 Update: LaTeX Skeleton Created

### 3. Created LaTeX Skeleton (`inst/paper/main-lean.tex`)

**Full working document with:**
- Complete preamble and document structure
- All 8 sections with subsection headers
- TODO markers for content to be filled (with page budgets and content notes)
- Abstract placeholder (150-200 words)
- All theorem environments defined
- Bibliography setup

**Section structure:**
1. Introduction (3 pages) - with subsections for tension, dual contribution, methods, related work
2. Setting (2 pages) - panel framework, group-time ATTs, first-stage identification
3. Forward-Looking Estimands (2.5 pages) - NEW section with FATT and FATE definitions
4. Identification (7.5 pages) - general framework + 3 paths (2 pages each) + synthesis
5. Inference (3 pages) - EIF propagation + model selection overview
6. Simulations (3 pages) - design, 3 scenarios, results table, interpretation
7. Application (3 pages) - SYG laws, design, validation results
8. Discussion (2 pages) - summary, guidance, limitations, extensions

**Key features:**
- Each section has TODO comments with:
  - Page budget
  - Detailed content outline
  - What to include/emphasize
- Theorem/proposition statements with proof references to supplement
- Table and equation placeholders
- Integrated related work (4 paragraphs in intro, not separate section)
- Abstract draft with dual contribution emphasis

**Compilation readiness:**
- Uses existing `common-defs.tex` and `typography-preamble.tex`
- Bibliography file: `heterogeneous-policy-effects.bib`
- Should compile to ~25-30 pages with TODO markers
- After content filled: target 24-25 pages

**Next steps:**
- Test compilation to verify structure
- Begin incremental drafting (start with Introduction)
- User can now see full paper structure and navigate sections

**Quality:** 93/100 (working skeleton with clear guidance for drafting)

---

## 2026-05-27 Update 2: High-Priority Alignment with Abstract

### 4. Implemented High-Priority Updates

**User updated abstract with stronger framing. Plan created to align outline. High-priority updates implemented:**

**Changes made:**

1. **Fixed typos in abstract (line 44):**
   - "comented" → "commented"
   - "imtroducing" → "introducing"

2. **Updated Introduction opening (Section 1.1):**
   - **Before:** "There is a fundamental tension at the heart of policy analysis..."
   - **After:** "Policy evaluation is fundamentally future-oriented. A policymaker deciding whether to maintain, repeal, or adopt a policy needs predictions about effects going forward..."
   - **Tone shift:** From abstract tension → concrete policy problem
   - **New emphasis:** "This disconnect...has received surprisingly little attention"
   - **Renamed subsection:** "The Tension Between..." → "The Disconnect Between Estimated and Needed Effects"

3. **Updated dual contribution framing (Section 1.2):**
   - **Added explicit (1) (2) numbering** matching abstract
   - **Changed language:** "We introduce" (not "define" or "formalize") - emphasizes novelty
   - **Added framing:** "data we can analyze (the past)" vs "estimands we care about (the future)"
   - **Renamed subsection:** "Dual Contribution: Estimands and Identification" → "Our Contribution"
   - **Structure:** Two clearly numbered paragraphs, more parallel

4. **Enhanced Section 3.1 (Estimands - Policy Challenge):**
   - **Echo abstract:** Opens with "Policy evaluation is fundamentally future-oriented"
   - **Concrete examples:** Added Medicaid, policing reform, tutoring program examples
   - **Sharper contrast:** "Standard estimands...target what has happened, not what will happen"
   - **More direct:** "What will be the effect going forward?" not abstract philosophical framing

5. **Updated Section 3.4 (Identification Challenge):**
   - **Added temporal framing:** "bridge from the data we can analyze (the past) to the estimands we care about (the future)"
   - **Preview:** Clearer statement of what Section 4 will present

6. **Restructured Section 7.4 (Application):**
   - **Renamed:** "Interpretation" → "Promise and Limits"
   - **Three paragraphs:**
     - **Promise:** What worked (Path 3 best, reasonable uncertainty, captured trends)
     - **Limits:** What failed (systematic underprediction, why)
     - **Lesson:** Honest reporting as strength, not weakness
   - **Balanced framing:** Shows both successes and failures explicitly
   - **Stronger conclusion:** "Transparent reporting...is not a weakness but a feature of credible science"

**Compilation test:** ✓ Success (18 pages, up from 15 - added substantive content)

**Language consistency:**
- "Policy evaluation is fundamentally future-oriented" - now appears in Intro and Section 3.1
- "Data we can analyze (past)" vs "estimands we care about (future)" - now in Sections 1.2, 3.4
- "This disconnect" - used in Introduction
- "Both the promise and limits" - featured in Section 7 title and content

**Quality of updates:** 95/100
- All high-priority changes implemented ✓
- Abstract language echoed throughout ✓
- More assertive about novelty ✓
- Honest reporting framed as strength ✓
- Compilation tested successfully ✓

---

## 2026-06-08: Introduction Edits + Setting Section Drafted

### 5. Introduction Evaluation and Targeted Edits

User ported intro from `main.tex` into `main-lean.tex` with light edits. Evaluated for coherence, citation suitability, and readability. Made 8 targeted edits:

1. Broke long Para 1 sentence into two cleaner sentences
2. "We might call" → "We call this assumption---our label---" (commits to the label)
3. Fixed missing "of": "causal effects of policies"
4. Removed duplicate Sun & Abraham citation from Para 4 opening (retained at end for TWFE bias point)
5. Fixed "and/or" → "or to expand it to jurisdictions where it has not"
6. Removed misaligned Gabler & Cintron citations from "standard practice" claim (they cover cross-unit heterogeneity, not temporal stability)
7. Trimmed Path 3 description in Para 6 from three sentences to one
8. Replaced vague "map cleanly onto these traditions" with explicit per-path mapping (Path 1 → invariance, Path 2 → modeling, Path 3 → reweighting + Lucas)

### 6. LaTeX Compile Fixes

Fixed two blocking errors preventing VS Code / latexmk compilation:

- **Removed `\usepackage{hyperref}`** from preamble — `typography-preamble.tex` loads it with different options, causing option clash
- **Removed 5 duplicate `\newtheorem` declarations** (proposition, theorem, lemma, corollary, remark) — all defined in `common-defs.tex`; kept `\newtheorem{assumption}{Assumption}` which common-defs omits
- **Added `\renewcommand{\P}{\bboardP}`** — `\P` was the LaTeX pilcrow ¶; common-defs uses `\bboardP` for `\mathbb{P}`; renewcommand keeps `\P` as short form in paper source

### 7. Setting and Notation Section (§2) Drafted

**§2.1 Panel Data Framework:**
- Ported formal notation from `main.tex`: units, time, potential outcomes, no interference
- Formal Assumption 1 (No interference) in `assumption` environment
- Full distributional notation: $\cO \sim \P$, $\P_t$, $\P_{p+k}$ with forward reference to §3
- User subsequently integrated staggered adoption notation ($G_i$, treatment irreversibility) into this subsection

**§2.2 Staggered Adoption and Group-Time ATTs:**
- Standard ATT definition (eq. 1)
- Group-time ATT definition (eq. 2) with $G_i$ cohort notation
- TWFE bias motivation
- Closing paragraph drawing hard line between observed ($t \leq p$) and future ($t > p$) — bridges to §3

**§2.3 First-Stage Identification:**
- Explicit scope disclaimer: "This paper does not propose new first-stage designs"
- Examples of qualifying designs (DiD, synthetic control, unconfoundedness)
- Two-step identification framed as a question then answered
- Forward pointer to §4 (three paths differ only in step (b))

### Open Questions / Next Steps

- Forward-Looking Estimands section (§3) — next to draft
- Section labels (sec:identification, sec:path1/2/3) referenced in §2.3 but not yet defined

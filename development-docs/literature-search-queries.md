# Literature Search Queries: SC Inference Methods

**Date:** 2026-03-04
**Purpose:** Actionable search queries to ensure we haven't missed relevant work
**Priority:** HIGH - Do this before claiming novelty in paper

---

## Critical Novelty Check: Has Anyone Done EIF for SC?

### Google Scholar Searches

**Search 1: Direct EIF + SC**
```
"synthetic control" "efficient influence function"
"synthetic control" "influence function" inference
"synthetic control" "semiparametric"
```
**Expected result:** Should be ZERO or very few hits
**If found:** READ IMMEDIATELY - may affect novelty claim

**Search 2: EIF + Panel Data + Causal**
```
"panel data" "efficient influence function" causal
"panel data" "influence function" treatment
"difference-in-differences" "efficient influence function"
```
**Expected result:** DiD papers (Sant'Anna, Callaway) but not SC
**Check:** Do any mention conditioning on Y_pre?

**Search 3: Augmented SC + Theory**
```
"augmented synthetic control" semiparametric
"augmented synthetic control" "influence function"
"augmented synthetic control" "double robustness"
Ben-Michael Feller Rothstein semiparametric
```
**Expected result:** Ben-Michael et al. paper but no follow-ups
**Check:** Has anyone extended their work?

**Search 4: SC + Variance + Theory**
```
"synthetic control" variance "asymptotic theory"
"synthetic control" "standard error" semiparametric
"synthetic control" inference efficient
```
**Expected result:** AAHIW, Ferman & Pinto, others but not EIF
**Check:** Any variance formulas that look like EIF?

### arXiv Searches (stat.ME and econ.EM)

**Recent Papers (2023-2026)**
```
Category: stat.ME, econ.EM
Keywords: synthetic control, inference
Date: 2023-01-01 to 2026-03-04
```
**Check:** Any new inference methods we missed?

**Semiparametric + Causal**
```
Category: stat.ME
Keywords: semiparametric, causal, influence function
Date: 2020-01-01 to 2026-03-04
```
**Check:** Any that apply to SC?

### SSRN Searches

**Economics + SC**
```
"synthetic control" inference
"synthetic control" standard error
Date: 2023-present
```
**Check:** Working papers not yet published?

### Citation Searches

**Forward Citations of Key Papers:**

1. **Ben-Michael et al. (2021) - Augmented SC**
   - Google Scholar: [Search for papers citing this]
   - Filter: 2021-2026
   - **Look for:** Anyone extending to EIF?

2. **Arkhangelsky et al. (2021) - SDID**
   - Google Scholar: [Search for papers citing this]
   - Filter: 2021-2026
   - **Look for:** Improved inference methods?

3. **Lei et al. (2018) - Conformal SC**
   - Google Scholar: [Search for papers citing this]
   - Filter: 2018-2026
   - **Look for:** Alternatives to conformal?

4. **Kennedy (2016, 2022) - Semiparametric theory**
   - Google Scholar: [Search for papers citing this]
   - Filter: Causal inference applications
   - **Look for:** Anyone applying to SC?

**Backward Citations:**
- Check Ben-Michael et al. references for any EIF papers we missed
- Check AAHIW references for asymptotic theory papers

---

## Specific Author Searches

### Check These Authors' Recent Work

**Ben-Michael, Eli (UC Berkeley)**
- Google Scholar profile
- Recent papers (2021-2026)
- **Check:** Follow-ups to augsynth? Theory papers?

**Feller, Avi (UC Berkeley)**
- Focus on causal inference methods
- **Check:** Any new SC work?

**Rothstein, Jesse (UC Berkeley)**
- Applied + methods
- **Check:** Applications of augsynth?

**Arkhangelsky, Dmitry (CEMFI Madrid)**
- Theory focus
- **Check:** SDID extensions or new SC papers?

**Athey, Susan (Stanford)**
- Many SC-related papers
- **Check:** New methods or theory?

**Imbens, Guido (Stanford)**
- Prolific, many SC papers
- **Check:** Recent work on SC inference?

**Wager, Stefan (Stanford)**
- ML + causal inference
- **Check:** ML methods for SC?

**Abadie, Alberto (MIT)**
- Original SC author
- **Check:** Recent papers on inference?

**Kennedy, Edward (CMU)**
- Semiparametric theory expert
- **Check:** Any SC applications?

**Sant'Anna, Pedro (Emory)**
- DR-DiD expert
- **Check:** Any SC work? Panel data + EIF?

**Chernozhukov, Victor (MIT)**
- DML, semiparametric methods
- **Check:** Recent SC papers?

---

## Topic-Specific Searches

### Topic 1: Multiple Treated Units + SC

**Google Scholar:**
```
"synthetic control" "multiple treated units"
"synthetic control" "average treatment effect on treated"
"synthetic control" ATT inference
```
**Goal:** Find papers focusing on multiple treated (not single case study)
**Check:** How do they handle inference?

### Topic 2: High-Dimensional Covariates + SC

**Google Scholar:**
```
"synthetic control" "high-dimensional"
"synthetic control" regularization inference
"synthetic control" "machine learning" inference
```
**Goal:** Papers dealing with T_0 large relative to N
**Check:** Rate conditions, cross-validation, etc.

### Topic 3: Double Robustness + Panel Data

**Google Scholar:**
```
"panel data" "double robustness" causal
"difference-in-differences" "double robustness"
"doubly robust" "panel data" treatment
```
**Goal:** DR methods for panel data (may inspire SC application)
**Check:** Any mention Y_pre as covariates?

### Topic 4: Propensity Score Weighting + SC

**Google Scholar:**
```
"synthetic control" "propensity score"
"synthetic control" weighting inference
"generalized propensity score" "panel data"
```
**Goal:** Papers connecting SC weights to propensity scores
**Check:** Do they derive influence functions?

### Topic 5: Bootstrap for SC

**Google Scholar:**
```
"synthetic control" bootstrap inference
"synthetic control" bootstrap variance
"panel data" bootstrap "treatment effect"
```
**Goal:** Understand state of bootstrap for SC
**Check:** Theory or just applied use?

### Topic 6: Conformal Prediction Beyond Lei et al.

**Google Scholar:**
```
conformal "synthetic control" OR "panel data"
conformal inference "treatment effects"
conformal "time series" causal
```
**Goal:** Extensions of conformal to SC setting
**Check:** Multiple treated units? ATT?

---

## Software & Package Documentation

### R Packages to Check

**1. augsynth (Ben-Michael et al.)**
- GitHub: https://github.com/ebenmichael/augsynth
- Check: Recent commits, issues, pull requests
- Look for: Any mention of EIF, semiparametric, or alternative variance
- Read: Full vignettes and documentation

**2. synthdid (AAHIW)**
- GitHub: https://github.com/synth-inference/synthdid
- Check: Variance estimation methods
- Look for: Theory documentation

**3. Synth (Abadie et al.)**
- CRAN: Check recent updates
- Look for: Any new inference methods

**4. gsynth (Xu)**
- Documentation on Bayesian inference
- Look for: Frequentist alternatives?

**5. Related packages**
- SCtools (visualization + inference)
- microsynth (multiple outcomes)
- tidysynth (tidy interface)
- **Check:** Any new inference implementations?

### Python Packages

**SparseSC**
- Check: Inference methods
- Look for: Theory references

### Stata Packages

**synth, synth_runner**
- Check: Recent updates to inference
- Look for: New options or methods

---

## Conference Proceedings & Working Papers

### Recent Conferences (2023-2026)

**Economics:**
- NBER Summer Institute (Econometrics, Labor, Public, IO)
- AEA Annual Meeting
- European Meeting of Econometric Society

**Statistics:**
- JSM (Joint Statistical Meetings)
- ENAR, WNAR (Biometrics)
- ICML, NeurIPS, AISTATS (ML + causal)

**Search strategy:**
- Conference programs for "synthetic control"
- Session on panel data methods
- Causal inference sessions

### Working Paper Series

**NBER**
- https://www.nber.org/papers
- Search: "synthetic control"
- Filter: 2023-2026

**arXiv**
- Categories: econ.EM, stat.ME
- Already covered above

**SSRN**
- Already covered above

**RePEc**
- https://ideas.repec.org
- Search: "synthetic control inference"

**CEMFI** (Arkhangelsky's institution)
- Working papers

**PIER** (Penn)
- Working papers

---

## Specific Papers to Get and Read

### Priority 1: MUST READ THIS WEEK

1. **Ben-Michael, Feller & Rothstein (2021)** - Full JASA paper
   - **Goal:** Check Section 3-4 for any EIF discussion
   - **Questions:**
     - Do they mention "influence function" anywhere?
     - Do they discuss efficiency?
     - Why did they choose conformal over other methods?
     - Is there supplementary material we're missing?

2. **Arkhangelsky et al. (2021)** - Full AER paper
   - **Goal:** Understand their asymptotic variance approach
   - **Questions:**
     - Do they derive influence function for SDID?
     - Why bootstrap instead of closed-form?
     - Can our EIF approach extend to SDID?

3. **Lei et al. (2018)** - Full paper (arXiv or published version)
   - **Goal:** Understand conformal implementation details
   - **Questions:**
     - How does it extend to multiple treated?
     - What are computational costs?
     - Can we implement for comparison?

### Priority 2: READ DURING THEORY PHASE (Week 1-2)

4. **Kennedy (2016)** - "Semiparametric Theory and Empirical Processes in Causal Inference"
   - Tutorial paper, foundational for our approach

5. **Kennedy (2022)** - "Semiparametric Doubly Robust Targeted Double Machine Learning: A Review"
   - Comprehensive review, connects to ML

6. **Hahn (1998)** - "On the Role of the Propensity Score..."
   - Classic paper on ATT efficiency

7. **Chernozhukov et al. (2018)** - "Double/Debiased Machine Learning..."
   - Rate requirements, cross-fitting

### Priority 3: READ DURING SIMULATION PHASE

8. **Ferman & Pinto (2021)** - "Synthetic Controls with Imperfect Pretreatment Fit"
   - Bias bounds, conservative inference

9. **Cattaneo et al. (2019)** - "Prediction Intervals for Synthetic Control Methods"
   - Alternative prediction interval approach

10. **Firpo & Possebom (2018)** - Placebo inference improvements
    - If it exists, check refinements to ADH

### Priority 4: SKIM / REFERENCE AS NEEDED

11. **Abadie (2021)** - "Using Synthetic Controls..." (JEL survey)
    - Overview of SC landscape

12. **Xu (2017)** - "Generalized Synthetic Control Method"
    - Factor model approach

13. **Doudchenko & Imbens (2016)** - "Balancing, Regression, Difference-in-Differences and Synthetic Control Methods"
    - Unifies SC with other methods

14. **Sant'Anna & Zhao (2020)** - "Doubly Robust Difference-in-Differences Estimators"
    - DR for DiD (comparison to our DR for SC)

---

## Empirical Applications Search

### Search Strategy

**Google Scholar:**
```
"synthetic control" [topic] 2020-2026
Filter: Full text available, data availability statement
```

**Topics to search:**
- Medicaid expansion
- Minimum wage
- School reform
- Education policy
- Health policy
- Environmental regulation
- Tax policy
- Labor market policy

### Criteria for Good Applications

**Must have:**
- Multiple treated units (N_1 ≥ 10)
- Data accessible (public or available upon request)
- Recent publication (2020-2026) with inference reported
- Clear treatment timing

**Nice to have:**
- Variety of N sizes (small: N~50, medium: N~100, large: N~200+)
- Different policy contexts
- Different inference methods used (placebo, conformal, bootstrap)
- Published in top journals (for credibility)

### Specific Application Searches

**Medicaid Expansion:**
```
"synthetic control" "medicaid expansion" "multiple states"
"synthetic control" ACA medicaid
```

**Minimum Wage:**
```
"synthetic control" "minimum wage" cities
"synthetic control" "minimum wage" counties
```

**Education:**
```
"synthetic control" schools reform
"synthetic control" education policy "multiple districts"
```

**Environment:**
```
"synthetic control" environmental regulation
"synthetic control" emissions policy
```

**Other:**
```
"synthetic control" "place-based policy"
"synthetic control" "local policy" multiple
```

---

## Zotero Setup

### Collections to Create

1. **SC_Foundation** (Abadie et al., original papers)
2. **SC_Inference** (Lei, Ben-Michael, AAHIW, etc.)
3. **Semiparametric_Theory** (Kennedy, Hahn, Chernozhukov, etc.)
4. **DiD_Related** (Sant'Anna, Callaway, etc.)
5. **Applications** (Empirical papers to replicate)
6. **To_Read** (Papers to read but not yet critical)
7. **Background** (General causal inference references)

### Tags to Use

- `must-cite` (Tier 1 papers)
- `theory` (Semiparametric theory papers)
- `methods` (SC methods papers)
- `applications` (Empirical papers)
- `replicate` (Applications we'll replicate)
- `comparison` (Papers with methods we'll compare to)
- `read-priority-1` / `read-priority-2` / `read-priority-3`

### Export Settings

- BibTeX export with:
  - Preserve capitalization in titles
  - Include abstract (for reference)
  - Include DOI/URL
  - Keep keywords

---

## Search Schedule (Week-by-Week)

### Week 1: Novelty Check (URGENT)

**Monday:**
- [ ] Google Scholar: EIF + SC (all combinations)
- [ ] arXiv: Recent SC papers (2023-2026)
- [ ] Check Ben-Michael et al. citations (forward)

**Tuesday:**
- [ ] Author searches (Ben-Michael, Arkhangelsky, Kennedy, Sant'Anna)
- [ ] GitHub: Check augsynth, synthdid recent activity

**Wednesday:**
- [ ] Read Ben-Michael et al. (2021) full paper
- [ ] Note any EIF mentions or related theory

**Thursday:**
- [ ] Read Arkhangelsky et al. (2021) full paper
- [ ] Note variance estimation approach

**Friday:**
- [ ] Compile novelty check results
- [ ] Update positioning based on findings
- [ ] Decide if novelty claim is valid

### Week 2: Theory Reading

**Focus:** Kennedy (2016, 2022), Hahn (1998), Chernozhukov et al. (2018)

**Monday-Friday:**
- Read one paper per day
- Take detailed notes on EIF derivation methods
- Note any connections to SC

### Week 3-4: SC Literature Deep Dive

**Focus:** Lei et al., Ferman & Pinto, Cattaneo et al., other SC inference papers

**Throughout:**
- Read 2-3 papers per week
- Implement comparison methods as needed
- Update literature review document

### Week 7-8: Applications Search

**Focus:** Find suitable empirical applications

**Monday-Wednesday:**
- Search for applications (Google Scholar, specific topics)
- Filter by criteria (multiple treated, data available, etc.)

**Thursday-Friday:**
- Contact authors for data if needed
- Download and organize data for top candidates

---

## Red Flags to Watch For

### Novelty Threats

1. **"Efficient estimation of synthetic control effects"** - If this title exists, READ IMMEDIATELY
2. **"Influence function for panel data with treatment"** + mentions SC
3. **"Doubly robust synthetic control"** - Could be similar
4. **Ben-Michael et al. follow-up** on theory/inference
5. **Kennedy + SC** - If Kennedy applied his framework to SC

### If Found, What to Do

**If someone has done EIF for SC:**
1. Read paper carefully - is it actually the same?
2. Check date - when was it posted/published?
3. Assess overlap - how similar is their approach?
4. Determine positioning:
   - If very similar but different angle: "Concurrent work"
   - If they did single treated, we do multiple: "Extension"
   - If they did theory but no simulations: "We add empirical validation"
   - If they beat us to it: Reassess project or pivot

**Contact plan:**
- If concurrent work found: May want to reach out for coordination
- Could lead to collaboration or complementary papers

---

## Documentation

### Keep Track Of

1. **Search log:**
   - Date, search terms, database, results found
   - Use spreadsheet or markdown table

2. **Papers identified:**
   - Title, authors, year, venue, status (to read / reading / read)
   - Priority level (1-3)
   - Key findings or notes

3. **Novelty assessment:**
   - Papers that might threaten novelty
   - How we differ or build on them
   - Updated positioning

### Template for Search Log

| Date | Database | Query | Hits | Relevant | Notes |
|------|----------|-------|------|----------|-------|
| 2026-03-04 | Google Scholar | "synthetic control" "efficient influence function" | 0 | 0 | GOOD - confirms novelty |
| 2026-03-04 | arXiv | synthetic control, stat.ME, 2023-2026 | 12 | 2 | Check papers X and Y |
| ... | ... | ... | ... | ... | ... |

---

## Questions to Answer from Literature Search

### Novelty Questions
1. Has anyone derived EIF for SC? (Expected: NO)
2. Has anyone done doubly robust SC inference? (Expected: NO)
3. Does Ben-Michael et al. mention EIF? (Expected: NO)
4. Is there related work in other fields? (Expected: MAYBE)

### Methods Questions
5. How is conformal inference implemented for ATT? (Lei et al., Ben-Michael et al.)
6. What bootstrap methods are used for SC? (AAHIW, others)
7. Are there other variance estimators we should compare to?
8. What do practitioners actually use? (Survey recent applied papers)

### Theory Questions
9. What rate conditions are standard for DML? (Chernozhukov et al.)
10. How is cross-fitting done with panel data?
11. Are there results on efficiency with high-dimensional covariates?
12. What are common regularity conditions for panel data?

### Application Questions
13. Which applications have multiple treated units?
14. Which applications have accessible data?
15. What inference methods are currently used in practice?
16. Are there examples where inference changed conclusions?

---

## Deliverables from Literature Search

### By End of Week 1 (Urgently Needed)
1. **Novelty check results** - Can we claim "first EIF for SC"?
2. **Updated positioning** - How to frame our contribution
3. **Key papers identified** - Ben-Michael et al. read, notes prepared

### By End of Week 2
4. **BibTeX file** - All Tier 1 papers imported to Zotero
5. **Reading notes** - Kennedy, Hahn, Chernozhukov summaries
6. **Theory framework** - Outline of our EIF derivation approach

### By End of Week 4
7. **Complete literature review** - All relevant papers read and summarized
8. **Comparison methods** - Clear understanding of placebo, conformal, bootstrap
9. **Related work section draft** - For paper (4-5 pages)

### By End of Week 8
10. **Applications identified** - 2-3 suitable applications with data
11. **Replication plan** - What we'll do with each application
12. **Simulation design finalized** - Based on literature gaps

---

## Contact When Literature Search Complete

After completing Week 1 novelty check, report:
- Whether EIF for SC exists
- Ben-Michael et al. findings (do they mention EIF?)
- Any threats to novelty
- Updated positioning strategy

**Decision point:** Proceed with full theory development or pivot if needed

---

**PRIORITY: Start with Week 1 novelty check ASAP**

This is the critical path item before investing more time in theory development. We need to confirm no one has published EIF-based inference for SC.

---

## Additional Resources

### Useful Websites

**NBER:** https://www.nber.org
- Summer Institute programs (recent methods papers)

**arXiv:** https://arxiv.org
- econ.EM, stat.ME categories

**SSRN:** https://www.ssrn.com
- Economics research network

**RePEc/IDEAS:** https://ideas.repec.org
- Economics papers, working papers

**Google Scholar:** https://scholar.google.com
- Most comprehensive, but need to filter carefully

### Mailing Lists / Forums

**Econometrics listservs:**
- Methods papers often circulated

**Twitter/X:**
- Follow: @eli_ben_michael, @SusanAthey, @ArkhangelskyDm
- Causal inference community active

**GitHub:**
- augsynth repo: https://github.com/ebenmichael/augsynth
- synthdid repo: https://github.com/synth-inference/synthdid
- Watch for updates, issues, discussions

---

**END OF SEARCH QUERIES DOCUMENT**

**Next action:** Execute Week 1 novelty check searches and report findings.

# Plan: Align Outline with Updated Abstract

**Date:** 2026-05-27
**Context:** User updated abstract with new framing; need to align paper structure and tone
**Goal:** Update outline to match abstract's emphasis and language

---

## Abstract Analysis

### Key Framing Elements

**1. Opening Hook (Stronger than current skeleton):**
> "Policy evaluation is a fundamentally future-oriented endeavor."

**Current skeleton:** Starts with "fundamental tension" (more abstract)
**Abstract version:** Direct and action-oriented - "future-oriented endeavor"

**2. The Disconnect:**
> "This disconnect between what is estimated and what is needed is rarely commented upon."

**Implication:** Paper addresses an under-recognized gap, not just extending existing literature
**Tone:** More assertive about novelty

**3. Dual Contribution (Crystal Clear):**
> "(1) introducing policy-relevant forward-looking estimands (Future ATT and Future ATE), and (2) three identification strategies"

**Note:** "introducing" not "formalizing" or "defining" - emphasizes novelty
**Structure:** Numbered contributions very explicit

**4. Temporal Framing:**
> "extrapolating the data we can analyze (which is in the past) to the estimands we care about (which are in the future)"

**Language:** Simple, direct, policy-relevant
**Metaphor:** Past → Future (use consistently throughout)

**5. Honest Reporting Emphasized:**
> "illustrates both the promise and limits of extrapolation, with all methods underpredicting"

**Implication:** Failure reporting is a feature, not a bug
**Tone:** Transparent about limitations

**6. Software:**
> "Software: R package \texttt{extrapolateATT}"

**Brief, at end** - appropriate weight

---

## Typos to Fix (Minor)

- Line 44: "comented" → "commented"
- Line 44: "imtroducing" → "introducing"

---

## Recommended Outline Updates

### 1. Introduction Opening (Section 1, first 0.5 pages)

**Current approach:**
```
"There is a fundamental tension at the heart of policy analysis..."
```

**Updated approach (match abstract):**
```
"Policy evaluation is fundamentally future-oriented. Policymakers deciding whether to
maintain, repeal, or adopt policies need predictions about effects going forward. Yet
standard panel data methods estimate backward-looking aggregates—averages over
already-observed periods. This disconnect between what is estimated and what is needed
has received surprisingly little attention."
```

**Changes:**
- Lead with "future-oriented" (action language)
- Frame as "disconnect between estimated and needed"
- Emphasize this gap is "rarely commented upon" / "surprisingly little attention"
- More assertive about paper's novelty

**Tone shift:** From "tension in the literature" → "practical gap that matters for policy"

---

### 2. Dual Contribution Framing (Section 1.2)

**Current structure:**
```
Contribution 1: Forward-Looking Estimands
Contribution 2: Three Identification Paths
```

**Match abstract numbering explicitly:**
```
Our contribution is twofold:

(1) We **introduce** policy-relevant forward-looking estimands—the Future ATT (FATT)
and Future ATE (FATE)—that formalize what effects policymakers need for decisions.

(2) We present **three identification strategies** for extrapolating from the data we
can analyze (the past) to the estimands we care about (the future).
```

**Changes:**
- Use numbered list (1) (2) explicitly
- Say "introduce" not "define" or "formalize" (emphasizes novelty)
- Use "the data we can analyze (the past)" vs "the estimands we care about (the future)" framing from abstract
- Brief, parallel structure

---

### 3. Section 3 (Estimands) - Enhance Motivation

**Current title:** "Forward-Looking Estimands"
**Keep as is** ✓

**Opening paragraph (Section 3.1) - strengthen:**

**Current draft plan:**
```
"Policy decisions are inherently forward-looking..."
```

**Updated to match abstract:**
```
"Policy evaluation is a fundamentally future-oriented endeavor. A policymaker
considering whether to maintain an existing policy needs to predict: What will the
effect be going forward? A jurisdiction considering adoption needs: What would the
effect be if we implement it now? Standard estimands—such as the ATT averaged over
past periods—target what has already happened, not what will happen."
```

**Changes:**
- Echo abstract's opening line
- More direct policy framing ("what will the effect be going forward?")
- Sharper contrast: "target what has already happened, not what will happen"

---

### 4. Section 4 (Identification) - Temporal Framing

**Add opening paragraph to Section 4.1 (General Framework):**

```
"The challenge: FATT and FATE involve effects at future times t > p, but we only
observe data through period p. To identify forward-looking estimands, we must bridge
from the data we can analyze (the past) to the estimands we care about (the future).
This requires assumptions about what is invariant across time."
```

**Language:** Mirrors abstract's "data we can analyze (past)" vs "estimands we care about (future)"

**Each path subsection (4.2, 4.3, 4.4) should state:**
- What is assumed invariant
- When that assumption is plausible
- What breaks if the assumption fails

---

### 5. Section 7 (Application) - "Promise and Limits" Framing

**Current plan:**
```
"Honest failure reporting: All methods underpredict"
```

**Match abstract's framing:**

**Section 7.3 (Results) - lead with:**
```
"This application illustrates both the promise and limits of temporal extrapolation."
```

**Then:**
- Promise: All three paths produce reasonable predictions, Path 3 performs best
- Limits: Even best-performing path underpredicts by 0.10-0.15
- Interpretation: When validation data reveal assumption violations

**Subsection 7.4 title:**
**Current:** "Interpretation"
**Update:** "Promise and Limits"

**Changes:**
- Frame as "both promise and limits" (from abstract)
- Balance: Show methods work reasonably well AND show where they fail
- Emphasize transparent reporting as strength

---

### 6. Discussion (Section 8) - Reinforce Framing

**Section 8.3 (Limitations) - opening sentence:**

**Current plan:**
```
"Our framework has several limitations..."
```

**Updated:**
```
"As our application demonstrates, extrapolation rests on untestable assumptions about
the future. When these assumptions fail, even sophisticated methods underpredict."
```

**Changes:**
- Connect explicitly to application results
- Frame limitations as inherent to extrapolation problem, not just our methods
- More direct about "untestable assumptions about the future"

---

## Consistent Language Throughout

### Phrases to Use (from abstract)

1. **"Policy evaluation is fundamentally future-oriented"** - Use in intro and estimands section
2. **"Data we can analyze (the past)"** vs **"estimands we care about (the future)"** - Use when introducing identification challenge
3. **"This disconnect"** - Use to describe gap between standard estimands and policy needs
4. **"Rarely commented upon"** - Use to emphasize novelty of recognizing this gap
5. **"Three identification strategies"** - Use instead of "three paths" in high-level framing (can use "paths" in technical sections)
6. **"Both the promise and limits"** - Use in application and discussion

### Phrases to Avoid

1. ~~"Fundamental Promise of Causal Inference"~~ - Abstract doesn't use this; too philosophical
2. ~~"Taking dynamics less/more seriously"~~ - Abstract doesn't use this framing; save for technical sections
3. ~~"Backward-looking vs forward-looking"~~ - Abstract uses "data we can analyze" vs "estimands we care about" (more concrete)

---

## Section-by-Section Updates

### Introduction (Section 1) - 3 pages

**Subsection 1.1 (0.5 pages) - NEW opening:**
- Lead: "Policy evaluation is fundamentally future-oriented"
- Disconnect: Standard methods estimate backward-looking aggregates
- Gap: "This disconnect...is rarely commented upon"
- Stakes: Can't make policy decisions with backward-looking estimates alone

**Subsection 1.2 (1 page) - Dual contribution:**
- Numbered explicitly: (1) introduce estimands, (2) three identification strategies
- Use "data we can analyze (past)" vs "estimands we care about (future)" framing
- Briefly preview each strategy (homogeneity, parametric, covariates)

**Subsection 1.3 (0.5 pages) - Methods:**
- EIF propagation
- Model selection framework
- Software

**Subsection 1.4 (1 page) - Related work:**
- Keep integrated (not separate section)
- Four paragraphs as currently planned
- Emphasize our gap is under-recognized

---

### Setting (Section 2) - 2 pages

**No major changes needed** - technical setup section

**Minor update:** Section 2.3 last sentence:
```
"Our contribution: Given identified θ_gt, when and how can we extrapolate from the
data we can analyze (t ≤ p) to the estimands we care about (t > p)?"
```

---

### Estimands (Section 3) - 2.5 pages

**Section 3.1 opening (0.5 pages):**
- Echo abstract: "Policy evaluation is fundamentally future-oriented"
- Sharper policy framing: "What will effect be going forward?"
- Direct contrast: "Standard estimands target what has happened, not what will happen"

**Section 3.2 (FATT) - no major changes**

**Section 3.3 (FATE) - no major changes**

**Section 3.4 (Challenge) - enhance:**
```
"To identify FATT and FATE, we must bridge from the data we can analyze (the past)
to the estimands we care about (the future). Section 4 presents three identification
strategies that differ in what they assume is invariant."
```

---

### Identification (Section 4) - 7.5 pages

**Section 4.1 (Framework) - add opening:**
```
"The identification challenge: FATT and FATE depend on effects at future times t > p,
but our data only extend through period p. To extrapolate, we need assumptions about
what remains stable as time advances. We present three strategies that differ in what
they assume is invariant."
```

**Sections 4.2, 4.3, 4.4 - minor updates:**
- Each path: State clearly what is invariant
- Each path: When assumption plausible, what breaks if violated
- Use "extrapolation" language consistently

**Section 4.5 (Synthesis) - no major changes**

---

### Inference (Section 5) - 3 pages

**No major changes needed** - methods section

**Minor update:** Section 5.2 (Model selection) - last paragraph:
```
"Selecting the right model is crucial: our application (Section 7) shows that even
with careful selection, extrapolation may fail when assumptions break."
```

---

### Simulations (Section 6) - 3 pages

**Section 6.3 (Interpretation) - enhance conclusion:**
```
"These simulations illustrate a key lesson: no single path dominates. The appropriate
strategy depends on which invariance assumption holds. When uncertain, report results
under multiple paths and assess sensitivity."
```

---

### Application (Section 7) - 3 pages

**Section 7.3 title:**
**Change from:** "Validation Results"
**Change to:** "Results: Promise and Limits"

**Section 7.3 opening:**
```
"This application illustrates both the promise and limits of temporal extrapolation.
Table 7 compares predicted FATT (using only training data through 2015) to observed
effects in validation periods (2016-2022)."
```

**Section 7.3 "Findings" paragraph - reframe:**

**Current plan:** "All three methods underpredict..."
**Updated:**
```
"Promise: All three paths produce reasonable predictions, with Path 3 (covariates)
performing best. Limits: Even Path 3 underpredicts by 0.10-0.15 in later years,
suggesting extrapolation assumptions were violated."
```

**Section 7.4 title:**
**Change from:** "Interpretation"
**Change to:** "Promise and Limits"

**Section 7.4 content - restructure:**

**Paragraph 1: Promise**
```
"The methods succeeded in the following ways: (1) Path 3 came closest to actual effects,
showing covariate-based extrapolation can outperform reduced-form approaches; (2) all
methods provided reasonable uncertainty quantification; (3) temporal trends were
partially captured by Paths 2-3."
```

**Paragraph 2: Limits**
```
"Where extrapolation failed: All methods underpredicted validation-period effects, with
gaps widening over time. Possible reasons: (1) effects accelerated post-2015 faster
than parametric models captured; (2) regime change not fully reflected in baseline
covariates; (3) spillover or feedback effects not modeled."
```

**Paragraph 3: Lesson**
```
"Honest reporting: This application shows that even sophisticated extrapolation methods
rest on untestable assumptions. When validation data are available, they reveal when
assumptions break. In real policy settings, such validation is rarely possible,
underscoring the inherent uncertainty in forward-looking causal inference."
```

---

### Discussion (Section 8) - 2 pages

**Section 8.1 (Summary) - opening:**
```
"Policy evaluation is fundamentally future-oriented, but standard panel methods estimate
backward-looking aggregates. We addressed this disconnect with a dual contribution:
(1) introducing policy-relevant forward-looking estimands (FATT and FATE), and
(2) three identification strategies for extrapolating from observed data to future
effects."
```

**Section 8.3 (Limitations) - opening:**
```
"As our application illustrates, extrapolation rests on untestable assumptions about
the future. All three paths assume some aspect of causal structure remains stable—
whether effects themselves (Path 1), temporal patterns (Path 2), or structural
covariate relationships (Path 3). When these assumptions fail, methods underpredict."
```

**Section 8.3 - add before "Extensions":**
```
"Transparency about limitations: We report application results honestly, including where
methods fail. This aligns with our research constitution's principle: no overselling
results. Limitations are features of the extrapolation problem itself, not merely our
methods."
```

---

## Summary of Key Changes

### Tone Shifts

1. **More assertive about novelty:** "rarely commented upon" vs "tension exists"
2. **More policy-oriented:** "future-oriented endeavor" vs "theoretical tension"
3. **More direct language:** "data we can analyze" vs "backward-looking estimands"
4. **Honest reporting as strength:** "both promise and limits" prominently featured

### Structural Changes

1. **Introduction opening:** Lead with "fundamentally future-oriented"
2. **Dual contribution:** Use explicit numbering (1) (2) matching abstract
3. **Application section 7.4:** Rename "Interpretation" → "Promise and Limits"
4. **Application content:** Balance successes and failures explicitly
5. **Discussion limitations:** Connect explicitly to application results

### Language Consistency

**Use throughout:**
- "Policy evaluation is fundamentally future-oriented"
- "Data we can analyze (past)" vs "estimands we care about (future)"
- "This disconnect" when describing gap
- "Three identification strategies" in high-level text
- "Both the promise and limits" when discussing application

**Avoid:**
- Overly philosophical framing ("Fundamental Promise")
- "Taking dynamics less/more seriously" (save for technical sections)
- Treating limitations as weaknesses (treat as inherent to problem)

---

## Implementation Priority

### Immediate (fix typos):
1. Fix "comented" → "commented" (line 44)
2. Fix "imtroducing" → "introducing" (line 44)

### High priority (major framing):
1. Update Introduction opening (Section 1.1)
2. Update dual contribution framing (Section 1.2)
3. Update Section 3 opening (estimands motivation)
4. Rename and restructure Section 7.4 ("Promise and Limits")

### Medium priority (language consistency):
1. Add "data we analyze (past)" vs "estimands we care about (future)" in Sections 3.4, 4.1
2. Echo "fundamentally future-oriented" in Section 3.1
3. Update Discussion opening to mirror abstract

### Lower priority (polish):
1. Ensure "three identification strategies" used in high-level text
2. Check "both promise and limits" appears in application and discussion
3. Verify no overselling in application interpretation

---

## Verification Checklist

After updates:
- [ ] Abstract language echoed in Introduction opening
- [ ] Dual contribution numbered explicitly (1) (2) in Section 1.2
- [ ] "Data we can analyze / estimands we care about" used in Sections 3.4, 4.1
- [ ] Section 7.4 renamed "Promise and Limits" with balanced content
- [ ] Discussion limitations connect to application results
- [ ] No philosophical "Fundamental Promise" language
- [ ] Honest reporting framed as strength, not weakness
- [ ] Typos fixed

---

## Next Steps

**After plan approval:**
1. Fix typos in abstract
2. Update Introduction opening (Section 1.1)
3. Update dual contribution framing (Section 1.2)
4. Update Section 3.1, 3.4, 4.1 with temporal framing
5. Restructure Section 7.3-7.4 ("Promise and Limits")
6. Update Discussion opening and limitations
7. Verify language consistency throughout

**Quality target:** 92/100 (outline fully aligned with abstract)

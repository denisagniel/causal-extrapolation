# Paper next steps: recommendations

Actionable recommendations for bringing the paper *"What we estimate when we estimate dynamic causal effects in panel data"* to submission-ready state. Take them one at a time in order.

**Location:** `latex/Estimating_policy_effects_in_the_presence_of_heterogeneity/main.tex`

---

## Step 1: Add bibliography and replace placeholders

**Goal:** Every "(cites)" in the manuscript becomes a proper citation.

**Actions:**
- Create a `.bib` file in the same folder as `main.tex` (e.g. `references.bib`).
- Add entries for: recent DiD/staggered-adoption and group-time ATT literature (Callaway & Sant'Anna, Sun & Abraham, de Chaisemartin & D'Haultfœuille, Roth & Sant'Anna, etc.) and transportability/external validity (Pearl, Bareinboim).
- In `main.tex`, add `\bibliographystyle{}` and `\bibliography{references}` (or use biblatex), and replace every "(cites)" with the appropriate `\cite{}` key(s).
- Ensure Related Work (Section 1.1) and Section 5 are fully referenced.

**Done when:** No "(cites)" remains; document compiles with a complete reference list.

---

## Step 2: Fix typo and resolve author note

**Goal:** Clean up in-text issues that would be flagged in review.

**Actions:**
- **Typo:** In the displayed equation for \(\theta_{p+1}\) in Section 5 (around line 198), change `A_ip` to `A_{ip}` so the subscript renders correctly.
- **Author note:** The blue note "Probably need to restrict \(G_i\) to be some function of \(A_i\)..." (after the equation \(\theta_{p+1} = \sum_g \mathbb{P}(G_i=g|A_{ip}=1)\theta_{g\cdot}\)) should either:
  - be turned into a short formal restriction with a one-line justification in the main text, or
  - be moved into a Remark.
  Remove the raw author comment before submission.

**Done when:** Equation is correct and the author note is either formalized or removed.

---

## Step 3: Expand Related Work and Section 5

**Goal:** Related Work is prose; Section 5 describes estimation and gives at least one concrete extrapolation model.

**Actions:**
- **Related Work (Section 1.1):** Rewrite the bullet points into short prose. Tie the paper explicitly to: (a) panel DiD and group-time effects, (b) transportability/external validity, (c) Lucas Critique.
- **Section 5:** Expand so it includes:
  - How \(\gamma\) is estimated (e.g. from \(\theta_{gt}\) for \(t \leq p\)) and under what conditions (e.g. identification of \(\theta_{gt}\)).
  - At least one concrete choice of \(f(g,t;\gamma)\) (e.g. linear in event-time, or additive in \(g\) and \(t\)).
  - Optionally: a sentence or short remark linking to the R package/semiparametric EIF implementation if that is part of the contribution.

**Done when:** Section 1.1 reads as a proper related-work paragraph; Section 5 includes estimation discussion and an example \(f\).

---

## Step 4: Add Abstract and Discussion/Conclusion

**Goal:** Manuscript has standard front and back matter.

**Actions:**
- **Abstract:** Add an abstract (before the first section) that states: the problem (backward-looking vs policy-relevant estimands), the two paths (time homogeneity vs formal extrapolation), and the main identification results in one or two sentences.
- **Discussion/Conclusion:** Add a final section that (a) summarizes the two paths and when each applies, (b) states limitations (e.g. reliance on \(\mathbb{P}_{p+1}\), single future period), (c) briefly mentions directions (e.g. sensitivity, multiple future periods).

**Done when:** Abstract and a closing section are in place and read cleanly.

---

## Step 5: Add simulation or applied example (and optional package link)

**Goal:** At least one numerical illustration so the paper is not purely theoretical.

**Actions:**
- Add either:
  - A **simulation**: e.g. bias of backward-looking ATT for FATT when time homogeneity fails, and/or performance of a simple extrapolation; or
  - An **illustrative application**: one policy where FATT/FATU are estimated under stated assumptions, or where time-homogeneity is tested.
- If the repo’s R package and `sims/` are part of the story: add a short subsection or remark in the paper (e.g. in Section 5 or in a new “Implementation” subsection) that describes the implementation and points to the package/sims.

**Done when:** The paper contains at least one simulation or applied example; if relevant, the package/sims are referenced.

---

## Optional / later

- **Title:** Consider a title that mentions "future" or "forward-looking" so the contribution is clear from the title alone.
- **Figures/tables:** Add a schematic (e.g. timeline: study period vs \(p+1\)) or a table of estimands and assumptions to improve readability.
- **common-defs.tex:** Decide whether to `\include` or `\input` `common-defs.tex` in `main.tex` for consistent notation and theorem environments, or leave the current Macro/GrandMacros setup as-is.

---

*Source: Reviewer-style assessment of the paper (plan).*

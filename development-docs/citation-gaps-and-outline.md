# Citation gaps and outline

This document outlines remaining citation work for the paper *"What we estimate when we estimate dynamic causal effects in panel data"* after adding the relevant citations from `heterogeneous-policy-effects.bib`. Use it to complete Step 1 (bibliography) and to add citations where no suitable bib entry existed.

**Main manuscript:** `latex/Estimating_policy_effects_in_the_presence_of_heterogeneity/main.tex`  
**Bibliography:** `latex/Estimating_policy_effects_in_the_presence_of_heterogeneity/heterogeneous-policy-effects.bib`

---

## 1. What was done

- **Bibliography:** `\usepackage{natbib}`, `\bibliographystyle{plainnat}`, and `\bibliography{heterogeneous-policy-effects}` were added to `main.tex`.
- **All "(cites)" placeholders** in Section 5 were replaced with `\citep{...}` using keys from the bib file.
- **In-text citations** were added in:
  - Introduction (Fundamental Promise, Lucas, recent panel/DiD advances, TWFE bias, external validity, informal practice, formal extrapolation)
  - Related Work (panel data advances, external validity/transportability, Lucas Critique)
  - Section 2 (group-time ATTs, infelicities of single linear model, backward-looking estimands not policy-relevant)
  - Section 4 (literature on ATT/sub-ATTs, parallel trends/DiD, rejection of time homogeneity, group-time effects)
  - Section 5 (explicit/implicit time heterogeneity, TWFE perverse effects, extrapolation, parameterizing time-varying effects)

---

## 2. Remaining citation gaps

Places that still need a citation (no suitable key in the current bib, or optional strengthening).

| Location | Claim | Recommendation |
|----------|--------|----------------|
| **Intro, para 1** | "fundamental and unacknowledged tension" / "causal inference with panel data" | Optional: one broad survey or key reference on causal inference with panel data. **LLM:** Use **Prompt 1** (Section 5). |
| **Section 3** | "we lack any direct knowledge of $\mathbb{P}_{p+1}$"; policy-relevant vs backward-looking estimands | Optional: identification of future or out-of-sample causal effects. **From bib (if you add a sentence):** `khosrowiExtrapolationCausalEffects2019`, `maebaExtrapolationTreatmentEffect2024`. **LLM:** Use **Prompt 3** (Section 5). |
| **Section 4, Remark** | "Assumption has testable implications"; testing equality of time-specific treatment effects | Optional: **From bib:** `perenyiSimplePowerfulTest2025` (test of constant treatment effect over time) if you add a sentence on testing time homogeneity. **LLM:** Use **Prompt 2** (Section 5). |

---

## 3. Bib entries marked "unsure"

These are in `heterogeneous-policy-effects.bib` but were not cited. Use them if they fit the narrative, or leave for other projects.

| Key | Title / topic | Possible use |
|-----|----------------|---------------|
| `211000901CausalFused` | A Causal Fused Lasso for Interpretable HTE Estimation | Related Work if you broaden to "heterogeneous effects estimation methods." |
| `230813026EstimatingEvaluating` | Estimating and Evaluating Counterfactual Prediction Models | Section 5 (extrapolation as prediction) or Section 3 (evaluation of policy-relevant quantities) if the paper discusses external validity or transport. |
| `250817780EfficientInference` | Efficient Inference under Label Shift in Unsupervised Domain Adaptation | Tangential: transporting effects to new populations; not panel/DiD. |
| `besherModelingUSClimate` | Besher et al., Modeling US Climate Policy Uncertainty | Application; only if you add a "policy uncertainty" or applied example. |
| `perenyiSimplePowerfulTest2025` | A Simple and Powerful Test of Vaccine Waning | **Relevant to testing:** Test of constant treatment effect over time. Consider citing in the Remark after Assumption 3.1 (testable implications of strict time homogeneity) if you add a sentence on testing. |
| `pruserTimeVaryingEffectsEconomic2020` | Time-Varying Effects of Economic Policy Uncertainty | Intro: "policy effects change over time" (macro/EPU, not causal identification). |
| `zhengDynamicSyntheticControl2024` | Dynamic Synthetic Control for Auto-Regressive Processes | Related Work if you mention synthetic control or AR settings. |

---

## 4. Missing bib entries (add to Zotero / bib)

The paper next steps and the citation plan recommend adding these; they are not in `heterogeneous-policy-effects.bib` yet.

- **Callaway & Sant'Anna** — Group-time ATT, staggered DiD; seminal for Section 2, Section 4.3, Section 5, and Related Work.
- **de Chaisemartin & D'Haultfœuille** — DiD with heterogeneous treatment effects; Section 5 and Related Work.
- **Roth & Sant'Anna** — Difference-in-differences; Section 5 and Related Work.
- **Pearl and/or Bareinboim** — Transportability, selection diagrams; Related Work (external validity / transportability).

After adding them to the bib file, insert citations at:

- **Callaway & Sant'Anna:** Intro (group-time, recent advances); Section 2 (group-time ATTs); Section 4.3 (rejection of time homogeneity, group-time proposals); Section 5 (explicit/implicit time heterogeneity, TWFE).
- **de Chaisemartin & D'Haultfœuille, Roth & Sant'Anna:** Section 5 (staggered adoption, TWFE); Related Work.
- **Pearl/Bareinboim:** Related Work (transportability of causal effects).

---

## 5. LLM prompts for discovering related citations

Use these prompts to get an LLM to **suggest related papers you might not have found**—not to look up exact references (you can do that yourself). Copy-paste the context plus one prompt. Ask for: **author(s), year, full title, venue, 1–2 sentence rationale**, and **BibTeX** (or full citation) for each suggestion. Encourage the LLM to include less obvious or recent papers, not only the most canonical.

**Context for all prompts:**  
I am writing a paper titled *"What we estimate when we estimate dynamic causal effects in panel data."* It argues that standard backward-looking estimands (e.g., ATT, group-time effects) are often not policy-relevant, introduces future-looking estimands (FATT, FATU, etc.), and discusses identification via time homogeneity or formal extrapolation. It connects to difference-in-differences, staggered adoption, external validity, and the Lucas Critique. I already have citations for Sun & Abraham, Callaway & Sant'Anna, Egami & Hartman, Khosrowi, Maeba, Lucas, and similar. I want **additional** related references I might have missed.

---

**Prompt 1 — Surveys / key references on causal inference with panel data or DiD**  
Suggest 2–4 **survey papers or influential references** on causal inference with panel data and/or difference-in-differences that would fit an introduction saying "recent advances in methods for causal inference with panel data." Include at least one that is a bit off the beaten path (e.g., applied field survey, methodological primer in another discipline). For each: full citation, one-sentence rationale, and BibTeX.

---

**Prompt 2 — Testing parallel trends and testing time homogeneity**  
Suggest 2–4 papers on **testing parallel trends** in DiD and/or **testing whether treatment effects are constant over time** (time homogeneity). My paper notes that strict time homogeneity has testable implications and that we can compare time-specific treatment effects, analogous to assessing parallel trends. Prefer papers that give formal tests or discuss power. For each: full citation, how it fits (parallel trends vs constant effects over time), and BibTeX.

---

**Prompt 3 — Future, out-of-sample, or policy-relevant causal estimands**  
Suggest 2–4 papers on **identification or estimands for future, out-of-sample, or policy-relevant causal effects** (estimands for a new time period or population, not just the study sample). My paper defines future ATT/FATU and discusses connecting observed data to a future distribution. Exclude broad external-validity surveys; focus on formal identification, estimands, or design. Include at least one I might not know from the standard econometrics causal-inference canon. For each: full citation, one-sentence rationale, and BibTeX.

---

**Prompt 4 — Parametric or structural extrapolation of causal effects**  
Suggest 2–4 papers on **parametric or structural models for extrapolating causal effects** to new times or populations (e.g., modeling group-time or dynamic effects with a parametric function, transporting effects across contexts, or using structural assumptions to identify future effects). My paper discusses specifying $\theta_{gt} = f(g,t;\gamma)$ to extrapolate. Include methodological and applied work. For each: full citation, one-sentence rationale, and BibTeX.

---

**Prompt 5 — Lucas Critique and policy evaluation / structural change**  
Suggest 2–4 papers that connect the **Lucas Critique** (or policy invariance / structural change) to **policy evaluation** or causal inference—e.g., when historical effects fail to predict future effects, or how empirical work in macro/policy has responded. I already cite Lucas (1976). I want follow-up or methodological papers that discuss extrapolation, external validity, or "effects that change when policy changes." For each: full citation, one-sentence rationale, and BibTeX.

---

**Prompt 6 — Heterogeneous treatment effects in policy evaluation**  
Suggest 2–4 papers on **heterogeneous treatment effects in policy or program evaluation** (beyond the standard DiD/event-study group-time literature). I am interested in: how policy effects vary by group or context, how that heterogeneity is modeled or aggregated, and how it affects policy relevance. Include work from applied micro, health, or education if relevant. For each: full citation, one-sentence rationale, and BibTeX.

---

**Prompt 7 — External validity, transportability, and selection bias**  
Suggest 2–4 papers on **external validity, transportability, or selection bias** when moving causal conclusions to new populations or settings. My paper discusses when backward-looking estimands do or don’t inform future decisions. I already have Egami & Hartman, Devaux & Egami, Khosrowi, Pearl/Bareinboim-style transportability. Suggest **additional** references—e.g., from statistics, epidemiology, or philosophy of science—that formalize or critique extrapolation. For each: full citation, one-sentence rationale, and BibTeX.

---

## 6. Quick checklist

- [ ] Add missing key references to `heterogeneous-policy-effects.bib` (Callaway & Sant'Anna, de Chaisemartin & D'Haultfœuille, Roth & Sant'Anna, Pearl/Bareinboim).
- [ ] Insert the new keys in `main.tex` at the locations listed in Section 4 above.
- [ ] Optionally add one citation in Intro para 1 (panel data / DiD survey).
- [ ] Optionally cite `perenyiSimplePowerfulTest2025` in the Remark on testable implications (Section 4) if you add a sentence on testing time homogeneity.
- [ ] Run `pdflatex` + `bibtex` + `pdflatex` twice and confirm no "(cites)" remain and the reference list compiles.

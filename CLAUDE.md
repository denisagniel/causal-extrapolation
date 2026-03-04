# CLAUDE.MD -- causal-extrapolation (extrapolateATT)

<!-- Customized for causal-extrapolation project. Research constitution and meta-spec are authoritative.
     Keep this file under ~150 lines — the agent loads it every session. -->

**Project:** causal-extrapolation (extrapolateATT R package)
**Branch:** main
**Type:** Methods / Causal Inference Paper

**Focus:** Semiparametric extrapolation of future average treatment effects (ATTs) using efficient influence functions (EIFs). Temporal extrapolation of group-time ATTs beyond observed periods with uncertainty quantification.

---

## Authority

- **Read before substantive work:** [meta-spec/RESEARCH_CONSTITUTION.md](meta-spec/RESEARCH_CONSTITUTION.md). All outputs (methods, claims, code, writing) must align with the research constitution. If a prompt conflicts with these, follow the constitution and surface the conflict.
- **I/you convention:** In agent-facing guidance in this repo, "I"/"my" = agent, "you"/"your" = human unless the sentence clearly instructs the agent (e.g. "You are a...").

---

## Core Principles

- **Plan first** — enter plan mode before non-trivial tasks; save plans to `quality_reports/plans/` when that folder exists
- **Verify after** — compile/render and confirm output at the end of every task
- **Quality gates** — nothing ships below 80/100 (commit); 90 PR; 95 excellence
- **[LEARN] tags** — when corrected, save `[LEARN:category] wrong → right` to MEMORY.md

---

## Folder Structure

```
causal-extrapolation/
├── CLAUDE.md                 # This file (project-specific agent guidance)
├── MEMORY.md                 # Session-persistent learning
├── README.md                 # Project overview and build instructions
├── .claude/                  # Rules, skills, agents, hooks (from agent-assisted-research-meta)
├── meta-spec/                # Research constitution, background (authoritative)
├── templates/                # Session log, quality report, requirements-spec
├── latex-dotfiles/           # Shared LaTeX style files
├── package/                  # extrapolateATT R package source
├── sims/                     # Simulation suite and demos
├── latex/                    # Paper: "Estimating policy effects in the presence of heterogeneity"
├── development-docs/         # Development notes, paper planning, simulation ideas
├── session_notes/            # Session notes (feed daily notes; see meta-spec/META_PROJECT_NOTES.md)
├── refs/                     # References and literature
└── quality_reports/          # Plans, session logs, merge reports (created as needed)
```

**Session notes:** Updated with session logs (post-plan, incremental, end-of-session); feed daily notes at `$AGENT_ASSISTED_RESEARCH_META_NOTES`. See [meta-spec/META_PROJECT_NOTES.md](meta-spec/META_PROJECT_NOTES.md).

---

## Tools and Conventions

- **R:** Primary language for analysis and reproducibility. Follow `.claude/rules/r-code-conventions.md` (project-specific). Modern R patterns: 7 custom skills (writing-tidyverse-r, metaprogramming-rlang, optimizing-r, designing-oop-r, customizing-vectors-r, developing-packages-r, techdebt-r). R package development: 4 Posit skills (testing-r-packages, cli-r, critical-code-reviewer, quarto-authoring). See `.claude/skills/README.md`.
- **Reproducibility:** Required. If it cannot be reproduced easily, it is not finished (constitution).
- **LaTeX:** Compile with `/compile-latex latex` (uses XeLaTeX). Optional: set `LATEX_DOTFILES` environment variable (e.g., `export LATEX_DOTFILES="$PWD/latex-dotfiles"` or point to external shared style directory). The `/compile-latex` skill prepends this to TEXINPUTS. See [meta-spec/LATEX_SETUP.md](meta-spec/LATEX_SETUP.md).
- **Quarto:** Authoring via `quarto-authoring` skill. Paper slides use Quarto only (no Beamer).

---

## Quality Thresholds

| Score | Gate       | Meaning                |
|-------|------------|------------------------|
| 80    | Commit     | Good enough to save    |
| 90    | PR         | Ready for deployment   |
| 95    | Excellence | Aspirational           |

---

## Skills Quick Reference (Research-Focused)

| Command                  | What It Does                        |
|--------------------------|-------------------------------------|
| `/lit-review [topic]`    | Literature search + synthesis       |
| `/research-ideation [topic]` | Research questions + strategies |
| `/interview-me [topic]`  | Interactive research interview      |
| `/review-paper [file]`   | Manuscript review                   |
| `/data-analysis [dataset]` | End-to-end R analysis            |
| `/simulations [estimator or setting]` | Design and run R simulation study (stress-testing, DGP, review) |
| `/review-r [file]`       | R code quality review               |
| `/devils-advocate`       | Challenge design before committing  |
| `/proofread [file]`      | Grammar/typo/consistency (papers and slides) |
| `/presentation-review [file]` | Multi-agent review of paper slides (visual, proofread, optional substance/TikZ) |
| `/commit [msg]`          | Stage, commit, PR, merge            |

**LaTeX papers:** `/compile-latex` (e.g. `latex` or `main`). **Paper slides:** Quarto only — use `quarto render` in `slides/` or `presentation/` (no Beamer). **Verification:** Invoke the verifier agent before commit or when creating PRs. **Out of scope:** teaching-only workflows (e.g. deploy, create-lecture, beamer-translator) are not in this repo; see eg-claudecode-workflow for lecture/course tooling. Additional skills (e.g. /validate-bib) may exist under .claude/skills/.

---

## Agents and skills in use

**In use:** domain-reviewer (papers, code), verifier (papers, paper slides, code), r-reviewer, proofreader (papers and research presentation slides), grant-reviewer (invoke for grant proposals; no dedicated skill), structure-reviewer (manuscripts and grants), tikz-reviewer (manuscript figures). Optionally slide-auditor (paper slides). **Skills:** `/presentation-review [file]` for paper slides (slide-auditor + proofreader + optional domain-reviewer and tikz-reviewer). For full manuscript review use `/review-paper`; for focused domain or structure review invoke domain-reviewer or structure-reviewer separately. **Out of scope:** teaching-only workflows; see eg-claudecode-workflow for lecture/course tooling.

---

## Project Types

See [meta-spec/PROJECT_TYPES.md](meta-spec/PROJECT_TYPES.md). Templates in `templates/project-types/`:

- **Methods / causal inference** — Top stat/biostat journals; identification, theory, stress-testing, software.
- **Applied statistics** — Applied stats outlets; full paper or partial (e.g., methods + results).
- **Applied (medical/subject)** — Top medical/subject journals; full or partial responsibility.
- **Grant writing** — Aims, significance, approach, budget/timeline, review criteria.

**Preprints:** Methods papers → preprints; applied probably not; partial responsibility definitely not. When posting: paper done (constitution §12 via `templates/project-types/paper-done-checklist.md`) → then `templates/project-types/preprint-checklist.md` and `.claude/rules/preprint-protocol.md`.

---

## Project-Specific Guidance

**R Package (package/):**
- Package name: `extrapolateATT`
- Core workflow: `estimate_group_time_ATT()` → `extrapolate_ATT()` → `integrate_covariates()` → `compute_variance()`
- Temporal models: linear, AR(1), spline (built-ins); custom models via function interface
- EIF propagation through extrapolation models for uncertainty quantification
- Build: `devtools::document("package")`, `devtools::check("package")`, `devtools::load_all("package")`

**Simulations (sims/):**
- Run all: `devtools::load_all("package"); source("sims/run_all.R")`
- Follow constitution §9 simulation invariants: include regimes where method struggles

**LaTeX Paper (latex/Estimating_policy_effects_in_the_presence_of_heterogeneity/):**
- Main file: `main.tex` (currently uses `\documentclass{article}` with local style files)
- Compile via `/compile-latex latex` (uses XeLaTeX: 3 passes + bibtex)
- Current setup: local `common-defs.tex` (708 lines, math definitions) + `typography-preamble.tex` (Charter font, 1in margins)
- **LaTeX style infrastructure available:** `latex-dotfiles/` contains `house-style.tex` (Crimson Pro, 0.75in margins) and `common-defs.tex` (identical to local version)
- **To use shared style:** Set `LATEX_DOTFILES` environment variable to project-root `latex-dotfiles/` or external shared style directory. The `/compile-latex` skill automatically prepends `$LATEX_DOTFILES` to TEXINPUTS. Papers can then use `\input{house-style}` instead of local style files.
- Paper describes semiparametric theory and EIF propagation (Section 5.1 referenced in README)
- **Migration note:** Paper currently uses local style files. To migrate to shared infrastructure: (1) set LATEX_DOTFILES, (2) replace local style inputs with `\input{house-style}` or keep current setup if Charter/1in margins preferred.

**Code-Paper-Package Alignment:**
- Follow `.claude/rules/code-paper-package-alignment.md`
- Ensure package API, simulations, and paper notation/methods are consistent

**Development Docs:**
- `paper-next-steps.md`: Paper development roadmap
- `citation-gaps-and-outline.md`: Literature gaps and paper structure
- `simulation-ideas.md`: Simulation design ideas

---

## Current Project State

- **Meta-spec:** Defines research identity, evidence hierarchy, and non-negotiables. Always in scope.
- **Project type:** Methods/Causal Inference (see [meta-spec/PROJECT_TYPES.md](meta-spec/PROJECT_TYPES.md))
- **Preprint policy:** This is a methods paper → will post preprint. When done: verify via `templates/project-types/paper-done-checklist.md`, then follow `templates/project-types/preprint-checklist.md` and `.claude/rules/preprint-protocol.md`.
- **Session notes:** Updated with session logs (post-plan, incremental, end-of-session); feed daily notes at `$AGENT_ASSISTED_RESEARCH_META_NOTES` (see meta-spec/META_PROJECT_NOTES.md).

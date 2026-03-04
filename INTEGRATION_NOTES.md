# Integration of agent-assisted-research-meta Infrastructure

**Date:** 2026-03-04

This project has been adapted to use the agent-assisted-research-meta workflow infrastructure from `git@code.rand.org:ai-tools1/agent-assisted-research-meta.git`.

## Files Added

### Core Configuration
- **CLAUDE.md** - Project-specific agent guidance (adapted for causal-extrapolation)
- **MEMORY.md** - Session-persistent learning (empty, to be populated)

### Infrastructure Directories
- **.claude/** - Rules, skills, agents, hooks
  - agents/: domain-reviewer, proofreader, verifier, r-reviewer, tikz-reviewer, etc.
  - rules/: session-logging, verification-protocol, r-code-conventions, proof-protocol, quality-gates, etc.
  - skills/: R package development, testing, simulations, LaTeX compilation, code review, etc.
  - hooks/: pre-compact, post-merge, protect-files, log-reminder, notify
  - settings.json: Permission patterns and hook configuration

- **meta-spec/** - Research constitution and meta-specifications
  - RESEARCH_CONSTITUTION.md: Core principles, evidence hierarchy, ethics
  - PROJECT_TYPES.md: Methods, applied stats, medical, grant templates
  - LATEX_SETUP.md: LaTeX compilation configuration
  - META_PROJECT_NOTES.md: Note-taking workflow
  - STARTING_A_PROJECT.md: Project initialization guide

- **templates/** - Session logs, quality reports, requirements specs
  - session-note.md, session-log.md, quality-report.md
  - project-types/: methods-paper-requirements.md, applied-paper-requirements.md, etc.
  - first-run-prompt.md, existing-project-prompt.md

- **latex-dotfiles/** - Shared LaTeX style files
  - house-style.tex: XeLaTeX style with Crimson Pro
  - common-defs.tex: Common definitions

### Project Structure
- **explorations/** - Research sandbox (see .claude/rules/exploration-folder-protocol.md)
- **quality_reports/** - Plans, session logs, merge reports (created, empty)
- **session_notes/** - Session notes (existing, README added)

## Project Configuration

**Project Type:** Methods / Causal Inference Paper

**Focus:** Semiparametric extrapolation of future average treatment effects (ATTs) using efficient influence functions (EIFs)

**Existing Structure Preserved:**
- package/ (extrapolateATT R package)
- sims/ (simulation suite)
- latex/ (paper)
- development-docs/ (paper planning, simulation ideas)
- refs/ (references)

## LaTeX Setup

To use shared LaTeX styles, set the `LATEX_DOTFILES` environment variable:

```bash
export LATEX_DOTFILES=/path/to/latex-dotfiles
```

Or add to project `.env` file. The `/compile-latex` skill will automatically prepend this to TEXINPUTS when set.

## Next Steps

1. **Review CLAUDE.md** - Verify project-specific settings are correct
2. **Review meta-spec/RESEARCH_CONSTITUTION.md** - Understand core principles and standards
3. **Set up LaTeX** - Configure LATEX_DOTFILES if using shared style
4. **Start using skills** - See CLAUDE.md for available research-focused skills
5. **Session logging** - Session notes will be updated with session logs (post-plan, incremental, end-of-session)

## Key Workflows

- **Plan first:** Use plan mode for non-trivial tasks
- **Quality gates:** 80 (commit), 90 (PR), 95 (excellence)
- **Code-paper-package alignment:** Follow .claude/rules/code-paper-package-alignment.md
- **Verification:** Use verifier agent before commits/PRs
- **Preprint protocol:** When ready, use templates/project-types/paper-done-checklist.md and preprint-checklist.md

## References

- Infrastructure repo: git@code.rand.org:ai-tools1/agent-assisted-research-meta.git
- Integration date: 2026-03-04
- Integration aligned /tmp/agent-assisted-research-meta with remote main branch

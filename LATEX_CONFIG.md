# LaTeX Configuration for causal-extrapolation

## Current Setup

The paper in `latex/Estimating_policy_effects_in_the_presence_of_heterogeneity/` currently uses:

- **Document class:** `article` with manual margin settings
- **Fonts:** Charter (via `typography-preamble.tex`)
- **Margins:** 1 inch (via `typography-preamble.tex`)
- **Math definitions:** Local `common-defs.tex` (708 lines)
- **Compilation:** XeLaTeX (3 passes + bibtex via `/compile-latex latex`)

## Available Infrastructure

The `latex-dotfiles/` directory provides:

1. **house-style.tex** - Modern style with:
   - XeLaTeX + fontspec
   - Crimson Pro (main text) + Libertinus Math
   - 0.75 inch margins
   - One-and-half spacing
   - Colored hyperlinks

2. **common-defs.tex** - Mathematical definitions (identical to local version)

## Compilation with `/compile-latex`

The `/compile-latex latex` skill:
- Uses XeLaTeX (not pdflatex)
- Runs 3-pass sequence: xelatex → bibtex → xelatex → xelatex
- Automatically prepends `$LATEX_DOTFILES` to TEXINPUTS when set
- Checks for overfull hboxes, undefined citations, label warnings

## Option 1: Keep Current Setup (No Change)

**No action needed.** The paper works as-is with local style files.

**Pros:**
- Paper already compiles successfully
- Charter font may be preferred
- 1 inch margins are standard

**Cons:**
- Duplicates common-defs.tex (though they're identical)
- Doesn't leverage shared infrastructure

## Option 2: Use Shared Style Infrastructure

### Step 1: Set LATEX_DOTFILES environment variable

In your shell profile (`.zshrc` or `.bashrc`):
```bash
export LATEX_DOTFILES="$HOME/path/to/causal-extrapolation/latex-dotfiles"
```

Or for project-local use only:
```bash
# In project root
export LATEX_DOTFILES="$PWD/latex-dotfiles"
```

### Step 2: Update main.tex

Replace:
```latex
\input{common-defs}
\input{typography-preamble}
```

With:
```latex
\input{house-style}
\input{common-defs}
```

Or keep typography-preamble if you prefer Charter over Crimson Pro.

### Step 3: Remove manual margin settings

If using `house-style.tex`, remove these lines from main.tex:
```latex
\setlength{\topmargin}{-.25in}
\setlength{\oddsidemargin}{-0.4in}
\setlength{\textwidth}{7.2in}
\setlength{\textheight}{9.0in}
```

The `house-style.tex` uses geometry package with 0.75in margins.

### Step 4: Compile

```bash
/compile-latex latex
```

The skill automatically uses `$LATEX_DOTFILES` in TEXINPUTS.

## Recommendation

**For now: Keep current setup** unless you want to standardize on the house style across multiple papers.

The current paper style works well and is already being used. The infrastructure is in place when you need it (e.g., for new papers in this project or standardization across projects).

If you later want to migrate:
1. Test the migration in a git branch
2. Check that all equations, figures, and formatting render correctly with Crimson Pro
3. Verify page count and layout meet journal requirements
4. Merge if satisfied

## Files Reference

- **Paper main file:** `latex/Estimating_policy_effects_in_the_presence_of_heterogeneity/main.tex`
- **Current local styles:**
  - `latex/.../common-defs.tex` (708 lines)
  - `latex/.../typography-preamble.tex` (10 lines)
- **Infrastructure styles:**
  - `latex-dotfiles/house-style.tex` (12 lines)
  - `latex-dotfiles/common-defs.tex` (708 lines, identical to local)
- **Compilation skill:** `.claude/skills/compile-latex/SKILL.md`
- **Setup guide:** `meta-spec/LATEX_SETUP.md`

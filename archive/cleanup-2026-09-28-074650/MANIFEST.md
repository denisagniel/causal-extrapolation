# Cleanup Manifest: 2026-09-28 07:46:50

**Project:** causal-extrapolation (extrapolateATT)
**Archived:** 4 files, 1 directory
**Trigger:** wrapping up the 2026-09-25 session (paper restructuring + Item 2) before
starting a new session; three items of untracked clutter were flagged during that session
and deferred for cleanup until now.

## Summary

- Stray duplicate directory: 1 directory, 2 files
- Temporary files: 1 file
- Empty session-note stub: 1 file

## Detailed Archive

### Stray duplicate directory (1 directory, 2 files)
Moved to: `stray_duplicates/inst-paper-session_logs/`

- `inst/paper/quality_reports/session_logs/README.md` → Byte-identical duplicate of the
  canonical, already-committed, frozen-historical `quality_reports/session_logs/README.md`
  at the project root. Verified via `diff`: zero differences.
- `inst/paper/quality_reports/session_logs/2026-04-08_application-implementation.md` →
  A **stale, incomplete duplicate** of the canonical, already-committed
  `quality_reports/session_logs/2026-04-08_application-implementation.md` at the project
  root. Verified via `diff`: the root version is the fuller, later version (includes Phase
  3/4 verification, the multi-policy comparison exploration, and a full quality-rubric
  breakdown that this copy lacks). Both files are about *this* project's real
  application-implementation session — the earlier assessment that this directory
  "references a different project" was wrong; it references `missing-data-did` only in
  the shared README's diagnosis pointer, not in the content file's subject matter. The
  actual defect is location, not content: this directory was never git-tracked and
  duplicates, incompletely, what already exists correctly at the project root.
- The now-empty parent directory `inst/paper/quality_reports/` was removed (git does not
  track empty directories, so no `git rm` was needed).

**Never touched:** the canonical `quality_reports/session_logs/` at the project root —
already committed, correctly frozen per `.claude/rules/session-logging.md`, left exactly as
is.

### Temporary files (1 file)
Moved to: `temp_files/`

- `Rplots.pdf` (repo root) → Default R graphics-device auto-output file. Zero content
  value; matches the disposable-artifact pattern the project's own `.gitignore` already
  covers for `tests/testthat/Rplots.pdf`, just at a different path. Never git-tracked.

### Empty session-note stub (1 file)
Moved to: `empty_stubs/`

- `session_notes/2026-09-02.md` → Contained only the unfilled `templates/session-note.md`
  placeholder text (`## 10:00 — <stem or short description>`, empty `**Goal.**`/`**What
  happened.**`/`**Next.**` fields) — no session content was ever written into it. Never
  git-tracked. Distinguished from `session_notes/2026-08-25.md`, which has real,
  substantive content and was committed separately rather than archived (see the
  2026-09-28 session note for that commit).

## Recovery

To recover any archived file:
1. Find it in the section above (shows original location).
2. Copy from `archive/cleanup-2026-09-28-074650/<category>/` back to its original path.

```bash
# Example: restore the stray inst/paper/ duplicate (not recommended -- it duplicates
# content already correct at the project root)
cp -r archive/cleanup-2026-09-28-074650/stray_duplicates/inst-paper-session_logs \
      inst/paper/quality_reports/session_logs
```

## Recommendations

- Add `Rplots.pdf` (bare, any location) to `.gitignore` alongside the existing
  `tests/testthat/Rplots.pdf` entry, so this does not recur. Not done in this pass —
  flagged for the next `.gitignore` touch rather than bundled into an unrelated cleanup
  commit.
- No other action needed; `quality_reports/plans/` and `session_notes/` at the project
  root are the correct, actively-used locations and were not touched by this cleanup.

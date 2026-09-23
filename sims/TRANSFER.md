# O2 Cluster Setup for extrapolateATT Simulations

**Sections covered:** Section 4b (real `did::att_gt()` first stage) and Section 7 estimated CATE (`grf::causal_forest`)

Each study now lives in its OWN self-contained directory with a per-study
`slurm/` harness (canonical `setup-cluster-simulations` layout):

- `sims/section4b/`   — Section 4b (real `did::att_gt()` first stage)
- `sims/section7est/` — Section 7 estimated CATE / oracle comparison

The old batch runner in `sims/slurm/` is superseded by these subdirs.

---

## Prerequisites

- O2 account with `short` partition access
- Git access to the `causal-extrapolation` repo from O2
- R packages installed on O2 (see below)

---

## One-time setup on O2

```bash
# SSH to O2
ssh <username>@o2.hms.harvard.edu

# Clone or pull the repo
cd ~/
git clone <your-repo-url> causal-extrapolation
# OR if already cloned:
# cd ~/causal-extrapolation && git pull

cd ~/causal-extrapolation

# Load modules
module load gcc/14.2.0
module load R/4.4.2

# Install the extrapolateATT package
R CMD INSTALL .

# Install required CRAN packages
Rscript -e "install.packages(
  c('did', 'grf', 'optparse', 'tibble', 'dplyr', 'fs', 'data.table'),
  repos = 'https://cloud.r-project.org',
  lib   = Sys.getenv('R_LIBS_USER')
)"
```

---

## Workflow

The harness is identical for both studies; only the study directory differs.
Substitute `sims/section4b` or `sims/section7est` for `<STUDY_DIR>` below, and
run each `slurm/` script from inside its study directory.

### Step 1 — Profile + size locally (a few reps, no SLURM)

Run from the study directory on a login node (fast). This times a handful of
work units, then writes `config/sizing.env` and `config/sizing.json` (which
`submit.sh` reads):

```bash
cd sims/section4b       # or: cd sims/section7est
Rscript slurm/profile_timing.R --n-units 5 --study-dir .
```

If every probe unit returns all-NA estimates, `profile_timing.R` aborts loudly
(no bogus sizing is written) — fix the inputs / package install and re-run.

### Step 2 — Submit the job array

```bash
cd sims/section4b       # or: cd sims/section7est
bash slurm/submit.sh
```

`submit.sh` runs a preflight (checks the `extrapolateATT` package is installed
and at least as new as `DESCRIPTION`), mints a run-id, chunks the array to
respect O2 limits (<=1000 tasks/array, <=10000 queued), records a code hash for
stale-result detection, and writes `MANIFEST.md`. Both studies are independent
and may be submitted simultaneously.

### Step 3 — Monitor progress

```bash
cd sims/section4b       # or: cd sims/section7est
bash slurm/monitor.sh                 # progress, queue state, failed-task scan
bash slurm/monitor.sh --tail-failures # also tail any failed task logs
```

### Step 4 — Combine results

When all task files are present (monitor prints the exact command), assemble the
single home artifact:

```bash
cd sims/section4b       # or: cd sims/section7est
Rscript slurm/combine.R --run-id <RUN_ID> \
  --scratch-dir <SCRATCH_DIR> --study-dir .
```

Output: `sims/<STUDY_DIR>/results/<RUN_ID>.rds`
- section4b: a data.frame with one row per replication (columns include
  `estimate`, `se`, `covered_95`, `covered_90`, `true_fatt`, `error_msg`).
- section7est: a data.frame with FOUR rows per replication (one per arm:
  `path1`, `path2`, `path3_oracle`, `path3_grf`), same columns plus `arm`.

`combine.R` refuses to write a stale or incomplete result unless
`--allow-partial` is passed, and reports how many rows carry an `error_msg`.

### Step 5 — Clean up scratch (optional)

```bash
cd sims/section4b       # or: cd sims/section7est
bash slurm/clean.sh --combined-only   # drop scratch runs already combined to home
```

### Step 6 — Transfer results back

```bash
# From your local machine:
scp <username>@o2.hms.harvard.edu:~/causal-extrapolation/sims/section4b/results/*.rds   sims/section4b/results/
scp <username>@o2.hms.harvard.edu:~/causal-extrapolation/sims/section7est/results/*.rds sims/section7est/results/
```

Or commit from O2 and pull locally:
```bash
# On O2:
git add sims/section4b/results/*.rds sims/section7est/results/*.rds
git commit -m "Add O2 simulation results (1000 reps)"
git push

# Locally:
git pull
```

---

## File structure

```
sims/section4b/                        # (identical layout for sims/section7est/)
├── config/
│   ├── grid.R                         # single source of truth (DGP params, seeds, unit_table)
│   ├── sizing.env                     # written by profile_timing.R (sourced by submit.sh)
│   └── sizing.json                    # human-readable sizing record
├── R/
│   ├── dgp.R                          # pre-computes fixed theta_gt + true FATT
│   ├── estimators.R                   # thin wrapper (estimators live in extrapolateATT)
│   └── run_one.R                      # runs ONE replication (contract per study)
├── slurm/
│   ├── run_replication.R              # runs ONE array task's block of units (crash-safe)
│   ├── profile_timing.R               # local sizing -> config/sizing.{env,json}
│   ├── combine.R                      # aggregate task_*.rds -> results/<run-id>.rds
│   ├── array.slurm                    # SLURM array body (job-name extrap-s4b / extrap-s7est)
│   ├── submit.sh                      # chunked/throttled submission + preflight
│   ├── monitor.sh                     # progress / failed-task detection / log discovery
│   ├── clean.sh                       # remove superseded scratch runs
│   └── purge_failed_tasks.R           # delete failed task files so --resume regenerates them
├── results/                           # final combined artifacts (home)
├── logs/latest -> <scratch>/logs      # symlink to the newest run's logs (created by submit.sh)
└── MANIFEST.md                        # written by submit.sh per run
```

Shared, untouched:
```
sims/scripts/dgp_helpers.R             # shared DGP helpers, sourced by each R/dgp.R
```

---

## SLURM settings

| Setting | Value | Notes |
|---|---|---|
| Partition | `short` | Jobs ≤ 12hr; sizing targets 1–3 hr/task |
| Memory | sized (`--mem`) | From `profile_timing.R` peak × safety; floor 2G |
| Time limit | sized (`--time`) | From per-unit median × reps/job × safety; floor 10 min |
| Array size | ≤ 1000 tasks/array | Chunked into waves if larger |
| Concurrency | `%CONCURRENCY_CAP` | Keeps queued jobs ≤ 10000 |
| Modules | `gcc/14.2.0`, `R/4.4.2` | Standard O2 |

Sizing is computed automatically by `profile_timing.R`; edit its named constants
(`WALL_MIN_HOURS`, `WALL_MAX_HOURS`, `MEM_SAFETY`, …) only if O2 policy changes.

---

## Seed design

Seeding is deterministic and independent of row ordering. Each study's
`config/grid.R` defines:

```
.unit_seed(config_id, rep_id) = BASE_SEED + config_id * SEED_STRIDE + rep_id
BASE_SEED   = 20260803
SEED_STRIDE = 100000
```

| Section | Stream | Seed | Notes |
|---|---|---|---|
| 4b | `add_did_eif` draw | `.unit_seed(config_id, rep_id)` | one stream per replication |
| 7est | gt draw (`add_noise_and_eif`) | `.unit_seed(config_id, rep_id)` | replaces old `7000 + r` |
| 7est | unit-level covariates | `.unit_seed(...) + 500000` | disjoint stream; replaces old `90000 + r` |

The fixed `theta_gt` in each study's `R/dgp.R` is seeded once at `401L`
(section4b) / `701L` (section7est), matching the old batch runners.

---

## Package installation notes

The harness uses `library(extrapolateATT)` (not `devtools::load_all()`), which
requires the package to be installed via `R CMD INSTALL .`. Re-run this after any
code change — `submit.sh`'s preflight will otherwise refuse to launch a stale run:

```bash
module load gcc/14.2.0 R/4.4.2
R CMD INSTALL .
```

---

## Common issues

**`Error in library(extrapolateATT): there is no package called 'extrapolateATT'`**
→ Run `R CMD INSTALL .` from the repo root on O2.

**`Error in library(grf): there is no package called 'grf'`** (section7est)
→ Run the package install snippet in the one-time setup above.

**`profile_timing.R` aborts: "All N probe units produced only NA estimates"**
→ Every replication failed (commonly a missing package or a broken
`sims/scripts/dgp_helpers.R` source path). Fix the cause, then re-run.

**`combine.R` errors "STALE RESULTS"**
→ The study source files changed after the run started. Re-profile and re-submit,
or `clean.sh --run-id <RUN_ID>` and start fresh.

**A few array tasks failed / timed out**
→ `monitor.sh` lists them. Re-running `submit.sh` resumes cheaply (completed
unit partials are skipped). To force regeneration of poisoned task files, use
`Rscript slurm/purge_failed_tasks.R --scratch-dir <SCRATCH_DIR> --apply` then resubmit.

**Scratch directory permission denied**
→ Check that `/n/scratch/users/<first>/<username>/` exists. Create with:
`mkdir -p /n/scratch/users/${USER:0:1}/${USER}/`

---

## Runtime estimates

| Section | Per-replicate | Notes |
|---|---|---|
| 4b (did::att_gt, n≈600) | ~1–2 sec | one arm (Path 2 EIF coverage) |
| 7est (grf, n=500, 500 trees) | ~0.3–0.8 sec | four arms; grf dominates |

`profile_timing.R` measures the true per-unit time on the target machine and
sizes the array accordingly. Both studies fit comfortably in `short` (≤12hr).

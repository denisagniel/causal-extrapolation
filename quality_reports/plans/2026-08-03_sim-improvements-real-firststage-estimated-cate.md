# Simulation Improvements Plan
**Date:** 2026-08-03  
**Scope:** Two targeted improvements to the simulation suite + O2 cluster infrastructure  
**Status:** Approved for implementation

---

## Background

The current simulation suite has two known gaps:

1. **Synthetic first stage** — `add_noise_and_eif()` uses `θ̂_gt = θ_gt + ε` (pure Gaussian noise). The EIF propagation machinery is never exercised against a real asymptotically-linear estimator. This weakens the paper's claim that EIF-based variance is correctly propagated.

2. **Oracle β in Path 3** — `sim_section7_path3_covariates.R` passes the true `τ(x) = α + βx` directly to `integrate_cate()`. The simulation isolates transport logic but does not validate that the method works when the CATE is estimated (the realistic use case).

Both improvements are **additive** (new scripts/functions alongside existing ones). No existing scripts are modified except minor additions at the end of `dgp_helpers.R`, a new Section 4b script, updates to Section 7, and O2 infrastructure files.

---

## Improvement 1: Real First-Stage via `did::att_gt()`

### What changes

**New function `generate_panel_data()` in `dgp_helpers.R`:**  
Generates unit-level staggered panel data from `make_theta_gt()` DGP parameters. Each unit `i` is assigned to a cohort `g` (treatment timing), has outcomes `Y_it = μ_0(i) + D_it · τ_gt + ε_it`, and is observed for all `t ∈ {1, …, p+1}`. Produces a data frame suitable for `did::att_gt()`.

**New function `add_did_eif()` in `dgp_helpers.R`:**  
Replaces `add_noise_and_eif()` for the "real first stage" scenario. Calls `did::att_gt()` on panel data, extracts `inffunc`, and returns a `gt_object` via `as_gt_object()`. Wraps the existing package infrastructure so the simulation exercises the full pipeline.

**New script `sims/scripts/sim_section4b_real_firststage.R`:**  
Mirrors Section 4 (EIF coverage) but uses `add_did_eif()` instead of `add_noise_and_eif()`. Same DGP (linear in event time), same metrics (variance ratio, 95%/90% coverage). Run locally with `n_replicates = 200`; full 1000-rep run on O2.

### DGP design

```
Units:   n_units per cohort (e.g. 200 per cohort × q cohorts = 600 total)
Cohorts: g ∈ {1, …, q}, treated at time g (staggered)
Control: "never-treated" cohort (g = 0 / g = Inf per did convention)
Outcome: Y_it = α_i + τ_gt · D_it + ε_it
         α_i ~ N(0, 1), ε_it ~ N(0, σ_Y)
         τ_gt from make_theta_gt(spec = "linear")
Treatment: D_it = 1(t ≥ g) for unit i in cohort g
did call:  att_gt(yname, tname, idname, gname, data, control_group = "nevertreated")
```

### What this validates

- `did::att_gt()` EIFs (`inffunc`) flow through `as_gt_object()` → `extrapolate_ATT()` → `compute_variance()` with correct variance
- Coverage of the full pipeline matches the oracle (synthetic noise) benchmark
- EIF propagation claim in the paper is empirically supported end-to-end

### Runtime estimate (per replicate)

`did::att_gt()` on ~600 units × 6 periods ≈ 0.5–2 seconds. At 1000 reps: ~15–30 min total. Target: 10 reps/job × 100 jobs on O2 (short partition, 1hr limit each).

---

## Improvement 2: Estimated CATE in Section 7 (Path 3)

### What changes

**Updated `sims/scripts/sim_section7_path3_covariates.R`:**  
Add a fourth arm — **Path 3 (estimated CATE)** — using `grf::causal_forest()`. The oracle arm is retained for comparison. New arm:

1. Fit `grf::causal_forest(X, Y, W)` on unit-level data
2. Get OOB CATE predictions: `tau_hat_u <- predict(forest)$predictions`
3. Get OOB variance estimates for the EIF: `var_hat_u <- predict(forest, estimate.variance = TRUE)$variance.estimates`
4. Pass to `integrate_cate()` exactly as the oracle arm, but with `tau = tau_hat_u` instead of oracle `tau_u`
5. Use `as_cate.causal_forest()` adapter (already in package) to build the `cate` object

Results compare: bias, RMSE, coverage for oracle vs estimated CATE.

### What this validates

- `integrate_cate()` + `as_cate.causal_forest()` pipeline works end-to-end
- Coverage degrades gracefully when CATE is estimated (not oracle): should be near-nominal at large n, slight under-coverage at small n
- Oracle arm serves as efficiency upper bound

### Runtime estimate (per replicate)

`grf::causal_forest()` on n=500 ≈ 0.1–0.5 seconds. At 1000 reps: ~3–8 min. Can run locally for 200 reps; full 1000 on O2 if desired.

---

## O2 Infrastructure

### Strategy

- **Heavy sections** (4b real first-stage, 7 with estimated CATE at 1000 reps) → O2 SLURM array jobs
- **Light sections** (existing 1–6, 7 oracle at 200 reps) → local, unchanged
- **Architecture:** one `run_single_replication.R` per section, SLURM array over replication batches

### Files generated under `sims/slurm/`

```
sims/slurm/
├── run_rep_section4b.R          # CLI wrapper: one batch of reps for Section 4b
├── run_rep_section7_estimated.R # CLI wrapper: one batch of reps for Section 7 estimated
├── run_simulations_section4b.slurm
├── run_simulations_section7est.slurm
├── launch_section4b.sh
├── launch_section7est.sh
├── quick_test.sh                # Smoke test: 1 batch of 2 reps each section
├── check_progress.sh
├── combine_results_section4b.R
├── combine_results_section7est.R
└── README_O2.md
```

### SLURM settings

| Setting | Value | Rationale |
|---|---|---|
| Partition | short | Jobs ≤ 1hr |
| Memory | 8G | did + grf can be memory-hungry |
| Time | 0:45:00 | Conservative for 10 reps/job |
| Array | 1–100 | 100 jobs × 10 reps = 1000 total |
| Modules | gcc/14.2.0, R/4.4.2 | Standard O2 |

### Package installation on O2

```bash
# On O2, after git pull:
module load gcc/14.2.0 R/4.4.2
R CMD INSTALL .   # installs extrapolateATT from repo root
Rscript -e "install.packages(c('did', 'grf', 'optparse'), repos='https://cloud.r-project.org')"
```

---

## Files to create / modify

| File | Action | Notes |
|---|---|---|
| `sims/scripts/dgp_helpers.R` | Append | Add `generate_panel_data()` and `add_did_eif()` |
| `sims/scripts/sim_section4b_real_firststage.R` | Create | New section, mirrors Section 4 |
| `sims/scripts/sim_section7_path3_covariates.R` | Modify | Add Path 3 estimated CATE arm |
| `sims/slurm/run_rep_section4b.R` | Create | CLI runner for Section 4b |
| `sims/slurm/run_rep_section7est.R` | Create | CLI runner for Section 7 estimated arm |
| `sims/slurm/run_simulations_section4b.slurm` | Create | SLURM array |
| `sims/slurm/run_simulations_section7est.slurm` | Create | SLURM array |
| `sims/slurm/launch_section4b.sh` | Create | Submit script |
| `sims/slurm/launch_section7est.sh` | Create | Submit script |
| `sims/slurm/quick_test.sh` | Create | Smoke test |
| `sims/slurm/check_progress.sh` | Create | Monitor jobs |
| `sims/slurm/combine_results_section4b.R` | Create | Aggregate batch RDS files |
| `sims/slurm/combine_results_section7est.R` | Create | Aggregate batch RDS files |
| `sims/slurm/README_O2.md` | Create | Deployment docs |
| `sims/run_all.R` | Modify | Source section 4b locally (n_replicates=200) |
| `sims/README.md` | Modify | Document new sections and O2 workflow |

---

## Non-goals

- Do not modify existing Sections 1–6 scripts (leave synthetic first stage intact there; it's fine for those demonstrations)
- Do not change the package R/ code
- Do not remove oracle arm from Section 7 (keep for comparison)
- DoubleML estimated CATE: deferred (grf is sufficient to validate the pipeline; DoubleML can be added later)

---

## Local testing protocol

After implementation:
```r
# Smoke test (n_replicates = 5, runs in ~30 sec)
devtools::load_all(".")
source("sims/scripts/dgp_helpers.R")
n_replicates <- 5
source("sims/scripts/sim_section4b_real_firststage.R")
source("sims/scripts/sim_section7_path3_covariates.R")
```

Then push and test `sims/slurm/quick_test.sh` on O2 before full launch.

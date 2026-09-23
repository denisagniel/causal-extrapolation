# Simulations

Simulations for the causal extrapolation paper. They illustrate backward-looking vs forward-looking estimands, Path 1 (time homogeneity), Path 2 (parametric extrapolation), EIF-based inference, and the role of cohort weights.

## Suggested order (matches development-docs/simulation-ideas.md)

1. **Section 1** — Backward-looking ATT vs FATT: establishes that the target of estimation matters when effects are time-heterogeneous.
2. **Section 2** — Path 1 under time homogeneity vs dynamics: when Path 1 is valid vs biased for the FATT.
3. **Section 3** — Path 2 correct vs misspecified: parametric extrapolation under correct and wrong functional form.
4. **Section 4** — EIF variance and coverage: operating characteristics of the proposed inference (synthetic first stage).
5. **Section 4b** — EIF coverage with **real `did::att_gt()` first stage**: validates EIF propagation end-to-end.
6. **Section 5** — Path 1 vs Path 2 on the same DGP with mild dynamics.
7. **Section 6** — Role of omega_g: FATT depends on cohort composition.
8. **Section 7** — Path 3 (covariate integration) under regime change: oracle and **estimated CATE** (`grf`) arms.

## Running

### Local (all sections, Section 4b at 200 reps)

From the project root:

```r
source("sims/run_all.R")
```

Loads the package, sources DGP helpers, and runs all sections. Section 4b defaults to 200 reps locally; the full 1000-rep version runs on O2. Results written to `sims/results/`.

Optional: create `sims/config/sim_config.R` to override `n_replicates`, `n`, `sigma_tau`, etc.

### Full runs on O2 (Sections 4b + 7 estimated, 1000 reps each)

See **`sims/slurm/README_O2.md`** for complete cluster instructions. Quick summary:

```bash
# On O2, from repo root:
bash sims/slurm/quick_test.sh          # smoke test (2 reps, no SLURM)
bash sims/slurm/launch_section4b.sh    # submit Section 4b array (100 jobs x 10 reps)
bash sims/slurm/launch_section7est.sh  # submit Section 7 estimated array
bash sims/slurm/check_progress.sh      # monitor completion

# After completion:
Rscript sims/slurm/combine_results_section4b.R
Rscript sims/slurm/combine_results_section7est.R
```

## Scripts

| Script | Output | Description |
|--------|--------|-------------|
| `scripts/dgp_helpers.R` | — | Shared DGP: `make_theta_gt`, `true_fatt_from_dgp`, `true_backward_att`, `add_noise_and_eif`, `generate_panel_data`, `add_did_eif`. |
| `scripts/sim_section1_backward_vs_fatt.R` | `section1_backward_vs_fatt.rds`, `section1_plot.png` | True ATT vs FATT over slope grid. |
| `scripts/sim_section2_path1_homogeneity.R` | `section2_path1_homogeneity.rds` | Path 1 under homogeneity (A) and dynamics (B). |
| `scripts/sim_section3_path2_spec.R` | `section3_path2_spec.rds` | Path 2 correct spec, misspec, and quadratic fit. |
| `scripts/sim_section4_eif_coverage.R` | `section4_eif_coverage.rds` | Variance ratio and Wald coverage (synthetic noise first stage). |
| `scripts/sim_section4b_real_firststage.R` | `section4b_real_firststage.rds` | Same as Section 4 but first stage is real `did::att_gt()`. Full pipeline validated. |
| `scripts/sim_section5_path1_vs_path2.R` | `section5_path1_vs_path2.rds` | Path 1 vs Path 2 on same DGP. |
| `scripts/sim_section6_omega.R` | `section6_omega.rds` | Omega sensitivity (correct vs uniform weights). |
| `scripts/sim_section7_path3_covariates.R` | `section7_path3_covariates.rds` | Path 3 under regime change: Paths 1-2 (biased), Path 3a oracle, Path 3b estimated CATE (`grf`). |

## Section 8: Stress Tests and Edge Cases

Section 8 complements Sections 1-7 by showing **where methods fail** (research constitution §9 compliance):

- **Section 8.1** — Non-smooth dynamics: Path 2 fails when true dynamics have breaks.
- **Section 8.2** — Model misspecification.
- **Section 8.3** — Small-sample extrapolation: uncertainty explosion with few observed periods.

```r
source("sims/run_section8.R")
```

## O2 cluster infrastructure

```
sims/slurm/
├── run_rep_section4b.R            # CLI runner for one batch of Section 4b reps
├── run_rep_section7est.R          # CLI runner for one batch of Section 7 estimated reps
├── run_simulations_section4b.slurm
├── run_simulations_section7est.slurm
├── launch_section4b.sh
├── launch_section7est.sh
├── quick_test.sh
├── check_progress.sh
├── combine_results_section4b.R
├── combine_results_section7est.R
└── README_O2.md                   ← full deployment instructions
```

## Demo

`scripts/demo_linear.R` is the original one-shot linear extrapolation demo; not part of the section suite.

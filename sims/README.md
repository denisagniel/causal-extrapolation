# Simulations

Simulations for the causal extrapolation paper. They illustrate backward-looking vs forward-looking estimands, Path 1 (time homogeneity), Path 2 (parametric extrapolation), EIF-based inference, and the role of cohort weights.

## Suggested order (matches development-docs/simulation-ideas.md)

1. **Section 1** — Backward-looking ATT vs FATT: establishes that the target of estimation matters when effects are time-heterogeneous.
2. **Section 2** — Path 1 under time homogeneity vs dynamics: when Path 1 is valid vs biased for the FATT.
3. **Section 3** — Path 2 correct vs misspecified: parametric extrapolation under correct and wrong functional form.
4. **Section 4** — EIF variance and coverage: operating characteristics of the proposed inference.
5. **Section 5** — Path 1 vs Path 2 on the same DGP with mild dynamics.
6. **Section 6** — Role of omega_g: FATT depends on cohort composition.

## Running

From the project root:

```r
source("sims/run_all.R")
```

This loads the package, sources the DGP helpers, and runs sections 1–6 in order. Results are written to `sims/results/`.

Optional: create `sims/config/sim_config.R` to set variables (e.g. `n_replicates`, `n`, `sigma_tau`) used by the section scripts if they read them (currently section scripts use their own defaults).

## Scripts

| Script | Output | Description |
|--------|--------|-------------|
| `scripts/dgp_helpers.R` | — | Shared DGP: `make_theta_gt`, `true_fatt_from_dgp`, `true_backward_att`, `add_noise_and_eif`. |
| `scripts/sim_section1_backward_vs_fatt.R` | `section1_backward_vs_fatt.rds`, `section1_plot.png` | True ATT vs FATT over slope grid. |
| `scripts/sim_section2_path1_homogeneity.R` | `section2_path1_homogeneity.rds` | Path 1 under homogeneity (A) and dynamics (B). |
| `scripts/sim_section3_path2_spec.R` | `section3_path2_spec.rds` | Path 2 correct spec, misspec, and quadratic fit. |
| `scripts/sim_section4_eif_coverage.R` | `section4_eif_coverage.rds` | Variance ratio and Wald coverage. |
| `scripts/sim_section5_path1_vs_path2.R` | `section5_path1_vs_path2.rds` | Path 1 vs Path 2 on same DGP. |
| `scripts/sim_section6_omega.R` | `section6_omega.rds` | Omega sensitivity (correct vs uniform weights). |

## Demo

`scripts/demo_linear.R` is the original one-shot linear extrapolation demo; it is not part of the section suite but can be run separately.

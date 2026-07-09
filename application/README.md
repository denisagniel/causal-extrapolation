# Application: Stand-Your-Ground Laws and Firearm Homicide

Empirical application of the `extrapolateATT` framework: extrapolate the future average
treatment effect on the treated (ATT) of stand-your-ground (SYG) laws on firearm homicide,
and validate against realized 2016–2022 outcomes.

**Design.** Train on 1981–2015 (estimate group-time ATTs, fit extrapolation models),
validate predictions against the realized 2016–2022 group-time ATTs.

## How to run

From the repository root:

```r
Rscript application/run_all.R          # full pipeline (scripts 01–08, excluding 05)
```

or run the numbered scripts in order:

```
application/scripts/
  01_data_prep.R              # aggregate raw data -> analysis_data.rds; SYG cohorts
  02_estimate_gt_atts.R       # did::att_gt -> as_gt_object() (gt_object WITH EIFs)
  03_path1_homogeneity.R      # Path 1: constant effect via path1_aggregate() + EIF SE
  04_path2_model_selection.R  # Path 2: time-series CV -> extrapolate_ATT() + EIF SE
  05_path3_covariate_integration.R   # DEFERRED / superseded (see banner in file)
  06_validation.R             # MSPE / MAE / coverage vs realized 2016–2022
  07_generate_tables.R        # LaTeX tables -> inst/paper/sim_tables/section9_*.tex
  08_create_validation_plot.R # validation figure with 95% EIF-based CIs
```

All scripts assume the working directory is the repository root and load the package via
`devtools::load_all(".")`.

## Reproducibility

- Seed: `set.seed(20260709)` at the top of each script (and `run_all.R` sources them in order).
- Output directories are created with `fs::dir_create()`.
- First-stage ATTs use `did::att_gt(..., bstrap = FALSE, est_method = "dr")`; the influence
  function is extracted via `as_gt_object()` and all downstream standard errors/intervals are
  **EIF-based** (`compute_variance()`), not iid or `predict.lm` SEs.

## Path 3 status (deferred)

Path 3 (direct CATE + covariate transport, `integrate_cate()`) requires, in this
difference-in-differences application, a **conditional DR-DiD transport influence function**.
That score is not yet validated, so `integrate_cate(design = "did")` is gated off in the
package. Script `05` is retained for provenance but is **not** part of the pipeline, and the
Path 3 row in the results tables is marked *pending*.

## Software environment

- R 4.5.1
- `did` 2.3.0, `grf` 2.6.1, `dplyr` 1.2.1, `fs` 1.6.6, `tidyverse`
- Package: `extrapolateATT` (this repository; `devtools::load_all(".")`)

## Data

`application/data/underlying-data_firearm-{homicide,suicide}.csv` — state-year panel
(50 states × 1981–2022 × race strata) with firearm-death counts, population, policy
indicators (incl. `syg`), and state covariates. The homicide file is used for the main
analysis. See the project data-ethics protocol for provenance/consent notes.

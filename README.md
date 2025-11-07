# extrapolateATT: Semiparametric extrapolation of dynamic causal effects

This project contains an R package (`package/`) and a small simulation/demo suite (`sims/`) that implement semiparametric extrapolation of future average treatment effects (ATTs) using efficient influence functions (EIFs).

Workflow overview:
- Estimate group–time ATTs (τ_gt) and EIFs using `did` via `estimate_group_time_ATT()`.
- Specify a temporal extrapolation model h_g(·) (built-ins: linear, AR(1), spline) or provide your own.
- Propagate EIFs through h_g to obtain future τ_{g,p+m} and their EIFs with `extrapolate_ATT()`.
- Optionally integrate conditional effects over a target covariate distribution with `integrate_covariates()`.
- Compute SEs and CIs using `compute_variance()`.

Build instructions:
1. Open R in the repo root.
2. devtools::document(pkg = "package")
3. devtools::check(pkg = "package")
4. devtools::load_all("package")

Run the demo:
```r
devtools::load_all("package")
source("sims/run_all.R")
```

See `vignettes/` for an end-to-end example (to be expanded).


# causal-extrapolation


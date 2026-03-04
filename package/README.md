# extrapolateATT

Semiparametric extrapolation of future average treatment effects (ATTs) using efficient influence functions (EIFs). Temporal extrapolation of group-time ATTs beyond observed periods with uncertainty quantification.

## Overview

The `extrapolateATT` package implements the semiparametric theory and EIF propagation methods described in Section 5.1 of the accompanying paper. It enables researchers to:

1. **Estimate group-time ATTs** from difference-in-differences designs
2. **Extrapolate to future periods** using temporal models (linear, AR(1), spline, custom)
3. **Propagate uncertainty** via influence function chain rule
4. **Integrate over covariates** for covariate-adjusted extrapolation (Path 3)

## Installation

```r
# Install from local source
devtools::install("path/to/extrapolateATT")

# Load package
library(extrapolateATT)
```

## Core Workflow

### Path 1: Temporal Extrapolation

```r
library(did)
data(mpdta)

# Step 1: Estimate group-time ATTs
gt_obj <- estimate_group_time_ATT(
  data = mpdta,
  y = lemp,
  t = year,
  g = first.treat,
  cluster = countyreal
)

# Step 2: Extrapolate to future periods
extrap <- extrapolate_ATT(
  gt_obj,
  h_fun = hg_linear,        # Temporal model
  dh_fun = dh_linear,       # Jacobian
  future_value = 5,         # Extrapolate to k* = 5
  time_scale = "event"      # Event time scale
)

# Step 3: Aggregate across groups (if desired)
overall <- aggregate_future_att(extrap, omega = c(0.5, 0.5))
```

### Path 3: Covariate Integration

```r
# Integrate conditional effects over a target covariate distribution
integrated <- integrate_covariates(
  gt_obj,
  x_target = new_covariate_distribution,  # Target F_X^{p+1}
  x_group = observed_covariate_distributions  # Observed F_X^g
)
```

## Multi-Method First-Stage Support

**New in v0.0.0.9000:** `extrapolateATT` now works with group-time ATT estimates from any first-stage method, not just `did::att_gt()`.

### Supported Methods

| Method | Package | Converter | Status |
|--------|---------|-----------|--------|
| Callaway & Sant'Anna | `did` | `as_gt_object.AGGTEobj()` | ✅ Built-in |
| Sun & Abraham | `fixest` | `as_gt_object.fixest()` | ✅ Built-in |
| Manual format | — | `as_gt_object.data.frame()` | ✅ Built-in |
| Borusyak et al. | `didimputation` | `as_gt_object.did_imputation()` | 📋 Stub (guide to manual) |
| Gardner | `did2s` | `as_gt_object.did2s()` | 📋 Stub (guide to manual) |
| De Chaisemartin & d'Haultfoeuille | `DIDmultiplegt` | `as_gt_object.DIDmultiplegt()` | 📋 Stub (guide to manual) |

### Using Multiple Methods

#### Method 1: Callaway & Sant'Anna (did)

```r
library(did)
data(mpdta)

did_result <- att_gt(
  yname = "lemp",
  gname = "first.treat",
  idname = "countyreal",
  tname = "year",
  data = mpdta,
  bstrap = FALSE  # Needed for EIF extraction
)

# Convert to standardized format
gt_obj <- as_gt_object(did_result)

# Extrapolate
extrap <- extrapolate_ATT(gt_obj, h_fun = hg_linear, ...)
```

#### Method 2: Sun & Abraham (fixest)

```r
library(fixest)

# Estimate with sunab (interaction-weighted)
res <- feols(
  y ~ x + sunab(cohort, year) | unit + year,
  data = your_data
)

# Convert to standardized format
gt_obj <- as_gt_object(res)

# Extrapolate
extrap <- extrapolate_ATT(gt_obj, h_fun = hg_linear, ...)
```

**Note:** fixest doesn't expose influence functions by default, so variance
propagation uses delta method approximation. For exact EIF propagation,
use `did::att_gt()`.

#### Method 3: Custom Estimates (Manual Format)

If you have group-time ATT estimates from any method:

```r
# Your estimates
estimates <- data.frame(
  g = c(2010, 2010, 2011, 2011),
  t = c(2012, 2013, 2012, 2013),
  tau_hat = c(0.5, 0.6, 0.4, 0.5)
)

# Your influence functions (if available)
eif <- list(
  rnorm(100), rnorm(100),  # g=2010
  rnorm(100), rnorm(100)   # g=2011
)

# Convert to gt_object
gt_obj <- as_gt_object(
  estimates,
  phi = eif,  # EIF for exact variance propagation
  n = 100,
  meta = list(source = "My Custom Method")
)

# Extrapolate
extrap <- extrapolate_ATT(gt_obj, h_fun = hg_linear, ...)
```

#### Method 4: Direct Construction

For maximum control:

```r
gt_obj <- new_gt_object(
  data = data.frame(g = c(1, 1), t = c(2, 3), tau_hat = c(0.5, 0.6)),
  phi = list(rnorm(50), rnorm(50)),  # EIF vectors
  n = 50,
  ids = 1:50,  # Optional: unit IDs
  meta = list(source = "Direct Construction")
)
```

### The gt_object Format

The `gt_object` is the standardized internal format used throughout the package:

```r
str(gt_obj)
# List of 8
#  $ data       : tibble [J × 4] with columns g, t, k, tau_hat
#  $ phi        : list [J] of EIF vectors (length n each)
#  $ times      : num [1:T] sorted unique time points
#  $ groups     : num [1:G] sorted unique groups
#  $ event_times: num [1:K] sorted unique event times
#  $ n          : int sample size
#  $ ids        : int [1:n] or NULL
#  $ meta       : list of metadata
```

All downstream functions (`extrapolate_ATT`, `integrate_covariates`, etc.) work with any valid `gt_object`, regardless of its source.

## Extending to New Methods

To add support for a new first-stage method:

1. **Create an S3 method** for `as_gt_object`:

```r
#' @export
as_gt_object.your_class <- function(x, ...) {
  # Extract group-time ATTs
  data <- data.frame(
    g = x$groups,
    t = x$times,
    tau_hat = x$estimates,
    k = x$times - x$groups
  )

  # Extract EIF (if available)
  phi <- extract_eif_from_your_object(x)  # Your extractor

  # Create gt_object
  new_gt_object(
    data = data,
    phi = phi,
    n = nobs(x),
    meta = list(source = "your_package::your_function")
  )
}
```

2. **Use it** like any other method:

```r
your_result <- your_package::your_function(...)
gt_obj <- as_gt_object(your_result)
extrap <- extrapolate_ATT(gt_obj, ...)
```

See `?as_gt_object` and `?new_gt_object` for details.

## Temporal Models

### Built-in Models

| Model | Function | Description |
|-------|----------|-------------|
| Linear | `hg_linear()`, `dh_linear()` | OLS projection |
| AR(1) | `hg_ar1()`, `dh_ar1()` | Autoregressive |
| Spline | `hg_spline()`, `dh_spline()` | Cubic spline |

### Custom Models

Define your own temporal model:

```r
# Exponential decay model
my_h <- function(times, future_value, decay = 0.1) {
  function(tau) {
    # Fit and extrapolate
    mean(tau) * exp(-decay * (future_value - max(times)))
  }
}

my_dh <- function(times, future_value, decay = 0.1) {
  # Jacobian (derivative vector)
  p <- length(times)
  rep(exp(-decay * (future_value - max(times))) / p, p)
}

# Use custom model
extrap <- extrapolate_ATT(
  gt_obj,
  h_fun = my_h,
  dh_fun = my_dh,
  future_value = 5,
  time_scale = "event",
  decay = 0.15  # Custom parameter
)
```

## Uncertainty Quantification

The package propagates uncertainty through extrapolation models via the influence function chain rule:

$$
\phi_{\psi}^i = \sum_{g,t} \frac{\partial \psi(\tau)}{\partial \tau_{gt}} \phi_{gt}^i
$$

### EIF-Based (Exact)

When influence functions are available (e.g., from `did::att_gt`):

```r
gt_obj <- as_gt_object(did_result)  # Extracts EIF
extrap <- extrapolate_ATT(gt_obj, ...)
# Variance computed via: Var(ψ) = (1/n) Σ_i [φ_ψ^i]²
```

### SE-Based (Approximate - Future)

When only standard errors are available:

```r
gt_obj <- as_gt_object(estimates, se = standard_errors, n = 100)
# Future: delta method approximation
```

## Covariate Integration (Path 3)

Integrate conditional effects over a target covariate distribution:

```r
integrated <- integrate_covariates(
  gt_obj,
  x_target = target_distribution,  # F_X^{p+1}
  x_group = list(                  # Observed F_X^g
    g1 = observed_dist_g1,
    g2 = observed_dist_g2
  ),
  h_fun = hg_linear,
  dh_fun = dh_linear,
  future_value = 5
)
```

## Theory

The package implements the semiparametric theory from Section 5.1 of the paper:

- **Estimand:** $\psi(\tau) = h(\tau_{g,1:p})$ where $h$ is a user-specified temporal model
- **EIF propagation:** Chain rule for influence functions
- **Variance:** $\text{Var}(\psi) = \frac{1}{n} \sum_{i=1}^n [\phi_\psi^i]^2$
- **Confidence intervals:** $\psi \pm z_{\alpha/2} \cdot \text{SE}(\psi)$

See the paper for theoretical details and formal results.

## Examples

See `demo/multi_method_demo.R` for a comprehensive demonstration of the multi-method support.

## Development

### Testing

```r
devtools::test()
```

### Package Check

```r
devtools::check()
```

### Building

```r
devtools::document()
devtools::build()
```

## Citation

If you use this package, please cite:

[Citation to be added once paper is finalized]

## License

MIT + file LICENSE

## Contributing

Contributions welcome! To add support for a new first-stage method:

1. Implement `as_gt_object.yourclass()` method
2. Add tests in `tests/testthat/test-from_yourmethod.R`
3. Document with roxygen2 comments
4. Submit a pull request

See `R/from_did.R` for an example implementation.

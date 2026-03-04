# Plan: Expand First-Stage Estimator Support

**Date:** 2026-03-04
**Goal:** Add converters for additional popular DiD estimators
**Status:** DRAFT

---

## Objective

Expand extrapolateATT to support the 4 most popular DiD estimators beyond `did::att_gt`:

1. **fixest::sunab** (Sun & Abraham 2021) ✅ Installed
2. **didimputation** (Borusyak et al. 2021) - Create stub
3. **did2s** (Gardner 2022) - Create stub
4. **DIDmultiplegt** (De Chaisemartin & d'Haultfoeuille 2020) - Create stub

---

## Approach

### Tier 1: Full Implementation (fixest)

**Package:** `fixest` (already installed)
**Method:** Sun & Abraham (2021) - Interaction-weighted estimator

**Key features:**
- Handles staggered adoption with heterogeneous treatment effects
- Returns fixest object with cohort:time interaction coefficients
- Standard errors via vcov
- No built-in EIF extraction (need to construct from vcov)

**Implementation:**
- `as_gt_object.fixest()` - Converter for feols(..., sunab(...))
- Extract coefficients and parse sunab names
- Construct EIF approximation from vcov (delta method)
- Comprehensive tests with mock fixest objects

### Tier 2: Smart Stubs (didimputation, did2s, DIDmultiplegt)

**Purpose:** Helpful error messages that guide users to manual format

**Strategy:**
1. Check if object is from the package
2. Provide informative error with:
   - Brief description of the method
   - Recommend manual format: `as_gt_object.data.frame()`
   - Show example code for extracting estimates
   - Link to documentation
   - Invite contributions

**Example stub:**
```r
as_gt_object.did_imputation <- function(x, ...) {
  stop(
    "Converter for didimputation not yet implemented.\n",
    "The didimputation package (Borusyak et al. 2021) uses imputation-based DiD.\n\n",
    "To use with extrapolateATT:\n",
    "1. Extract group-time estimates from your didimputation object\n",
    "2. Format as data.frame(g = ..., t = ..., tau_hat = ...)\n",
    "3. Use: as_gt_object(your_data, n = sample_size)\n\n",
    "See ?as_gt_object for examples.\n",
    "Contributions welcome! See R/from_did.R for implementation pattern.",
    call. = FALSE
  )
}
```

---

## Implementation: fixest::sunab Converter

### Understanding fixest Output

**sunab() syntax:**
```r
library(fixest)
res <- feols(y ~ x + sunab(cohort_var, time_var) | unit + time, data = df)
```

**Output structure:**
- Class: `fixest`
- Coefficients: Named vector with pattern `"cohort::time::relative_time"`
- Standard errors: via `se(res)` or `vcov(res)`
- Sample size: via `nobs(res)`

**Example coefficient names:**
```
"cohort::2010:time::2012"  # Group 2010, time 2012
"cohort::2010:time::2013"  # Group 2010, time 2013
"cohort::2011:time::2012"  # Group 2011, time 2012
```

### Parsing Strategy

**Challenge:** Coefficient names vary by fixest version and sunab specification

**Solution:** Robust parsing with multiple fallback strategies
1. Try standard pattern: `cohort::(\d+):time::(\d+)`
2. Try alternative patterns: `(\d+):(\d+)`, `t(\d+)\.c(\d+)`, etc.
3. Error if none match (with helpful message)

### EIF Approximation

**Issue:** fixest doesn't expose influence functions directly

**Solution:** Construct approximate EIF from vcov matrix

**Approach:**
1. Extract vcov(res) - variance-covariance matrix
2. Assume asymptotic normality: √n(θ̂ - θ) → N(0, Σ)
3. Construct approximate EIF: φᵢ ≈ score_i (via influence.fixest if available)
4. If influence() not available: warn and create NULL EIF (SE-only mode)

**Code structure:**
```r
# Try to extract influence functions
if (exists("influence.fixest")) {
  infl <- influence(x)
  phi <- as.list(as.data.frame(infl))
} else {
  # Fall back to SE-only
  warning("fixest::influence() not available. Using SE-only mode.")
  phi <- NULL
}
```

### Implementation Plan

**File:** `package/R/from_fixest.R` (new)

**Functions:**
1. `as_gt_object.fixest()` - Main S3 method
2. `parse_sunab_names()` - Extract (g, t) from coefficient names
3. `extract_fixest_eif()` - Get influence functions (if available)

**Validation:**
- Check that sunab was used (has cohort-time interactions)
- Validate coefficient name parsing
- Check dimension consistency

**Tests:** `package/tests/testthat/test-from_fixest.R`
- Mock fixest objects with various coefficient name patterns
- Test parsing with different formats
- Test with/without influence functions
- Test integration with extrapolate_ATT

---

## Files to Create/Modify

### New Files (5)

| File | Purpose | Priority |
|------|---------|----------|
| `R/from_fixest.R` | fixest::sunab converter | HIGH |
| `R/from_didimputation.R` | didimputation stub | MEDIUM |
| `R/from_did2s.R` | did2s stub | MEDIUM |
| `R/from_didmultiplegt.R` | DIDmultiplegt stub | MEDIUM |
| `tests/testthat/test-from_fixest.R` | fixest converter tests | HIGH |

### Modified Files (2)

| File | Change |
|------|--------|
| `package/README.md` | Update supported methods table |
| `package/DESCRIPTION` | Add fixest to Suggests |

---

## Detailed Implementation: fixest Converter

### Step 1: Parse sunab Coefficient Names

```r
parse_sunab_names <- function(coef_names) {
  # Pattern 1: "cohort::2010:time::2012"
  pattern1 <- "cohort::(\\d+):time::(\\d+)"
  matches1 <- regmatches(coef_names, regexec(pattern1, coef_names))

  # Pattern 2: "2010:2012" (simpler format)
  pattern2 <- "^(\\d+):(\\d+)$"
  matches2 <- regmatches(coef_names, regexec(pattern2, coef_names))

  # Pattern 3: Relative time format
  pattern3 <- "cohort::(\\d+):rel_time::([-\\d]+)"
  matches3 <- regmatches(coef_names, regexec(pattern3, coef_names))

  # Extract g and t
  g <- integer(length(coef_names))
  t <- integer(length(coef_names))

  for (i in seq_along(coef_names)) {
    if (length(matches1[[i]]) >= 3) {
      g[i] <- as.integer(matches1[[i]][2])
      t[i] <- as.integer(matches1[[i]][3])
    } else if (length(matches2[[i]]) >= 3) {
      g[i] <- as.integer(matches2[[i]][2])
      t[i] <- as.integer(matches2[[i]][3])
    } else if (length(matches3[[i]]) >= 3) {
      g[i] <- as.integer(matches3[[i]][2])
      rel_time <- as.integer(matches3[[i]][3])
      t[i] <- g[i] + rel_time
    } else {
      stop("Could not parse coefficient name: ", coef_names[i])
    }
  }

  data.frame(g = g, t = t)
}
```

### Step 2: Main Converter

```r
#' @export
as_gt_object.fixest <- function(x, extract_eif = TRUE, ...) {
  # Validate input
  if (!inherits(x, "fixest")) {
    stop("x must be a fixest object from fixest::feols()")
  }

  # Check if sunab was used
  # Look for cohort-time interaction terms in coefficient names
  coef_names <- names(coef(x))
  has_sunab <- any(grepl("cohort|time", coef_names))

  if (!has_sunab) {
    stop(
      "x does not appear to use sunab().\n",
      "Use feols(..., sunab(cohort_var, time_var)) to estimate ",
      "group-time ATTs with fixest."
    )
  }

  # Extract sunab coefficients
  sunab_idx <- grep("cohort.*time|^\\d+:\\d+$", coef_names)
  if (length(sunab_idx) == 0) {
    stop("No sunab coefficients found in fixest object.")
  }

  sunab_coefs <- coef(x)[sunab_idx]
  sunab_names <- names(sunab_coefs)

  # Parse names to get (g, t)
  gt_df <- parse_sunab_names(sunab_names)

  # Create data
  data <- data.frame(
    g = gt_df$g,
    t = gt_df$t,
    k = gt_df$t - gt_df$g,
    tau_hat = as.numeric(sunab_coefs)
  )

  # Extract standard errors
  se_vals <- se(x)[sunab_idx]
  if (!is.null(se_vals)) {
    data$se <- as.numeric(se_vals)
  }

  # Try to extract influence functions
  phi <- NULL
  n <- nobs(x)

  if (extract_eif) {
    phi <- extract_fixest_eif(x, sunab_idx)
    if (is.null(phi)) {
      warning(
        "Could not extract influence functions from fixest object.\n",
        "Variance propagation will use delta method (approximate).\n",
        "For exact EIF propagation, consider using did::att_gt()."
      )
    }
  }

  # Create gt_object
  new_gt_object(
    data = data,
    phi = phi,
    n = n,
    meta = list(
      source = "fixest::sunab",
      fixest_version = as.character(utils::packageVersion("fixest")),
      fixest_object = x
    )
  )
}

extract_fixest_eif <- function(x, sunab_idx) {
  # Try to get influence functions
  # This may not be available in all fixest versions

  tryCatch({
    # Check if influence() method exists
    if (!exists("influence.fixest", mode = "function")) {
      return(NULL)
    }

    # Extract influence function matrix
    infl <- influence(x)

    if (is.null(infl) || !is.matrix(infl)) {
      return(NULL)
    }

    # Select columns for sunab coefficients
    infl_sunab <- infl[, sunab_idx, drop = FALSE]

    # Convert to list of vectors
    phi <- lapply(seq_len(ncol(infl_sunab)), function(j) {
      as.numeric(infl_sunab[, j])
    })

    return(phi)
  }, error = function(e) {
    return(NULL)
  })
}
```

### Step 3: Tests

```r
test_that("as_gt_object.fixest parses sunab names", {
  # Test various coefficient name formats

  # Format 1: cohort::g:time::t
  names1 <- c(
    "cohort::2010:time::2012",
    "cohort::2010:time::2013",
    "cohort::2011:time::2012"
  )

  parsed1 <- parse_sunab_names(names1)
  expect_equal(parsed1$g, c(2010, 2010, 2011))
  expect_equal(parsed1$t, c(2012, 2013, 2012))

  # Format 2: simple g:t
  names2 <- c("2010:2012", "2010:2013")
  parsed2 <- parse_sunab_names(names2)
  expect_equal(parsed2$g, c(2010, 2010))
  expect_equal(parsed2$t, c(2012, 2013))
})

test_that("as_gt_object.fixest works with mock object", {
  # Create mock fixest object
  mock_fixest <- structure(
    list(
      coefficients = c(
        "cohort::2010:time::2012" = 0.5,
        "cohort::2010:time::2013" = 0.6,
        "cohort::2011:time::2012" = 0.4
      ),
      se = c(0.1, 0.12, 0.09),
      nobs = 100,
      vcov = diag(3) * c(0.1, 0.12, 0.09)^2
    ),
    class = c("fixest", "fixest_model")
  )

  # Mock se() and coef() functions
  se <- function(x) x$se
  coef <- function(x) x$coefficients
  nobs <- function(x) x$nobs

  suppressWarnings(
    gt_obj <- as_gt_object(mock_fixest, extract_eif = FALSE)
  )

  expect_s3_class(gt_obj, "gt_object")
  expect_equal(nrow(gt_obj$data), 3)
  expect_equal(gt_obj$data$g, c(2010, 2010, 2011))
  expect_equal(gt_obj$data$t, c(2012, 2013, 2012))
  expect_equal(gt_obj$meta$source, "fixest::sunab")
})
```

---

## Testing Strategy

### Unit Tests
- Coefficient name parsing (various formats)
- Mock fixest objects
- With/without influence functions
- Error handling (non-sunab fixest objects)

### Integration Tests
- fixest → as_gt_object → extrapolate_ATT
- Compare results with did::att_gt (on same data)

### Real Data Tests (manual/skipped)
- Test with actual fixest::sunab output
- Verify coefficient extraction
- Check EIF if available

---

## Implementation Order

1. ✅ **Parse sunab names** - Implement and test parsing logic
2. ✅ **Main converter** - as_gt_object.fixest()
3. ✅ **EIF extraction** - extract_fixest_eif() with fallback
4. ✅ **Tests** - Comprehensive test suite
5. ✅ **Stubs** - Create helpful stubs for other packages
6. ✅ **Documentation** - Update README and roxygen
7. ✅ **Demo** - Add fixest example to demo script

---

## Success Criteria

- ✅ fixest::sunab converter works with mock objects
- ✅ Handles various coefficient name formats
- ✅ Gracefully falls back to SE-only when no EIF
- ✅ Clear error messages for non-sunab fixest objects
- ✅ Comprehensive tests (>90% coverage of new code)
- ✅ Stubs guide users to manual format
- ✅ Documentation updated
- ✅ All existing tests still pass

---

## Expected Effort

| Task | Time | Complexity |
|------|------|------------|
| fixest converter | 2-3 hours | Medium (parsing logic) |
| Tests | 1-2 hours | Low-Medium |
| Stubs | 1 hour | Low |
| Documentation | 1 hour | Low |
| **Total** | **5-7 hours** | |

---

## Next Steps After This

1. **Delta-method variance** (Phase 4.1) - Handle SE-only case better
2. **Vignette** - Create vignette("first-stage-methods")
3. **Community contributions** - Make it easy for others to add methods
4. **Real data validation** - Test with actual empirical applications

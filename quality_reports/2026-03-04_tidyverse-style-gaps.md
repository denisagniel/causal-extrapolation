# Tidyverse Style Gap Analysis: extrapolateATT Package

**Date:** 2026-03-04
**Reference:** `.claude/skills/writing-tidyverse-r/SKILL.md`
**Current Status:** ⚠️ **PARTIALLY COMPLIANT** - Uses base R instead of tidyverse patterns

---

## Executive Summary

The `extrapolateATT` package uses **base R patterns** (lapply, vapply, Map, Reduce) instead of **tidyverse patterns** (map, walk, reduce) specified in the `writing-tidyverse-r` skill.

**Trade-off:**
- **Current approach:** Minimal dependencies (5 imports), stable, standard for R packages
- **Tidyverse approach:** Modern, consistent with analysis scripts, requires purrr import

**Decision needed:** Should package internals follow tidyverse patterns (adding purrr dependency) or maintain base R approach (minimal dependencies)?

---

## Detailed Gap Analysis

### 1. Functional Programming: Base R vs purrr ❌

**Tidyverse skill requires:** `map()`, `map_dbl()`, `walk()` from purrr
**Package currently uses:** `lapply()`, `vapply()`, `Map()`, `Reduce()`

#### Specific Instances

| File | Line | Current | Tidyverse Equivalent |
|------|------|---------|---------------------|
| did_extract_gt.R | 29 | `lapply(seq_len(n), ...)` | `map(seq_len(n), ...)` |
| validators.R | 47 | `vapply(phi, length, integer(1))` | `map_int(phi, length)` |
| extrapolate_ATT.R | 206 | `Map(function(w, phi) ...)` | `map2(omega, phi_g_future, ...)` |
| extrapolate_ATT.R | 206 | `Reduce(\`+\`, ...)` | `reduce(..., \`+\`)` |
| aggregate_groups.R | 50 | `Map()` + `Reduce()` | `map2()` + `reduce()` |

**Example transformation:**

```r
# Current (Base R)
phi <- lapply(seq_len(nrow(data)), function(j) as.numeric(IF[, j]))

# Tidyverse
phi <- map(seq_len(nrow(data)), ~as.numeric(IF[, .x]))
# or with lambda shorthand
phi <- map(seq_len(nrow(data)), \(j) as.numeric(IF[, j]))
```

**Gap severity:** HIGH - Core functional programming patterns don't match skill

---

### 2. For-Loops vs map() ⚠️

**Tidyverse skill says:** "Avoid explicit loops for simple operations", use `map()` or `walk()`
**Package currently uses:** 3 for-loops

#### Locations

| File | Line | Purpose | Could be map? |
|------|------|---------|---------------|
| extrapolate_ATT.R | 167 | Loop over groups, build results list | ✅ Yes - `map()` |
| path1_aggregate.R | 55 | Loop over groups, compute means | ✅ Yes - `map()` |
| utils_numerical.R | 86 | Fill matrix columns | ⚠️ Maybe - performance-critical |

**Example transformation:**

```r
# Current (for-loop)
tau_g_future <- vector("list", length(groups))
phi_g_future <- vector("list", length(groups))
for (k in seq_along(groups)) {
  gk <- groups[k]
  # ... computations ...
  tau_g_future[[k]] <- h_factory(tau_vec)
  phi_g_future[[k]] <- as.numeric(phi_mat %*% dh_vec)
}

# Tidyverse
results <- map(seq_along(groups), \(k) {
  gk <- groups[k]
  # ... computations ...
  list(
    tau = h_factory(tau_vec),
    phi = as.numeric(phi_mat %*% dh_vec)
  )
})
tau_g_future <- map(results, "tau")
phi_g_future <- map(results, "phi")
```

**Gap severity:** MODERATE - Loops work fine, but don't match skill style

---

### 3. String Functions: sprintf() vs str_glue() ⚠️

**Tidyverse skill says:** Use stringr (`str_glue()`) instead of base R (`sprintf()`, `paste()`)
**Package currently uses:** `sprintf()` extensively for error messages

#### Locations

**20+ instances** of `sprintf()` in validators.R, compute_variance.R, extrapolate_ATT.R, etc.

```r
# Current (Base R)
stop(sprintf("%s must be numeric, got %s", name, class(x)[1]), call. = FALSE)

# Tidyverse
stop(str_glue("{name} must be numeric, got {class(x)[1]}"), call. = FALSE)
```

**Also uses:** `paste()` with `collapse` argument

```r
# Current
paste(names(by_g_idx), collapse = ", ")

# Tidyverse
str_c(names(by_g_idx), collapse = ", ")
```

**Gap severity:** LOW - `sprintf()` is standard for error messages, but skill says use stringr

---

### 4. Pipes: Not Used ⚠️

**Tidyverse skill says:** "Always use native pipe `|>` instead of magrittr `%>%`"
**Package currently uses:** No pipes at all

**Example where pipes could help:**

```r
# Current (nested)
result <- tibble::tibble(g = groups, tau_future = as.numeric(unlist(tau_g_future)))

# With pipe (more readable)
result <- tau_g_future |>
  unlist() |>
  as.numeric() |>
  tibble::tibble(g = groups, tau_future = _)
```

**Gap severity:** LOW - Package internals commonly avoid pipes for clarity

---

### 5. Missing Dependencies ❌

**To use tidyverse patterns, need to add:**

```r
# Current DESCRIPTION Imports:
Imports:
    tibble,
    rlang,
    stats,
    numDeriv,
    did

# Would need to add:
Imports:
    tibble,
    rlang,
    stats,
    numDeriv,
    did,
    purrr,      # for map, walk, reduce
    stringr     # for str_glue, str_c
```

**Trade-off:** 2 additional dependencies vs style consistency

---

## Tidyverse Compliance Matrix

| Requirement | Current | Compliant | Gap |
|------------|---------|-----------|-----|
| **Use map() not lapply()** | lapply, Map | ❌ No | purrr not imported |
| **Use map_*() not vapply()** | vapply | ❌ No | purrr not imported |
| **Use reduce() not Reduce()** | Reduce | ❌ No | purrr not imported |
| **Use walk() for side effects** | for-loops | ❌ No | purrr not imported |
| **Use str_glue() not sprintf()** | sprintf | ❌ No | stringr not imported |
| **Use str_c() not paste()** | paste | ❌ No | stringr not imported |
| **Use native pipe \|>** | No pipes | ⚠️ Partial | Could add |
| **snake_case naming** | Yes | ✅ Yes | None |
| **Use tibble** | Yes | ✅ Yes | None |
| **Use rlang for NSE** | Yes | ✅ Yes | None |

**Overall Compliance:** 3/10 ❌

---

## Why This Gap Exists

### R Package Development Philosophy

The current code follows **traditional R package development practices**:

1. **Minimal dependencies:** Base R is always available, purrr is not
2. **Stability:** Base R functions rarely change API
3. **Performance:** No function call overhead from purrr
4. **Ubiquity:** Works in any R environment
5. **CRAN friendly:** Fewer dependencies = easier maintenance

### Tidyverse Analysis Script Philosophy

The `writing-tidyverse-r` skill follows **data analysis script practices**:

1. **Consistency:** Same patterns everywhere (map, str_*, pipes)
2. **Readability:** Modern syntax is clearer
3. **Type safety:** `map_dbl()` always returns double
4. **Composability:** Pipes make workflows clear
5. **Modern:** Latest R ecosystem patterns

**Both are valid!** Choice depends on package goals.

---

## Recommendation Options

### Option A: Maintain Base R (Current) ✅ **RECOMMENDED**

**Rationale:**
- Standard practice for R package internals
- Minimal dependencies (5 imports)
- Stable, well-tested patterns
- Performance-optimized
- CRAN submission ready

**Action:** Document that package internals use base R, analysis code uses tidyverse

**Pros:**
- ✅ Minimal dependencies
- ✅ Maximum stability
- ✅ Standard R package practice
- ✅ No refactoring needed

**Cons:**
- ❌ Inconsistent with analysis scripts
- ❌ Not following tidyverse skill
- ❌ Less modern looking code

---

### Option B: Adopt Tidyverse Patterns

**Rationale:**
- Consistency with `writing-tidyverse-r` skill
- Modern, readable code
- Matches analysis scripts style

**Action:** Refactor to use purrr + stringr patterns

**Changes required:**
1. Add purrr and stringr to DESCRIPTION Imports
2. Replace `lapply()` → `map()` (5 instances)
3. Replace `vapply()` → `map_int()` (1 instance)
4. Replace `Map()` → `map2()` (3 instances)
5. Replace `Reduce()` → `reduce()` (2 instances)
6. Replace `sprintf()` → `str_glue()` (20+ instances)
7. Replace `paste()` → `str_c()` (5+ instances)
8. Convert for-loops to `map()` (2 instances, keep 1 for performance)
9. Consider adding pipes where helpful

**Estimated effort:** 2-3 hours
**Testing required:** Re-run full test suite (197 tests)

**Pros:**
- ✅ Matches tidyverse skill
- ✅ Consistent with analysis code
- ✅ Modern, readable patterns
- ✅ Type-stable functions

**Cons:**
- ❌ 2 additional dependencies
- ❌ Refactoring risk
- ❌ May break existing code
- ❌ Less common for package internals

---

### Option C: Hybrid Approach

**Rationale:**
- Use base R for core algorithms (performance-critical)
- Use tidyverse for user-facing functions
- Document the distinction

**Action:** Selective refactoring

**Pros:**
- ✅ Balance of both approaches
- ✅ Performance where needed
- ✅ Readability where helpful

**Cons:**
- ⚠️ Inconsistent patterns within package
- ⚠️ Harder to maintain two styles

---

## Detailed Refactoring Example

### Example 1: did_extract_gt.R

**Current (Base R):**
```r
phi <- lapply(seq_len(nrow(data)), function(j) as.numeric(IF[, j]))
```

**Tidyverse:**
```r
library(purrr)  # or add to DESCRIPTION Imports
phi <- map(seq_len(nrow(data)), \(j) as.numeric(IF[, j]))
```

**Impact:** Identical behavior, requires purrr

---

### Example 2: validators.R

**Current (Base R):**
```r
lengths <- vapply(phi, length, integer(1))
```

**Tidyverse:**
```r
lengths <- map_int(phi, length)
```

**Benefit:** Shorter, clearer intent (always returns integer vector)

---

### Example 3: aggregate_groups.R

**Current (Base R):**
```r
phi <- Reduce(`+`, Map(function(w, phi_vec) w * phi_vec, omega, eif_list))
```

**Tidyverse:**
```r
phi <- map2(omega, eif_list, \(w, phi_vec) w * phi_vec) |>
  reduce(`+`)
```

**Benefit:** More readable pipeline, clearer steps

---

### Example 4: Error Messages

**Current (Base R):**
```r
stop(sprintf("%s must be numeric, got %s", name, class(x)[1]), call. = FALSE)
```

**Tidyverse:**
```r
stop(str_glue("{name} must be numeric, got {class(x)[1]}"), call. = FALSE)
```

**Benefit:** Clearer template syntax, less error-prone

---

## Testing Impact

If refactoring to tidyverse:

1. **All 197 tests should still pass** (behavior unchanged)
2. **Add dependency checks:**
   ```r
   test_that("purrr is available", {
     expect_true(requireNamespace("purrr", quietly = TRUE))
   })
   ```
3. **Check performance** (purrr has minimal overhead, but measure)
4. **Update documentation** if patterns change

---

## Recommendation Summary

**For extrapolateATT package: Maintain Base R approach (Option A)** ✅

**Rationale:**
1. **Standard practice:** Most CRAN packages use base R internals
2. **Minimal dependencies:** Currently only 5 imports (excellent)
3. **Stability:** Base R APIs don't change
4. **Performance:** No purrr overhead in tight loops
5. **Production ready:** Package already at 88/100 quality

**Clarification needed:**
- `.claude/rules/r-code-conventions.md` says "Prefer tidyverse style"
- `.claude/skills/writing-tidyverse-r` specifies map/purrr patterns
- **BUT** these may be intended for analysis scripts, not package internals

**Suggest:** Update conventions document to clarify:
```markdown
## Tidyverse Style

**For analysis scripts:** Use tidyverse patterns (map, str_*, pipes)
**For package internals:** Base R acceptable for minimal dependencies
**For user-facing package code:** Tidyverse encouraged where helpful
```

---

## Conclusion

The `extrapolateATT` package code is **intentionally using base R patterns** rather than tidyverse patterns. This is:

- ✅ **Standard for R packages** (minimal dependencies)
- ❌ **Inconsistent with tidyverse skill** (which targets analysis code)
- ⚠️ **Ambiguous based on conventions** (says "prefer tidyverse" but may mean scripts)

**No changes recommended** unless you want full tidyverse consistency across all code (scripts + packages), in which case Option B refactoring would take ~2-3 hours.

**Current quality score (88/100) would remain unchanged** - both approaches are high quality, just different philosophies.

**Decision needed:** Clarify whether tidyverse patterns are required for package code or only analysis scripts.

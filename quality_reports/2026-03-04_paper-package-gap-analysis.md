# Paper vs Package Implementation Gap Analysis

## Summary

The package implements the **core FATT estimation** for all three paths with correct EIF propagation. However, several paper features are not yet implemented.

## ✅ Fully Implemented

### Core Estimation (All 3 Paths)
- **Path 1**: Time homogeneity (`path1_aggregate()`)
- **Path 2**: Temporal extrapolation (`extrapolate_ATT()` + `hg_linear`, `hg_quadratic`)
- **Path 3**: Covariate integration (`integrate_covariates()`) ✓ 99.2% coverage
- **EIF propagation**: Full Jacobian-based for all paths
- **Variance estimation**: `compute_variance()` with correct asymptotic inference
- **First-stage support**: `did`, `did2s`, `didimputation`, `didmultiplegt`, `fixest`

## ❌ Missing from Package (Mentioned in Paper)

### 1. Multiple Estimands (Only FATT Implemented)
**Paper defines 4 estimands (lines 125-130):**
- ✅ FATT (Future ATT) - **implemented**
- ❌ FATU (Future ATU) - **not implemented**
- ❌ FATE (Future ATE) - **not implemented**  
- ❌ FATS (Future ATS, similarity-based) - **not implemented**

**Impact**: Medium. FATU/FATE would require conditioning on A_ip=0 or no conditioning. Same methods apply.

**Implementation effort**: ~2-3 hours per estimand (mostly adapting aggregation weights)

---

### 2. Model Selection Framework (Section 5.2)
**Paper provides comprehensive CV framework (~3 pages):**
- Time-series cross-validation with hold-out periods
- MSPE (Mean Squared Prediction Error) metric
- Coverage-based selection criterion
- Model averaging with exponential weights
- 5-step practical workflow

**Package status**: ❌ **Not implemented at all**

**Impact**: HIGH. Section 5.2 is a major paper contribution but completely missing from package.

**Implementation effort**: ~1 week
- `cv_extrapolate()` function for time-series CV
- `select_model()` for MSPE/coverage-based selection
- `model_average()` for weighted averaging
- Tests and documentation

---

### 3. Additional Temporal Models
**Paper mentions (line 270, 299):**
- ✅ Linear - **implemented** (`hg_linear`)
- ✅ Quadratic - **implemented** (`hg_quadratic`)
- ❌ Splines - **mentioned but not implemented**
- ❌ AR(1) / autoregressive - **not mentioned, common choice**
- ❌ Log-linear - **mentioned in workflow**

**Impact**: Medium-Low. Users can define custom models, but built-ins would be convenient.

**Implementation effort**: ~3-4 hours per model

---

### 4. Vignettes
**Package has**: ❌ No vignettes directory

**Paper describes**: Full workflow with examples

**Impact**: Medium. Makes package harder to use for new users.

**Implementation effort**: ~1-2 days
- End-to-end workflow vignette
- Path 3 covariate integration vignette
- Model selection vignette (if implemented)

---

### 5. Documentation Gaps
**Missing:**
- ❌ Path comparison guide (when to use Path 1 vs 2 vs 3)
- ❌ Assumption testing guidance (pre-trends, time homogeneity)
- ❌ Real data example / case study

**Impact**: Low-Medium. These are documentation rather than functionality.

---

## 🔶 Partially Complete

### Custom Temporal Models
**Status**: Interface exists but underdocumented
- ✅ Users CAN define custom `h_fun` / `dh_fun`
- ⚠️ Documentation is brief (package-level docs mention it)
- ❌ No worked example in vignette

---

## Priority Recommendations

### High Priority (For Package Completeness)
1. **Model selection framework** - Major paper contribution, completely missing
2. **FATU estimand** - Second most important estimand for policy
3. **Vignette with end-to-end workflow** - Essential for usability

### Medium Priority (Nice to Have)
4. **Spline temporal model** - Paper mentions it multiple times
5. **FATE estimand** - Useful for population-level policy questions
6. **Model comparison guide** - Help users choose Path 1 vs 2 vs 3

### Low Priority (Future Enhancements)
7. **FATS estimand** - More niche use case
8. **AR(1) model** - Useful for time series but not paper priority
9. **Additional documentation** - Always improvable

---

## Constitution Alignment Check

**§9 Software Invariants:**
- ✅ APIs reflect statistical structure
- ✅ Safe defaults throughout
- ✅ No quiet fallbacks
- ✅ UQ for all estimators
- ✅ Reproducibility
- ✅ Stress testing in simulations

**Verdict**: Core implementation is excellent. Gaps are features, not quality issues.

---

## Bottom Line

**What's working**: All three paths fully implemented with correct inference (Path 3 just achieved 99.2% coverage)

**What's missing**: Ancillary features (multiple estimands, model selection, vignettes) that would make package more complete but aren't blocking for paper publication

**Recommendation**: 
- For **paper submission**: Current package is sufficient (core theory implemented)
- For **CRAN / public release**: Should add at minimum: model selection framework, FATU, and vignettes

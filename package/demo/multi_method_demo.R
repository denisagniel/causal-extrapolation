# Demo: Multi-Method First-Stage Support for extrapolateATT
#
# This demo shows how to use extrapolateATT with different first-stage methods.
# The package now supports:
# 1. Callaway & Sant'Anna (did package) - built-in converter
# 2. Manual format (data.frame + EIF) - for any custom method
# 3. Extensible to other methods via S3

library(extrapolateATT)

# ==============================================================================
# Example 1: Using did::att_gt (Callaway & Sant'Anna)
# ==============================================================================

cat("\n=== Example 1: Callaway & Sant'Anna (did package) ===\n\n")

# Create mock did::att_gt output
set.seed(123)
n <- 100  # Sample size
J <- 4    # Number of group-time pairs

mock_did_result <- structure(
  list(
    group = c(2010, 2010, 2011, 2011),
    t = c(2012, 2013, 2012, 2013),
    att = c(0.5, 0.6, 0.4, 0.5),
    se = c(0.1, 0.12, 0.09, 0.11),
    inffunc = matrix(rnorm(n * J), nrow = n, ncol = J)
  ),
  class = "AGGTEobj"
)

# Convert to gt_object (standardized format)
gt_obj <- as_gt_object(mock_did_result, extract_eif = TRUE)

cat("✓ Converted did::att_gt output to gt_object\n\n")
cat("Structure:\n")
print(names(gt_obj))
cat("\nGroup-time ATT estimates:\n")
print(gt_obj$data)
cat("\nHas EIF for variance propagation:", !is.null(gt_obj$phi), "\n")
cat("Sample size:", gt_obj$n, "\n")
cat("Source:", gt_obj$meta$source, "\n")

# Extrapolate to future periods
cat("\n--- Extrapolating to future event time k* = 4 ---\n\n")

extrap <- extrapolate_ATT(
  gt_obj,
  h_fun = hg_linear,
  dh_fun = dh_linear,
  future_value = 4,  # Extrapolate to event time k* = 4
  time_scale = "event",
  per_group = TRUE
)

cat("Extrapolated ATTs:\n")
print(extrap$tau_g_future)

# ==============================================================================
# Example 2: Manual Format with EIF (Custom Method)
# ==============================================================================

cat("\n\n=== Example 2: Manual Format (Custom Method with EIF) ===\n\n")

# Suppose you have group-time ATT estimates from a custom method
# AND you have influence functions
set.seed(456)
n_obs <- 150
n_gt <- 5

custom_estimates <- data.frame(
  g = c(2010, 2010, 2010, 2011, 2011),
  t = c(2012, 2013, 2014, 2012, 2013),
  tau_hat = c(0.3, 0.5, 0.6, 0.4, 0.5)
)

# Mock EIF vectors (in practice, these come from your estimator)
custom_eif <- lapply(1:n_gt, function(j) rnorm(n_obs))

cat("Custom estimates:\n")
print(custom_estimates)

# Method 1: Using as_gt_object with EIF
gt_obj_custom <- as_gt_object(
  custom_estimates,
  phi = custom_eif,
  n = n_obs,
  meta = list(
    source = "Custom DiD Method",
    notes = "With influence functions for full variance propagation"
  )
)

cat("\n✓ Converted custom estimates to gt_object\n")
cat("Source:", gt_obj_custom$meta$source, "\n")
cat("Has EIF:", !is.null(gt_obj_custom$phi), "\n")
cat("EIF length:", length(gt_obj_custom$phi[[1]]), "\n")

# Extrapolate
cat("\n--- Extrapolating to event time k* = 5 ---\n\n")

extrap_custom <- extrapolate_ATT(
  gt_obj_custom,
  h_fun = hg_linear,
  dh_fun = dh_linear,
  future_value = 5,  # Event time k* = 5
  time_scale = "event",
  per_group = TRUE
)

cat("Extrapolated ATTs:\n")
print(extrap_custom$tau_g_future)

# ==============================================================================
# Example 3: Using new_gt_object (Direct Constructor)
# ==============================================================================

cat("\n\n=== Example 3: Direct Construction with new_gt_object() ===\n\n")

# For maximum control, use new_gt_object directly
set.seed(789)
n3 <- 200
n_gt3 <- 3

manual_data <- data.frame(
  g = c(1, 1, 2),
  t = c(2, 3, 3),
  k = c(1, 2, 1),  # Explicitly provide event time
  tau_hat = c(0.5, 0.6, 0.4)
)

manual_eif <- lapply(1:n_gt3, function(j) rnorm(n3))

gt_obj_manual <- new_gt_object(
  data = manual_data,
  phi = manual_eif,
  n = n3,
  ids = 1:n3,  # Optional: unit IDs
  meta = list(
    source = "Manual Construction",
    estimator = "Custom Estimator",
    notes = "Full control over all fields"
  )
)

cat("✓ Created gt_object with new_gt_object()\n")
cat("Structure:\n")
str(gt_obj_manual, max.level = 1)
cat("\nMetadata:\n")
print(gt_obj_manual$meta)

# ==============================================================================
# Example 4: Backward Compatibility
# ==============================================================================

cat("\n\n=== Example 4: Backward Compatibility ===\n\n")
cat("The existing estimate_group_time_ATT() function still works unchanged.\n")
cat("It now uses the new converter infrastructure internally.\n\n")

cat("Example code (requires real did-compatible data):\n\n")
cat("  library(did)\n")
cat("  data(mpdta)\n")
cat("  \n")
cat("  gt_obj <- estimate_group_time_ATT(\n")
cat("    data = mpdta,\n")
cat("    y = lemp,\n")
cat("    t = year,\n")
cat("    g = first.treat,\n")
cat("    cluster = countyreal\n")
cat("  )\n")
cat("  \n")
cat("  extrap <- extrapolate_ATT(\n")
cat("    gt_obj,\n")
cat("    h_fun = hg_linear,\n")
cat("    dh_fun = dh_linear,\n")
cat("    future_value = 5,\n")
cat("    time_scale = 'event'\n")
cat("  )\n")

# ==============================================================================
# Summary
# ==============================================================================

cat("\n\n=== Summary ===\n\n")
cat("Key Features:\n")
cat("✓ Converter factory pattern supports multiple first-stage methods\n")
cat("✓ as_gt_object() - Generic S3 method for conversion\n")
cat("✓ new_gt_object() - Manual constructor for full control\n")
cat("✓ Built-in converters: did::att_gt (AGGTEobj)\n")
cat("✓ Manual format: data.frame + EIF\n")
cat("✓ Backward compatible: estimate_group_time_ATT() unchanged\n\n")

cat("Current Requirements:\n")
cat("• EIF (phi) is required for variance propagation\n")
cat("• Future enhancement: SE-only mode with delta method (Phase 4)\n\n")

cat("Extending to New Methods:\n")
cat("To add support for a new first-stage method:\n")
cat("1. Implement as_gt_object.yourclass() method\n")
cat("2. Extract group-time ATTs: data.frame(g, t, tau_hat, k)\n")
cat("3. Extract EIF vectors: list of length-n vectors\n")
cat("4. Call new_gt_object() with extracted components\n\n")

cat("=== Demo Complete ===\n")

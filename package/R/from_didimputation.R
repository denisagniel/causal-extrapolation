#' Convert didimputation output to gt_object (stub)
#'
#' Placeholder converter for the didimputation package (Borusyak et al. 2021).
#' Full implementation not yet available. Use manual format instead.
#'
#' @param x Result from `didimputation::did_imputation()`
#' @param ... Additional arguments (currently unused)
#'
#' @return This function currently throws an informative error.
#'
#' @details
#' ## About didimputation
#'
#' The `didimputation` package (Borusyak, Jaravel, & Spiess, 2021) implements
#' an imputation-based estimator for difference-in-differences with staggered
#' treatment adoption. It imputes counterfactual outcomes for treated units
#' using not-yet-treated units as controls.
#'
#' **Key features:**
#' - Handles staggered adoption with heterogeneous treatment effects
#' - Imputation-based approach (differs from regression-based methods)
#' - Robust to dynamic treatment effects
#'
#' **Reference:** Borusyak, K., Jaravel, X., & Spiess, J. (2021). "Revisiting
#' Event Study Designs: Robust and Efficient Estimation." arXiv:2108.12419.
#'
#' ## How to use didimputation with extrapolateATT
#'
#' Until a full converter is implemented, you can use the manual format:
#'
#' ### Step 1: Run didimputation
#' ```r
#' library(didimputation)
#'
#' # Your DiD estimation
#' did_result <- did_imputation(
#'   data = your_data,
#'   yname = "outcome",
#'   gname = "cohort",
#'   tname = "year",
#'   idname = "unit"
#' )
#' ```
#'
#' ### Step 2: Extract group-time estimates
#' ```r
#' # Extract cohort-specific estimates by time
#' # (Exact method depends on didimputation output structure)
#' gt_estimates <- data.frame(
#'   g = ...,         # Cohort/group
#'   t = ...,         # Time period
#'   tau_hat = ...,   # Group-time ATT estimate
#'   se = ...         # Standard error (if available)
#' )
#' ```
#'
#' ### Step 3: Convert to gt_object
#' ```r
#' library(extrapolateATT)
#'
#' gt_obj <- as_gt_object(
#'   gt_estimates,
#'   n = nrow(your_data),  # Sample size
#'   meta = list(source = "didimputation")
#' )
#'
#' # Now extrapolate
#' extrap <- extrapolate_ATT(
#'   gt_obj,
#'   h_fun = hg_linear,
#'   dh_fun = dh_linear,
#'   future_value = 5,
#'   time_scale = "event"
#' )
#' ```
#'
#' ## Contributing
#'
#' A full converter implementation would be welcome! To contribute:
#'
#' 1. Study the didimputation output structure
#' 2. Implement `as_gt_object.did_imputation()` following the pattern in
#'    `R/from_did.R` or `R/from_fixest.R`
#' 3. Extract group-time ATTs and (if available) influence functions
#' 4. Add tests in `tests/testthat/test-from_didimputation.R`
#' 5. Submit a pull request
#'
#' See `?as_gt_object` and `?new_gt_object` for the required output format.
#'
#' @examples
#' \dontrun{
#' # This will error with helpful instructions
#' library(didimputation)
#' result <- did_imputation(...)
#' gt_obj <- as_gt_object(result)  # Error with instructions
#'
#' # Instead, use manual format:
#' gt_estimates <- data.frame(g = ..., t = ..., tau_hat = ...)
#' gt_obj <- as_gt_object(gt_estimates, n = sample_size)
#' }
#'
#' @export
as_gt_object.did_imputation <- function(x, ...) {
  stop(
    "\n══════════════════════════════════════════════════════════════\n",
    "Converter for didimputation not yet implemented.\n",
    "══════════════════════════════════════════════════════════════\n\n",
    "ABOUT: The didimputation package (Borusyak et al. 2021) uses\n",
    "imputation-based DiD estimation for staggered adoption designs.\n\n",
    "TO USE WITH extrapolateATT:\n\n",
    "1. Extract group-time estimates from your didimputation object:\n\n",
    "   gt_data <- data.frame(\n",
    "     g = ...,        # cohort/group\n",
    "     t = ...,        # time period\n",
    "     tau_hat = ...   # group-time ATT estimate\n",
    "   )\n\n",
    "2. Convert to gt_object using manual format:\n\n",
    "   gt_obj <- as_gt_object(\n",
    "     gt_data,\n",
    "     n = nrow(your_original_data),\n",
    "     meta = list(source = 'didimputation')\n",
    "   )\n\n",
    "3. Extrapolate as usual:\n\n",
    "   extrap <- extrapolate_ATT(gt_obj, h_fun = hg_linear, ...)\n\n",
    "See ?as_gt_object for more details on manual format.\n\n",
    "CONTRIBUTE: Full converter implementation welcome!\n",
    "See R/from_did.R for implementation pattern.\n",
    "══════════════════════════════════════════════════════════════\n",
    call. = FALSE
  )
}

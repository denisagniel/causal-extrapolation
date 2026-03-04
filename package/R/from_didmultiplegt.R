#' Convert DIDmultiplegt output to gt_object (stub)
#'
#' Placeholder converter for the DIDmultiplegt package (De Chaisemartin &
#' d'Haultfoeuille 2020). Full implementation not yet available. Use manual
#' format instead.
#'
#' @param x Result from `DIDmultiplegt::did_multiplegt()`
#' @param ... Additional arguments (currently unused)
#'
#' @return This function currently throws an informative error.
#'
#' @details
#' ## About DIDmultiplegt
#'
#' The `DIDmultiplegt` package (De Chaisemartin & d'Haultfoeuille, 2020)
#' implements several difference-in-differences estimators for designs with
#' multiple groups and time periods. It handles staggered treatment adoption
#' and provides diagnostics for treatment effect heterogeneity.
#'
#' **Key features:**
#' - Handles staggered adoption with multiple treatment periods
#' - Robust to dynamic treatment effects and heterogeneity
#' - Provides tests for treatment effect homogeneity
#' - Dynamic effects via `dynamic = TRUE` option
#'
#' **Reference:** De Chaisemartin, C. & d'Haultfoeuille, X. (2020). "Two-Way
#' Fixed Effects Estimators with Heterogeneous Treatment Effects." American
#' Economic Review, 110(9): 2964-96.
#'
#' ## How to use DIDmultiplegt with extrapolateATT
#'
#' To extract group-time ATTs, you need to use the dynamic effects option:
#'
#' ### Step 1: Run DIDmultiplegt with dynamic effects
#' ```r
#' library(DIDmultiplegt)
#'
#' # Estimate with dynamic effects
#' result <- did_multiplegt(
#'   df = your_data,
#'   Y = "outcome",
#'   G = "unit",
#'   T = "year",
#'   D = "treatment",
#'   dynamic = 5,           # Number of dynamic effects
#'   placebo = 2            # Placebo periods (optional)
#' )
#' ```
#'
#' ### Step 2: Extract dynamic effect estimates
#' ```r
#' # DIDmultiplegt returns effect by relative time
#' # You need to map these to (group, time) space
#'
#' # Extract estimates (exact structure depends on output format)
#' dynamic_effects <- result$dynamic_effects
#' relative_times <- result$relative_times
#'
#' # Convert to group-time format
#' # This requires knowledge of treatment timing for each group
#' gt_data <- data.frame(
#'   g = ...,         # Cohort (treatment timing)
#'   t = ...,         # Calendar time
#'   tau_hat = ...,   # Dynamic effect estimate
#'   se = ...         # Standard error (if available)
#' )
#' ```
#'
#' ### Step 3: Convert to gt_object
#' ```r
#' library(extrapolateATT)
#'
#' gt_obj <- as_gt_object(
#'   gt_data,
#'   n = nrow(your_data),
#'   meta = list(
#'     source = "DIDmultiplegt",
#'     method = "De Chaisemartin & d'Haultfoeuille (2020)"
#'   )
#' )
#'
#' # Extrapolate
#' extrap <- extrapolate_ATT(
#'   gt_obj,
#'   h_fun = hg_linear,
#'   dh_fun = dh_linear,
#'   future_value = 5,
#'   time_scale = "event"
#' )
#' ```
#'
#' ## Note on Event Study Format
#'
#' DIDmultiplegt returns effects by **relative time** (event study), not by
#' (group, time) pairs. To use with extrapolateATT:
#'
#' - If you have a single treatment cohort: relative time = event time (k)
#' - If you have multiple cohorts: you need to map relative times to calendar
#'   times for each cohort separately
#'
#' ## Contributing
#'
#' A full converter implementation would be welcome! To contribute:
#'
#' 1. Study the DIDmultiplegt output structure (especially with `dynamic = TRUE`)
#' 2. Implement logic to map relative time effects to (group, time) space
#' 3. Implement `as_gt_object.DIDmultiplegt()` following the pattern in
#'    `R/from_did.R`
#' 4. Add tests in `tests/testthat/test-from_didmultiplegt.R`
#' 5. Submit a pull request
#'
#' See `?as_gt_object` and `?new_gt_object` for the required output format.
#'
#' @examples
#' \dontrun{
#' # This will error with helpful instructions
#' library(DIDmultiplegt)
#' result <- did_multiplegt(..., dynamic = 5)
#' gt_obj <- as_gt_object(result)  # Error with instructions
#'
#' # Instead, extract and format manually:
#' gt_estimates <- data.frame(g = ..., t = ..., tau_hat = ...)
#' gt_obj <- as_gt_object(gt_estimates, n = sample_size)
#' }
#'
#' @export
as_gt_object.DIDmultiplegt <- function(x, ...) {
  stop(
    "\n══════════════════════════════════════════════════════════════\n",
    "Converter for DIDmultiplegt not yet implemented.\n",
    "══════════════════════════════════════════════════════════════\n\n",
    "ABOUT: The DIDmultiplegt package (De Chaisemartin & d'Haultfoeuille\n",
    "2020) implements DiD estimators for multiple groups and periods.\n",
    "Use dynamic = TRUE option for event-study estimates.\n\n",
    "TO USE WITH extrapolateATT:\n\n",
    "1. Run DIDmultiplegt with dynamic effects:\n\n",
    "   result <- did_multiplegt(\n",
    "     df = data,\n",
    "     Y = 'outcome', G = 'unit', T = 'time', D = 'treatment',\n",
    "     dynamic = 5  # number of dynamic effects\n",
    "   )\n\n",
    "2. Extract dynamic effects and map to (group, time) space:\n\n",
    "   # DIDmultiplegt returns effects by relative time\n",
    "   # You need to convert to (cohort, calendar_time) format\n\n",
    "   gt_data <- data.frame(\n",
    "     g = ...,        # treatment cohort\n",
    "     t = ...,        # calendar time\n",
    "     tau_hat = ...   # dynamic effect estimate\n",
    "   )\n\n",
    "3. Convert to gt_object:\n\n",
    "   gt_obj <- as_gt_object(\n",
    "     gt_data,\n",
    "     n = nrow(your_data),\n",
    "     meta = list(source = 'DIDmultiplegt')\n",
    "   )\n\n",
    "4. Extrapolate:\n\n",
    "   extrap <- extrapolate_ATT(gt_obj, h_fun = hg_linear, ...)\n\n",
    "NOTE: DIDmultiplegt output is in event-study format (relative time).\n",
    "Mapping to (group, time) space requires treatment timing information.\n\n",
    "See ?as_gt_object for more details on manual format.\n\n",
    "CONTRIBUTE: Full converter implementation welcome!\n",
    "See R/from_did.R for implementation pattern.\n",
    "══════════════════════════════════════════════════════════════\n",
    call. = FALSE
  )
}

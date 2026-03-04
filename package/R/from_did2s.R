#' Convert did2s output to gt_object (stub)
#'
#' Placeholder converter for the did2s package (Gardner 2022).
#' Full implementation not yet available. Use manual format instead.
#'
#' @param x Result from `did2s::did2s()`
#' @param ... Additional arguments (currently unused)
#'
#' @return This function currently throws an informative error.
#'
#' @details
#' ## About did2s
#'
#' The `did2s` package (Gardner, 2022) implements a two-stage difference-in-
#' differences estimator for staggered treatment adoption. The two-stage
#' approach:
#' 1. **Stage 1:** Estimate unit and time fixed effects using untreated observations
#' 2. **Stage 2:** Estimate treatment effects on residuals
#'
#' **Key features:**
#' - Handles staggered adoption with heterogeneous treatment effects
#' - Two-stage approach robust to treatment effect heterogeneity
#' - Returns fixest object from stage 2
#'
#' **Reference:** Gardner, J. (2022). "Two-stage differences in differences."
#' arXiv:2207.05943.
#'
#' ## How to use did2s with extrapolateATT
#'
#' The `did2s` package returns a fixest object. You may be able to use the
#' fixest converter directly if the output structure is compatible:
#'
#' ### Option 1: Try fixest converter
#' ```r
#' library(did2s)
#'
#' # Run did2s estimation
#' result <- did2s(
#'   data = your_data,
#'   yname = "outcome",
#'   first_stage = ~ 0 | unit + year,
#'   second_stage = ~ i(cohort, year, ref = 0),
#'   treatment = "treatment_var",
#'   cluster_var = "unit"
#' )
#'
#' # Try fixest converter (if output structure matches)
#' gt_obj <- as_gt_object(result)  # May work if sunab-like format
#' ```
#'
#' ### Option 2: Manual format
#' ```r
#' # Extract event-study estimates from did2s output
#' coefs <- coef(result)
#' ses <- se(result)
#'
#' # Parse coefficient names to get (cohort, time) pairs
#' # This depends on your second_stage specification
#'
#' gt_data <- data.frame(
#'   g = ...,         # Cohort
#'   t = ...,         # Time
#'   tau_hat = ...,   # Coefficient
#'   se = ...         # Standard error
#' )
#'
#' # Convert to gt_object
#' gt_obj <- as_gt_object(
#'   gt_data,
#'   n = nrow(your_data),
#'   meta = list(source = "did2s", method = "Gardner (2022)")
#' )
#'
#' # Extrapolate
#' extrap <- extrapolate_ATT(gt_obj, h_fun = hg_linear, ...)
#' ```
#'
#' ## Contributing
#'
#' A dedicated converter implementation would be welcome! To contribute:
#'
#' 1. Determine if did2s output is compatible with fixest converter
#' 2. If not, implement `as_gt_object.did2s()` following the pattern in
#'    `R/from_fixest.R`
#' 3. Handle coefficient name parsing for event-study specifications
#' 4. Add tests in `tests/testthat/test-from_did2s.R`
#' 5. Submit a pull request
#'
#' See `?as_gt_object` and `?new_gt_object` for the required output format.
#'
#' @examples
#' \dontrun{
#' # This will error with helpful instructions
#' library(did2s)
#' result <- did2s(...)
#' gt_obj <- as_gt_object(result)  # May work if fixest-compatible
#'
#' # If not, use manual format:
#' gt_estimates <- data.frame(g = ..., t = ..., tau_hat = ...)
#' gt_obj <- as_gt_object(gt_estimates, n = sample_size)
#' }
#'
#' @export
as_gt_object.did2s <- function(x, ...) {
  stop(
    "\n══════════════════════════════════════════════════════════════\n",
    "Converter for did2s not yet implemented.\n",
    "══════════════════════════════════════════════════════════════\n\n",
    "ABOUT: The did2s package (Gardner 2022) uses two-stage DiD\n",
    "estimation for staggered adoption designs. Stage 1 estimates\n",
    "fixed effects; Stage 2 estimates treatment effects.\n\n",
    "TO USE WITH extrapolateATT:\n\n",
    "OPTION 1: Try fixest converter (did2s returns fixest object)\n\n",
    "   # did2s may be compatible with fixest::sunab converter\n",
    "   gt_obj <- as_gt_object(your_did2s_result)\n\n",
    "OPTION 2: Manual format if Option 1 fails\n\n",
    "1. Extract event-study coefficients from did2s output:\n\n",
    "   coefs <- coef(result)\n",
    "   # Parse names to get (cohort, time) pairs\n\n",
    "2. Format as data.frame:\n\n",
    "   gt_data <- data.frame(\n",
    "     g = ...,        # cohort\n",
    "     t = ...,        # time\n",
    "     tau_hat = ...   # coefficient\n",
    "   )\n\n",
    "3. Convert to gt_object:\n\n",
    "   gt_obj <- as_gt_object(\n",
    "     gt_data,\n",
    "     n = nrow(your_data),\n",
    "     meta = list(source = 'did2s')\n",
    "   )\n\n",
    "4. Extrapolate:\n\n",
    "   extrap <- extrapolate_ATT(gt_obj, h_fun = hg_linear, ...)\n\n",
    "See ?as_gt_object for more details.\n\n",
    "CONTRIBUTE: Full converter implementation welcome!\n",
    "See R/from_fixest.R for implementation pattern.\n",
    "══════════════════════════════════════════════════════════════\n",
    call. = FALSE
  )
}

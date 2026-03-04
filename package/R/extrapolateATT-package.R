#' @keywords internal
"_PACKAGE"

#' extrapolateATT: Semiparametric Extrapolation of Future ATTs
#'
#' Estimate group-time average treatment effects (ATTs) with the \code{did}
#' package, extrapolate to future time points via user-specified temporal
#' models \code{h_g(·)}, and propagate efficient influence functions (EIFs) for
#' uncertainty quantification.
#'
#' @section Core workflow:
#' The package provides a three-step workflow for extrapolating treatment effects:
#'
#' \enumerate{
#'   \item \strong{Estimate group-time ATTs:} Use \code{\link{estimate_group_time_ATT}}
#'     to extract \eqn{\hat{\tau}_{g,t}} and EIFs from \code{did::att_gt()}.
#'   \item \strong{Extrapolate to future:} Apply temporal model \code{h_g(·)} via
#'     \code{\link{extrapolate_ATT}}, propagating EIFs by chain rule.
#'   \item \strong{Compute uncertainty:} Use \code{\link{compute_variance}} to obtain
#'     standard errors and confidence intervals from propagated EIFs.
#' }
#'
#' @section Temporal models:
#' Built-in temporal extrapolation models:
#' \itemize{
#'   \item \code{\link{hg_linear}}, \code{\link{dh_linear}}: Linear trend
#'   \item \code{\link{hg_quadratic}}, \code{\link{dh_quadratic}}: Quadratic trend
#' }
#'
#' Custom temporal models can be defined by providing:
#' \itemize{
#'   \item \code{h_fun}: A factory function taking \code{(times, future_time, ...)}
#'     and returning a function that maps observed ATT vector to future ATT
#'   \item \code{dh_fun}: A function returning the Jacobian (derivative weights)
#' }
#'
#' @section Aggregation:
#' Aggregate across groups or time periods:
#' \itemize{
#'   \item \code{\link{aggregate_groups}}: Weighted aggregation with EIF propagation
#'   \item \code{\link{path1_aggregate}}: Within-group averaging then across-group aggregation
#' }
#'
#' @section Key features:
#' \itemize{
#'   \item \strong{Semiparametric efficiency:} Uses efficient influence functions
#'     for asymptotically valid inference
#'   \item \strong{Flexible temporal models:} Linear, quadratic, or custom extrapolation
#'   \item \strong{Time scales:} Calendar time or event time extrapolation
#'   \item \strong{Uncertainty quantification:} Propagates EIFs via chain rule for valid SEs
#'   \item \strong{Safe numerics:} Automatic singularity detection in matrix operations
#'   \item \strong{Input validation:} Comprehensive checks with informative error messages
#' }
#'
#' @section Mathematical foundation:
#' The semiparametric theory and EIF propagation formulas are described in:
#'
#' Agniel (2026). "Estimating policy effects in the presence of heterogeneity."
#' Section 5.1 provides the formal derivation of EIF propagation through
#' temporal extrapolation models.
#'
#' @section Basic example:
#' \preformatted{
#' # (Assumes you have panel data with did-compatible structure)
#' library(extrapolateATT)
#'
#' # Step 1: Estimate group-time ATTs
#' # gt_obj <- estimate_group_time_ATT(data, y = outcome, g = cohort, t = time)
#'
#' # Step 2: Extrapolate to future using linear model
#' # result <- extrapolate_ATT(
#' #   gt_obj,
#' #   h_fun = hg_linear,
#' #   dh_fun = dh_linear,
#' #   future_value = 2025,
#' #   time_scale = "calendar",
#' #   per_group = FALSE,
#' #   omega = c(0.6, 0.4)  # Group weights
#' # )
#'
#' # Step 3: Compute confidence interval
#' # ci <- compute_variance(result$phi_future, estimate = result$tau_future)
#' # print(ci$ci)
#' }
#'
#' @section See also:
#' \itemize{
#'   \item \code{did} package for difference-in-differences estimation
#'   \item Package vignettes (when available) for detailed workflows
#' }
#'
#' @name extrapolateATT-package
#' @aliases extrapolateATT
NULL

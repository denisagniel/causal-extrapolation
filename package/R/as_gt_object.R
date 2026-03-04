#' Convert first-stage output to gt_object
#'
#' Generic S3 method to convert output from various first-stage DiD estimators
#' into the standardized `gt_object` format used by `extrapolate_ATT()`.
#'
#' @param x Output from a first-stage estimator (e.g., `did::att_gt()`,
#'   `fixest::feols(..., sunab(...))`, or a data.frame with manual estimates).
#' @param ... Additional arguments passed to methods.
#'
#' @return Object of class `gt_object`. See `?new_gt_object` for structure.
#'
#' @details
#' ## Supported Methods
#'
#' **Built-in converters:**
#' - `as_gt_object.AGGTEobj()` - Callaway & Sant'Anna (did package)
#' - `as_gt_object.data.frame()` - Manual format (see below)
#'
#' **Manual format:**
#' If you have group-time ATT estimates from an unsupported method, you can:
#' 1. Format as data.frame with columns `g`, `t`, `tau_hat` (and optionally `k`, `se`)
#' 2. Call `as_gt_object(data, phi = ..., n = ...)`
#' 3. Or use `new_gt_object()` directly for full control
#'
#' ## Extending
#'
#' To add support for a new first-stage method:
#' 1. Implement `as_gt_object.yourclass()` method
#' 2. Extract group-time ATTs and format as data.frame(g, t, tau_hat, k)
#' 3. Extract EIF vectors if available (list of length-n vectors)
#' 4. Call `new_gt_object(data, phi = phi, n = n, meta = list(source = "yourmethod"))`
#'
#' See `vignette("first-stage-methods")` for examples.
#'
#' @examples
#' \dontrun{
#' # Example 1: From did::att_gt
#' library(did)
#' data(mpdta)
#' did_result <- att_gt(yname = "lemp", gname = "first.treat",
#'                      idname = "countyreal", tname = "year",
#'                      data = mpdta)
#' gt_obj <- as_gt_object(did_result)
#'
#' # Example 2: Manual data.frame
#' data <- data.frame(
#'   g = c(2010, 2010, 2011),
#'   t = c(2012, 2013, 2012),
#'   tau_hat = c(0.5, 0.6, 0.4),
#'   se = c(0.1, 0.12, 0.09)
#' )
#' gt_obj <- as_gt_object(data, n = 100)
#' }
#'
#' @export
as_gt_object <- function(x, ...) {
  UseMethod("as_gt_object")
}

#' @rdname as_gt_object
#' @export
as_gt_object.gt_object <- function(x, ...) {
  # Already a gt_object, validate and return
  validate_gt_object(x)
  x
}

#' @rdname as_gt_object
#' @export
as_gt_object.default <- function(x, ...) {
  class_str <- stringr::str_c(class(x), collapse = ", ")
  stop(stringr::str_glue(
    "No method for converting class '{class_str}' to gt_object.\n",
    "Supported classes: AGGTEobj (did), data.frame.\n",
    "For custom estimates, use as_gt_object.data.frame() or new_gt_object().\n",
    "See vignette('first-stage-methods') for examples."
  ), call. = FALSE)
}

#' @rdname as_gt_object
#' @param phi List of EIF vectors (for data.frame method)
#' @param se Standard errors (for data.frame method)
#' @param n Sample size (for data.frame method)
#' @param ids Unit identifiers (for data.frame method)
#' @param meta Metadata list (for data.frame method)
#' @export
as_gt_object.data.frame <- function(x, phi = NULL, se = NULL, n = NULL,
                                     ids = NULL, meta = NULL, ...) {
  # Manual conversion from data frame
  # User provides data with g, t, tau_hat and optionally phi/se

  # Add source to metadata
  meta <- meta %||% list()
  if (!"source" %in% names(meta)) {
    meta$source <- "manual (data.frame)"
  }

  new_gt_object(data = x, phi = phi, n = n, se = se, ids = ids, meta = meta, ...)
}

#' @keywords internal
`%||%` <- function(x, y) if (is.null(x)) y else x

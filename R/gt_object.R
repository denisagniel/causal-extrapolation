#' Create gt_object from raw components
#'
#' Construct a gt_object (group-time ATT container) directly from data components.
#' This is the low-level constructor for users with custom first-stage estimates
#' or methods not yet supported by built-in converters.
#'
#' @param data Data frame with columns `g` (group/cohort), `t` (time), `tau_hat`
#'   (group-time ATT estimate). Optionally include `k` (event time = t - g);
#'   if absent, it will be computed automatically.
#' @param phi List of EIF vectors (length n each), one per row of `data`. If NULL,
#'   variance propagation will not be available (only point estimates).
#' @param n Sample size. Required if `phi` is provided; otherwise inferred.
#' @param se Optional: standard errors for each group-time ATT. Used for
#'   approximate variance propagation via delta method when `phi` is NULL.
#' @param ids Optional: unit identifiers (length n). Useful for debugging.
#' @param meta Optional: list of metadata (e.g., source method, original object).
#' @param ... Additional fields to include in the gt_object.
#'
#' @return Object of class `gt_object` with standardized structure:
#' \describe{
#'   \item{data}{Tibble with columns g, t, k, tau_hat (and se if provided)}
#'   \item{phi}{List of EIF vectors or NULL}
#'   \item{times}{Sorted unique time points}
#'   \item{groups}{Sorted unique groups}
#'   \item{event_times}{Sorted unique event times (k = t - g)}
#'   \item{n}{Sample size}
#'   \item{ids}{Unit identifiers or NULL}
#'   \item{meta}{Metadata list}
#' }
#'
#' @details
#' The gt_object format is the standardized internal representation used by
#' `extrapolate_ATT()` and downstream functions. It decouples the extrapolation
#' machinery from any specific first-stage method.
#'
#' **Uncertainty quantification:**
#' - **Full propagation (preferred):** Provide `phi` (EIF list). Enables exact
#'   variance propagation through the extrapolation model via influence function
#'   chain rule.
#' - **Approximate propagation:** Provide `se` without `phi`. Uses delta method
#'   (assumes independence; may underestimate variance).
#' - **Point estimates only:** Omit both `phi` and `se`. Extrapolation will
#'   produce point estimates without standard errors.
#'
#' @examples
#' \dontrun{
#' # Example 1: Manual format with EIF
#' data <- data.frame(
#'   g = c(2010, 2010, 2011),
#'   t = c(2012, 2013, 2012),
#'   tau_hat = c(0.5, 0.6, 0.4)
#' )
#' phi <- replicate(3, rnorm(100), simplify = FALSE)
#' gt_obj <- new_gt_object(data, phi = phi, n = 100)
#'
#' # Example 2: Manual format with SE only
#' data$se <- c(0.1, 0.12, 0.09)
#' gt_obj <- new_gt_object(data, se = data$se, n = 100)
#'
#' # Example 3: Point estimates only
#' gt_obj <- new_gt_object(data, n = 100)
#' }
#'
#' @export
new_gt_object <- function(data, phi = NULL, n = NULL, se = NULL, ids = NULL, meta = NULL, ...) {
  # Validate inputs
  if (!is.data.frame(data)) {
    stop("data must be a data.frame or tibble", call. = FALSE)
  }

  required_cols <- c("g", "t", "tau_hat")
  missing_cols <- setdiff(required_cols, names(data))

  if (length(missing_cols) > 0) {
    missing_str <- stringr::str_c(missing_cols, collapse = ", ")
    stop(stringr::str_glue(
      "data must have columns: g, t, tau_hat. Missing: {missing_str}"
    ), call. = FALSE)
  }

  # Convert to tibble
  data <- tibble::as_tibble(data)

  # Compute k (event time) if not present
  if (!"k" %in% names(data)) {
    data$k <- data$t - data$g
  }

  # Validate alignment: phi length must match data rows
  if (!is.null(phi)) {
    if (!is.list(phi)) {
      stop("phi must be a list of EIF vectors", call. = FALSE)
    }
    if (length(phi) != nrow(data)) {
      stop(stringr::str_glue(
        "phi has length {length(phi)} but data has {nrow(data)} rows. These must match."
      ), call. = FALSE)
    }
    # Validate each EIF vector
    phi_lengths <- purrr::map_int(phi, length)
    if (!all(phi_lengths == phi_lengths[1])) {
      stop("All EIF vectors in phi must have the same length (n)", call. = FALSE)
    }
  }

  # Infer or validate sample size
  if (is.null(n)) {
    if (!is.null(phi)) {
      n <- length(phi[[1]])
    } else {
      n <- NA_integer_
      warning(
        "Sample size n not provided and cannot be inferred (phi is NULL). ",
        "Set n explicitly if needed for downstream operations.",
        call. = FALSE
      )
    }
  } else {
    # Validate n against phi if both provided
    if (!is.null(phi) && length(phi[[1]]) != n) {
      stop(stringr::str_glue(
        "n = {n} does not match length of EIF vectors ({length(phi[[1]])})"
      ), call. = FALSE)
    }
  }

  # Handle uncertainty quantification
  if (is.null(phi) && is.null(se)) {
    warning(
      "No uncertainty quantification provided (phi or se). ",
      "Variance propagation will not be available. ",
      "Extrapolation will produce point estimates only.",
      call. = FALSE
    )
  }

  # If se provided, add to data
  if (!is.null(se)) {
    if (length(se) != nrow(data)) {
      stop(stringr::str_glue(
        "se has length {length(se)} but data has {nrow(data)} rows. These must match."
      ), call. = FALSE)
    }
    data$se <- se
  }

  # Validate ids if provided
  if (!is.null(ids) && length(ids) != n) {
    stop(stringr::str_glue(
      "ids has length {length(ids)} but n = {n}. These must match."
    ), call. = FALSE)
  }

  # Build gt_object
  obj <- list(
    data = data,
    phi = phi,
    times = sort(unique(data$t)),
    groups = sort(unique(data$g)),
    event_times = sort(unique(data$k)),
    n = n,
    ids = ids,
    meta = meta %||% list(),
    ...
  )

  class(obj) <- c("gt_object", "extrapolateATT")

  # Validate structure
  validate_gt_object(obj)

  obj
}

#' @keywords internal
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Convert did::att_gt output to gt_object
#'
#' S3 method to convert output from `did::att_gt()` (Callaway & Sant'Anna)
#' into the standardized `gt_object` format. Extracts group-time ATTs and
#' efficient influence functions (EIFs) for variance propagation.
#'
#' @param x Result from `did::att_gt()` (class `AGGTEobj` from att_gt, not aggte).
#' @param extract_eif Extract influence functions? Default TRUE. Set to FALSE
#'   for faster conversion if you only need point estimates.
#' @param ... Additional arguments (currently unused).
#'
#' @return Object of class `gt_object`. See `?new_gt_object` for structure.
#'
#' @details
#' ## What is extracted
#'
#' **From att_gt output:**
#' - Group-time ATT estimates (`att`)
#' - Group identifiers (`group`)
#' - Time points (`t`)
#' - Event times (computed as `k = t - group`)
#' - Standard errors (`se`) if available
#'
#' **Influence functions:**
#' The `did` package stores EIFs in `x$inffunc`, an n × J matrix where:
#' - Rows correspond to units (n = sample size)
#' - Columns correspond to group-time pairs (J = number of (g,t) cells)
#' - Column j contains the EIF for the jth group-time ATT
#'
#' These are converted to a list of length-n vectors for use in
#' `extrapolate_ATT()` and `compute_variance()`.
#'
#' ## Requirements
#'
#' - `x` must be from `did::att_gt()`, not `did::aggte()` (which aggregates
#'   across group-time cells and loses the granular structure needed for
#'   extrapolation).
#' - If `extract_eif = TRUE`, `x$inffunc` must be present. This requires
#'   `did` version >= 2.1.0 and the `bstrap = FALSE` option in `att_gt()`.
#'
#' @examples
#' \dontrun{
#' library(did)
#' data(mpdta)
#'
#' # Estimate group-time ATTs
#' did_result <- att_gt(
#'   yname = "lemp",
#'   gname = "first.treat",
#'   idname = "countyreal",
#'   tname = "year",
#'   data = mpdta,
#'   bstrap = FALSE  # Needed for inffunc
#' )
#'
#' # Convert to gt_object
#' gt_obj <- as_gt_object(did_result)
#'
#' # Check structure
#' names(gt_obj)
#' head(gt_obj$data)
#' length(gt_obj$phi)  # Should equal nrow(gt_obj$data)
#' }
#'
#' @export
as_gt_object.AGGTEobj <- function(x, extract_eif = TRUE, ...) {
  # Validate input
  if (!inherits(x, "AGGTEobj")) {
    class_str <- stringr::str_c(class(x), collapse = ", ")
    stop(stringr::str_glue(
      "Expected class 'AGGTEobj' from did::att_gt(), got class: {class_str}"
    ), call. = FALSE)
  }

  # Check if it's actually from att_gt (not aggte)
  # att_gt objects have 'group' field; aggte objects do not
  if (!"group" %in% names(x)) {
    stop(
      "x must be output from did::att_gt(), not did::aggte().\n",
      "aggte() aggregates across group-time cells, losing the structure needed for extrapolation.\n",
      "Use att_gt() to obtain group-time specific ATTs.",
      call. = FALSE
    )
  }

  # Extract group-time ATT estimates
  # The did package stores these directly in the att_gt object
  data <- tibble::tibble(
    g = x$group,
    t = x$t,
    k = x$t - x$group,  # event time
    tau_hat = x$att
  )

  # Extract standard errors if available
  if (!is.null(x$se)) {
    data$se <- x$se
  }

  # Extract EIF if requested and available
  phi <- NULL
  n <- NULL

  if (extract_eif) {
    if (is.null(x$inffunc)) {
      warning(
        "x$inffunc is NULL. Cannot extract EIFs.\n",
        "This may be because:\n",
        "  1. did::att_gt() was called with bstrap = TRUE (default), or\n",
        "  2. An older version of did is being used.\n",
        "To enable EIF extraction:\n",
        "  - Use bstrap = FALSE in att_gt()\n",
        "  - Ensure did version >= 2.1.0\n",
        "Proceeding without EIF. Variance propagation will not be available.",
        call. = FALSE
      )
    } else {
      # x$inffunc is n × J matrix
      # Rows = units (n = sample size)
      # Columns = group-time pairs (J = nrow(data))
      IF <- x$inffunc

      # Validate dimensions
      if (ncol(IF) != nrow(data)) {
        stop(stringr::str_glue(
          "Dimension mismatch: x$inffunc has {ncol(IF)} columns but ",
          "there are {nrow(data)} group-time pairs. These must match."
        ), call. = FALSE)
      }

      n <- nrow(IF)

      # Convert to list of EIF vectors (one per group-time pair)
      # Column j corresponds to row j of data
      phi <- purrr::map(seq_len(ncol(IF)), function(j) as.numeric(IF[, j]))
    }
  }

  # Create gt_object
  new_gt_object(
    data = data,
    phi = phi,
    n = n,
    meta = list(
      source = "did::att_gt",
      did_version = as.character(utils::packageVersion("did")),
      did_object = x  # Store original for reference
    )
  )
}

#' Extract τ_gt and EIFs from a did object (deprecated)
#'
#' This function is deprecated. Use `as_gt_object(did_obj)` instead.
#'
#' @param did_obj An object from `did::att_gt()`.
#' @param ids Optional vector of unit ids to align EIFs (unused).
#'
#' @return A list with `data` tibble (g, t, k, tau_hat) and `phi` list of EIF vectors.
#'
#' @keywords internal
#' @export
did_extract_gt <- function(did_obj, ids = NULL) {
  .Deprecated("as_gt_object", package = "extrapolateATT")

  # Preserve backward-compatible error message
  # Accept both "att_gt" and "AGGTEobj" (different versions of did use different classes)
  if (!inherits(did_obj, "att_gt") && !inherits(did_obj, "AGGTEobj")) {
    stop("did_obj must be an att_gt object.", call. = FALSE)
  }

  # Convert using new method
  gt_obj <- as_gt_object(did_obj, extract_eif = TRUE)

  # Return in old format (list with data and phi)
  list(
    data = gt_obj$data,
    phi = gt_obj$phi
  )
}

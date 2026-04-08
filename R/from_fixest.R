#' Convert fixest sunab output to gt_object
#'
#' S3 method to convert output from `fixest::feols(..., sunab(...))` (Sun & Abraham)
#' into the standardized `gt_object` format. Extracts group-time ATTs from
#' cohort-time interaction coefficients.
#'
#' @param x Result from `fixest::feols()` with `sunab()` specification.
#' @param extract_eif Attempt to extract influence functions? Default TRUE.
#'   If unavailable, falls back to SE-only mode.
#' @param ... Additional arguments (currently unused).
#'
#' @return Object of class `gt_object`. See `?new_gt_object` for structure.
#'
#' @details
#' ## Sun & Abraham (2021) Method
#'
#' The Sun & Abraham estimator uses interaction-weighted estimation to handle
#' staggered adoption with heterogeneous treatment effects. It specifies:
#'
#' ```r
#' fixest::feols(y ~ x + sunab(cohort_var, time_var) | unit + time, data = df)
#' ```
#'
#' This produces cohort-time interaction coefficients that represent group-time
#' ATTs. The converter extracts these coefficients and formats them for
#' extrapolation.
#'
#' ## What is extracted
#'
#' **From fixest output:**
#' - Cohort-time interaction coefficients (group-time ATTs)
#' - Standard errors from vcov
#' - Sample size
#' - Coefficient names parsed to extract (g, t) pairs
#'
#' **Influence functions:**
#' The converter attempts to extract influence functions via `influence.fixest()`
#' if available. If not available (depends on fixest version), falls back to
#' SE-only mode with a warning. Variance propagation will use delta method
#' approximation in SE-only mode.
#'
#' ## Coefficient name parsing
#'
#' The converter handles multiple coefficient name formats from different fixest
#' versions:
#' - `"cohort::2010:time::2012"` (standard format)
#' - `"2010:2012"` (simplified format)
#' - `"cohort::2010:rel_time::2"` (relative time format)
#'
#' If parsing fails, an informative error is raised.
#'
#' ## Requirements
#'
#' - `x` must be from `fixest::feols()` with `sunab()` specification
#' - The model must include cohort-time interaction terms
#' - For EIF extraction: fixest version with `influence()` method (optional)
#'
#' @examples
#' \dontrun{
#' library(fixest)
#'
#' # Simulate staggered adoption data
#' data <- sim_did_data(n = 1000, periods = 10)
#'
#' # Estimate with Sun & Abraham
#' res <- feols(
#'   y ~ x + sunab(cohort, year) | unit + year,
#'   data = data
#' )
#'
#' # Convert to gt_object
#' gt_obj <- as_gt_object(res)
#'
#' # Check structure
#' head(gt_obj$data)
#' gt_obj$meta$source  # "fixest::sunab"
#'
#' # Extrapolate
#' extrap <- extrapolate_ATT(
#'   gt_obj,
#'   h_fun = hg_linear,
#'   dh_fun = dh_linear,
#'   future_value = 5,
#'   time_scale = "event"
#' )
#' }
#'
#' @export
as_gt_object.fixest <- function(x, extract_eif = TRUE, ...) {
  # Validate input class
  if (!inherits(x, "fixest")) {
    class_str <- stringr::str_c(class(x), collapse = ", ")
    stop(stringr::str_glue(
      "Expected class 'fixest' from fixest::feols(), got class: {class_str}"
    ), call. = FALSE)
  }

  # Check if sunab was used
  # Look for cohort-time interaction terms in coefficient names
  coef_names <- names(stats::coef(x))

  if (is.null(coef_names) || length(coef_names) == 0) {
    stop(
      "No coefficients found in fixest object.\n",
      "Ensure the model was estimated successfully.",
      call. = FALSE
    )
  }

  # Identify sunab coefficients
  # Patterns: "cohort::...:time::..." or simple "g:t" format
  sunab_pattern <- "cohort.*time|^\\d+:\\d+$|rel_time"
  sunab_idx <- grep(sunab_pattern, coef_names)

  if (length(sunab_idx) == 0) {
    stop(
      "x does not appear to use sunab().\n",
      "No cohort-time interaction coefficients found.\n\n",
      "To use fixest with extrapolateATT:\n",
      "  Use: feols(y ~ x + sunab(cohort_var, time_var) | fe, data = df)\n\n",
      "Example:\n",
      "  res <- feols(lemp ~ sunab(first.treat, year) | countyreal + year, data = mpdta)\n",
      "  gt_obj <- as_gt_object(res)\n\n",
      "See ?fixest::sunab for details on the Sun & Abraham estimator.",
      call. = FALSE
    )
  }

  # Extract sunab coefficients
  sunab_coefs <- stats::coef(x)[sunab_idx]
  sunab_names <- names(sunab_coefs)

  # Parse names to get (g, t)
  gt_df <- parse_sunab_names(sunab_names)

  # Create data frame
  data <- tibble::tibble(
    g = gt_df$g,
    t = gt_df$t,
    k = gt_df$t - gt_df$g,
    tau_hat = as.numeric(sunab_coefs)
  )

  # Extract standard errors
  se_vals <- tryCatch(
    {
      if (requireNamespace("fixest", quietly = TRUE)) {
        fixest::se(x)[sunab_idx]
      } else {
        sqrt(diag(stats::vcov(x)))[sunab_idx]
      }
    },
    error = function(e) NULL
  )

  if (!is.null(se_vals) && length(se_vals) == nrow(data)) {
    data$se <- as.numeric(se_vals)
  }

  # Sample size
  n <- stats::nobs(x)

  # Try to extract influence functions
  phi <- NULL

  if (extract_eif) {
    phi <- extract_fixest_eif(x, sunab_idx, n)

    if (is.null(phi)) {
      message(
        "Note: Could not extract influence functions from fixest object.\n",
        "Variance propagation will be approximate (delta method).\n",
        "This is expected behavior for most fixest versions.\n",
        "For exact EIF propagation, consider using did::att_gt()."
      )
    }
  }

  # Create gt_object
  new_gt_object(
    data = data,
    phi = phi,
    n = n,
    meta = list(
      source = "fixest::sunab",
      fixest_version = as.character(utils::packageVersion("fixest")),
      method = "Sun & Abraham (2021)",
      fixest_object = x,  # Store for reference
      note = "Cohort-time interactions from sunab() specification"
    )
  )
}

#' Parse sunab coefficient names to extract group and time
#'
#' Extracts (g, t) pairs from fixest coefficient names. Handles multiple
#' formats used by different fixest versions.
#'
#' @param coef_names Character vector of coefficient names from fixest::sunab
#'
#' @return Data frame with columns g (group/cohort) and t (time)
#'
#' @keywords internal
parse_sunab_names <- function(coef_names) {
  n <- length(coef_names)
  g <- integer(n)
  t <- integer(n)

  for (i in seq_along(coef_names)) {
    name <- coef_names[i]

    # Pattern 1: "cohort::2010:time::2012" (standard format)
    pattern1 <- "cohort::(\\d+):time::(\\d+)"
    match1 <- regmatches(name, regexec(pattern1, name))

    if (length(match1[[1]]) >= 3) {
      g[i] <- as.integer(match1[[1]][2])
      t[i] <- as.integer(match1[[1]][3])
      next
    }

    # Pattern 2: "2010:2012" (simplified format)
    pattern2 <- "^(\\d+):(\\d+)$"
    match2 <- regmatches(name, regexec(pattern2, name))

    if (length(match2[[1]]) >= 3) {
      g[i] <- as.integer(match2[[1]][2])
      t[i] <- as.integer(match2[[1]][3])
      next
    }

    # Pattern 3: "cohort::2010:rel_time::2" or "cohort::2010:rel_time::1" (relative time format)
    pattern3 <- "cohort::(\\d+):rel_time::([-+]?\\d+)"
    match3 <- regmatches(name, regexec(pattern3, name))

    if (length(match3[[1]]) >= 3) {
      g[i] <- as.integer(match3[[1]][2])
      rel_time <- as.integer(match3[[1]][3])
      t[i] <- g[i] + rel_time
      next
    }

    # Pattern 4: Try to find any two 4-digit numbers (years)
    pattern4 <- "(\\d{4}).*(\\d{4})"
    match4 <- regmatches(name, regexec(pattern4, name))

    if (length(match4[[1]]) >= 3) {
      g[i] <- as.integer(match4[[1]][2])
      t[i] <- as.integer(match4[[1]][3])
      next
    }

    # If none matched, error with helpful message
    stop(stringr::str_glue(
      "Could not parse sunab coefficient name: '{name}'\n",
      "Expected formats:\n",
      "  - 'cohort::2010:time::2012'\n",
      "  - '2010:2012'\n",
      "  - 'cohort::2010:rel_time::2'\n\n",
      "If you encounter this error with a valid sunab model, please report it.\n",
      "Workaround: Extract estimates manually and use as_gt_object.data.frame()"
    ), call. = FALSE)
  }

  data.frame(g = g, t = t)
}

#' Extract influence functions from fixest object
#'
#' Attempts to extract influence functions from a fixest object for variance
#' propagation. Returns NULL if not available.
#'
#' @param x fixest object
#' @param sunab_idx Indices of sunab coefficients
#' @param n Sample size
#'
#' @return List of EIF vectors or NULL if unavailable
#'
#' @keywords internal
extract_fixest_eif <- function(x, sunab_idx, n) {
  # Check if influence() method exists for fixest
  # This is not available in all fixest versions

  tryCatch({
    # Try to call influence() if it exists
    if (!requireNamespace("fixest", quietly = TRUE)) {
      return(NULL)
    }

    # Check if influence method exists
    # In some versions: influence.fixest()
    # In others: may not be exported

    # Try to get influence function matrix
    infl <- tryCatch(
      {
        # Attempt 1: Direct call
        fixest::influence(x)
      },
      error = function(e) {
        # Attempt 2: Try estfun (if sandwich package installed)
        if (requireNamespace("sandwich", quietly = TRUE)) {
          sandwich::estfun(x)
        } else {
          NULL
        }
      }
    )

    if (is.null(infl)) {
      return(NULL)
    }

    # Validate dimensions
    if (!is.matrix(infl)) {
      return(NULL)
    }

    if (nrow(infl) != n) {
      warning(
        "Influence function matrix has wrong dimensions.\n",
        "Expected ", n, " rows (sample size), got ", nrow(infl), " rows."
      )
      return(NULL)
    }

    # Select columns for sunab coefficients
    if (ncol(infl) < max(sunab_idx)) {
      warning(
        "Influence function matrix has too few columns.\n",
        "Cannot extract EIFs for all sunab coefficients."
      )
      return(NULL)
    }

    infl_sunab <- infl[, sunab_idx, drop = FALSE]

    # Convert to list of vectors (one per group-time pair)
    phi <- lapply(seq_len(ncol(infl_sunab)), function(j) {
      as.numeric(infl_sunab[, j])
    })

    return(phi)

  }, error = function(e) {
    # Silently return NULL if extraction fails
    # A message will be shown by the main converter function
    return(NULL)
  })
}

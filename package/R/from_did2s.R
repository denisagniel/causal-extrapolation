#' Convert did2s output to gt_object
#'
#' S3 method to convert output from `did2s::did2s()` (Gardner 2022) into the
#' standardized `gt_object` format. The `did2s` package implements two-stage
#' difference-in-differences and returns a fixest object with event-study
#' coefficients.
#'
#' @param x Result from `did2s::did2s()` with event-study specification
#'   (e.g., `second_stage = ~ i(rel_year, ref = c(-1, Inf))`).
#' @param cohort_timing Data frame with columns `cohort` (g) and optionally
#'   `first_treat_time`. If a single cohort, can be a scalar. Required to map
#'   event-study estimates to (cohort, time) format.
#' @param base_time Scalar. The time period corresponding to relative time 0.
#'   Required if `cohort_timing` is not provided or doesn't have timing info.
#' @param extract_eif Attempt to extract influence functions? Default TRUE.
#'   Likely unavailable (did2s returns fixest without EIF).
#' @param ... Additional arguments passed to `as_gt_object.fixest()`.
#'
#' @return Object of class `gt_object`. See `?new_gt_object` for structure.
#'
#' @details
#' ## Gardner (2022) Two-Stage DiD
#'
#' The `did2s` package implements a two-stage estimator:
#' 1. **Stage 1:** Estimate unit and time fixed effects using untreated obs
#' 2. **Stage 2:** Estimate treatment effects on residuals (returns fixest)
#'
#' **Key feature:** Returns a fixest object from stage 2, typically with
#' event-study specification using `i(rel_year, ref = ...)`.
#'
#' ## Event-Study to (Cohort, Time) Mapping
#'
#' `did2s` with event-study returns coefficients like:
#' - `rel_year::-2` (2 periods before treatment)
#' - `rel_year::0` (treatment period)
#' - `rel_year::1` (1 period after treatment)
#' - etc.
#'
#' These are **relative times**. To use with extrapolateATT, we need
#' **(cohort, calendar time)** format.
#'
#' **Mapping logic:**
#' ```
#' For cohort g treated at time g:
#'   rel_year = 0 → calendar time t = g
#'   rel_year = 1 → calendar time t = g + 1
#'   rel_year = 2 → calendar time t = g + 2
#'   ...
#' ```
#'
#' ## Usage Scenarios
#'
#' ### Scenario 1: Single Cohort
#'
#' ```r
#' result <- did2s(
#'   data = df,
#'   yname = "outcome",
#'   first_stage = ~ 0 | unit + year,
#'   second_stage = ~ i(rel_year, ref = c(-1, Inf)),
#'   treatment = "treated",
#'   cluster_var = "unit"
#' )
#'
#' # Provide cohort and base time
#' gt_obj <- as_gt_object(
#'   result,
#'   cohort_timing = 2010,  # All treated in 2010
#'   base_time = 2010       # rel_year=0 corresponds to 2010
#' )
#' ```
#'
#' ### Scenario 2: Try as fixest
#'
#' Since `did2s` returns a fixest object, the fixest converter might work
#' directly if coefficients follow a recognizable pattern:
#'
#' ```r
#' result <- did2s(...)
#'
#' # Try fixest converter (may work for some specifications)
#' gt_obj <- as_gt_object.fixest(result)
#' ```
#'
#' ### Scenario 3: Manual Format
#'
#' For complex designs:
#'
#' ```r
#' # Extract coefficients
#' coefs <- coef(result)
#' ses <- se(result)
#'
#' # Parse names and map to (g, t)
#' gt_data <- data.frame(
#'   g = ...,  # cohort
#'   t = ...,  # calendar time
#'   tau_hat = coefs
#' )
#'
#' gt_obj <- as_gt_object(gt_data, n = nobs(result))
#' ```
#'
#' ## Requirements
#'
#' - `x` must be from `did2s::did2s()` with event-study second_stage
#' - Must provide either `cohort_timing` or both cohort_timing + base_time
#' - Returns SE-only (no EIF); variance propagation will use delta method
#'
#' @examples
#' \dontrun{
#' library(did2s)
#'
#' # Event-study specification
#' result <- did2s(
#'   data = df,
#'   yname = "outcome",
#'   first_stage = ~ 0 | unit + year,
#'   second_stage = ~ i(rel_year, ref = c(-1, Inf)),
#'   treatment = "treated",
#'   cluster_var = "unit"
#' )
#'
#' # Convert (single cohort)
#' gt_obj <- as_gt_object(
#'   result,
#'   cohort_timing = 2010,
#'   base_time = 2010
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
#' }
#'
#' @export
as_gt_object.did2s <- function(x, cohort_timing = NULL, base_time = NULL,
                                extract_eif = FALSE, ...) {
  # did2s returns a fixest object
  # Check if it's actually fixest
  if (!inherits(x, "fixest")) {
    stop(
      "x must be a fixest object from did2s::did2s().\n",
      "did2s returns a fixest object from the second stage.",
      call. = FALSE
    )
  }

  # Check for event-study coefficients (rel_year, rel_time, etc.)
  coef_names <- names(stats::coef(x))

  if (is.null(coef_names) || length(coef_names) == 0) {
    stop("No coefficients found in did2s output.", call. = FALSE)
  }

  # Look for event-study pattern
  is_event_study <- any(grepl("rel_year|rel_time|event", coef_names, ignore.case = TRUE))

  if (!is_event_study) {
    # Maybe it's a sunab-style specification? Try fixest converter
    message(
      "did2s output doesn't appear to be event-study format.\n",
      "Attempting to use fixest::sunab converter..."
    )
    return(as_gt_object.fixest(x, extract_eif = extract_eif, ...))
  }

  # Extract event-study coefficients
  # Pattern: "rel_year::0", "rel_year::1", etc.
  es_pattern <- "rel_year::([-0-9]+)|rel_time::([-0-9]+)"
  es_idx <- grep(es_pattern, coef_names)

  if (length(es_idx) == 0) {
    stop(
      "No event-study coefficients found in did2s output.\n",
      "Expected coefficient names like 'rel_year::0', 'rel_year::1', etc.\n",
      "Use did2s(..., second_stage = ~ i(rel_year, ref = ...)) for event-study.",
      call. = FALSE
    )
  }

  # Parse relative times from coefficient names
  es_coefs <- stats::coef(x)[es_idx]
  es_names <- names(es_coefs)

  # Extract relative times
  rel_times <- numeric(length(es_names))
  for (i in seq_along(es_names)) {
    name <- es_names[i]

    # Try rel_year pattern
    match <- regmatches(name, regexec("rel_year::([-0-9]+)", name))
    if (length(match[[1]]) >= 2) {
      rel_times[i] <- as.integer(match[[1]][2])
      next
    }

    # Try rel_time pattern
    match <- regmatches(name, regexec("rel_time::([-0-9]+)", name))
    if (length(match[[1]]) >= 2) {
      rel_times[i] <- as.integer(match[[1]][2])
      next
    }

    stop(stringr::str_glue(
      "Could not parse relative time from coefficient name: '{name}'"
    ), call. = FALSE)
  }

  # Extract standard errors
  se_vals <- tryCatch(
    {
      if (requireNamespace("fixest", quietly = TRUE)) {
        fixest::se(x)[es_idx]
      } else {
        sqrt(diag(stats::vcov(x)))[es_idx]
      }
    },
    error = function(e) NULL
  )

  # Check cohort_timing provided
  if (is.null(cohort_timing)) {
    stop(
      "\n══════════════════════════════════════════════════════════════\n",
      "cohort_timing is required to map event-study to (cohort, time).\n",
      "══════════════════════════════════════════════════════════════\n\n",
      "did2s returns event-study estimates (relative time k).\n",
      "extrapolateATT needs (cohort g, calendar time t) format.\n\n",
      "SOLUTION 1: Single cohort (all treated at same time)\n\n",
      "  gt_obj <- as_gt_object(\n",
      "    your_did2s_result,\n",
      "    cohort_timing = 2010,  # treatment year\n",
      "    base_time = 2010       # calendar time for rel_year=0\n",
      "  )\n\n",
      "SOLUTION 2: Try fixest converter (if sunab-style)\n\n",
      "  # did2s may work with fixest converter if using sunab\n",
      "  gt_obj <- as_gt_object.fixest(your_did2s_result)\n\n",
      "SOLUTION 3: Manual format\n\n",
      "  coefs <- coef(result)\n",
      "  gt_data <- data.frame(g = ..., t = ..., tau_hat = ...)\n",
      "  gt_obj <- as_gt_object(gt_data, n = nobs(result))\n\n",
      "See ?as_gt_object.did2s for details.\n",
      "══════════════════════════════════════════════════════════════\n",
      call. = FALSE
    )
  }

  # Handle cohort_timing (same logic as didimputation)
  if (is.numeric(cohort_timing) && length(cohort_timing) == 1) {
    # Single cohort case
    if (is.null(base_time)) {
      base_time <- cohort_timing
      message(
        "Assuming base_time = ", base_time, " (cohort treatment time).\n",
        "Relative time 0 maps to calendar time t=", base_time, "."
      )
    }

    # Create data for single cohort
    data <- tibble::tibble(
      g = cohort_timing,
      t = base_time + rel_times,
      k = rel_times,
      tau_hat = as.numeric(es_coefs)
    )

    if (!is.null(se_vals)) {
      data$se <- as.numeric(se_vals)
    }

  } else if (is.data.frame(cohort_timing)) {
    # Multiple cohorts case
    if (!"cohort" %in% names(cohort_timing)) {
      stop("cohort_timing data.frame must have 'cohort' column", call. = FALSE)
    }

    cohorts <- cohort_timing$cohort

    # Determine base time for each cohort
    if ("first_treat_time" %in% names(cohort_timing)) {
      base_times <- cohort_timing$first_treat_time
    } else if (!is.null(base_time)) {
      base_times <- rep(base_time, length(cohorts))
    } else {
      base_times <- cohorts
      message(
        "Assuming each cohort's treatment time equals cohort value.\n",
        "Cohort g treated at time g."
      )
    }

    # Replicate for each cohort
    data_list <- purrr::map2(cohorts, base_times, function(g, bt) {
      df <- tibble::tibble(
        g = g,
        t = bt + rel_times,
        k = rel_times,
        tau_hat = as.numeric(es_coefs)
      )

      if (!is.null(se_vals)) {
        df$se <- as.numeric(se_vals)
      }

      df
    })

    data <- dplyr::bind_rows(data_list)

  } else {
    stop(
      "cohort_timing must be either:\n",
      "  - A scalar (single cohort), or\n",
      "  - A data.frame with 'cohort' column (multiple cohorts)",
      call. = FALSE
    )
  }

  # Try to extract EIF (unlikely to succeed)
  phi <- NULL
  n <- stats::nobs(x)

  if (extract_eif) {
    phi <- extract_fixest_eif(x, es_idx, n)
    if (is.null(phi)) {
      message(
        "Note: Could not extract influence functions from did2s object.\n",
        "This is expected (did2s uses fixest which doesn't expose EIF).\n",
        "Variance propagation will be approximate (delta method)."
      )
    }
  }

  # Create gt_object
  new_gt_object(
    data = data,
    phi = phi,
    n = n,
    meta = list(
      source = "did2s",
      method = "Gardner (2022)",
      note = "Event-study estimates mapped to (cohort, time) format",
      did2s_fixest_object = x
    )
  )
}

#' Convert didimputation output to gt_object
#'
#' S3 method to convert output from `didimputation::did_imputation()`
#' (Borusyak et al. 2021) into the standardized `gt_object` format.
#'
#' @param x Result from `didimputation::did_imputation()` with `horizon = TRUE`.
#' @param cohort_timing Data frame with columns `cohort` (g) and optionally
#'   `first_treat_time`. If a single cohort, can be a scalar. Required to map
#'   event-study estimates to (cohort, time) format.
#' @param base_time Scalar. The time period corresponding to event time 0.
#'   Required if `cohort_timing` is not provided or doesn't have timing info.
#' @param ... Additional arguments (currently unused).
#'
#' @return Object of class `gt_object`. See `?new_gt_object` for structure.
#'
#' @details
#' ## Borusyak, Jaravel, & Spiess (2021) Method
#'
#' The didimputation package implements an imputation-based estimator for DiD.
#' It estimates counterfactual outcomes Y(0) using not-yet-treated units and
#' computes treatment effects as Y(1) - Ŷ(0).
#'
#' **Key feature:** With `horizon = TRUE`, returns event-study estimates by
#' relative time (0 = treatment period, 1 = one period after, etc.).
#'
#' ## Event-Study to (Cohort, Time) Mapping
#'
#' `didimputation` returns effects by **relative time** (event-study format).
#' To use with extrapolateATT, we need **(cohort, calendar time)** format.
#'
#' **Mapping logic:**
#' ```
#' For cohort g treated at time g:
#'   Event time k=0 → calendar time t = g
#'   Event time k=1 → calendar time t = g + 1
#'   Event time k=2 → calendar time t = g + 2
#'   ...
#' ```
#'
#' ## Usage Scenarios
#'
#' ### Scenario 1: Single Cohort
#'
#' If all units treated at the same time:
#'
#' ```r
#' result <- did_imputation(..., horizon = TRUE)
#'
#' # Provide cohort and base time
#' gt_obj <- as_gt_object(
#'   result,
#'   cohort_timing = 2010,  # All treated in 2010
#'   base_time = 2010       # Event time 0 = 2010
#' )
#' ```
#'
#' ### Scenario 2: Multiple Cohorts
#'
#' If treatment is staggered:
#'
#' ```r
#' result <- did_imputation(..., horizon = TRUE)
#'
#' # Provide cohort timing data
#' cohort_info <- data.frame(
#'   cohort = c(2010, 2011, 2012),
#'   first_treat_time = c(2010, 2011, 2012)
#' )
#'
#' gt_obj <- as_gt_object(result, cohort_timing = cohort_info)
#' ```
#'
#' ### Scenario 3: Manual Format
#'
#' If mapping is complex, use manual format:
#'
#' ```r
#' # Extract event-study results
#' es_results <- result  # data.frame from didimputation
#'
#' # Map to (g, t) manually based on your design
#' gt_data <- data.frame(
#'   g = ...,  # cohort
#'   t = ...,  # calendar time
#'   tau_hat = es_results$estimate
#' )
#'
#' gt_obj <- as_gt_object(gt_data, n = your_sample_size)
#' ```
#'
#' ## Requirements
#'
#' - `x` must be from `didimputation::did_imputation()` with `horizon = TRUE`
#' - Must provide either `cohort_timing` or both cohort_timing + base_time
#' - Returns SE-only (no EIF); variance propagation will use delta method
#'
#' @examples
#' \dontrun{
#' library(didimputation)
#'
#' # Single cohort example
#' result <- did_imputation(
#'   data = df,
#'   yname = "outcome",
#'   gname = "cohort",
#'   tname = "year",
#'   idname = "unit",
#'   horizon = TRUE
#' )
#'
#' # Convert (single cohort, all treated in 2010)
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
as_gt_object.did_imputation <- function(x, cohort_timing = NULL,
                                         base_time = NULL, ...) {
  # Validate input
  if (!is.data.frame(x)) {
    stop(
      "x must be a data.frame from didimputation::did_imputation().\n",
      "Did you forget horizon = TRUE?",
      call. = FALSE
    )
  }

  # Check for required columns
  required_cols <- c("term", "estimate", "std.error")
  missing_cols <- setdiff(required_cols, names(x))

  if (length(missing_cols) > 0) {
    stop(stringr::str_glue(
      "x appears to be from didimputation but is missing columns: ",
      "{stringr::str_c(missing_cols, collapse = ', ')}.\n",
      "Expected output from did_imputation(..., horizon = TRUE)."
    ), call. = FALSE)
  }

  # Check if horizon was used (event-study format)
  # Event times should be numeric (0, 1, 2, ...) or "treat"
  if (!"term" %in% names(x) || nrow(x) == 0) {
    stop(
      "x must have event-study estimates.\n",
      "Use did_imputation(..., horizon = TRUE) to get event-study format.",
      call. = FALSE
    )
  }

  # Filter to numeric event times (exclude "treat" if present)
  x_numeric <- x[!is.na(suppressWarnings(as.numeric(as.character(x$term)))), ]

  if (nrow(x_numeric) == 0) {
    stop(
      "No numeric event times found in didimputation output.\n",
      "Use horizon = TRUE to get event-study estimates by relative time.",
      call. = FALSE
    )
  }

  # Extract event times
  event_times <- as.numeric(as.character(x_numeric$term))

  # Check cohort_timing provided
  if (is.null(cohort_timing)) {
    stop(
      "\n══════════════════════════════════════════════════════════════\n",
      "cohort_timing is required to map event-study to (cohort, time).\n",
      "══════════════════════════════════════════════════════════════\n\n",
      "didimputation returns event-study estimates (relative time k).\n",
      "extrapolateATT needs (cohort g, calendar time t) format.\n\n",
      "SOLUTION 1: Single cohort (all treated at same time)\n\n",
      "  gt_obj <- as_gt_object(\n",
      "    your_didimputation_result,\n",
      "    cohort_timing = 2010,  # treatment year\n",
      "    base_time = 2010       # calendar time for k=0\n",
      "  )\n\n",
      "SOLUTION 2: Multiple cohorts (staggered treatment)\n\n",
      "  cohort_info <- data.frame(\n",
      "    cohort = c(2010, 2011, 2012),\n",
      "    first_treat_time = c(2010, 2011, 2012)\n",
      "  )\n",
      "  gt_obj <- as_gt_object(result, cohort_timing = cohort_info)\n\n",
      "SOLUTION 3: Manual format (complex designs)\n\n",
      "  # Map event-study to (g,t) manually\n",
      "  gt_data <- data.frame(g = ..., t = ..., tau_hat = ...)\n",
      "  gt_obj <- as_gt_object(gt_data, n = sample_size)\n\n",
      "See ?as_gt_object.did_imputation for details.\n",
      "══════════════════════════════════════════════════════════════\n",
      call. = FALSE
    )
  }

  # Handle cohort_timing
  if (is.numeric(cohort_timing) && length(cohort_timing) == 1) {
    # Single cohort case
    if (is.null(base_time)) {
      base_time <- cohort_timing
      message(
        "Assuming base_time = ", base_time, " (cohort treatment time).\n",
        "Event time k=0 maps to calendar time t=", base_time, "."
      )
    }

    # Create data for single cohort
    data <- tibble::tibble(
      g = cohort_timing,
      t = base_time + event_times,
      k = event_times,
      tau_hat = x_numeric$estimate,
      se = x_numeric$std.error
    )

  } else if (is.data.frame(cohort_timing)) {
    # Multiple cohorts case
    if (!"cohort" %in% names(cohort_timing)) {
      stop("cohort_timing data.frame must have 'cohort' column", call. = FALSE)
    }

    # Replicate event-study estimates for each cohort
    cohorts <- cohort_timing$cohort

    # Determine base time for each cohort
    if ("first_treat_time" %in% names(cohort_timing)) {
      base_times <- cohort_timing$first_treat_time
    } else if (!is.null(base_time)) {
      base_times <- rep(base_time, length(cohorts))
    } else {
      # Assume cohort = treatment time
      base_times <- cohorts
      message(
        "Assuming each cohort's treatment time equals cohort value.\n",
        "Cohort g treated at time g."
      )
    }

    # Replicate for each cohort
    data_list <- purrr::map2(cohorts, base_times, function(g, bt) {
      tibble::tibble(
        g = g,
        t = bt + event_times,
        k = event_times,
        tau_hat = x_numeric$estimate,
        se = x_numeric$std.error
      )
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

  # Create gt_object (SE-only, no EIF from didimputation)
  new_gt_object(
    data = data,
    phi = NULL,  # didimputation doesn't provide EIF
    n = NA_integer_,  # Sample size not in output
    se = data$se,
    meta = list(
      source = "didimputation",
      method = "Borusyak, Jaravel, & Spiess (2021)",
      note = "Event-study estimates mapped to (cohort, time) format",
      event_study_original = x_numeric
    )
  )
}

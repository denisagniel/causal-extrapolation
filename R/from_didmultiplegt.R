#' Convert DIDmultiplegt output to gt_object
#'
#' S3 method to convert output from `DIDmultiplegt::did_multiplegt()`
#' (De Chaisemartin & d'Haultfoeuille 2020) into the standardized `gt_object`
#' format.
#'
#' @param x Result from `DIDmultiplegt::did_multiplegt()` with `dynamic = TRUE`.
#' @param cohort_timing Data frame with columns `cohort` (g) and optionally
#'   `first_treat_time`. If a single cohort, can be a scalar. Required to map
#'   event-study estimates to (cohort, time) format.
#' @param base_time Scalar. The time period corresponding to relative time 0.
#'   Required if `cohort_timing` is not provided or doesn't have timing info.
#' @param ... Additional arguments (currently unused).
#'
#' @return Object of class `gt_object`. See `?new_gt_object` for structure.
#'
#' @details
#' ## De Chaisemartin & d'Haultfoeuille (2020) Method
#'
#' The `DIDmultiplegt` package implements several DiD estimators for multiple
#' groups and periods. With `dynamic = TRUE`, it returns dynamic treatment
#' effects by relative time.
#'
#' **Key feature:** Returns effects by **relative time** to treatment
#' (event-study format), along with pre-trends tests and diagnostics.
#'
#' ## Event-Study to (Cohort, Time) Mapping
#'
#' `DIDmultiplegt` with `dynamic = TRUE` returns:
#' - `effect_0`: Effect in treatment period (k=0)
#' - `effect_1`: Effect 1 period after treatment (k=1)
#' - `effect_2`: Effect 2 periods after treatment (k=2)
#' - etc.
#'
#' And optionally:
#' - `placebo_1`: Placebo 1 period before (k=-1)
#' - `placebo_2`: Placebo 2 periods before (k=-2)
#' - etc.
#'
#' These are **relative times**. To use with extrapolateATT, we need
#' **(cohort, calendar time)** format.
#'
#' **Mapping logic:**
#' ```
#' For cohort g treated at time g:
#'   effect_0 (k=0) → calendar time t = g
#'   effect_1 (k=1) → calendar time t = g + 1
#'   effect_2 (k=2) → calendar time t = g + 2
#'   ...
#' ```
#'
#' ## Usage Scenarios
#'
#' ### Scenario 1: Single Cohort
#'
#' ```r
#' result <- did_multiplegt(
#'   df = data,
#'   Y = "outcome",
#'   G = "unit",
#'   T = "year",
#'   D = "treatment",
#'   dynamic = 5,     # 5 dynamic effects
#'   placebo = 2      # 2 placebo tests
#' )
#'
#' # Provide cohort and base time
#' gt_obj <- as_gt_object(
#'   result,
#'   cohort_timing = 2010,  # All treated in 2010
#'   base_time = 2010       # effect_0 corresponds to 2010
#' )
#' ```
#'
#' ### Scenario 2: Multiple Cohorts
#'
#' ```r
#' result <- did_multiplegt(..., dynamic = 5)
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
#' For complex designs:
#'
#' ```r
#' # Extract dynamic effects
#' effects <- c(
#'   result$placebo_2,  # k = -2
#'   result$placebo_1,  # k = -1
#'   result$effect_0,   # k = 0
#'   result$effect_1,   # k = 1
#'   result$effect_2    # k = 2
#' )
#'
#' # Map to (g, t) based on treatment timing
#' gt_data <- data.frame(
#'   g = ...,  # cohort
#'   t = ...,  # calendar time
#'   tau_hat = effects
#' )
#'
#' gt_obj <- as_gt_object(gt_data, n = nrow(original_data))
#' ```
#'
#' ## Requirements
#'
#' - `x` must be from `DIDmultiplegt::did_multiplegt()` with `dynamic > 0`
#' - Must provide either `cohort_timing` or both cohort_timing + base_time
#' - Returns SE-only (no EIF); variance propagation will use delta method
#'
#' @examples
#' \dontrun{
#' library(DIDmultiplegt)
#'
#' # Dynamic effects
#' result <- did_multiplegt(
#'   df = df,
#'   Y = "outcome",
#'   G = "unit",
#'   T = "year",
#'   D = "treatment",
#'   dynamic = 5,
#'   placebo = 2
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
#'   future_value = 8,
#'   time_scale = "event"
#' )
#' }
#'
#' @export
as_gt_object.DIDmultiplegt <- function(x, cohort_timing = NULL,
                                        base_time = NULL, ...) {
  # Validate input - should be a list with dynamic effects
  if (!is.list(x)) {
    stop(
      "x must be output from DIDmultiplegt::did_multiplegt().\n",
      "Expected a list with dynamic effects.",
      call. = FALSE
    )
  }

  # Extract dynamic effects
  # Look for effect_0, effect_1, ..., placebo_1, placebo_2, ...
  effect_names <- grep("^effect_\\d+$", names(x), value = TRUE)
  placebo_names <- grep("^placebo_\\d+$", names(x), value = TRUE)

  if (length(effect_names) == 0) {
    stop(
      "No dynamic effects found in DIDmultiplegt output.\n",
      "Use did_multiplegt(..., dynamic = K) where K > 0 to get dynamic effects.",
      call. = FALSE
    )
  }

  # Extract effect numbers
  effect_nums <- as.integer(sub("effect_", "", effect_names))
  placebo_nums <- if (length(placebo_names) > 0) {
    -as.integer(sub("placebo_", "", placebo_names))
  } else {
    integer(0)
  }

  # Combine into event times
  event_times <- c(placebo_nums, effect_nums)
  event_times <- sort(event_times)

  # Extract estimates
  estimates <- numeric(length(event_times))
  se_vals <- numeric(length(event_times))

  for (i in seq_along(event_times)) {
    k <- event_times[i]

    if (k < 0) {
      # Placebo
      name <- paste0("placebo_", abs(k))
      estimates[i] <- x[[name]]
      # SE might be in se_placebo_k or N_placebo_k
      se_name <- paste0("se_placebo_", abs(k))
      if (se_name %in% names(x)) {
        se_vals[i] <- x[[se_name]]
      } else {
        se_vals[i] <- NA
      }
    } else {
      # Effect
      name <- paste0("effect_", k)
      estimates[i] <- x[[name]]
      # SE might be in se_effect_k
      se_name <- paste0("se_effect_", k)
      if (se_name %in% names(x)) {
        se_vals[i] <- x[[se_name]]
      } else {
        se_vals[i] <- NA
      }
    }
  }

  # Check cohort_timing provided
  if (is.null(cohort_timing)) {
    stop(
      "\n══════════════════════════════════════════════════════════════\n",
      "cohort_timing is required to map event-study to (cohort, time).\n",
      "══════════════════════════════════════════════════════════════\n\n",
      "DIDmultiplegt returns event-study estimates (relative time k).\n",
      "extrapolateATT needs (cohort g, calendar time t) format.\n\n",
      "SOLUTION 1: Single cohort (all treated at same time)\n\n",
      "  gt_obj <- as_gt_object(\n",
      "    your_didmultiplegt_result,\n",
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
      "  # Extract and map dynamic effects to (g,t) manually\n",
      "  gt_data <- data.frame(g = ..., t = ..., tau_hat = ...)\n",
      "  gt_obj <- as_gt_object(gt_data, n = sample_size)\n\n",
      "See ?as_gt_object.DIDmultiplegt for details.\n",
      "══════════════════════════════════════════════════════════════\n",
      call. = FALSE
    )
  }

  # Handle cohort_timing (same logic as other converters)
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
      tau_hat = estimates
    )

    if (any(!is.na(se_vals))) {
      data$se <- se_vals
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
        t = bt + event_times,
        k = event_times,
        tau_hat = estimates
      )

      if (any(!is.na(se_vals))) {
        df$se <- se_vals
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

  # Create gt_object (SE-only, no EIF from DIDmultiplegt)
  new_gt_object(
    data = data,
    phi = NULL,  # DIDmultiplegt doesn't provide EIF
    n = NA_integer_,  # Sample size not typically in output
    meta = list(
      source = "DIDmultiplegt",
      method = "De Chaisemartin & d'Haultfoeuille (2020)",
      note = "Dynamic effects mapped to (cohort, time) format",
      didmultiplegt_original = x
    )
  )
}

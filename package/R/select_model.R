#' Select Best Model from Cross-Validation Results
#'
#' Selects the best temporal extrapolation model based on cross-validation
#' metrics. Supports selection by MSPE alone or combined MSPE and coverage criteria.
#'
#' @param cv_result A `cv_extrapolate` object from [cv_extrapolate_ATT()].
#' @param criterion Selection criterion. Options:
#'   \itemize{
#'     \item `"mspe"` - Select model with lowest average MSPE (default)
#'     \item `"coverage"` - Select model with coverage closest to nominal
#'       among models within `tolerance` of best MSPE
#'     \item `"combined"` - Weighted combination: ranks MSPE and coverage,
#'       selects model with best average rank
#'   }
#' @param tolerance For `"coverage"` criterion: MSPE tolerance as proportion
#'   of best MSPE (default 0.1 = 10% worse than best). Models within this
#'   tolerance are considered, then coverage is used to break ties.
#' @param target_coverage Target coverage rate for `"coverage"` criterion
#'   (default: level from cv_result, or 0.95).
#'
#' @details
#' ## Selection Criteria
#'
#' - **mspe**: Selects argmin(average MSPE). This is the default and matches
#'   the paper's recommendation (Section 5.2).
#'
#' - **coverage**: Among models with MSPE within `tolerance` of the best,
#'   selects the model with coverage rate closest to nominal. Useful when
#'   multiple models have similar extrapolation error but differ in uncertainty
#'   quantification.
#'
#' - **combined**: Ranks models by MSPE (lower = better) and by coverage
#'   distance from nominal (smaller distance = better), then selects the model
#'   with the best average rank. This balances prediction accuracy and
#'   calibration.
#'
#' @return A character scalar: the name of the selected model.
#'
#' @examples
#' # Create mock data (need sufficient time periods for quadratic)
#' set.seed(456)
#' n <- 100
#' gt_data <- data.frame(
#'   g = rep(c(0, 1), each = 5),
#'   t = rep(1:5, 2),
#'   tau_hat = rnorm(10, 0.5, 0.1),
#'   k = rep(1:5, 2) - rep(c(0, 1), each = 5)
#' )
#'
#' gt_obj <- list(
#'   data = gt_data,
#'   phi = lapply(1:10, function(i) rnorm(n, sd = 0.1)),
#'   times = 1:5,
#'   groups = c(0, 1),
#'   event_times = unique(gt_data$k),
#'   n = n
#' )
#' class(gt_obj) <- c("gt_object", "extrapolateATT")
#'
#' # Run CV (with enough points for quadratic model)
#' models <- build_model_specs(c("linear", "quadratic"))
#' cv_result <- cv_extrapolate_ATT(gt_obj, models, horizons = 1:2,
#'                                  future_value = 6, compute_coverage = FALSE)
#'
#' # Select by MSPE (default)
#' best <- select_best_model(cv_result, criterion = "mspe")
#' print(best)
#'
#' # Use selected model
#' result <- extrapolate_ATT(gt_obj, h_fun = models[[best]]$h_fun,
#'                           dh_fun = models[[best]]$dh_fun, future_value = 6)
#' print(result$tau_g_future)
#'
#' @export
select_best_model <- function(cv_result,
                               criterion = c("mspe", "coverage", "combined"),
                               tolerance = 0.1,
                               target_coverage = NULL) {
  # Validate input
  if (!inherits(cv_result, "cv_extrapolate")) {
    stop("cv_result must be a cv_extrapolate object from cv_extrapolate_ATT()", call. = FALSE)
  }

  criterion <- match.arg(criterion)

  if (criterion %in% c("coverage", "combined") && !cv_result$compute_coverage) {
    stop(stringr::str_glue(
      'criterion = "{criterion}" requires coverage to be computed. ',
      'Re-run cv_extrapolate_ATT() with compute_coverage = TRUE.'
    ), call. = FALSE)
  }

  # Set default target coverage
  if (is.null(target_coverage)) {
    target_coverage <- if (!is.null(cv_result$level)) cv_result$level else 0.95
  }

  validate_confidence_level(target_coverage, name = "target_coverage")

  # Get average metrics
  avg_metrics <- cv_result$avg_mspe

  if (nrow(avg_metrics) == 0) {
    stop("cv_result contains no models to select from", call. = FALSE)
  }

  # Selection logic
  selected_model <- switch(
    criterion,

    # Criterion 1: Lowest MSPE
    mspe = {
      avg_metrics$model[which.min(avg_metrics$avg_mspe)]
    },

    # Criterion 2: Best coverage among models with similar MSPE
    coverage = {
      best_mspe <- min(avg_metrics$avg_mspe)
      mspe_threshold <- best_mspe * (1 + tolerance)

      # Filter to models within tolerance
      candidates <- avg_metrics[avg_metrics$avg_mspe <= mspe_threshold, ]

      if (nrow(candidates) == 0) {
        # Shouldn't happen, but be defensive
        candidates <- avg_metrics[1, ]
      }

      # Among candidates, select model with coverage closest to target
      candidates$cov_distance <- abs(candidates$avg_coverage - target_coverage)
      candidates$model[which.min(candidates$cov_distance)]
    },

    # Criterion 3: Combined rank (MSPE rank + coverage rank)
    combined = {
      # Rank by MSPE (lower is better, so rank 1 = best)
      avg_metrics$mspe_rank <- rank(avg_metrics$avg_mspe, ties.method = "min")

      # Rank by coverage distance from target (smaller distance is better)
      avg_metrics$cov_distance <- abs(avg_metrics$avg_coverage - target_coverage)
      avg_metrics$cov_rank <- rank(avg_metrics$cov_distance, ties.method = "min")

      # Average rank
      avg_metrics$avg_rank <- (avg_metrics$mspe_rank + avg_metrics$cov_rank) / 2

      # Select model with best (lowest) average rank
      avg_metrics$model[which.min(avg_metrics$avg_rank)]
    }
  )

  as.character(selected_model)
}

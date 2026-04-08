#' Time-Series Cross-Validation for Temporal Extrapolation Models
#'
#' Implements the time-series CV procedure from Section 5.2 to evaluate candidate
#' temporal models for extrapolation. Tests each model by holding out late periods,
#' fitting on earlier data, and computing mean squared prediction error (MSPE) on
#' held-out future observations.
#'
#' @param gt_object An object produced by [estimate_group_time_ATT()].
#' @param model_specs A named list of model specifications. Each element must
#'   contain: `h_fun`, `dh_fun`, and `name`. Use [build_model_specs()] to
#'   construct standard specifications.
#' @param horizons Integer vector of forecast horizons to test (e.g., `1:3`).
#'   For each horizon `h`, the function holds out the last `h` periods as test
#'   data and fits models on earlier periods.
#' @param future_value Numeric scalar: the actual future time to extrapolate to
#'   (e.g., `p + 1`). This is used to determine the data range and is distinct
#'   from the CV horizons.
#' @param time_scale One of `"calendar"` or `"event"`; determines whether
#'   sequences are constructed over calendar times `t` or event times `k = t - g`.
#' @param compute_coverage Logical; if `TRUE`, compute 95% confidence interval
#'   coverage rates for each model (requires EIF propagation, computationally
#'   expensive). Default: `FALSE`.
#' @param omega Optional numeric vector of group weights for aggregation. If
#'   provided, computes aggregated predictions across groups. If `NULL`, uses
#'   equal weights.
#' @param level Confidence level for coverage computation (default 0.95).
#'   Only used if `compute_coverage = TRUE`.
#' @param ... Additional arguments passed to `h_fun` and `dh_fun`.
#'
#' @details
#' ## Algorithm
#'
#' For each horizon `h` in `horizons`:
#' 1. Split data: training window is `t <= max(t) - h`, test window is
#'    `t > max(t) - h`.
#' 2. For each model in `model_specs`:
#'    - For each (group, test_time) pair in test window:
#'      - Fit model on training data for that group
#'      - Extrapolate to test_time
#'      - Compare prediction to observed ATT
#'    - Compute MSPE: `(1 / |G| * h) * sum((predicted - observed)^2)`
#' 3. Average MSPE across horizons: `MSPE_m = mean(MSPE_m(h))`
#' 4. Select best model: `argmin(MSPE_m)`
#'
#' ## Return Structure
#'
#' An S3 object of class `cv_extrapolate` containing:
#' - `results`: Tibble with columns `model`, `horizon`, `mspe`, `coverage`
#' - `best_model`: Name of model with lowest average MSPE
#' - `avg_mspe`: Average MSPE for each model across horizons
#' - `predictions`: Detailed predictions for each (model, horizon, group, time)
#' - `model_specs`: The input model specifications
#' - `horizons`: The input horizons
#' - `compute_coverage`: Whether coverage was computed
#'
#' @section Reference:
#' This implements the time-series cross-validation procedure from Section 5.2
#' of the paper. See [select_best_model()] for model selection and
#' [average_models()] for model averaging with exponential weights.
#'
#' @return An S3 object of class `cv_extrapolate` with CV results and diagnostics.
#'
#' @examples
#' # Create example data with quadratic trend
#' set.seed(123)
#' n <- 100
#' groups <- c(0, 1)
#' times <- 1:6
#'
#' data_list <- list()
#' phi_list <- list()
#' idx <- 1
#'
#' for (g in groups) {
#'   for (t in times) {
#'     # Quadratic DGP
#'     tau_true <- 0.1 + 0.05 * t + 0.02 * t^2
#'     data_list[[idx]] <- data.frame(g = g, t = t,
#'                                     tau_hat = tau_true + rnorm(1, sd = 0.01),
#'                                     k = t - g)
#'     phi_list[[idx]] <- rnorm(n, sd = 0.1)
#'     idx <- idx + 1
#'   }
#' }
#'
#' gt_obj <- list(
#'   data = do.call(rbind, data_list),
#'   phi = phi_list,
#'   times = 1:6,
#'   groups = groups,
#'   event_times = unique(do.call(rbind, data_list)$k),
#'   n = n
#' )
#' class(gt_obj) <- c("gt_object", "extrapolateATT")
#'
#' # Build model specifications
#' models <- build_model_specs(c("linear", "quadratic"))
#'
#' # Run time-series CV
#' cv_result <- cv_extrapolate_ATT(
#'   gt_obj,
#'   model_specs = models,
#'   horizons = 1:2,
#'   future_value = 7,
#'   time_scale = "calendar",
#'   compute_coverage = FALSE
#' )
#'
#' # View results
#' print(cv_result)
#' summary(cv_result)
#' plot(cv_result)
#'
#' # Quadratic should win (data is quadratic)
#' print(cv_result$best_model)
#'
#' # Use selected model for extrapolation
#' best_spec <- models[[cv_result$best_model]]
#' result <- extrapolate_ATT(
#'   gt_obj,
#'   h_fun = best_spec$h_fun,
#'   dh_fun = best_spec$dh_fun,
#'   future_value = 7,
#'   time_scale = "calendar"
#' )
#'
#' @export
cv_extrapolate_ATT <- function(gt_object,
                                model_specs,
                                horizons,
                                future_value,
                                time_scale = c("calendar", "event"),
                                compute_coverage = FALSE,
                                omega = NULL,
                                level = 0.95,
                                ...) {
  # Input validation
  validate_gt_object(gt_object, name = "gt_object")
  validate_model_specs(model_specs, name = "model_specs")
  time_scale <- match.arg(time_scale)
  validate_scalar(future_value, name = "future_value")

  if (!is.logical(compute_coverage) || length(compute_coverage) != 1) {
    stop("compute_coverage must be a logical scalar", call. = FALSE)
  }

  if (compute_coverage) {
    validate_confidence_level(level, name = "level")
    if (is.null(gt_object$phi)) {
      stop("compute_coverage = TRUE requires EIFs (gt_object$phi must not be NULL)", call. = FALSE)
    }
  }

  # Prepare data
  df <- gt_object$data
  groups <- gt_object$groups
  n <- gt_object$n

  # Choose time variable
  if (time_scale == "calendar") {
    if (!"t" %in% names(df)) {
      stop("time_scale = 'calendar' requires column 't' in data", call. = FALSE)
    }
    df$time_var <- df$t
  } else {
    if (!"k" %in% names(df)) {
      if (!"t" %in% names(df) || !"g" %in% names(df)) {
        stop("time_scale = 'event' requires columns 't' and 'g' to compute k = t - g", call. = FALSE)
      }
      df$k <- df$t - df$g
    }
    df$time_var <- df$k
  }

  # Get max available time
  max_time <- max(df$time_var)

  # Validate horizons against available data
  validate_horizons(horizons, max_available = max_time, name = "horizons")

  # Set default omega (equal weights) if not provided
  if (is.null(omega)) {
    omega <- rep(1 / length(groups), length(groups))
  } else {
    validate_group_weights(omega, n_groups = length(groups), name = "omega", warn_sum = FALSE)
  }

  # Storage for results
  all_predictions <- list()
  cv_results <- list()

  # Main CV loop: iterate over horizons
  for (h in horizons) {
    train_cutoff <- max_time - h

    # Check sufficient training data
    if (train_cutoff < min(df$time_var)) {
      warning(stringr::str_glue(
        "Horizon h = {h} leaves no training data (cutoff = {train_cutoff}, min time = {min(df$time_var)}). Skipping."
      ), call. = FALSE)
      next
    }

    # Split train/test
    train_data <- df[df$time_var <= train_cutoff, ]
    test_data <- df[df$time_var > train_cutoff, ]

    if (nrow(test_data) == 0) {
      warning(stringr::str_glue("Horizon h = {h} has no test data. Skipping."), call. = FALSE)
      next
    }

    # Iterate over models
    for (model_name in names(model_specs)) {
      spec <- model_specs[[model_name]]

      # Storage for this (model, horizon) combination
      pred_list <- list()

      # Iterate over test observations
      for (i in seq_len(nrow(test_data))) {
        test_row <- test_data[i, ]
        test_group <- test_row$g
        test_time <- test_row$time_var
        test_tau_obs <- test_row$tau_hat

        # Get training data for this group
        train_group_data <- train_data[train_data$g == test_group, ]

        # Check sufficient training observations for this group
        p_train <- nrow(train_group_data)
        if (p_train < 2) {
          # Need at least 2 observations for linear (most models need >= 2)
          warning(stringr::str_glue(
            "Group {test_group}, horizon {h}: insufficient training data (p = {p_train}). Skipping."
          ), call. = FALSE)
          next
        }

        # Extract times and tau values for this group (ordered)
        train_group_data <- train_group_data[order(train_group_data$time_var), ]
        times_train <- train_group_data$time_var
        tau_train <- train_group_data$tau_hat

        # Get EIF vectors if needed
        phi_train <- NULL
        if (compute_coverage && !is.null(gt_object$phi)) {
          # Match rows in original data to get phi indices
          train_indices <- which(df$g == test_group & df$time_var %in% times_train)
          train_indices <- train_indices[order(df$time_var[train_indices])]
          phi_train <- gt_object$phi[train_indices]
        }

        # Predict test_time using this model
        # Build h_fun and dh_fun for this group's training data
        h_func <- spec$h_fun(times_train, test_time, ...)
        tau_pred <- h_func(tau_train)

        # Compute standard error if needed
        se_pred <- NA_real_
        ci_lower <- NA_real_
        ci_upper <- NA_real_
        in_ci <- NA

        if (compute_coverage && !is.null(phi_train)) {
          # Propagate EIF
          dh_vec <- spec$dh_fun(times_train, test_time, ...)

          # Build phi matrix (n x p_train)
          phi_mat <- fast_cbind_list(phi_train)

          # Propagate: phi_future = phi_mat %*% dh_vec
          phi_pred <- as.numeric(phi_mat %*% dh_vec)

          # Variance estimate
          var_pred <- mean(phi_pred^2)
          se_pred <- sqrt(var_pred)

          # Confidence interval
          z_crit <- qnorm(1 - (1 - level) / 2)
          ci_lower <- tau_pred - z_crit * se_pred
          ci_upper <- tau_pred + z_crit * se_pred

          # Check coverage
          in_ci <- (test_tau_obs >= ci_lower) && (test_tau_obs <= ci_upper)
        }

        # Store prediction
        pred_list[[length(pred_list) + 1]] <- tibble::tibble(
          model = model_name,
          horizon = h,
          g = test_group,
          time = test_time,
          tau_obs = test_tau_obs,
          tau_pred = tau_pred,
          se = se_pred,
          ci_lower = ci_lower,
          ci_upper = ci_upper,
          in_ci = in_ci
        )
      }

      # Combine predictions for this (model, horizon)
      if (length(pred_list) > 0) {
        pred_df <- dplyr::bind_rows(pred_list)

        # Compute MSPE
        mspe <- mean((pred_df$tau_pred - pred_df$tau_obs)^2)

        # Compute coverage if applicable
        coverage_rate <- NA_real_
        if (compute_coverage) {
          coverage_rate <- mean(pred_df$in_ci, na.rm = TRUE)
        }

        # Store results
        cv_results[[length(cv_results) + 1]] <- tibble::tibble(
          model = model_name,
          horizon = h,
          mspe = mspe,
          coverage = coverage_rate,
          n_test = nrow(pred_df)
        )

        # Store detailed predictions
        all_predictions[[length(all_predictions) + 1]] <- pred_df
      }
    }
  }

  # Combine all results
  if (length(cv_results) == 0) {
    stop("No CV results generated. Check that horizons are valid and sufficient training data exists.", call. = FALSE)
  }

  results_df <- dplyr::bind_rows(cv_results)
  predictions_df <- if (length(all_predictions) > 0) dplyr::bind_rows(all_predictions) else NULL

  # Compute average MSPE per model
  avg_mspe <- results_df |>
    dplyr::group_by(model) |>
    dplyr::summarise(
      avg_mspe = mean(mspe, na.rm = TRUE),
      avg_coverage = if (compute_coverage) mean(coverage, na.rm = TRUE) else NA_real_,
      .groups = "drop"
    ) |>
    dplyr::arrange(avg_mspe)

  # Identify best model
  best_model <- avg_mspe$model[1]

  # Build output object
  out <- list(
    results = results_df,
    best_model = as.character(best_model),
    avg_mspe = avg_mspe,
    predictions = predictions_df,
    model_specs = model_specs,
    horizons = horizons,
    future_value = future_value,
    time_scale = time_scale,
    compute_coverage = compute_coverage,
    level = if (compute_coverage) level else NULL
  )

  class(out) <- c("cv_extrapolate", "extrapolateATT")
  out
}

#' Print method for cv_extrapolate objects
#'
#' @param x A `cv_extrapolate` object
#' @param ... Additional arguments (ignored)
#' @export
print.cv_extrapolate <- function(x, ...) {
  cat("Time-Series Cross-Validation Results\n")
  cat(stringr::str_glue("Time scale: {x$time_scale}\n"))
  cat(stringr::str_glue("Horizons tested: {stringr::str_c(x$horizons, collapse = ', ')}\n"))
  cat(stringr::str_glue("Number of models: {length(x$model_specs)}\n"))
  cat(stringr::str_glue("Coverage computed: {x$compute_coverage}\n\n"))

  cat("Average MSPE by model:\n")
  print(x$avg_mspe, n = Inf)

  cat(stringr::str_glue("\nBest model (lowest MSPE): {x$best_model}\n"))

  invisible(x)
}

#' Summary method for cv_extrapolate objects
#'
#' @param object A `cv_extrapolate` object
#' @param ... Additional arguments (ignored)
#' @export
summary.cv_extrapolate <- function(object, ...) {
  cat("===== Time-Series Cross-Validation Summary =====\n\n")

  # Overall settings
  cat("Settings:\n")
  cat(stringr::str_glue("  Time scale: {object$time_scale}\n"))
  cat(stringr::str_glue("  Horizons: {stringr::str_c(object$horizons, collapse = ', ')}\n"))
  cat(stringr::str_glue("  Models tested: {length(object$model_specs)}\n"))
  cat(stringr::str_glue("  Coverage computed: {object$compute_coverage}\n"))
  if (object$compute_coverage) {
    cat(stringr::str_glue("  Confidence level: {object$level}\n"))
  }
  cat("\n")

  # Detailed results by model and horizon
  cat("Results by Model and Horizon:\n")
  print(object$results, n = Inf)
  cat("\n")

  # Average MSPE summary
  cat("Average MSPE across horizons:\n")
  print(object$avg_mspe, n = Inf)
  cat("\n")

  # Best model
  cat(stringr::str_glue("Best model: {object$best_model} (MSPE = {round(object$avg_mspe$avg_mspe[1], 6)})\n"))

  # MSPE range
  mspe_range <- range(object$avg_mspe$avg_mspe)
  mspe_ratio <- mspe_range[2] / mspe_range[1]
  cat(stringr::str_glue("MSPE range: [{round(mspe_range[1], 6)}, {round(mspe_range[2], 6)}] (ratio: {round(mspe_ratio, 2)})\n"))

  # Coverage summary if available
  if (object$compute_coverage) {
    cat("\nCoverage Summary:\n")
    for (i in seq_len(nrow(object$avg_mspe))) {
      model_name <- object$avg_mspe$model[i]
      avg_cov <- object$avg_mspe$avg_coverage[i]
      cat(stringr::str_glue("  {model_name}: {round(avg_cov * 100, 1)}%\n"))
    }
  }

  # Diagnostics
  cat("\nDiagnostics:\n")
  n_test_total <- sum(object$results$n_test)
  cat(stringr::str_glue("  Total test observations: {n_test_total}\n"))

  if (!is.null(object$predictions)) {
    n_groups <- length(unique(object$predictions$g))
    cat(stringr::str_glue("  Number of groups: {n_groups}\n"))
  }

  invisible(object)
}

#' Plot method for cv_extrapolate objects
#'
#' Produces diagnostic plots for cross-validation results. Creates a multi-panel
#' plot showing: (1) MSPE by horizon for each model, (2) Average MSPE comparison,
#' and optionally (3) Coverage rates by horizon.
#'
#' @param x A `cv_extrapolate` object
#' @param ... Additional arguments (ignored)
#' @export
plot.cv_extrapolate <- function(x, ...) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is required for plotting. Install with: install.packages('ggplot2')", call. = FALSE)
  }

  # Determine number of panels
  n_panels <- if (x$compute_coverage) 3 else 2

  # Store old par settings
  old_par <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(old_par))

  # Set up multi-panel plot
  if (n_panels == 2) {
    graphics::par(mfrow = c(1, 2))
  } else {
    graphics::par(mfrow = c(2, 2))
  }

  # Panel 1: MSPE by horizon
  results_wide <- tidyr::pivot_wider(
    x$results,
    id_cols = horizon,
    names_from = model,
    values_from = mspe
  )

  plot(x$results$horizon, x$results$mspe,
       type = "n",
       xlab = "Horizon",
       ylab = "MSPE",
       main = "MSPE by Horizon",
       xlim = range(x$horizons),
       ylim = range(x$results$mspe, na.rm = TRUE) * c(0.9, 1.1))

  # Plot each model with different color
  colors <- grDevices::rainbow(length(x$model_specs))
  for (i in seq_along(names(x$model_specs))) {
    model_name <- names(x$model_specs)[i]
    model_data <- x$results[x$results$model == model_name, ]
    graphics::lines(model_data$horizon, model_data$mspe, col = colors[i], lwd = 2)
    graphics::points(model_data$horizon, model_data$mspe, col = colors[i], pch = 19)
  }
  graphics::legend("topleft", legend = names(x$model_specs), col = colors, lwd = 2, pch = 19, cex = 0.8)

  # Panel 2: Average MSPE comparison
  graphics::barplot(
    x$avg_mspe$avg_mspe,
    names.arg = x$avg_mspe$model,
    col = colors,
    main = "Average MSPE by Model",
    ylab = "Average MSPE",
    las = 2,  # Rotate labels
    cex.names = 0.8
  )

  # Add a star to the best model
  best_idx <- which(x$avg_mspe$model == x$best_model)
  graphics::text(best_idx, x$avg_mspe$avg_mspe[best_idx],
       labels = "*",
       pos = 3, cex = 2, col = "black")

  # Panel 3: Coverage by horizon (if computed)
  if (x$compute_coverage) {
    plot(x$results$horizon, x$results$coverage,
         type = "n",
         xlab = "Horizon",
         ylab = "Coverage Rate",
         main = "Coverage by Horizon",
         xlim = range(x$horizons),
         ylim = c(0, 1))

    # Add nominal coverage line
    graphics::abline(h = if (!is.null(x$level)) x$level else 0.95,
           lty = 2, col = "gray50", lwd = 2)

    # Plot each model
    for (i in seq_along(names(x$model_specs))) {
      model_name <- names(x$model_specs)[i]
      model_data <- x$results[x$results$model == model_name, ]
      graphics::lines(model_data$horizon, model_data$coverage, col = colors[i], lwd = 2)
      graphics::points(model_data$horizon, model_data$coverage, col = colors[i], pch = 19)
    }
    graphics::legend("topleft", legend = c("Nominal", names(x$model_specs)),
           col = c("gray50", colors),
           lty = c(2, rep(1, length(colors))),
           lwd = 2, pch = c(NA, rep(19, length(colors))),
           cex = 0.7)
  }

  invisible(x)
}

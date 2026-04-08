#' Model-Averaged Extrapolation with Exponential Weights
#'
#' Computes a model-averaged future ATT estimate by running extrapolation with
#' each candidate model and combining results with exponential weights based on
#' cross-validation MSPE. Propagates EIFs through the weighted average for
#' valid uncertainty quantification.
#'
#' @param cv_result A `cv_extrapolate` object from [cv_extrapolate_ATT()].
#' @param gt_object The `gt_object` used in the original CV (from
#'   [estimate_group_time_ATT()]).
#' @param future_value Numeric scalar: the future time to extrapolate to.
#' @param time_scale One of `"calendar"` or `"event"`; must match cv_result.
#' @param temperature Numeric scalar controlling weight concentration (default 1).
#'   Weights are `w_m ∝ exp(-MSPE_m / temperature)`. Lower temperature = more
#'   concentration on best model; higher temperature = more uniform weights.
#' @param omega Optional group weights for aggregation. If provided, returns
#'   aggregated estimate; if `NULL`, returns per-group estimates.
#' @param per_group Logical; if `TRUE`, return per-group results. If `FALSE`,
#'   aggregate across groups (requires `omega`).
#' @param ... Additional arguments passed to model h_fun and dh_fun.
#'
#' @details
#' ## Algorithm
#'
#' 1. Compute exponential weights: `w_m = exp(-MSPE_m / temp) / Z` where
#'    `Z = sum(exp(-MSPE_m / temp))` ensures weights sum to 1.
#' 2. For each model `m`, run [extrapolate_ATT()] to get `tau_m` and `phi_m`.
#' 3. Compute weighted average: `tau_avg = sum(w_m * tau_m)`.
#' 4. Propagate EIFs: `phi_avg = sum(w_m * phi_m)`.
#'
#' The resulting `phi_avg` is the correct influence function for the
#' model-averaged estimator, enabling valid inference via the usual variance
#' formula: `Var(tau_avg) = mean(phi_avg^2)`.
#'
#' ## Temperature Parameter
#'
#' - `temperature = 1` (default): Standard exponential weighting
#' - `temperature -> 0`: Winner-take-all (all weight on best model)
#' - `temperature -> Inf`: Uniform weights (equal averaging)
#'
#' ## Reference
#'
#' Implements the model averaging approach from Section 5.2 of the paper.
#' Exponential weights are a principled way to combine predictions based on
#' out-of-sample performance (analogous to stacking or Bayesian model averaging
#' with MSPE as pseudo-log-likelihood).
#'
#' @return An `extrap_object` with model-averaged estimates and EIFs. Contains:
#' - `tau_g_future`: Per-group averaged estimates
#' - `phi_g_future`: Per-group averaged EIFs
#' - `tau_future`, `phi_future`: Aggregated estimates (if `per_group = FALSE`)
#' - `weights`: Named vector of model weights
#' - `model_results`: List of individual model results (for diagnostics)
#'
#' @examples
#' # Create mock data (need sufficient time periods)
#' set.seed(789)
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
#' # Run CV
#' models <- build_model_specs(c("linear", "quadratic"))
#' cv_result <- cv_extrapolate_ATT(gt_obj, models, horizons = 1:2,
#'                                  future_value = 6, compute_coverage = FALSE)
#'
#' # Model-averaged extrapolation
#' avg_result <- average_models(cv_result, gt_obj, future_value = 6,
#'                               time_scale = "calendar", temperature = 1,
#'                               per_group = TRUE)
#'
#' # Check weights (models with lower MSPE get higher weight)
#' print(avg_result$weights)
#'
#' # Extract averaged estimate
#' print(avg_result$tau_g_future)
#'
#' # Try different temperatures
#' # Winner-take-all (temperature near 0)
#' avg_concentrated <- average_models(cv_result, gt_obj, future_value = 6,
#'                                    time_scale = "calendar", temperature = 0.1,
#'                                    per_group = TRUE)
#' print(avg_concentrated$weights)
#'
#' # Uniform (temperature large)
#' avg_uniform <- average_models(cv_result, gt_obj, future_value = 6,
#'                               time_scale = "calendar", temperature = 10,
#'                               per_group = TRUE)
#' print(avg_uniform$weights)
#'
#' @export
average_models <- function(cv_result,
                            gt_object,
                            future_value,
                            time_scale = c("calendar", "event"),
                            temperature = 1,
                            omega = NULL,
                            per_group = TRUE,
                            ...) {
  # Input validation
  if (!inherits(cv_result, "cv_extrapolate")) {
    stop("cv_result must be a cv_extrapolate object from cv_extrapolate_ATT()", call. = FALSE)
  }

  validate_gt_object(gt_object, name = "gt_object")
  validate_scalar(future_value, name = "future_value")
  validate_scalar(temperature, name = "temperature")

  if (temperature <= 0) {
    stop("temperature must be positive", call. = FALSE)
  }

  time_scale <- match.arg(time_scale)

  # Check time_scale matches cv_result
  if (time_scale != cv_result$time_scale) {
    warning(stringr::str_glue(
      "time_scale = '{time_scale}' differs from cv_result$time_scale = '{cv_result$time_scale}'. ",
      "Using provided time_scale, but this may be inconsistent."
    ), call. = FALSE)
  }

  # Compute exponential weights
  avg_mspe <- cv_result$avg_mspe$avg_mspe
  names(avg_mspe) <- cv_result$avg_mspe$model

  # Check for NA values in MSPE
  if (any(is.na(avg_mspe))) {
    stop("CV results contain NA values for MSPE. Check that horizons produced valid test data.", call. = FALSE)
  }

  # Handle edge case: if all MSPE are identical, use uniform weights
  if (length(avg_mspe) == 1 || stats::sd(avg_mspe) < 1e-10) {
    weights <- rep(1 / length(avg_mspe), length(avg_mspe))
    names(weights) <- names(avg_mspe)
    if (length(avg_mspe) > 1) {
      message("All models have nearly identical MSPE; using uniform weights.")
    }
  } else {
    # Exponential weighting: w_m ∝ exp(-MSPE_m / temp)
    log_weights <- -avg_mspe / temperature

    # Normalize to avoid overflow (subtract max)
    log_weights <- log_weights - max(log_weights)
    weights <- exp(log_weights)
    weights <- weights / sum(weights)
  }

  # Run extrapolation for each model
  model_specs <- cv_result$model_specs
  model_results <- list()
  groups <- gt_object$groups

  for (model_name in names(model_specs)) {
    spec <- model_specs[[model_name]]

    # Run extrapolate_ATT for this model
    extrap_result <- extrapolate_ATT(
      gt_object,
      h_fun = spec$h_fun,
      dh_fun = spec$dh_fun,
      future_value = future_value,
      time_scale = time_scale,
      per_group = TRUE,  # Always get per-group first
      ...
    )

    model_results[[model_name]] <- extrap_result
  }

  # Weighted average of tau_g_future
  tau_g_list <- purrr::map(model_results, ~ .x$tau_g_future$tau_future)
  tau_g_matrix <- do.call(cbind, tau_g_list)  # groups x models

  # Apply weights: each row is weighted average across models
  tau_g_avg <- as.numeric(tau_g_matrix %*% weights)

  # Weighted average of phi_g_future
  # Each model_results[[m]]$phi_g_future is a list of EIF vectors (one per group)
  phi_g_avg <- list()

  for (g_idx in seq_along(groups)) {
    # Get phi vectors for this group from each model
    phi_list <- purrr::map(model_results, ~ .x$phi_g_future[[g_idx]])

    # Stack into matrix (n x M)
    phi_matrix <- do.call(cbind, phi_list)

    # Weighted average: phi_avg = phi_matrix %*% weights
    phi_g_avg[[g_idx]] <- as.numeric(phi_matrix %*% weights)
  }

  names(phi_g_avg) <- groups

  # Build per-group result tibble
  tau_g_future <- tibble::tibble(
    g = groups,
    tau_future = tau_g_avg
  )

  # Build output object
  out <- list(
    tau_g_future = tau_g_future,
    phi_g_future = phi_g_avg,
    weights = weights,
    model_results = model_results,
    temperature = temperature,
    model_names = names(model_specs)
  )

  # Aggregate across groups if requested
  if (!per_group) {
    if (is.null(omega)) {
      stop("omega is required when per_group = FALSE (aggregation requested)", call. = FALSE)
    }

    validate_group_weights(omega, n_groups = length(groups), name = "omega", warn_sum = TRUE)

    # Aggregate tau
    tau_future <- sum(omega * tau_g_avg)

    # Aggregate phi
    phi_future <- purrr::map2(omega, phi_g_avg, \(w, phi) w * phi) |>
      purrr::reduce(`+`)

    out$tau_future <- tau_future
    out$phi_future <- phi_future
  }

  class(out) <- c("extrap_object_averaged", "extrap_object", "extrapolateATT")
  out
}

#' Print method for extrap_object_averaged
#'
#' @param x An `extrap_object_averaged` object
#' @param ... Additional arguments (ignored)
#' @export
print.extrap_object_averaged <- function(x, ...) {
  cat("Model-Averaged Extrapolation Results\n")
  cat(stringr::str_glue("Number of models: {length(x$model_names)}\n"))
  cat(stringr::str_glue("Temperature: {x$temperature}\n\n"))

  cat("Model weights:\n")
  weights_df <- tibble::tibble(
    model = names(x$weights),
    weight = as.numeric(x$weights)
  ) |> dplyr::arrange(dplyr::desc(weight))
  print(weights_df, n = Inf)

  cat("\nPer-group averaged estimates:\n")
  print(x$tau_g_future, n = Inf)

  if ("tau_future" %in% names(x)) {
    cat(stringr::str_glue("\nAggregated estimate: {round(x$tau_future, 4)}\n"))
  }

  invisible(x)
}

#' Build Model Specifications for Cross-Validation
#'
#' Factory function to construct properly formatted model specifications for
#' time-series cross-validation. Simplifies creating candidate model lists by
#' providing common temporal extrapolation models (linear, quadratic, spline).
#'
#' @param model_names Character vector of model names to include. Options:
#'   \itemize{
#'     \item `"linear"` - Linear trend extrapolation (requires p >= 2)
#'     \item `"quadratic"` - Quadratic trend extrapolation (requires p >= 3)
#'   }
#' @param custom_models Optional named list of custom model specifications to
#'   append. Each element must be a list with fields: `h_fun`, `dh_fun`, `name`.
#'
#' @details
#' This function creates a named list of model specifications suitable for use
#' with [cv_extrapolate_ATT()]. Each specification contains:
#' \itemize{
#'   \item `h_fun` - Function factory: `function(times, future_time)` returns a
#'     function that maps observed ATTs to extrapolated values
#'   \item `dh_fun` - Jacobian function: `function(times, future_time)` returns
#'     a numeric vector of partial derivatives for EIF propagation
#'   \item `name` - Character name for display in results
#' }
#'
#' See [hg_linear()] and [hg_quadratic()] for the interface design rationale.
#'
#' @return A named list of model specifications suitable for [cv_extrapolate_ATT()].
#'
#' @examples
#' # Build linear and quadratic models
#' models <- build_model_specs(c("linear", "quadratic"))
#' names(models)  # "linear", "quadratic"
#'
#' # Build only linear model
#' models_linear <- build_model_specs("linear")
#'
#' # Add a custom model
#' custom <- list(
#'   constant = list(
#'     h_fun = function(times, future_time) {
#'       function(tau_g) mean(tau_g)
#'     },
#'     dh_fun = function(times, future_time) {
#'       rep(1 / length(times), length(times))
#'     },
#'     name = "constant"
#'   )
#' )
#' models_with_custom <- build_model_specs("linear", custom_models = custom)
#'
#' @export
build_model_specs <- function(model_names = c("linear", "quadratic"),
                               custom_models = NULL) {
  # Validate inputs
  if (!is.character(model_names)) {
    stop("model_names must be a character vector", call. = FALSE)
  }

  if (length(model_names) == 0) {
    stop("model_names cannot be empty", call. = FALSE)
  }

  # Check for valid model names
  valid_names <- c("linear", "quadratic")
  invalid <- setdiff(model_names, valid_names)
  if (length(invalid) > 0) {
    invalid_str <- stringr::str_c(invalid, collapse = ", ")
    valid_str <- stringr::str_c(valid_names, collapse = ", ")
    stop(stringr::str_glue(
      "Invalid model names: {invalid_str}. Valid options: {valid_str}"
    ), call. = FALSE)
  }

  # Build specifications list
  specs <- list()

  # Linear model
  if ("linear" %in% model_names) {
    specs$linear <- list(
      h_fun = hg_linear,
      dh_fun = dh_linear,
      name = "linear"
    )
  }

  # Quadratic model
  if ("quadratic" %in% model_names) {
    specs$quadratic <- list(
      h_fun = hg_quadratic,
      dh_fun = dh_quadratic,
      name = "quadratic"
    )
  }

  # Append custom models if provided
  if (!is.null(custom_models)) {
    if (!is.list(custom_models)) {
      stop("custom_models must be a named list", call. = FALSE)
    }

    if (is.null(names(custom_models)) || any(names(custom_models) == "")) {
      stop("custom_models must have names for all elements", call. = FALSE)
    }

    # Check for name conflicts
    conflicts <- intersect(names(specs), names(custom_models))
    if (length(conflicts) > 0) {
      conflicts_str <- stringr::str_c(conflicts, collapse = ", ")
      stop(stringr::str_glue(
        "Name conflict: custom_models contains names already in use: {conflicts_str}"
      ), call. = FALSE)
    }

    # Validate custom model structure (basic check)
    for (i in seq_along(custom_models)) {
      custom_name <- names(custom_models)[i]
      custom_spec <- custom_models[[i]]

      required_fields <- c("h_fun", "dh_fun", "name")
      missing <- setdiff(required_fields, names(custom_spec))

      if (length(missing) > 0) {
        missing_str <- stringr::str_c(missing, collapse = ", ")
        stop(stringr::str_glue(
          "custom_models[['{custom_name}']] is missing required fields: {missing_str}"
        ), call. = FALSE)
      }
    }

    # Append custom models
    specs <- c(specs, custom_models)
  }

  # Final validation
  validate_model_specs(specs, name = "model_specs")

  specs
}

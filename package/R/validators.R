#' Input Validation Helpers
#'
#' Internal validation functions to ensure type safety, dimension consistency,
#' and informative error messages. Used throughout the package to catch issues
#' early with clear diagnostic information.
#'
#' @name validators
#' @keywords internal
NULL

#' Validate numeric vector
#'
#' @param x Vector to validate
#' @param name Variable name for error messages
#' @param allow_na Whether to allow NA values
#' @keywords internal
validate_numeric_vector <- function(x, name = "x", allow_na = FALSE) {
  if (!is.numeric(x)) {
    stop(sprintf("%s must be numeric, got %s", name, class(x)[1]), call. = FALSE)
  }
  if (!allow_na && any(is.na(x))) {
    n_na <- sum(is.na(x))
    stop(sprintf("%s contains %d NA value(s)", name, n_na), call. = FALSE)
  }
  if (any(is.infinite(x))) {
    n_inf <- sum(is.infinite(x))
    stop(sprintf("%s contains %d Inf value(s)", name, n_inf), call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate EIF list structure
#'
#' @param phi List of EIF vectors
#' @param n Expected length of each vector
#' @param name Variable name for error messages
#' @keywords internal
validate_eif_list <- function(phi, n, name = "phi") {
  if (!is.list(phi)) {
    stop(sprintf("%s must be a list of EIF vectors, got %s", name, class(phi)[1]), call. = FALSE)
  }

  if (length(phi) == 0) {
    stop(sprintf("%s is an empty list", name), call. = FALSE)
  }

  lengths <- vapply(phi, length, integer(1))

  if (!all(lengths == n)) {
    bad_idx <- which(lengths != n)
    stop(sprintf(
      "%s: All EIF vectors must have length n = %d. Found mismatches at indices: %s (lengths: %s)",
      name, n, paste(bad_idx, collapse = ", "), paste(lengths[bad_idx], collapse = ", ")
    ), call. = FALSE)
  }

  invisible(TRUE)
}

#' Validate group weights
#'
#' @param omega Numeric vector of group weights
#' @param n_groups Expected number of groups
#' @param name Variable name for error messages
#' @param warn_sum Whether to warn if weights don't sum to 1
#' @keywords internal
validate_group_weights <- function(omega, n_groups, name = "omega", warn_sum = TRUE) {
  validate_numeric_vector(omega, name = name, allow_na = FALSE)

  if (length(omega) != n_groups) {
    stop(sprintf(
      "%s must have length %d (number of groups), got %d",
      name, n_groups, length(omega)
    ), call. = FALSE)
  }

  if (any(omega < 0)) {
    n_neg <- sum(omega < 0)
    stop(sprintf("%s must be non-negative (found %d negative value(s))", name, n_neg), call. = FALSE)
  }

  # Optional: warn if doesn't sum to 1
  if (warn_sum && abs(sum(omega) - 1) > 1e-6) {
    warning(sprintf(
      "%s does not sum to 1 (sum = %.6f). Results will be weighted but may not be interpretable as averages.",
      name, sum(omega)
    ), call. = FALSE)
  }

  invisible(TRUE)
}

#' Validate confidence level
#'
#' @param level Confidence level scalar
#' @param name Variable name for error messages
#' @keywords internal
validate_confidence_level <- function(level, name = "level") {
  validate_numeric_vector(level, name = name, allow_na = FALSE)

  if (length(level) != 1) {
    stop(sprintf("%s must be a scalar, got length %d", name, length(level)), call. = FALSE)
  }

  if (level <= 0 || level >= 1) {
    stop(sprintf("%s must be in (0, 1), got %.4f", name, level), call. = FALSE)
  }

  invisible(TRUE)
}

#' Validate gt_object structure
#'
#' @param gt_obj Object to validate
#' @param name Variable name for error messages
#' @keywords internal
validate_gt_object <- function(gt_obj, name = "gt_object") {
  if (!inherits(gt_obj, "gt_object")) {
    stop(sprintf(
      "%s must be a gt_object (from estimate_group_time_ATT()), got class: %s",
      name, paste(class(gt_obj), collapse = ", ")
    ), call. = FALSE)
  }

  required_fields <- c("data", "phi", "times", "groups", "n")
  missing <- setdiff(required_fields, names(gt_obj))

  if (length(missing) > 0) {
    stop(sprintf(
      "%s is missing required fields: %s",
      name, paste(missing, collapse = ", ")
    ), call. = FALSE)
  }

  # Check alignment between phi and data
  if (length(gt_obj$phi) != nrow(gt_obj$data)) {
    stop(sprintf(
      "%s$phi has length %d but %s$data has %d rows. These must match.",
      name, length(gt_obj$phi), name, nrow(gt_obj$data)
    ), call. = FALSE)
  }

  # Validate data structure
  if (!is.data.frame(gt_obj$data)) {
    stop(sprintf("%s$data must be a data.frame or tibble", name), call. = FALSE)
  }

  # Check for required columns in data
  required_cols <- c("g", "t", "tau_hat")
  missing_cols <- setdiff(required_cols, names(gt_obj$data))
  if (length(missing_cols) > 0) {
    stop(sprintf(
      "%s$data is missing required columns: %s",
      name, paste(missing_cols, collapse = ", ")
    ), call. = FALSE)
  }

  invisible(TRUE)
}

#' Validate scalar numeric
#'
#' @param x Value to validate
#' @param name Variable name for error messages
#' @keywords internal
validate_scalar <- function(x, name = "x") {
  if (!is.numeric(x) || length(x) != 1) {
    stop(sprintf("%s must be a numeric scalar, got %s of length %d",
                 name, class(x)[1], length(x)), call. = FALSE)
  }
  if (is.na(x) || is.infinite(x)) {
    stop(sprintf("%s must be finite, got %s", name, as.character(x)), call. = FALSE)
  }
  invisible(TRUE)
}

#' Validate lengths match
#'
#' @param x First vector
#' @param y Second vector
#' @param name_x Name of first vector
#' @param name_y Name of second vector
#' @keywords internal
validate_lengths_match <- function(x, y, name_x = "x", name_y = "y") {
  len_x <- length(x)
  len_y <- length(y)

  if (len_x != len_y) {
    stop(sprintf(
      "Length mismatch: %s has length %d but %s has length %d",
      name_x, len_x, name_y, len_y
    ), call. = FALSE)
  }

  invisible(TRUE)
}

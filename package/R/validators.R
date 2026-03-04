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
    stop(stringr::str_glue("{name} must be numeric, got {class(x)[1]}"), call. = FALSE)
  }
  if (!allow_na && any(is.na(x))) {
    n_na <- sum(is.na(x))
    stop(stringr::str_glue("{name} contains {n_na} NA value(s)"), call. = FALSE)
  }
  if (any(is.infinite(x))) {
    n_inf <- sum(is.infinite(x))
    stop(stringr::str_glue("{name} contains {n_inf} Inf value(s)"), call. = FALSE)
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
    stop(stringr::str_glue("{name} must be a list of EIF vectors, got {class(phi)[1]}"),
         call. = FALSE)
  }

  if (length(phi) == 0) {
    stop(stringr::str_glue("{name} is an empty list"), call. = FALSE)
  }

  lengths <- purrr::map_int(phi, length)

  if (!all(lengths == n)) {
    bad_idx <- which(lengths != n)
    bad_idx_str <- stringr::str_c(bad_idx, collapse = ", ")
    bad_lengths_str <- stringr::str_c(lengths[bad_idx], collapse = ", ")
    stop(stringr::str_glue(
      "{name}: All EIF vectors must have length n = {n}. ",
      "Found mismatches at indices: {bad_idx_str} (lengths: {bad_lengths_str})"
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
    stop(stringr::str_glue(
      "{name} must have length {n_groups} (number of groups), got {length(omega)}"
    ), call. = FALSE)
  }

  if (any(omega < 0)) {
    n_neg <- sum(omega < 0)
    stop(stringr::str_glue("{name} must be non-negative (found {n_neg} negative value(s))"),
         call. = FALSE)
  }

  # Optional: warn if doesn't sum to 1
  if (warn_sum && abs(sum(omega) - 1) > 1e-6) {
    omega_sum <- sum(omega)
    warning(stringr::str_glue(
      "{name} does not sum to 1 (sum = {round(omega_sum, 6)}). ",
      "Results will be weighted but may not be interpretable as averages."
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
    stop(stringr::str_glue("{name} must be a scalar, got length {length(level)}"),
         call. = FALSE)
  }

  if (level <= 0 || level >= 1) {
    stop(stringr::str_glue("{name} must be in (0, 1), got {round(level, 4)}"),
         call. = FALSE)
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
    classes_str <- stringr::str_c(class(gt_obj), collapse = ", ")
    stop(stringr::str_glue(
      "{name} must be a gt_object (from estimate_group_time_ATT()), got class: {classes_str}"
    ), call. = FALSE)
  }

  required_fields <- c("data", "phi", "times", "groups", "n")
  missing <- setdiff(required_fields, names(gt_obj))

  if (length(missing) > 0) {
    missing_str <- stringr::str_c(missing, collapse = ", ")
    stop(stringr::str_glue("{name} is missing required fields: {missing_str}"),
         call. = FALSE)
  }

  # Check alignment between phi and data (if phi is not NULL)
  if (!is.null(gt_obj$phi)) {
    if (length(gt_obj$phi) != nrow(gt_obj$data)) {
      phi_len <- length(gt_obj$phi)
      data_rows <- nrow(gt_obj$data)
      stop(stringr::str_glue(
        "{name}$phi has length {phi_len} but {name}$data has {data_rows} rows. These must match."
      ), call. = FALSE)
    }
  }

  # Validate data structure
  if (!is.data.frame(gt_obj$data)) {
    stop(stringr::str_glue("{name}$data must be a data.frame or tibble"), call. = FALSE)
  }

  # Check for required columns in data
  required_cols <- c("g", "t", "tau_hat")
  missing_cols <- setdiff(required_cols, names(gt_obj$data))
  if (length(missing_cols) > 0) {
    missing_cols_str <- stringr::str_c(missing_cols, collapse = ", ")
    stop(stringr::str_glue("{name}$data is missing required columns: {missing_cols_str}"),
         call. = FALSE)
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
    stop(stringr::str_glue("{name} must be a numeric scalar, got {class(x)[1]} of length {length(x)}"),
         call. = FALSE)
  }
  if (is.na(x) || is.infinite(x)) {
    stop(stringr::str_glue("{name} must be finite, got {as.character(x)}"), call. = FALSE)
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
    stop(stringr::str_glue(
      "Length mismatch: {name_x} has length {len_x} but {name_y} has length {len_y}"
    ), call. = FALSE)
  }

  invisible(TRUE)
}

#' Validate model specification list
#'
#' @param model_specs Named list of model specifications
#' @param name Variable name for error messages
#' @keywords internal
validate_model_specs <- function(model_specs, name = "model_specs") {
  # Check it's a list
  if (!is.list(model_specs)) {
    stop(stringr::str_glue("{name} must be a list, got {class(model_specs)[1]}"),
         call. = FALSE)
  }

  # Check it's not empty
  if (length(model_specs) == 0) {
    stop(stringr::str_glue("{name} is an empty list"), call. = FALSE)
  }

  # Check it's named
  if (is.null(names(model_specs)) || any(names(model_specs) == "")) {
    stop(stringr::str_glue("{name} must be a named list (all elements need names)"),
         call. = FALSE)
  }

  # Check each element has required fields
  required_fields <- c("h_fun", "dh_fun", "name")

  for (i in seq_along(model_specs)) {
    spec <- model_specs[[i]]
    spec_name <- names(model_specs)[i]

    # Check it's a list
    if (!is.list(spec)) {
      stop(stringr::str_glue(
        "{name}[['{spec_name}']] must be a list, got {class(spec)[1]}"
      ), call. = FALSE)
    }

    # Check required fields present
    missing <- setdiff(required_fields, names(spec))
    if (length(missing) > 0) {
      missing_str <- stringr::str_c(missing, collapse = ", ")
      stop(stringr::str_glue(
        "{name}[['{spec_name}']] is missing required fields: {missing_str}"
      ), call. = FALSE)
    }

    # Check h_fun is a function
    if (!is.function(spec$h_fun)) {
      stop(stringr::str_glue(
        "{name}[['{spec_name}']]$h_fun must be a function, got {class(spec$h_fun)[1]}"
      ), call. = FALSE)
    }

    # Check dh_fun is a function
    if (!is.function(spec$dh_fun)) {
      stop(stringr::str_glue(
        "{name}[['{spec_name}']]$dh_fun must be a function, got {class(spec$dh_fun)[1]}"
      ), call. = FALSE)
    }

    # Check name is a character scalar
    if (!is.character(spec$name) || length(spec$name) != 1) {
      stop(stringr::str_glue(
        "{name}[['{spec_name}']]$name must be a character scalar"
      ), call. = FALSE)
    }
  }

  invisible(TRUE)
}

#' Validate CV horizons
#'
#' @param horizons Integer vector of forecast horizons
#' @param max_available Maximum available time periods (optional)
#' @param name Variable name for error messages
#' @keywords internal
validate_horizons <- function(horizons, max_available = NULL, name = "horizons") {
  # Check numeric
  if (!is.numeric(horizons)) {
    stop(stringr::str_glue("{name} must be numeric, got {class(horizons)[1]}"),
         call. = FALSE)
  }

  # Check not empty
  if (length(horizons) == 0) {
    stop(stringr::str_glue("{name} cannot be empty"), call. = FALSE)
  }

  # Check no NA or Inf FIRST (before any comparisons that might fail with NA)
  if (any(is.na(horizons))) {
    stop(stringr::str_glue("{name} contains NA values"), call. = FALSE)
  }
  if (any(is.infinite(horizons))) {
    stop(stringr::str_glue("{name} contains Inf values"), call. = FALSE)
  }

  # Check all positive
  if (any(horizons <= 0)) {
    n_nonpos <- sum(horizons <= 0)
    stop(stringr::str_glue(
      "{name} must contain only positive values (found {n_nonpos} non-positive value(s))"
    ), call. = FALSE)
  }

  # Check all integers
  if (any(horizons != floor(horizons))) {
    n_nonint <- sum(horizons != floor(horizons))
    stop(stringr::str_glue(
      "{name} must contain only integers (found {n_nonint} non-integer value(s))"
    ), call. = FALSE)
  }

  # Check against max_available if provided
  if (!is.null(max_available)) {
    if (any(horizons >= max_available)) {
      bad_h <- horizons[horizons >= max_available]
      bad_h_str <- stringr::str_c(bad_h, collapse = ", ")
      stop(stringr::str_glue(
        "{name} contains values ({bad_h_str}) >= max available time periods ({max_available}). ",
        "Need at least one training observation for each horizon."
      ), call. = FALSE)
    }
  }

  invisible(TRUE)
}

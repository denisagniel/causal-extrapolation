#' Variance, standard error, and confidence interval from EIF
#'
#' Computes Var(φ)/n, standard error, and Wald confidence interval for a scalar
#' estimand using its efficient influence function (EIF) evaluations.
#'
#' @param phi Numeric vector of EIF contributions (length n).
#' @param estimate Optional scalar estimate; used to report CI.
#' @param level Confidence level for CI.
#' @param center If TRUE, center phi before variance computation.
#'
#' @return A list with elements var, se, ci (numeric length 2), and level.
#' @export
compute_variance <- function(phi, estimate = NULL, level = 0.95, center = TRUE) {
  # Input validation
  validate_numeric_vector(phi, name = "phi", allow_na = TRUE)
  validate_confidence_level(level, name = "level")

  if (!is.null(estimate)) {
    validate_scalar(estimate, name = "estimate")
  }

  # Handle NA values explicitly
  if (any(is.na(phi))) {
    n_na <- sum(is.na(phi))
    warning(sprintf(
      "phi contains %d NA value(s); these will be removed before variance computation",
      n_na
    ), call. = FALSE)
    phi <- phi[!is.na(phi)]
  }

  n <- length(phi)

  # Need at least 2 observations for variance
  if (n < 2) {
    stop(sprintf(
      "Insufficient non-NA observations in phi for variance computation (need at least 2, got %d)",
      n
    ), call. = FALSE)
  }

  # Center if requested
  if (center) {
    phi <- phi - mean(phi)
  }

  # Compute variance
  v <- stats::var(phi)
  varn <- v / n
  se <- sqrt(varn)

  # Confidence interval
  alpha <- 1 - level
  z <- stats::qnorm(1 - alpha / 2)
  ci <- if (!is.null(estimate)) {
    c(estimate - z * se, estimate + z * se)
  } else {
    c(NA_real_, NA_real_)
  }

  list(var = varn, se = se, ci = ci, level = level)
}






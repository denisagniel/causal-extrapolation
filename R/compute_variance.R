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
#'
#' @examples
#' # Simulate EIF vector from a causal estimator
#' set.seed(20260304)
#' n <- 200
#' phi <- rnorm(n, mean = 0, sd = 0.15)  # EIFs should have mean ≈ 0
#'
#' # Compute variance and 95% confidence interval
#' result <- compute_variance(phi, estimate = 0.45, level = 0.95)
#'
#' print(result$var)  # Variance estimate
#' print(result$se)   # Standard error
#' print(result$ci)   # 95% CI
#'
#' # Try different confidence levels
#' ci_99 <- compute_variance(phi, estimate = 0.45, level = 0.99)
#' print(ci_99$ci)  # Wider CI
#'
#' # Without estimate, CI will be NA
#' result_no_est <- compute_variance(phi, level = 0.95)
#' print(result_no_est$ci)  # c(NA, NA)
#'
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
    warning(stringr::str_glue(
      "phi contains {n_na} NA value(s); these will be removed before variance computation"
    ), call. = FALSE)
    phi <- phi[!is.na(phi)]
  }

  n <- length(phi)

  # Need at least 2 observations for variance
  if (n < 2) {
    stop(stringr::str_glue(
      "Insufficient non-NA observations in phi for variance computation (need at least 2, got {n})"
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






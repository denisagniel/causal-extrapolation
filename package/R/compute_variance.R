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
  phi <- as.numeric(phi)
  n <- length(phi)
  if (center) phi <- phi - mean(phi, na.rm = TRUE)
  v <- stats::var(phi, na.rm = TRUE)
  varn <- v / n
  se <- sqrt(varn)
  alpha <- 1 - level
  z <- stats::qnorm(1 - alpha / 2)
  ci <- if (!is.null(estimate)) c(estimate - z * se, estimate + z * se) else c(NA_real_, NA_real_)
  list(var = varn, se = se, ci = ci, level = level)
}






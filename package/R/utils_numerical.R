#' Safe Matrix Inversion with Singularity Check
#'
#' Computes the inverse of X'X with condition number checking to prevent
#' crashes from singular or near-singular matrices.
#'
#' @param X Numeric matrix (n x p).
#' @param tol Tolerance for condition number (default 1e-8). If kappa(X'X) > 1/tol,
#'   an error is raised.
#'
#' @return The inverse of X'X.
#' @keywords internal
safe_matrix_inverse <- function(X, tol = 1e-8) {
  if (!is.matrix(X) && !is.numeric(X)) {
    stop("X must be a numeric matrix")
  }

  if (is.vector(X)) {
    X <- matrix(X, ncol = 1)
  }

  n <- nrow(X)
  p <- ncol(X)

  # Check minimum observations
  if (n < p) {
    stop(sprintf(
      "Insufficient observations for matrix inversion: need at least %d observations, got %d",
      p, n
    ))
  }

  XtX <- crossprod(X)

  # Check condition number for near-singularity
  cond_num <- kappa(XtX, exact = TRUE)

  if (cond_num > 1/tol || is.infinite(cond_num)) {
    stop(sprintf(
      "Matrix X'X is near-singular or singular (condition number = %.2e).
Possible causes:
  - Repeated time values (creates exact linear dependence)
  - Insufficient distinct observations (need at least p = %d distinct times)
  - Poorly scaled time values (try centering/scaling)
  - Numerical instability",
      cond_num, p
    ))
  }

  solve(XtX)
}

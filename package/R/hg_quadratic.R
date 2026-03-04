#' Quadratic temporal extrapolation h_g and its Jacobian
#'
#' Implements a quadratic trend in event time: fit tau ~ 1 + k + k^2 to the
#' observed sequence and evaluate at the future event time. The Jacobian
#' w.r.t. past tau equals the OLS projection weights.
#'
#' @param times Numeric vector of observed event times (length p >= 3).
#' @param future_time Single numeric future event time (e.g. k* = p+1 - g).
#'
#' @details
#' Requires at least p >= 3 observations (intercept + linear + quadratic terms).
#' Checks for singular design matrices (e.g., repeated time values, insufficient
#' distinct times) and will raise an informative error if the matrix X'X is
#' near-singular.
#'
#' @return `hg_quadratic()` returns a function that maps a vector of tau to the extrapolated value.
#' `dh_quadratic()` returns the Jacobian vector of length length(times).
#' @export
hg_quadratic <- function(times, future_time) {
  force(times)
  force(future_time)
  function(tau_g) {
    w <- dh_quadratic(times, future_time)
    as.numeric(sum(w * tau_g))
  }
}

#' @rdname hg_quadratic
#' @export
dh_quadratic <- function(times, future_time) {
  # Validate minimum observations
  p <- length(times)
  if (p < 3) {
    stop("Quadratic model requires at least 3 observations (p >= 3)")
  }

  X <- cbind(1, times, times^2)
  xstar <- c(1, future_time, future_time^2)

  # Safe matrix inversion with singularity checking
  XtX_inv <- safe_matrix_inverse(X)

  # Compute projection weights: x*' (X'X)^{-1} X'
  w <- as.numeric(t(xstar) %*% XtX_inv %*% t(X))
  w
}

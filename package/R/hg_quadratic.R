#' Quadratic temporal extrapolation h_g and its Jacobian
#'
#' Implements a quadratic trend in event time: fit tau ~ 1 + k + k^2 to the
#' observed sequence and evaluate at the future event time. The Jacobian
#' w.r.t. past tau equals the OLS projection weights.
#'
#' @param times Numeric vector of observed event times (length p).
#' @param future_time Single numeric future event time (e.g. k* = p+1 - g).
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
  X <- cbind(1, times, times^2)
  xstar <- c(1, future_time, future_time^2)
  XtX_inv <- solve(crossprod(X))
  w <- as.numeric(t(xstar) %*% XtX_inv %*% t(X))
  w
}

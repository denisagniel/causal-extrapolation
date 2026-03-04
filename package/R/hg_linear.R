#' Linear temporal extrapolation h_g and its Jacobian
#'
#' Implements a linear trend model for temporal dynamics: fit an intercept and time
#' to the observed sequence (1:p, tau_{g,1:p}), and evaluate at the future time.
#' The Jacobian w.r.t. past τ_{g,1:p} equals the OLS projection weights.
#'
#' @param times Numeric vector of observed times (length p >= 2).
#' @param future_time Single numeric future time (p + m).
#'
#' @details
#' Requires at least p >= 2 observations (intercept + slope). Checks for
#' singular design matrices (e.g., repeated time values) and will raise an
#' informative error if the matrix X'X is near-singular.
#'
#' @return `hg_linear()` returns a function that maps a vector of τ_{g,1:p} to τ_{g,p+m}.
#' `dh_linear()` returns a numeric vector of length p giving ∂h_g/∂τ_{g,1:p}.
#' @export
hg_linear <- function(times, future_time) {
  force(times); force(future_time)
  function(tau_g) {
    w <- dh_linear(times, future_time)
    as.numeric(sum(w * tau_g))
  }
}

#' @rdname hg_linear
#' @export
dh_linear <- function(times, future_time) {
  # Validate minimum observations
  p <- length(times)
  if (p < 2) {
    stop("Linear model requires at least 2 observations (p >= 2)")
  }

  X <- cbind(1, times)
  xstar <- c(1, future_time)

  # Safe matrix inversion with singularity checking
  XtX_inv <- safe_matrix_inverse(X)

  # Compute projection weights: x*' (X'X)^{-1} X'
  w <- as.numeric(t(xstar) %*% XtX_inv %*% t(X))
  w
}






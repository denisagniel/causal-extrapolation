#' Linear temporal extrapolation h_g and its Jacobian
#'
#' Implements a linear trend model for temporal dynamics: fit an intercept and time
#' to the observed sequence (1:p, tau_{g,1:p}), and evaluate at the future time.
#' The Jacobian w.r.t. past τ_{g,1:p} equals the OLS projection weights.
#'
#' @param times Numeric vector of observed times (length p >= 2).
#' @param future_time Single numeric future time (p + m).
#' @param weights Optional numeric vector of length `length(times)`, the
#'   weighted-least-squares weights \eqn{\lambda_t}. If `NULL` (default), an
#'   equal-weighted (ordinary least squares) fit is used, matching prior
#'   behavior. Passing the inverse-variance weights from [gls_weights()]
#'   attains the semiparametric efficiency bound for Path 2, per RC5 and the
#'   Path 2 EIF derivation (Appendix); any other fixed, positive `weights`
#'   remains a valid (if generally inefficient) choice.
#'
#' @details
#' Requires at least p >= 2 observations (intercept + slope). Checks for
#' singular design matrices (e.g., repeated time values) and will raise an
#' informative error if the matrix X'X is near-singular.
#'
#' \strong{Interface design:}
#' \itemize{
#'   \item \code{hg_linear} returns a \emph{function factory}: it takes times and
#'     future_time, then returns a function that can be applied to tau vectors.
#'     This allows \code{extrapolate_ATT} to construct the extrapolation function
#'     once and apply it to different tau values if needed.
#'   \item \code{dh_linear} returns the Jacobian weights \emph{directly} as a vector.
#'     These weights are used immediately in EIF propagation, so no factory is needed.
#' }
#'
#' This asymmetric design is intentional: \code{h_fun} must be a factory because
#' \code{extrapolate_ATT} internally calls \code{h_fun(times, future_value)} to
#' construct a function, then applies that function. \code{dh_fun} is called once
#' and its output (the weight vector) is used directly in matrix multiplication.
#'
#' @return `hg_linear()` returns a function that maps a vector of τ_{g,1:p} to τ_{g,p+m}.
#' `dh_linear()` returns a numeric vector of length p giving ∂h_g/∂τ_{g,1:p}.
#'
#' @examples
#' # Observed ATTs at times 1, 2, 3
#' times <- c(1, 2, 3)
#' tau_observed <- c(0.2, 0.3, 0.4)  # Linear increasing trend
#'
#' # Extrapolate to future time 5
#' h <- hg_linear(times, future_time = 5)
#' tau_future <- h(tau_observed)
#' print(tau_future)  # Should be around 0.6 if trend continues
#'
#' # Get Jacobian weights for EIF propagation
#' dh_weights <- dh_linear(times, future_time = 5)
#' print(dh_weights)  # Projection weights
#'
#' # Verify h uses dh internally
#' manual_result <- sum(dh_weights * tau_observed)
#' print(all.equal(tau_future, manual_result))
#'
#' @export
hg_linear <- function(times, future_time, weights = NULL) {
  force(times); force(future_time); force(weights)
  function(tau_g) {
    w <- dh_linear(times, future_time, weights)
    as.numeric(sum(w * tau_g))
  }
}

#' @rdname hg_linear
#' @export
dh_linear <- function(times, future_time, weights = NULL) {
  # Validate minimum observations
  p <- length(times)
  if (p < 2) {
    stop("Linear model requires at least 2 observations (p >= 2)")
  }

  X <- cbind(1, times)
  xstar <- c(1, future_time)

  if (is.null(weights)) {
    w <- as.numeric(t(xstar) %*% safe_matrix_inverse(X) %*% t(X))
  } else {
    if (length(weights) != p) {
      stop(stringr::str_glue(
        "weights must have length {p} (one per observed time), got {length(weights)}."
      ), call. = FALSE)
    }
    # Weighted least squares: x*' (X'WX)^{-1} X'W, W = diag(weights)
    XtWX_inv <- safe_matrix_inverse(X, weights = weights)
    w <- as.numeric(t(xstar) %*% XtWX_inv %*% t(X * weights))
  }
  w
}






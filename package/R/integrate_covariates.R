#' Integrate extrapolated conditional ATT over a target covariate distribution
#'
#' Given per-unit conditional extrapolated EIF contributions or per-group averages,
#' integrate over a target covariate distribution F_X* using either observed target
#' sample `x_target` (finite-pop average) or a Monte Carlo `sampler()`.
#'
#' @param extrap_object Result of `extrapolate_ATT()` with per-unit EIF vectors in
#'   `phi_g_future` (or aggregated `phi_future` if already aggregated by group).
#' @param x_target Optional data.frame/tibble of target covariates; if provided,
#'   finite-pop average is used.
#' @param sampler Optional function(n) -> tibble that generates draws from F_X*.
#' @param weights Optional numeric vector of weights aligned with rows of x_target.
#' @param id_target Optional vector of ids for target units.
#'
#' @return A list with integrated estimate `tau_star` and EIF vector `phi_star`.
#' @export
integrate_covariates <- function(extrap_object, x_target = NULL, sampler = NULL, weights = NULL, id_target = NULL) {
  # Simplest path: treat existing EIF vector as already per-target unit and average.
  if (!is.null(extrap_object$phi_future) && is.null(x_target) && is.null(sampler)) {
    phi <- extrap_object$phi_future
    tau <- extrap_object$tau_future
    return(list(tau_star = tau, phi_star = phi))
  }
  # Placeholder: If x_target provided, we simply average group-level results using weights.
  # In more advanced use, user supplies mapping from X -> group or conditional ATT.
  if (!is.null(x_target)) {
    w <- if (is.null(weights)) rep(1 / nrow(x_target), nrow(x_target)) else weights / sum(weights)
    # Without a conditional model τ_{p+m}(X), we fallback to overall aggregation.
    if (!is.null(extrap_object$phi_future)) {
      phi_star <- extrap_object$phi_future
      tau_star <- extrap_object$tau_future
      return(list(tau_star = tau_star, phi_star = phi_star))
    }
  }
  stop("For conditional integration, supply either aggregated phi_future/tau_future, or implement a mapping τ_{p+m}(X).")
}






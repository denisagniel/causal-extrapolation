#' Extrapolate future ATTs and propagate EIFs
#'
#' Applies a user-provided temporal model h_g(·) and its Jacobian ∂h_g/∂τ_{g,1:p}
#' to each group's observed τ̂_{g,1:p} to obtain τ̂_{g,p+m}, and propagates EIFs
#' via the chain rule. Optionally aggregates to overall τ̂_{p+m} with group weights ω_g.
#'
#' @param gt_object An object produced by `estimate_group_time_ATT()`.
#' @param h_fun A function factory taking (times, future_time, ...) and returning
#'   a function mapping τ_{g,1:p} -> τ_{g,p+m}.
#' @param dh_fun A function taking (times, future_time, ...) and returning the
#'   Jacobian vector ∂h_g/∂τ_{g,1:p}. If NULL, numerical derivative is used.
#' @param future_time Deprecated; use `future_value`.
#' @param future_value Numeric scalar: either future calendar time or future event time (k*),
#'   depending on `time_scale`.
#' @param time_scale One of "calendar" or "event"; determines whether sequences
#'   are constructed over calendar times `t` or event times `k = t - g`.
#' @param omega Optional numeric vector of group weights ω_g for aggregation.
#' @param per_group If TRUE, return per-group results. If FALSE, aggregate with ω_g.
#' @param ... Additional arguments passed to h_fun/dh_fun.
#'
#' @return A list (`extrap_object`) with:
#' - tau_g_future: tibble(g, tau_future)
#' - phi_g_future: list of EIF vectors per group
#' - tau_future, phi_future if aggregated (per_group = FALSE)
#' @export
extrapolate_ATT <- function(gt_object, h_fun, dh_fun = NULL, future_time = NULL, future_value = NULL, omega = NULL, per_group = TRUE, time_scale = c("calendar", "event"), ...) {
  stopifnot(inherits(gt_object, "gt_object"))
  time_scale <- match.arg(time_scale)
  if (!is.null(future_time) && is.null(future_value)) future_value <- future_time
  if (is.null(future_value)) stop("Provide future_value (calendar time or event time).")
  groups <- gt_object$groups
  n <- gt_object$n

  # Build per-group vectors of tau_{g,1:p}
  df <- gt_object$data
  # Choose ordering variable
  if (time_scale == "calendar") {
    df$ord_time <- df$t
  } else {
    if (!"k" %in% names(df)) df$k <- df$t - df$g
    df$ord_time <- df$k
  }

  # Build per-group tau vectors and phi matrices ordered by ord_time
  phi_rows <- gt_object$phi
  if (length(phi_rows) != nrow(df)) stop("Length of phi list must match rows of data.")
  ord <- order(df$g, df$ord_time)
  df_ord <- df[ord, ]
  phi_ord <- phi_rows[ord]
  by_g_idx <- split(seq_len(nrow(df_ord)), df_ord$g)

  tau_g_future <- vector("list", length(groups))
  names(tau_g_future) <- groups
  phi_g_future <- vector("list", length(groups))
  names(phi_g_future) <- groups

  for (k in seq_along(groups)) {
    gk <- groups[k]
    idx <- by_g_idx[[as.character(gk)]]
    sub <- df_ord[idx, ]
    times_vec <- sub$ord_time
    tau_vec <- sub$tau_hat
    # Assemble phi matrix n x p
    phi_mat <- do.call(cbind, phi_ord[idx])
    if (is.null(dim(phi_mat))) phi_mat <- matrix(phi_mat, nrow = n, ncol = 1)

    # Derivative weights and extrapolation per group
    h_factory <- h_fun(times_vec, future_value, ...)
    dh_vec <- if (!is.null(dh_fun)) dh_fun(times_vec, future_value, ...) else NULL
    if (is.null(dh_vec)) {
      if (!requireNamespace("numDeriv", quietly = TRUE)) stop("numDeriv required for numerical Jacobian.")
      base <- tau_vec * 0
      # compute gradient wrt each component around current tau_vec
      dh_vec <- as.numeric(numDeriv::grad(function(z) h_fun(times_vec, future_value, ...)(z), x = tau_vec))
    }
    tau_g_future[[k]] <- h_factory(tau_vec)
    phi_g_future[[k]] <- as.numeric(phi_mat %*% dh_vec)
  }

  tib <- tibble::tibble(g = groups, tau_future = as.numeric(unlist(tau_g_future)))
  out <- list(tau_g_future = tib, phi_g_future = phi_g_future)

  if (!per_group) {
    if (is.null(omega)) stop("Provide omega group weights to aggregate.")
    if (length(omega) != length(groups)) stop("omega must have length equal to number of groups.")
    tau_future <- sum(omega * tib$tau_future)
    phi_future <- Reduce(`+`, Map(function(w, phi) w * phi, omega, phi_g_future))
    out$tau_future <- tau_future
    out$phi_future <- phi_future
  }

  class(out) <- c("extrap_object", "extrapolateATT")
  out
}


#' Extrapolate future ATTs and propagate EIFs
#'
#' Applies a user-provided temporal model \code{h_g(·)} and its Jacobian \code{dh_g/dtau}
#' to each group's observed \code{tau_hat} values to obtain future ATT estimates,
#' and propagates EIFs via the chain rule. Optionally aggregates to overall future
#' ATT with group weights \code{omega_g}.
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
#' @section Custom temporal models:
#' To define a custom temporal extrapolation model, provide:
#'
#' \enumerate{
#'   \item \strong{h_fun} - A function factory with signature
#'     \code{function(times, future_time, ...)} that returns a function
#'     \code{function(tau_vector)} mapping observed ATTs to future ATT.
#'
#'   \item \strong{dh_fun} - A function with signature
#'     \code{function(times, future_time, ...)} that returns the Jacobian
#'     (derivative) vector of length \code{length(times)}.
#' }
#'
#' The asymmetric interface (factory vs direct return) is intentional:
#' \code{extrapolate_ATT} calls \code{h_factory <- h_fun(times, future_value)}
#' to construct the extrapolation function, then applies it. The Jacobian from
#' \code{dh_fun} is used directly in matrix multiplication for EIF propagation.
#'
#' Example custom model (exponential decay):
#' \preformatted{
#' my_h <- function(times, future_time, decay_rate = 0.1) {
#'   function(tau) {
#'     # Fit exponential model and extrapolate
#'     # (simplified example)
#'     mean(tau) * exp(-decay_rate * (future_time - max(times)))
#'   }
#' }
#'
#' my_dh <- function(times, future_time, decay_rate = 0.1) {
#'   # Return Jacobian weights
#'   rep(1/length(times), length(times))  # Simplified
#' }
#'
#' result <- extrapolate_ATT(gt_obj, h_fun = my_h, dh_fun = my_dh,
#'                           future_value = 10, decay_rate = 0.2)
#' }
#'
#' @return A list (`extrap_object`) with:
#' - tau_g_future: tibble(g, tau_future)
#' - phi_g_future: list of EIF vectors per group
#' - tau_future, phi_future if aggregated (per_group = FALSE)
#'
#' @examples
#' # Create mock group-time ATT estimates (in practice, from estimate_group_time_ATT)
#' set.seed(20260304)
#' n <- 100
#' gt_data <- tibble::tibble(
#'   g = rep(c(0, 1), each = 3),
#'   t = rep(1:3, 2),
#'   tau_hat = rnorm(6, mean = 0.5, sd = 0.1),
#'   k = t - g
#' )
#'
#' # Create mock EIF vectors
#' phi <- replicate(nrow(gt_data), rnorm(n, sd = 0.1), simplify = FALSE)
#'
#' # Build gt_object
#' gt_obj <- list(
#'   data = gt_data,
#'   phi = phi,
#'   times = sort(unique(gt_data$t)),
#'   groups = sort(unique(gt_data$g)),
#'   n = n
#' )
#' class(gt_obj) <- c("gt_object", "extrapolateATT")
#'
#' # Extrapolate to future time using linear model
#' result <- extrapolate_ATT(
#'   gt_obj,
#'   h_fun = hg_linear,
#'   dh_fun = dh_linear,
#'   future_value = 5,
#'   time_scale = "calendar",
#'   per_group = TRUE
#' )
#'
#' # Access per-group results
#' print(result$tau_g_future)
#'
#' # Aggregate across groups with weights
#' result_agg <- extrapolate_ATT(
#'   gt_obj,
#'   h_fun = hg_linear,
#'   dh_fun = dh_linear,
#'   future_value = 5,
#'   time_scale = "calendar",
#'   per_group = FALSE,
#'   omega = c(0.6, 0.4)
#' )
#'
#' # Overall future ATT estimate
#' print(result_agg$tau_future)
#'
#' @export
extrapolate_ATT <- function(gt_object, h_fun, dh_fun = NULL, future_time = NULL, future_value = NULL, omega = NULL, per_group = TRUE, time_scale = c("calendar", "event"), ...) {
  # Input validation
  validate_gt_object(gt_object, name = "gt_object")
  time_scale <- match.arg(time_scale)

  # Handle deprecated future_time argument
  if (!is.null(future_time) && is.null(future_value)) {
    future_value <- future_time
  }

  if (is.null(future_value)) {
    stop("future_value is required (calendar time or event time depending on time_scale)", call. = FALSE)
  }
  validate_scalar(future_value, name = "future_value")

  # Validate omega if provided and aggregation requested
  if (!per_group && is.null(omega)) {
    stop("omega is required when per_group = FALSE (aggregation requested)", call. = FALSE)
  }

  groups <- gt_object$groups
  n <- gt_object$n

  # Validate omega dimensions if provided
  if (!is.null(omega)) {
    validate_group_weights(omega, n_groups = length(groups), name = "omega", warn_sum = TRUE)
  }

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

    # Check for NULL group (shouldn't happen but be defensive)
    if (is.null(idx) || length(idx) == 0) {
      stop(sprintf(
        "Group %s not found in data. Available groups: %s",
        gk, paste(names(by_g_idx), collapse = ", ")
      ), call. = FALSE)
    }

    sub <- df_ord[idx, ]
    times_vec <- sub$ord_time
    tau_vec <- sub$tau_hat

    # Assemble phi matrix n x p
    # Use fast_cbind_list for efficient matrix construction
    phi_mat <- fast_cbind_list(phi_ord[idx])

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
    # omega validation already done at top of function
    tau_future <- sum(omega * tib$tau_future)
    phi_future <- Reduce(`+`, Map(function(w, phi) w * phi, omega, phi_g_future))
    out$tau_future <- tau_future
    out$phi_future <- phi_future
  }

  class(out) <- c("extrap_object", "extrapolateATT")
  out
}


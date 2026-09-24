#' Path 1: aggregate group-time ATTs assuming constant effect within group
#'
#' For each group, computes the (weighted) average of tau_hat over observed (g,t)
#' cells, then aggregates across groups with omega. Propagates EIFs by
#' within-group averaging then aggregation.
#'
#' @param gt_object An object of class gt_object (data, phi, groups, n).
#' @param omega Numeric vector of group weights (length = number of groups). If NULL
#'   (default), equal weights `rep(1 / n_groups, n_groups)` are used. Weights are honored
#'   in both the point estimate and the propagated EIF.
#' @param weighting Within-group weighting scheme for averaging `tau_hat` over
#'   the observed periods `t` in each group. `"equal"` (default) is the
#'   simple mean used previously; it is valid for any asymptotically linear
#'   first-stage. `"gls"` uses the inverse-variance (GLS) weights
#'   \eqn{\lambda_{gt} \propto 1/\mathrm{Var}(\phi_{gt})}, estimated from the
#'   sample variance of each cell's supplied EIF vector, and attains the
#'   semiparametric efficiency bound when the first-stage EIFs are themselves
#'   efficient. Both schemes are valid (correct variance); only the
#'   efficiency differs.
#' @return A list with tau_future (scalar), phi_future (length-n vector), and
#'   tau_g (per-group means) and phi_g (list of EIF vectors per group) for optional use.
#'
#' @examples
#' # Create mock gt_object with multiple observations per group
#' set.seed(20260304)
#' n <- 100
#' gt_data <- tibble::tibble(
#'   g = c(0, 0, 0, 1, 1),
#'   t = c(1, 2, 3, 1, 2),
#'   tau_hat = c(0.2, 0.3, 0.4, 0.5, 0.6),
#'   k = t - g
#' )
#'
#' phi <- replicate(nrow(gt_data), rnorm(n, sd = 0.1), simplify = FALSE)
#'
#' gt_obj <- list(
#'   data = gt_data,
#'   phi = phi,
#'   times = sort(unique(gt_data$t)),
#'   groups = sort(unique(gt_data$g)),
#'   n = n
#' )
#' class(gt_obj) <- c("gt_object", "extrapolateATT")
#'
#' # Aggregate with equal weights
#' omega <- c(0.5, 0.5)
#' result <- path1_aggregate(gt_obj, omega)
#'
#' print(result$tau_g)  # Per-group averages
#' print(result$tau_future)  # Overall weighted average
#'
#' @export
path1_aggregate <- function(gt_object, omega = NULL, weighting = c("equal", "gls")) {
  weighting <- match.arg(weighting)
  validate_gt_object(gt_object, name = "gt_object")
  df <- gt_object$data
  phi_rows <- gt_object$phi
  groups <- gt_object$groups
  n <- gt_object$n
  validate_lengths_match(phi_rows, seq_len(nrow(df)),
                         name_x = "phi", name_y = "data rows")

  # Default to equal group weights; validate before use so callers cannot silently
  # drop or misspecify omega (audit M1/M9).
  if (is.null(omega)) {
    omega <- rep(1 / length(groups), length(groups))
  }
  validate_group_weights(omega, n_groups = length(groups), name = "omega", warn_sum = TRUE)

  results <- purrr::map(seq_along(groups), \(i) {
    g <- groups[i]
    idx <- which(df$g == g)
    phi_mat <- fast_cbind_list(phi_rows[idx])

    lambda <- if (weighting == "gls") {
      gls_weights(phi_rows[idx])
    } else {
      rep(1 / length(idx), length(idx))
    }

    tau_mean <- sum(lambda * df$tau_hat[idx])
    # EIF for the weighted group mean: same linear combination of the
    # cell-level EIFs, with the same (fixed, data-independent-at-this-step)
    # weights lambda -- valid for any lambda > 0 summing to 1, per the
    # product-rule argument in Appendix, Path 1 EIF.
    phi_mean <- as.numeric(phi_mat %*% lambda)

    list(tau = tau_mean, phi = phi_mean)
  })

  tau_g <- purrr::map_dbl(results, "tau")
  phi_g <- purrr::map(results, "phi")
  names(phi_g) <- groups

  agg <- aggregate_groups(tau_g, phi_g, omega)
  list(
    tau_future = agg$value,
    phi_future = agg$phi,
    tau_g = tau_g,
    phi_g = phi_g
  )
}

#' Inverse-variance (GLS) weights from a list of EIF vectors
#'
#' Computes normalized weights \eqn{\lambda_j \propto 1/\widehat{\mathrm{Var}}(\phi_j)}
#' from the sample variance of each supplied influence-function vector, for use
#' as the efficient (GLS) weighting in [path1_aggregate()] and the weighted
#' least-squares step of [extrapolate_ATT()]. The overall scale of
#' \eqn{\mathrm{Var}(\phi_j)} versus \eqn{\mathrm{Var}(\widehat\theta_j) =
#' \mathrm{Var}(\phi_j)/n} is immaterial here: weighted averages and weighted
#' least squares are invariant to a common positive rescaling of the weights,
#' and `n` (the number of units backing every cell in a single `gt_object`)
#' is common across cells.
#'
#' @param phi_list A list of numeric EIF vectors (one per cell), as stored in
#'   `gt_object$phi[idx]`.
#' @param floor A small positive lower bound on the estimated variance, to
#'   avoid a near-zero-variance cell receiving unbounded weight from sampling
#'   noise in the variance estimate itself. Default `1e-8`.
#' @return A numeric vector of weights, same length as `phi_list`, summing to 1.
#'
#' @export
gls_weights <- function(phi_list, floor = 1e-8) {
  if (length(phi_list) == 0) {
    stop("gls_weights() requires at least one EIF vector.", call. = FALSE)
  }
  v <- vapply(phi_list, function(phi) max(stats::var(phi), floor), numeric(1))
  lambda <- 1 / v
  lambda / sum(lambda)
}

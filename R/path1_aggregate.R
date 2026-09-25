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
#'   efficient. `"gls-joint"` bypasses the within-group-then-across-group
#'   two-step structure entirely: it reassembles \emph{every} cell (not just
#'   one group's) into a single jointly-aligned score matrix via
#'   [build_score_matrix()] and combines all cells directly into the
#'   per-group \eqn{\widehat\beta_g} and the overall \eqn{\widehat\theta_{p+1}}
#'   via [combine_cell_scores()], using the \emph{full} cross-cell covariance
#'   rather than assuming cells (including cells in different groups) are
#'   uncorrelated. This requires a reliable unit id (`ids`, or
#'   `gt_object$ids`) to align cells row-for-row; see Details. All three
#'   schemes are valid (correct variance) when the identifying assumptions
#'   hold; only the efficiency differs, and `"gls-joint"`'s efficiency
#'   statement is the one documented in [combine_cell_scores()] (optimal-GMM
#'   among linear combinations of the supplied cells, not the semiparametric
#'   efficiency bound for \eqn{\theta_{p+1}} itself).
#' @param omega_estimated Logical. Were the cohort weights `omega` estimated from this same
#'   sample (rather than fixed and known a priori)? Default `FALSE`, which reproduces this
#'   function's historical behavior exactly. When `TRUE`, the propagated EIF additionally
#'   carries the functional-delta-method term \eqn{\sum_g \theta_{g\cdot}\phi_{\omega_g,i}}
#'   from the paper's Path 1 derivation (Appendix \code{app:eif1}), and `omega_scores` must
#'   be supplied. Leaving this at `FALSE` while using estimated weights \emph{understates}
#'   the variance.
#' @param omega_scores An \eqn{n \times q} matrix of per-unit weight influence functions, as
#'   returned by [build_omega_score()]. Required when `omega_estimated = TRUE` and ignored
#'   otherwise. If `omega` is `NULL` the weights are taken from
#'   `attr(omega_scores, "omega")`, so that the weights and their influence functions are
#'   guaranteed to correspond to the same estimator.
#' @param ids Row keys for [build_score_matrix()], used only when
#'   `weighting = "gls-joint"`. `NULL` (default) uses `gt_object$ids`; if that is also
#'   `NULL`, `path1_aggregate()` errors rather than silently assuming a consistent row
#'   order across cells (same contract as `build_score_matrix(require_ids = TRUE)`).
#' @param cluster Optional cluster identifier passed to [build_score_matrix()], used only
#'   when `weighting = "gls-joint"`.
#' @param shrink Shrinkage rule passed to [estimate_score_cov()], used only when
#'   `weighting = "gls-joint"`. Default `"auto"`.
#' @return A list with tau_future (scalar), phi_future (length-n vector), and
#'   tau_g (per-group means) and phi_g (list of EIF vectors per group) for optional use.
#'
#' @details
#' ## Estimated versus known cohort weights
#'
#' The Path 1 estimand is \eqn{\theta_{p+1} = \sum_g \omega_g \theta_{g\cdot}} with
#' \eqn{\omega_g = \P(G_i = g \mid A_{ip} = 1)}. Its influence function has \emph{two}
#' terms (paper, Appendix \code{app:eif1}):
#' \deqn{\phi_{\psi_1,i} = \sum_g \omega_g \phi_{\theta_{g\cdot},i}
#'   + \sum_g \theta_{g\cdot}\phi_{\omega_g,i}.}
#' The second term is present only when \eqn{\omega} is estimated. Set
#' `omega_estimated = TRUE` and pass `omega_scores` in that case; otherwise the reported
#' standard errors are too small. See [build_omega_score()] for the exactly-zero
#' certificate that the extra term satisfies under effect homogeneity.
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
#' @seealso [build_omega_score()], [aggregate_groups()]
#'
#' @export
path1_aggregate <- function(gt_object, omega = NULL, weighting = c("equal", "gls", "gls-joint"),
                            omega_estimated = FALSE, omega_scores = NULL,
                            ids = NULL, cluster = NULL, shrink = "auto") {
  weighting <- match.arg(weighting)
  if (!is.logical(omega_estimated) || length(omega_estimated) != 1 ||
        is.na(omega_estimated)) {
    stop("`omega_estimated` must be a single TRUE or FALSE.", call. = FALSE)
  }
  validate_gt_object(gt_object, name = "gt_object")
  df <- gt_object$data
  phi_rows <- gt_object$phi
  groups <- gt_object$groups
  n <- gt_object$n
  validate_lengths_match(phi_rows, seq_len(nrow(df)),
                         name_x = "phi", name_y = "data rows")

  if (omega_estimated) {
    if (is.null(omega_scores)) {
      stop(
        "path1_aggregate(omega_estimated = TRUE) requires `omega_scores`, the per-unit ",
        "influence functions of the estimated cohort weights. Build them with ",
        "build_omega_score(G, treated_by_p, groups = gt_object$groups).",
        call. = FALSE
      )
    }
    omega_scores <- .validate_omega_scores(
      omega_scores, n_groups = length(groups), n = n
    )
    # Prefer the omega_hat carried by the scores when the caller did not name one: that
    # keeps the weights and their influence functions tied to a single estimator.
    if (is.null(omega)) {
      omega <- attr(omega_scores, "omega")
      if (is.null(omega)) {
        stop(
          "`omega` is NULL and `omega_scores` carries no \"omega\" attribute. Supply ",
          "`omega`, or build the scores with build_omega_score().",
          call. = FALSE
        )
      }
      omega <- unname(omega)
    }
  } else if (!is.null(omega_scores)) {
    warning(
      "`omega_scores` was supplied but `omega_estimated` is FALSE, so the ",
      "estimated-weight variance term is NOT included. Set omega_estimated = TRUE to ",
      "propagate it.",
      call. = FALSE
    )
    omega_scores <- NULL
  }

  # Default to equal group weights; validate before use so callers cannot silently
  # drop or misspecify omega (audit M1/M9).
  if (is.null(omega)) {
    omega <- rep(1 / length(groups), length(groups))
  }
  validate_group_weights(omega, n_groups = length(groups), name = "omega", warn_sum = TRUE)

  if (weighting == "gls-joint") {
    Phi <- build_score_matrix(gt_object, ids = ids, cluster = cluster, require_ids = TRUE)
    cells <- attr(Phi, "cells")
    cmb <- combine_cell_scores(
      Phi, values = df$tau_hat, restriction = cells$g, target = omega,
      shrink = shrink, omega_scores = omega_scores
    )

    tau_g <- cmb$beta
    names(tau_g) <- colnames(cmb$phi_beta)
    phi_g <- lapply(seq_len(ncol(cmb$phi_beta)), function(k) cmb$phi_beta[, k])
    names(phi_g) <- colnames(cmb$phi_beta)

    return(list(
      tau_future = cmb$value,
      phi_future = cmb$phi,
      tau_g = tau_g,
      phi_g = phi_g
    ))
  }

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

  agg <- aggregate_groups(tau_g, phi_g, omega, omega_scores = omega_scores)
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

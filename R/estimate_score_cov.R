#' Covariance of a joint cell score matrix, with optional shrinkage
#'
#' Estimates the \eqn{J \times J} covariance \eqn{\Sigma} of the per-\eqn{(g,t)}-cell scores
#' assembled by [build_score_matrix()], together with its inverse and explicit conditioning
#' diagnostics. The covariance is on the package's per-unit score scale: the covariance
#' matrix of the cell *estimates* is \eqn{\Sigma / n_{\text{eff}}}, matching
#' [compute_variance()]'s \eqn{\mathrm{Var}(\phi)/n} convention, and
#' \eqn{\Sigma_{jj} / n_{\text{eff}}} reproduces cell \eqn{j}'s usual variance exactly.
#'
#' @section Conditioning:
#' With \eqn{J} cells and only \eqn{n_{\text{eff}}} independent units (or clusters), the
#' unshrunk sample covariance is exactly singular once \eqn{J \ge n_{\text{eff}}} and badly
#' conditioned well before that; cells that share most of their units are close to
#' collinear. This function never returns a confidently-wrong inverse: if \eqn{\Sigma}
#' cannot be inverted reliably it returns `Sigma_inv = NULL` and `ok = FALSE` with a
#' warning, leaving the decision to the caller.
#'
#' @section Shrinkage:
#' All non-trivial options apply the same convex combination toward the diagonal target,
#' \deqn{\Sigma = (1 - \alpha)\widehat\Sigma + \alpha \, \mathrm{diag}(\widehat\Sigma),}
#' which leaves every cell's marginal variance untouched (the diagonal is identical for all
#' \eqn{\alpha}) and only damps the off-diagonal covariances. The options differ solely in
#' how \eqn{\alpha} is chosen:
#' \describe{
#'   \item{`"none"`}{\eqn{\alpha = 0}: the raw sample covariance.}
#'   \item{`"diagonal"`}{\eqn{\alpha = 1}: all cross-cell covariance discarded. This is the
#'     implicit assumption of the package's historical list-of-columns representation.}
#'   \item{`"ledoit-wolf"`}{\eqn{\alpha = \min(1, (J + 1) / n_{\text{eff}})} unless `alpha`
#'     is supplied. \strong{This is a simplified variant, not the Ledoit-Wolf estimator.}
#'     The genuine Ledoit-Wolf rule derives \eqn{\alpha} from an estimate of the optimal
#'     (Frobenius-risk-minimizing) shrinkage intensity, which requires fourth-moment
#'     quantities this function does not compute. What is implemented is a deterministic
#'     dimension-to-sample-size rule: it is monotone in \eqn{J/n_{\text{eff}}}, reaches full
#'     diagonal shrinkage exactly where the sample covariance becomes singular
#'     (\eqn{J + 1 \ge n_{\text{eff}}}), and guarantees a positive-definite result whenever
#'     every cell has positive variance — but it makes \emph{no} optimality claim. The name
#'     is retained only so the option is findable; treat it as "automatic convex shrinkage".}
#'   \item{`"auto"` (default)}{`"none"` when \eqn{n_{\text{eff}}/J \ge} `min_ratio`;
#'     otherwise warn and fall back to `"ledoit-wolf"`.}
#' }
#'
#' @param score_matrix An \eqn{n_{\text{eff}} \times J} numeric matrix of per-unit (or
#'   per-cluster) cell scores, as returned by [build_score_matrix()].
#' @param shrink Shrinkage rule; one of `"auto"`, `"none"`, `"diagonal"`, `"ledoit-wolf"`.
#'   See Shrinkage above.
#' @param alpha Optional shrinkage intensity in \eqn{[0, 1]}, overriding the rule implied by
#'   `shrink`. Supplying `alpha` with `shrink = "auto"` pins the intensity while leaving the
#'   automatic fallback logic in place.
#' @param min_ratio Positive floor on \eqn{n_{\text{eff}}/J}. Below it, `shrink = "auto"`
#'   warns and shrinks rather than attempting an ill-conditioned inverse. Default `10`.
#'
#' @return A list with
#'   \describe{
#'     \item{`Sigma`}{the \eqn{J \times J} (possibly shrunk) covariance, always returned.}
#'     \item{`Sigma_inv`}{its inverse, or `NULL` when inversion is unreliable.}
#'     \item{`shrink_used`}{the rule actually applied (`"auto"` is never reported; the
#'       resolved rule is).}
#'     \item{`alpha`}{the shrinkage intensity used.}
#'     \item{`kappa`}{condition number of `Sigma`.}
#'     \item{`rank`}{numerical rank of `Sigma`.}
#'     \item{`n_eff`, `J`}{dimensions of `score_matrix`.}
#'     \item{`ok`}{`TRUE` iff `Sigma` is full rank and `Sigma_inv` was computed.}
#'   }
#'
#' @seealso [build_score_matrix()]
#'
#' @examples
#' set.seed(20260925)
#' Phi <- matrix(rnorm(300 * 4), nrow = 300)
#' res <- estimate_score_cov(Phi)
#' res$shrink_used
#' res$ok
#'
#' # Too few units relative to cells: auto shrinks and says so.
#' Phi_wide <- matrix(rnorm(40 * 15), nrow = 40)
#' suppressWarnings(estimate_score_cov(Phi_wide)$alpha)
#'
#' @export
estimate_score_cov <- function(score_matrix,
                               shrink = c("auto", "none", "diagonal", "ledoit-wolf"),
                               alpha = NULL, min_ratio = 10) {
  shrink <- match.arg(shrink)

  if (!is.matrix(score_matrix) || !is.numeric(score_matrix)) {
    stop(stringr::str_glue(
      "score_matrix must be a numeric matrix (see build_score_matrix()), got ",
      "{class(score_matrix)[1]}."
    ), call. = FALSE)
  }
  if (anyNA(score_matrix)) {
    stop("score_matrix must not contain NA values.", call. = FALSE)
  }
  if (any(!is.finite(score_matrix))) {
    stop("score_matrix must be finite (no Inf/NaN).", call. = FALSE)
  }

  n_eff <- nrow(score_matrix)
  J <- ncol(score_matrix)

  if (n_eff < 2) {
    stop(stringr::str_glue(
      "score_matrix needs at least 2 rows to estimate a covariance, got {n_eff}."
    ), call. = FALSE)
  }
  if (J < 1) {
    stop("score_matrix must have at least one column (cell).", call. = FALSE)
  }
  if (!is.numeric(min_ratio) || length(min_ratio) != 1 || !is.finite(min_ratio) ||
        min_ratio <= 0) {
    stop("`min_ratio` must be a single positive finite number.", call. = FALSE)
  }
  if (!is.null(alpha)) {
    if (!is.numeric(alpha) || length(alpha) != 1 || !is.finite(alpha) ||
          alpha < 0 || alpha > 1) {
      stop("`alpha` must be a single number in [0, 1], or NULL.", call. = FALSE)
    }
  }

  Sigma_hat <- stats::cov(score_matrix)
  d <- diag(Sigma_hat)
  if (any(d <= 0)) {
    bad <- which(d <= 0)
    bad_str <- stringr::str_c(bad[seq_len(min(5, length(bad)))], collapse = ", ")
    stop(stringr::str_glue(
      "Cell(s) {bad_str} have zero variance ",
      "in score_matrix, so no covariance (and no inverse) is defined. Drop the degenerate ",
      "cell(s) before calling estimate_score_cov()."
    ), call. = FALSE)
  }

  # ---- Resolve the shrinkage rule ----------------------------------------------------
  ratio <- n_eff / J
  shrink_used <- shrink
  if (shrink == "auto") {
    if (ratio >= min_ratio) {
      shrink_used <- "none"
    } else {
      shrink_used <- "ledoit-wolf"
      warning(stringr::str_glue(
        "estimate_score_cov(): n_eff / J = {round(ratio, 2)} is below min_ratio = ",
        "{min_ratio}, so the sample cross-cell covariance is unreliable. Falling back to ",
        "convex shrinkage toward the diagonal ('ledoit-wolf') rather than inverting an ",
        "ill-conditioned matrix."
      ), call. = FALSE)
    }
  }

  alpha_used <- if (!is.null(alpha)) {
    alpha
  } else {
    switch(
      shrink_used,
      none = 0,
      diagonal = 1,
      # Simplified, deterministic dimension-to-sample rule; see Shrinkage in the docs. It
      # hits 1 exactly where the sample covariance loses full rank (J + 1 >= n_eff).
      `ledoit-wolf` = min(1, (J + 1) / n_eff)
    )
  }

  Sigma <- (1 - alpha_used) * Sigma_hat + alpha_used * diag(d, nrow = J)
  dimnames(Sigma) <- dimnames(Sigma_hat)

  # ---- Conditioning diagnostics and inverse ------------------------------------------
  kappa_val <- tryCatch(kappa(Sigma, exact = TRUE), error = function(e) Inf)
  rank_val <- tryCatch(as.integer(qr(Sigma)$rank), error = function(e) NA_integer_)

  Sigma_inv <- NULL
  ok <- FALSE
  if (isTRUE(!is.na(rank_val) && rank_val == J) && is.finite(kappa_val) &&
        kappa_val < 1 / .Machine$double.eps) {
    Sigma_inv <- tryCatch(solve(Sigma), error = function(e) NULL)
    ok <- !is.null(Sigma_inv)
    if (!is.null(Sigma_inv)) {
      dimnames(Sigma_inv) <- dimnames(Sigma)
    }
  }

  if (!ok) {
    warning(stringr::str_glue(
      "estimate_score_cov(): Sigma is singular or numerically non-invertible ",
      "(rank {rank_val} of {J}, condition number ",
      "{format(kappa_val, scientific = TRUE, digits = 3)}). Returning Sigma_inv = NULL ",
      "and ok = FALSE rather than a spurious inverse. Try shrink = 'diagonal' or a larger ",
      "`alpha`, or drop collinear cells."
    ), call. = FALSE)
  }

  list(
    Sigma = Sigma,
    Sigma_inv = Sigma_inv,
    shrink_used = shrink_used,
    alpha = alpha_used,
    kappa = kappa_val,
    rank = rank_val,
    n_eff = n_eff,
    J = J,
    ok = ok
  )
}

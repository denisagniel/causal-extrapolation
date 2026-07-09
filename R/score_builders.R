#' Orthogonal correction scores for Path 3 transport EIF
#'
#' Internal builders for the Neyman-orthogonal correction term in the doubly-robust
#' transport influence function (Path 3). Each returns a length-n numeric vector — the
#' correction evaluated on the source sample, BEFORE reweighting by the transport weight
#' \eqn{w(X_i)}. The transport EIF assembled in [integrate_cate()] is
#' \deqn{\phi_i = w_i (\tau_i - \psi) + w_i \cdot \mathrm{correction}_i + r_i.}
#'
#' @name score_builders
#' @keywords internal
NULL

#' AIPW correction (unconfoundedness design)
#'
#' Computes the augmented inverse-propensity-weighted (AIPW) correction
#' \deqn{A_i (Y_i - \mu_1(X_i)) / e(X_i) - (1 - A_i)(Y_i - \mu_0(X_i)) / (1 - e(X_i)).}
#' This is the piece that makes the transport score Neyman-orthogonal to the nuisances
#' \eqn{(\mu_0, \mu_1, e)}. See theory note eq. (2).
#'
#' @param cate A validated CATE contract list with elements `A`, `Y`, `mu1`, `mu0`, `e`.
#' @return Numeric vector of length n (the AIPW correction per observation).
#' @keywords internal
score_aipw <- function(cate) {
  # AIPW residual correction; orthogonal to (mu0, mu1, e). Length-n vector.
  cate$A * (cate$Y - cate$mu1) / cate$e -
    (1 - cate$A) * (cate$Y - cate$mu0) / (1 - cate$e)
}

#' DR-DiD correction (difference-in-differences design) -- EXPERIMENTAL, NOT VALIDATED
#'
#' Intended to compute a doubly-robust difference-in-differences correction in its
#' conditional (per-\eqn{X}) form. **This implementation is not yet validated against the
#' Sant'Anna and Zhao (2020) DR-DiD influence function and is not mean-zero as written**
#' (it lacks the propensity normalization by \eqn{\mathbb{E}[A]} and does not residualize
#' the treated arm). The `design = "did"` path in [integrate_cate()] is therefore gated
#' off until this score is derived in the theory note and cross-checked numerically
#' against `DRDID::drdid()`. Kept as an internal placeholder only; do not rely on it.
#'
#' @param cate A validated CATE contract list with elements `A`, `dY`, `m0_dY`, `e`.
#' @return Numeric vector of length n.
#' @references Sant'Anna, P. H. C., & Zhao, J. (2020). Doubly robust
#'   difference-in-differences estimators. \emph{Journal of Econometrics}, 219(1), 101-122.
#' @keywords internal
score_drdid <- function(cate) {
  # PLACEHOLDER residualized-change score -- NOT the validated Sant'Anna-Zhao score.
  # See the function docs; design = "did" is gated off in integrate_cate() until fixed.
  (cate$A - cate$e) / (cate$e * (1 - cate$e)) * (cate$dY - cate$m0_dY)
}

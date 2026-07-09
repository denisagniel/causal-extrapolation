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

#' DR-DiD correction (difference-in-differences design)
#'
#' Computes the doubly-robust difference-in-differences correction of Sant'Anna and Zhao
#' (2020) in its conditional (per-\eqn{X}) form: the residualized outcome-change score
#' \deqn{\frac{A_i - e(X_i)}{e(X_i)(1 - e(X_i))}\,\big(\Delta Y_i - m_0(X_i)\big),}
#' where \eqn{\Delta Y_i} is the observed outcome change and \eqn{m_0(X_i)} is the
#' conditional expectation of the change among the untreated. This score is orthogonal to
#' the nuisances \eqn{(m_0, e)}. Reweighted by \eqn{w(X_i)} in [integrate_cate()].
#'
#' @param cate A validated CATE contract list with elements `A`, `dY`, `m0_dY`, `e`.
#' @return Numeric vector of length n (the DR-DiD correction per observation).
#' @references Sant'Anna, P. H. C., & Zhao, J. (2020). Doubly robust
#'   difference-in-differences estimators. \emph{Journal of Econometrics}, 219(1), 101–122.
#' @keywords internal
score_drdid <- function(cate) {
  # Residualized-change DR-DiD score; orthogonal to (m0, e). Length-n vector.
  (cate$A - cate$e) / (cate$e * (1 - cate$e)) * (cate$dY - cate$m0_dY)
}

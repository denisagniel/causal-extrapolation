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
#' Computes the doubly-robust difference-in-differences correction in its conditional
#' (per-\eqn{X}) form. Under conditional parallel trends, DR-DiD is structurally identical
#' to AIPW applied to the outcome change \eqn{\Delta Y}: substitute \eqn{Y \to \Delta Y} and
#' \eqn{\mu_a(x) \to m_a(x) = \mathbb{E}[\Delta Y \mid X = x, A = a]}, with the DR-DiD
#' structural constraint \eqn{m_1 = m_0 + \tau}. The correction is
#' \deqn{\frac{A_i (\Delta Y_i - m_1(X_i))}{e(X_i)} -
#'   \frac{(1 - A_i)(\Delta Y_i - m_0(X_i))}{1 - e(X_i)},}
#' which is Neyman-orthogonal to the nuisances \eqn{(m_0, m_1, e)}. See theory note eq. (2),
#' DiD variant. This is the piece that makes the transport score orthogonal; the transport
#' EIF assembled in [integrate_cate()] reweights it by \eqn{w(X_i)}.
#'
#' \strong{Collapse certificate.} When the target equals the source (\eqn{w \equiv 1}) the
#' transport EIF reduces exactly to the ordinary DR-DiD / AIPW-on-changes efficient
#' influence function \eqn{(\tau_i - \psi) + \mathrm{correction}_i}. This is the DiD analog
#' of the unconfoundedness collapse certificate and is unit-tested.
#'
#' @param cate A validated CATE contract list with elements `A`, `dY`, `m0_dY`, `tau`, `e`.
#'   The treated-arm change regression is derived as \eqn{m_1 = m_0 + \tau} (\code{m0_dY} is
#'   the single source of truth; the contract carries no separate \code{m1_dY}).
#' @return Numeric vector of length n (the DR-DiD correction per observation).
#' @references Sant'Anna, P. H. C., & Zhao, J. (2020). Doubly robust
#'   difference-in-differences estimators. \emph{Journal of Econometrics}, 219(1), 101-122.
#' @keywords internal
score_drdid <- function(cate) {
  # AIPW-on-changes: Y -> dY, mu_a -> m_a, with the DR-DiD constraint m1 = m0 + tau.
  # Residualizes BOTH arms (the placeholder's bug was residualizing only m0). Orthogonal to
  # (m0, m1, e). Certified by the collapse test in test-integrate-cate.R.
  m0 <- cate$m0_dY
  m1 <- cate$m0_dY + cate$tau
  cate$A * (cate$dY - m1) / cate$e -
    (1 - cate$A) * (cate$dY - m0) / (1 - cate$e)
}

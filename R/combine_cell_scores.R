#' GMM/GLS-efficient combination of a joint cell score matrix
#'
#' Combines the columns of a (possibly correlated) score matrix into one or more target
#' linear combinations, using the full cross-cell covariance recovered by
#' [build_score_matrix()]/[estimate_score_cov()] rather than assuming the cells are
#' independent. This is the natural generalization of [gls_weights()], which uses only
#' the diagonal (per-cell variances) of that covariance.
#'
#' @section What this computes:
#' Let \eqn{\Phi} be the supplied \eqn{n_{\text{eff}} \times J} score matrix with covariance
#' \eqn{\Sigma}, and \eqn{\widehat\theta} the corresponding length-\eqn{J} cell estimates
#' (`values`). Given a known restriction \eqn{\theta = R\beta} (\eqn{R} an \eqn{J \times q}
#' matrix; e.g. \eqn{q} groups, one column per group indicating which cells belong to it)
#' and a target \eqn{\psi = c'\beta} (\eqn{c} length \eqn{q}), the minimum-distance /
#' optimal-GMM combination is
#' \deqn{A = R'\Sigma^{-1}R, \qquad \lambda^* = \Sigma^{-1}R A^{-1}c, \qquad
#'   \widehat\beta = A^{-1}R'\Sigma^{-1}\widehat\theta, \qquad
#'   \widehat\psi = c'\widehat\beta = {\lambda^*}'\widehat\theta,}
#' with propagated influence function \eqn{\phi_\psi = \Phi\lambda^*}. By construction
#' \eqn{{\lambda^*}'R = c'} (unbiasedness), and when the same \eqn{\Sigma} is used
#' throughout, \eqn{{\lambda^*}'\Sigma\lambda^* = c'A^{-1}c} exactly.
#'
#' @section What efficiency this does and does not deliver:
#' `combine_cell_scores()` returns the minimum-variance combination \strong{within the
#' class of fixed linear combinations of the supplied cell scores} that is unbiased for
#' the target: over all \eqn{\lambda} with \eqn{\lambda'R = c'}, it minimizes
#' \eqn{\mathrm{Var}(\lambda'\phi_i)}, attaining \eqn{c'A^{-1}c}. This is the optimal-GMM
#' (efficient minimum-distance) weighting for the linear moment system
#' \eqn{\E[\widehat\theta - R\beta] = 0}.
#'
#' This is \strong{not} the semiparametric efficiency bound for the target functional, and
#' should not be described as such. It is efficient within the span of the \eqn{J} supplied
#' scores; attaining the bound additionally requires (i) that the efficient influence
#' function under the \emph{restricted} model lie in that span -- imposing a restriction
#' shrinks the tangent space, and the restricted EIF is a projection that need not be a
#' linear combination of the unrestricted cell EIFs; (ii) that the set of cells and the
#' first-stage comparison-group design already be optimal (e.g. `control_group =
#' "notyettreated"` vs. `"nevertreated"` in a DiD first stage yields a different span and a
#' different attainable variance); and (iii) that the supplied per-cell scores already be
#' efficient for their own cell parameters -- efficiency is inherited from the first stage,
#' not created here.
#'
#' @section A practical caveat:
#' When cells reuse comparison units (e.g. group-time ATTs sharing a not-yet-treated
#' comparison group), \eqn{\Sigma} is strongly positively correlated and can be
#' near-singular. The GLS optimum then legitimately takes large, opposite-signed entries in
#' \eqn{\lambda^*} -- nominally efficient, but finite-sample unstable and dominated by
#' whichever small cohort has the least-shared comparators. `diagnostics` flags this rather
#' than silently returning an unstable combination; consider a larger `alpha` (more
#' shrinkage) or `shrink = "diagonal"` if it fires.
#'
#' @param score_matrix An \eqn{n_{\text{eff}} \times J} numeric score matrix, as returned by
#'   [build_score_matrix()].
#' @param values Numeric vector of length \eqn{J}, the per-cell point estimates
#'   \eqn{\widehat\theta} that `score_matrix`'s columns are the influence functions of.
#' @param restriction Either a known \eqn{J \times q} restriction matrix \eqn{R}, or a
#'   length-\eqn{J} grouping vector (factor, character, or numeric) that is expanded to an
#'   indicator matrix via [.build_restriction()]. `NULL` (default) means every cell shares
#'   one common scalar (\eqn{R} is a column of ones, \eqn{q = 1}).
#' @param target Numeric vector of length \eqn{q}, the coefficients \eqn{c} defining the
#'   target \eqn{\psi = c'\beta}. `NULL` is only valid when \eqn{q = 1} (the implicit
#'   `target = 1`, i.e. \eqn{\psi = \beta}).
#' @param cov Optional, the output of [estimate_score_cov()] for `score_matrix`. Computed
#'   internally via `estimate_score_cov(score_matrix, shrink = shrink)` when `NULL`.
#' @param shrink Shrinkage rule passed to [estimate_score_cov()] when `cov` is `NULL`.
#'   Ignored when `cov` is supplied. \strong{Used only to select the weights} `lambda`; the
#'   reported standard error always comes from the realized, unshrunk variance of
#'   `score_matrix %*% lambda` (see Details), so shrinkage never makes the reported SE
#'   optimistic.
#' @param fallback What to do when `cov$ok` is `FALSE` (an unreliable inverse). `"diagonal"`
#'   (default) recomputes with `shrink = "diagonal"` (always invertible) and warns.
#'   `"error"` refuses instead.
#' @param omega_scores Optional \eqn{n_{\text{eff}} \times q} matrix of per-unit influence
#'   functions for an \emph{estimated} `target`, as returned by [build_omega_score()].
#'   Supply this only when `target` was itself estimated from this sample; the returned
#'   `phi` then additionally carries the functional-delta-method term
#'   \eqn{\sum_k \widehat\beta_k \phi_{c_k,i}}, exactly as [aggregate_groups()] does for
#'   Path 1's cohort weights. The point estimate never depends on `omega_scores`.
#'
#' @return A list of class `"cell_combination"`:
#'   \describe{
#'     \item{`value`}{the combined point estimate \eqn{\widehat\psi}.}
#'     \item{`phi`}{length-\eqn{n_{\text{eff}}} propagated influence function (plus the
#'       `omega_scores` term, if supplied).}
#'     \item{`lambda`}{length-\eqn{J} combination weights, named by `colnames(score_matrix)`.}
#'     \item{`beta`, `vcov_beta`}{\eqn{\widehat\beta} and \eqn{A^{-1}/n_{\text{eff}}}.}
#'     \item{`phi_beta`}{\eqn{n_{\text{eff}} \times q} matrix of per-free-parameter
#'       influence functions of \eqn{\widehat\beta} (column \eqn{k} is the EIF of
#'       \eqn{\widehat\beta_k}); `phi` is `phi_beta %*% target` up to the `omega_scores`
#'       term.}
#'     \item{`se`}{honest standard error from the realized, unshrunk variance of
#'       `score_matrix %*% lambda` -- valid regardless of `shrink`.}
#'     \item{`se_nominal`}{\eqn{\sqrt{c'A^{-1}c / n_{\text{eff}}}} from the (possibly
#'       shrunk) `Sigma` used to choose `lambda`; a diagnostic only, not for inference.}
#'     \item{`weighting_used`}{`"full-covariance"` or `"diagonal"` (see `fallback`).}
#'     \item{`shrink_used`, `alpha`, `kappa`, `ok`}{passed through from [estimate_score_cov()].}
#'     \item{`diagnostics`}{list with `l1_norm`, `min_lambda`, `n_negative`.}
#'   }
#'
#' @seealso [build_score_matrix()], [estimate_score_cov()], [gls_weights()] (the
#'   diagonal-only special case this generalizes), [path1_aggregate()] (`weighting =
#'   "gls-joint"`).
#'
#' @examples
#' set.seed(20260925)
#' Phi <- matrix(rnorm(300 * 4), nrow = 300)
#' res <- combine_cell_scores(Phi, values = c(1, 1.2, 0.9, 1.1))
#' res$value
#' res$se
#'
#' @export
combine_cell_scores <- function(score_matrix, values, restriction = NULL, target = NULL,
                                cov = NULL, shrink = "auto",
                                fallback = c("diagonal", "error"), omega_scores = NULL) {
  fallback <- match.arg(fallback)

  if (!is.matrix(score_matrix) || !is.numeric(score_matrix)) {
    stop(stringr::str_glue(
      "score_matrix must be a numeric matrix (see build_score_matrix()), got ",
      "{class(score_matrix)[1]}."
    ), call. = FALSE)
  }
  n_eff <- nrow(score_matrix)
  J <- ncol(score_matrix)
  validate_numeric_vector(values, name = "values", allow_na = FALSE)
  if (length(values) != J) {
    stop(stringr::str_glue(
      "`values` has length {length(values)} but score_matrix has {J} columns (cells). ",
      "These must match."
    ), call. = FALSE)
  }

  R <- .build_restriction(restriction, J = J)
  q <- ncol(R)

  if (is.null(target)) {
    if (q != 1) {
      stop(stringr::str_glue(
        "`target` is NULL, which is only valid when the restriction implies q = 1 free ",
        "parameter (got q = {q}). Supply `target`, a length-{q} vector."
      ), call. = FALSE)
    }
    target <- 1
  }
  validate_numeric_vector(target, name = "target", allow_na = FALSE)
  if (length(target) != q) {
    stop(stringr::str_glue(
      "`target` has length {length(target)} but `restriction` implies q = {q} free ",
      "parameter(s). These must match."
    ), call. = FALSE)
  }

  empty_cols <- which(colSums(abs(R)) == 0)
  if (length(empty_cols) > 0) {
    stop(stringr::str_glue(
      "restriction column(s) {stringr::str_c(empty_cols, collapse = ', ')} are entirely ",
      "zero -- no cell is assigned to that free parameter, so beta is not identified for ",
      "it (an \"empty group\"). Remove it from `target`/`restriction`, or supply at least ",
      "one cell for it."
    ), call. = FALSE)
  }

  # ---- J == 1: no covariance structure to exploit ------------------------------------
  if (J == 1) {
    lambda <- target
    value <- sum(lambda * values)
    phi <- as.numeric(score_matrix %*% lambda)
    beta <- target
    phi_beta <- matrix(phi, ncol = 1)
    return(structure(
      list(
        value = value, phi = phi, lambda = stats::setNames(lambda, colnames(score_matrix)),
        beta = beta, vcov_beta = matrix(stats::var(phi) / n_eff, 1, 1), phi_beta = phi_beta,
        se = sqrt(stats::var(phi) / n_eff), se_nominal = sqrt(stats::var(phi) / n_eff),
        weighting_used = "full-covariance", shrink_used = "none", alpha = 0,
        kappa = 1, ok = TRUE,
        diagnostics = list(l1_norm = sum(abs(lambda)), min_lambda = min(lambda),
                          n_negative = sum(lambda < 0))
      ),
      class = "cell_combination"
    ))
  }

  # ---- Resolve Sigma / Sigma_inv, with the diagonal fallback -------------------------
  if (is.null(cov)) {
    cov <- estimate_score_cov(score_matrix, shrink = shrink)
  }
  weighting_used <- "full-covariance"
  if (!isTRUE(cov$ok)) {
    if (fallback == "error") {
      stop(stringr::str_glue(
        "combine_cell_scores(): Sigma is not reliably invertible (estimate_score_cov() ",
        "reported ok = FALSE), and fallback = \"error\". Supply a shrunk `cov` (e.g. ",
        "shrink = \"diagonal\"), or pass fallback = \"diagonal\" to recover automatically."
      ), call. = FALSE)
    }
    warning(
      "combine_cell_scores(): Sigma from the supplied/computed covariance was not ",
      "reliably invertible; falling back to fallback = \"diagonal\" (shrink = \"diagonal\") ",
      "so lambda is still well-defined, at the cost of ignoring cross-cell correlation.",
      call. = FALSE
    )
    cov <- estimate_score_cov(score_matrix, shrink = "diagonal")
    weighting_used <- "diagonal"
    if (!isTRUE(cov$ok)) {
      stop(
        "combine_cell_scores(): even the diagonal fallback failed to invert. This can ",
        "only happen if a cell has zero variance, which estimate_score_cov() should have ",
        "already caught; please file this as a bug.",
        call. = FALSE
      )
    }
  }
  Sigma_inv <- cov$Sigma_inv

  # ---- The GMM-efficient closed form -------------------------------------------------
  A <- t(R) %*% Sigma_inv %*% R
  A_kappa <- tryCatch(kappa(A, exact = TRUE), error = function(e) Inf)
  if (!is.finite(A_kappa) || A_kappa > 1 / .Machine$double.eps) {
    stop(stringr::str_glue(
      "combine_cell_scores(): A = R'Sigma_inv R is singular or numerically ",
      "non-invertible (condition number {format(A_kappa, scientific = TRUE, digits = 3)}). ",
      "This happens when two free parameters (columns of `restriction`) are not jointly ",
      "identified from the supplied cells given Sigma; check for collinear groupings."
    ), call. = FALSE)
  }
  A_inv <- solve(A)

  lambda <- as.numeric(Sigma_inv %*% R %*% A_inv %*% target)
  beta <- as.numeric(A_inv %*% t(R) %*% Sigma_inv %*% values)
  value <- sum(lambda * values)
  phi <- as.numeric(score_matrix %*% lambda)

  se <- sqrt(stats::var(phi) / n_eff)
  var_nominal <- as.numeric(t(target) %*% A_inv %*% target) / n_eff
  se_nominal <- sqrt(var_nominal)

  # Per-free-parameter EIFs of beta_hat: columns of Phi %*% Sigma_inv %*% R %*% A_inv.
  phi_beta <- score_matrix %*% Sigma_inv %*% R %*% A_inv
  colnames(phi_beta) <- colnames(R)
  vcov_beta <- A_inv / n_eff

  if (!is.null(omega_scores)) {
    omega_scores <- .validate_omega_scores(omega_scores, n_groups = q, n = n_eff)
    phi <- phi + .omega_contribution(omega_scores, beta)
  }

  diagnostics <- list(
    l1_norm = sum(abs(lambda)), min_lambda = min(lambda), n_negative = sum(lambda < 0)
  )
  if (diagnostics$n_negative > 0 || diagnostics$l1_norm > 2) {
    warning(stringr::str_glue(
      "combine_cell_scores(): the GMM-efficient weights include {diagnostics$n_negative} ",
      "negative entr{if (diagnostics$n_negative == 1) 'y' else 'ies'} and an L1 norm of ",
      "{round(diagnostics$l1_norm, 2)} (> 2). This is a legitimate consequence of strongly ",
      "correlated cells (e.g. shared comparison units), but is nominally efficient and ",
      "finite-sample unstable -- consider more shrinkage (a larger `alpha`, or ",
      "shrink = \"diagonal\") if this combination looks implausible."
    ), call. = FALSE)
  }

  colnames_sm <- colnames(score_matrix)
  structure(
    list(
      value = value,
      phi = phi,
      lambda = stats::setNames(lambda, colnames_sm),
      beta = beta,
      vcov_beta = vcov_beta,
      phi_beta = phi_beta,
      se = se,
      se_nominal = se_nominal,
      weighting_used = weighting_used,
      shrink_used = cov$shrink_used,
      alpha = cov$alpha,
      kappa = cov$kappa,
      ok = cov$ok,
      diagnostics = diagnostics
    ),
    class = "cell_combination"
  )
}

#' Expand a restriction argument into a J x q indicator/design matrix
#'
#' @param restriction `NULL`, a `J x q` numeric matrix, or a length-`J` grouping vector
#'   (factor, character, or numeric/integer treated as discrete labels).
#' @param J Number of cells (rows of the returned matrix).
#' @return A numeric `J x q` matrix.
#' @keywords internal
.build_restriction <- function(restriction, J) {
  if (is.null(restriction)) {
    return(matrix(1, nrow = J, ncol = 1))
  }
  if (is.matrix(restriction)) {
    if (!is.numeric(restriction)) {
      stop("`restriction`, when a matrix, must be numeric.", call. = FALSE)
    }
    if (nrow(restriction) != J) {
      stop(stringr::str_glue(
        "`restriction` has {nrow(restriction)} rows but there are {J} cells. These must ",
        "match."
      ), call. = FALSE)
    }
    return(restriction)
  }
  if (!is.atomic(restriction)) {
    stop(
      "`restriction` must be NULL, a J x q numeric matrix, or a length-J grouping vector.",
      call. = FALSE
    )
  }
  if (length(restriction) != J) {
    stop(stringr::str_glue(
      "`restriction` has length {length(restriction)} but there are {J} cells. These must ",
      "match."
    ), call. = FALSE)
  }
  if (anyNA(restriction)) {
    stop("`restriction` must not contain NA values.", call. = FALSE)
  }
  labels <- sort(unique(restriction))
  q <- length(labels)
  R <- matrix(0, nrow = J, ncol = q)
  for (k in seq_len(q)) {
    R[restriction == labels[k], k] <- 1
  }
  colnames(R) <- as.character(labels)
  R
}

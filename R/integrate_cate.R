#' Integrate a conditional ATT over a target covariate distribution (Path 3)
#'
#' Maps a user-supplied conditional average treatment effect (CATE) estimate into a
#' forward-looking average treatment effect on the treated (FATT) by integrating over a
#' target covariate distribution, and assembles the doubly-robust **transport influence
#' function** for valid inference. This is Path 3 of the extrapolation framework.
#'
#' The estimand is
#' \deqn{\theta = \int \tau(x)\, dF^{p+1}(x) = \mathbb{E}_{\mathrm{src}}[w(X)\,\tau(X)],}
#' where \eqn{\tau(x)} is the conditional ATT, \eqn{F^{p+1}} the target (e.g. future)
#' covariate distribution, and \eqn{w(x) = dF^{p+1}/dF^{\mathrm{src}}(x)} the density
#' ratio relative to the source sample on which \eqn{\tau} was estimated.
#'
#' @section Mapping, not estimation:
#' This function does **not** fit a CATE model or estimate a density ratio. The user
#' supplies fitted predictions on their source sample (see the contract below), obtained
#' from any asymptotically-linear / cross-fit learner (e.g. via [as_cate()]).
#' `integrate_cate()` assembles the transport EIF and computes standard errors and
#' confidence intervals from it.
#'
#' @section The CATE contract:
#' `cate` is a named list of predictions evaluated on the source sample (all vectors have
#' length \eqn{n}), or the output of [as_cate()]:
#' \describe{
#'   \item{`design = "unconfoundedness"`}{`tau` (CATE \eqn{\hat\mu_1 - \hat\mu_0}),
#'     `mu1`, `mu0` (outcome regressions), `e` (propensity in \eqn{(0,1)}), `A` (0/1
#'     treatment), `Y` (outcome), `X` (\eqn{n \times d} covariate frame).}
#'   \item{`design = "did"`}{`tau` (conditional DR-DiD effect), `dY` (outcome change),
#'     `m0_dY` (conditional expectation of the change among the untreated), `e`, `A`,
#'     `X`.}
#' }
#'
#' @section Target vs weights (Form A vs Form B):
#' Supply **exactly one** of:
#' \itemize{
#'   \item `target` (Form A) — an integer or logical index into the **source rows**
#'     selecting the target subpopulation (e.g. the treated units for the FATT). The point
#'     estimate is the mean of \eqn{\hat\tau} over the target, and the implied transport
#'     weight is \eqn{w_i = (n / n^*)\,\mathbf{1}\{i \in \mathrm{target}\}} (exactly 1 when
#'     the target is the full source sample — the no-shift case).
#'   \item `weights` (Form B) — a length-\eqn{n} vector of density-ratio values
#'     \eqn{w(X_i)} that you have supplied or estimated externally.
#' }
#' If you have an **external** target covariate sample that is not a subset of the source,
#' estimate the density ratio yourself and pass it as `weights`: to preserve the
#' mapping-not-estimation contract, this function will not estimate a density ratio for
#' you.
#'
#' @section Collapse property:
#' When the target equals the source (`target = seq_len(n)`, or `weights = rep(1, n)`),
#' \eqn{w \equiv 1} and the transport EIF reduces exactly to the ordinary AIPW/ATT
#' efficient influence function. This is the correctness certificate for the method (and
#' is unit-tested).
#'
#' @param cate A CATE contract list (see Details) or the output of [as_cate()].
#' @param design One of `"unconfoundedness"` or `"did"`. Ignored if `cate` carries a
#'   `design` attribute from [as_cate()] (the attribute wins, with a warning on conflict).
#' @param target Form A: integer/logical index into the source rows selecting the target
#'   subpopulation. Mutually exclusive with `weights`.
#' @param weights Form B: length-n density-ratio weights \eqn{w(X_i)}. Mutually exclusive
#'   with `target`.
#' @param level Confidence level for the interval (default 0.95).
#' @param validate Whether to validate the CATE contract (default TRUE).
#'
#' @return An object of class `cate_integration` (a list) with:
#' \describe{
#'   \item{estimate}{Scalar FATT estimate \eqn{\hat\theta}.}
#'   \item{phi}{Length-n transport EIF vector (consumable by [compute_variance()]).}
#'   \item{se}{Standard error.}
#'   \item{ci}{Confidence interval (length-2 numeric).}
#'   \item{level}{Confidence level.}
#'   \item{w}{Length-n transport weights used.}
#'   \item{design}{The design used.}
#'   \item{form}{`"target_index"` or `"density_ratio"`.}
#'   \item{n, n_eff}{Sample size and effective sample size \eqn{(\sum w)^2 / \sum w^2}.}
#' }
#'
#' @examples
#' # Minimal unconfoundedness example with a hand-built contract (no learner needed).
#' set.seed(20260708)
#' n <- 400
#' X <- data.frame(x1 = rnorm(n))
#' e <- plogis(0.5 * X$x1)
#' A <- rbinom(n, 1, e)
#' tau_x <- 1 + 0.5 * X$x1                 # true CATE
#' mu0 <- X$x1
#' mu1 <- mu0 + tau_x
#' Y <- mu0 + A * tau_x + rnorm(n, sd = 0.5)
#'
#' cate <- list(tau = tau_x, mu1 = mu1, mu0 = mu0, e = e, A = A, Y = Y, X = X)
#'
#' # FATT over the treated units (Form A).
#' res <- integrate_cate(cate, design = "unconfoundedness", target = which(A == 1))
#' res$estimate
#' res$ci
#'
#' @seealso [as_cate()] for adapters that build the contract from grf/DoubleML/rlearner
#'   fits; [compute_variance()] for the inference step.
#' @export
integrate_cate <- function(cate,
                           design = c("unconfoundedness", "did"),
                           target = NULL,
                           weights = NULL,
                           level = 0.95,
                           validate = TRUE) {
  design <- match.arg(design)

  # An as_cate() adapter may carry the design as an attribute; it takes precedence.
  cate_design <- attr(cate, "design")
  if (!is.null(cate_design)) {
    if (!missing(design) && !identical(design, cate_design)) {
      warning(stringr::str_glue(
        "design = '{design}' conflicts with the design '{cate_design}' carried by ",
        "`cate`; using '{cate_design}'."
      ), call. = FALSE)
    }
    design <- cate_design
  }

  validate_confidence_level(level, name = "level")
  if (validate) {
    validate_cate_input(cate, design = design)
  }

  # Exactly one of target / weights.
  if (is.null(target) && is.null(weights)) {
    stop("Provide exactly one of `target` (Form A) or `weights` (Form B).", call. = FALSE)
  }
  if (!is.null(target) && !is.null(weights)) {
    stop("Provide only one of `target` and `weights`; they define different estimands.",
         call. = FALSE)
  }

  n <- length(cate$tau)

  # Resolve transport weights, the point estimate, and the target-sampling correction.
  wr <- resolve_transport_weights(cate, target = target, weights = weights, n = n)
  w <- wr$w
  psi_hat <- wr$psi_hat
  r <- wr$r

  # Neyman-orthogonal correction (per design), reweighted by w.
  correction <- switch(
    design,
    unconfoundedness = score_aipw(cate),
    did              = score_drdid(cate)
  )

  # Transport EIF (theory note eq. 2). r == 0 in the supported (fixed-target) modes.
  phi <- w * (cate$tau - psi_hat) + w * correction + r

  # Overlap diagnostic: effective sample size collapses under heavy covariate shift.
  n_eff <- if (sum(w^2) > 0) (sum(w))^2 / sum(w^2) else 0
  if (n_eff < 0.1 * n) {
    warning(stringr::str_glue(
      "Heavy covariate shift: effective sample size {round(n_eff, 1)} is < 10% of n = {n}. ",
      "Transport inference may be unstable (poor overlap / large density ratio)."
    ), call. = FALSE)
  }

  inf <- compute_variance(phi, estimate = psi_hat, level = level, center = TRUE)

  new_cate_integration(
    estimate = psi_hat,
    phi = phi,
    inf = inf,
    w = w,
    design = design,
    form = wr$form,
    n = n,
    n_eff = n_eff
  )
}


#' Resolve transport weights, point estimate, and target-sampling correction
#'
#' Maps the Form A (`target` index) / Form B (`weights`) inputs to a common length-n
#' weight vector `w`, the point estimate `psi_hat`, and the target-sampling correction
#' `r` (identically zero in the supported fixed-target modes; see [integrate_cate()]).
#'
#' @param cate Validated CATE contract list.
#' @param target Form A index (integer/logical into source rows) or NULL.
#' @param weights Form B length-n density-ratio vector or NULL.
#' @param n Source sample size.
#' @return List with `w`, `psi_hat`, `r`, `form`.
#' @keywords internal
resolve_transport_weights <- function(cate, target, weights, n) {
  if (!is.null(weights)) {
    # Form B: user-supplied density ratio.
    validate_numeric_vector(weights, name = "weights")
    if (length(weights) != n) {
      stop(stringr::str_glue(
        "`weights` has length {length(weights)} but n = {n} (length of cate$tau)."
      ), call. = FALSE)
    }
    if (any(weights < 0)) {
      stop("`weights` (density ratio) must be non-negative.", call. = FALSE)
    }
    if (abs(mean(weights) - 1) > 0.05) {
      warning(stringr::str_glue(
        "mean(weights) = {round(mean(weights), 4)} is far from 1; the density ratio may ",
        "be misnormalized (E_src[w] should be 1)."
      ), call. = FALSE)
    }
    return(list(
      w = weights,
      psi_hat = mean(weights * cate$tau),
      r = numeric(n),
      form = "density_ratio"
    ))
  }

  # Form A: target is an index/logical into the source rows.
  idx <- resolve_target_index(target, n)
  n_star <- length(idx)
  if (n_star == 0) {
    stop("`target` selects zero source rows.", call. = FALSE)
  }
  w <- numeric(n)
  w[idx] <- n / n_star  # empirical density ratio; == 1 when target is the full source
  list(
    w = w,
    psi_hat = mean(cate$tau[idx]),
    r = numeric(n),  # target treated as a fixed subsample of the source: r == 0
    form = "target_index"
  )
}


#' Normalize a Form A target specification to integer source-row indices
#'
#' Accepts a logical mask (length n) or an integer/numeric index vector. Rejects external
#' covariate frames with an informative pointer to Form B.
#'
#' @param target The `target` argument from [integrate_cate()].
#' @param n Source sample size.
#' @return Integer vector of source-row indices.
#' @keywords internal
resolve_target_index <- function(target, n) {
  if (is.data.frame(target) || is.matrix(target)) {
    stop(paste0(
      "`target` is a covariate frame, but integrate_cate() does not estimate a density ",
      "ratio (mapping, not estimation). Either (a) pass `target` as an integer/logical ",
      "index into the source rows used to fit `cate`, or (b) estimate the density ratio ",
      "w(X) = dF_target/dF_source yourself and pass it via `weights` (Form B)."
    ), call. = FALSE)
  }
  if (is.logical(target)) {
    if (length(target) != n) {
      stop(stringr::str_glue(
        "logical `target` has length {length(target)} but n = {n}."
      ), call. = FALSE)
    }
    return(which(target))
  }
  if (is.numeric(target)) {
    idx <- as.integer(target)
    if (any(idx < 1) || any(idx > n) || any(is.na(idx))) {
      stop(stringr::str_glue(
        "integer `target` must contain valid row indices in 1:{n}."
      ), call. = FALSE)
    }
    return(idx)
  }
  stop("`target` must be an integer or logical index into the source rows.", call. = FALSE)
}


#' Construct a cate_integration object
#'
#' @param estimate Scalar FATT estimate.
#' @param phi Length-n transport EIF vector.
#' @param inf Output of [compute_variance()] (list with var, se, ci, level).
#' @param w Length-n transport weights.
#' @param design Design string.
#' @param form `"target_index"` or `"density_ratio"`.
#' @param n Source sample size.
#' @param n_eff Effective sample size.
#' @return Object of class `cate_integration`.
#' @keywords internal
new_cate_integration <- function(estimate, phi, inf, w, design, form, n, n_eff) {
  structure(
    list(
      estimate = estimate,
      phi = phi,
      se = inf$se,
      ci = inf$ci,
      level = inf$level,
      var = inf$var,
      w = w,
      design = design,
      form = form,
      n = n,
      n_eff = n_eff
    ),
    class = c("cate_integration", "extrapolateATT")
  )
}


#' Print a cate_integration object
#'
#' @param x A `cate_integration` object.
#' @param ... Additional arguments (ignored).
#' @export
print.cate_integration <- function(x, ...) {
  cat("Path 3: CATE integration over target covariate distribution\n")
  cat("-----------------------------------------------------------\n")
  cat(stringr::str_glue("Design:    {x$design}\n"))
  cat(stringr::str_glue("Form:      {x$form}\n"))
  cat(stringr::str_glue("Estimate:  {format(x$estimate, digits = 4, nsmall = 4)}\n"))
  cat(stringr::str_glue("SE:        {format(x$se, digits = 4, nsmall = 4)}\n"))
  ci_level <- round(100 * x$level)
  ci_lo <- format(x$ci[1], digits = 4, nsmall = 4)
  ci_hi <- format(x$ci[2], digits = 4, nsmall = 4)
  cat(stringr::str_glue("{ci_level}% CI:    [{ci_lo}, {ci_hi}]\n"))
  cat(stringr::str_glue("n:         {x$n} (effective {round(x$n_eff, 1)})\n"))
  invisible(x)
}

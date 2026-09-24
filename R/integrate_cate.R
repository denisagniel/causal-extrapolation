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
#' @section Two weights, one score:
#' The transport influence function carries **two** distinct weights, one on each of its
#' two terms:
#' \deqn{\phi_i = w^{\mathrm{ctr}}_i\,(\tau_i - \theta) \;+\;
#'   w^{\mathrm{aug}}_i\,\mathrm{aug}_i \;+\; r_i,}
#' with \eqn{\mathrm{aug}} the Neyman-orthogonal correction (AIPW, or DR-DiD on the outcome
#' change). \eqn{w^{\mathrm{ctr}}} states *which units the estimand averages over*;
#' \eqn{w^{\mathrm{aug}}} states *how strongly each unit's outcome residual corrects the
#' plug-in*. The two coincide only when target membership is itself a smooth function of
#' \eqn{X} (Regime (iii) below). When the target is a hard subset of the source — a
#' membership indicator — they necessarily differ: \eqn{w^{\mathrm{ctr}}} is that indicator
#' while \eqn{w^{\mathrm{aug}}} is the *membership propensity*
#' \eqn{q(x) = \mathbb{P}(i \in \mathrm{target} \mid X = x)}, renormalized. This is what
#' keeps both arms of \eqn{\mathrm{aug}} active and the score doubly robust: a hard
#' indicator on \eqn{\mathrm{aug}} would zero out whichever arm the indicator excludes.
#'
#' @section Target vs weights (Form A vs Form B) and the three regimes:
#' Supply **exactly one** of `target` (Form A) or `weights` (Form B). These map onto the
#' regimes as follows.
#'
#' **Regime (i) — internal target (Form A).** `target` is an integer or logical index into
#' the **source rows** selecting a target subpopulation of *this* sample (e.g. the treated
#' units, for the FATT). Then
#' \deqn{w^{\mathrm{ctr}}_i = (n/n^*)\,\mathbf{1}\{i \in \mathrm{target}\}, \qquad
#'   w^{\mathrm{aug}}_i = q(X_i) \,/\, \widehat{\mathbb{P}}(i \in \mathrm{target}),}
#' where \eqn{q} is supplied via `target_score` and \eqn{\widehat{\mathbb{P}}(i \in
#' \mathrm{target}) = n^*/n}. `target_score` has an exact default in the two cases where the
#' index itself pins \eqn{q} down: the full source (\eqn{q \equiv 1}, the no-shift case) and
#' the treated set (\eqn{q = e}, since membership there *is* treatment status). The latter
#' gives \eqn{w^{\mathrm{ctr}} = A/\hat\pi} and \eqn{w^{\mathrm{aug}} = \hat e/\hat\pi}: the
#' efficient ATT influence function of Hahn (1998). For any other `target`, `target_score`
#' is **required** — the membership propensity is not recoverable from the index alone.
#'
#' **Regime (iii) — known density ratio (Form B).** `weights` is a length-\eqn{n} vector of
#' density-ratio values \eqn{w(X_i)} you supplied or estimated externally. Target
#' membership is smooth in \eqn{X} by construction here, so the same weight applies to both
#' terms: \eqn{w^{\mathrm{ctr}} = w^{\mathrm{aug}} = w}. The reported standard error treats
#' `weights` as **known/fixed**; if they were estimated, the SE is valid only when that
#' estimation error is asymptotically negligible relative to \eqn{n^{-1/2}}, and
#' anticonservative otherwise.
#'
#' **Regime (ii) — external finite target sample.** Not currently supported. See
#' `n_target` below.
#'
#' To target an **external** covariate sample that is not a subset of the source, estimate
#' the density ratio yourself and pass it as `weights`: to preserve the
#' mapping-not-estimation contract, this function will not estimate a density ratio for
#' you.
#'
#' @section Scope: external target samples (`n_target`):
#' Supplying `n_target` is an error. Inference for a genuinely **external** finite target
#' covariate sample of size \eqn{n^*} requires a variance decomposition of the form
#' \eqn{\mathrm{Var}_{\mathrm{target}}(\tau)/n^* +
#' \mathrm{Var}_{\mathrm{src}}(w^{\mathrm{aug}}\,\mathrm{aug})/n}, whose first term is a
#' property of the target rows and therefore needs per-target-unit \eqn{\hat\tau} values
#' that this function's contract does not accept. Use Regime (i) when the target is a
#' subpopulation of the source, or Regime (iii) with a density ratio when it is not.
#'
#' @section Truncation for weak overlap:
#' `trunc` applies to Regime (iii) (Form B density-ratio weights) only. When \eqn{w(\bX)}
#' is heavy-tailed, a few source units can dominate the transport sum and inflate the
#' variance. `trunc` caps \eqn{w} at a level \eqn{C} and re-normalizes
#' (Hájek), which strictly reduces variance but introduces a bias
#' \deqn{|\tilde B(C)| \le \frac{\{Q(w>C)\}^{1/2}}{1-\delta_C}\,\{\mathrm{Var}_Q(\tau)\}^{1/2},}
#' where \eqn{\delta_C = 1 - \mathbb{E}_{\mathrm{src}}[w \wedge C]} is the target weight-mass
#' discarded by the cap. This bound is **exactly zero when \eqn{\tau} is constant on the
#' target region**, i.e. truncation is free of first-order bias whenever the conditional
#' effect does not itself vary in the region that is being truncated away. `trunc = "auto"`
#' selects the smallest cap on `trunc_grid` whose worst-case bias is at most
#' `trunc_gamma` times the standard error (default 1/4, costing under one percentage point
#' of nominal coverage at the 95% level); `trunc = C` (numeric, \eqn{\ge 1}) fixes the cap.
#' Truncation always changes the estimand to the \eqn{C}-capped target
#' \eqn{\theta(C) = \mathbb{E}_{\mathrm{src}}[\tilde w_C\,\tau]}; report `delta_trunc`
#' alongside the point estimate as an explicit statement of the target covariate mass the
#' design cannot support. Normalization is mandatory when `trunc` is finite: unnormalized
#' truncation carries a pure scale bias of order \eqn{\delta_C} even when \eqn{\tau} is
#' constant, so this function always Hájek-normalizes internally.
#'
#' The bound above is derived for a weight that multiplies the **whole** score, which is
#' the Regime (iii) structure. In Regime (i) the centering weight is a fixed membership
#' indicator with no tail to cap, and the two weights are not interchangeable, so a finite
#' `trunc` (or `"auto"`) is rejected there rather than silently reinterpreted.
#'
#' @section Collapse properties:
#' Two no-shift certificates pin the assembly down, and they target **different**
#' functionals:
#' \itemize{
#'   \item `target = seq_len(n)` (or `weights = rep(1, n)`) puts \eqn{w \equiv 1} on every
#'     unit, averaging \eqn{\tau} over the whole population: the score reduces exactly to
#'     the ordinary AIPW efficient influence function for the **ATE**.
#'   \item `target = which(A == 1)` under `design = "unconfoundedness"` reduces exactly to
#'     the efficient influence function for the **ATT** (Hahn, 1998),
#'     \eqn{(A/\pi)(\tau - \theta) + (e/\pi)\,\mathrm{aug}}.
#' }
#' Both are unit-tested, as is the DiD analog of the first.
#'
#' @param cate A CATE contract list (see Details) or the output of [as_cate()].
#' @param design Identification design. `"unconfoundedness"` uses the AIPW transport score;
#'   `"did"` uses the DR-DiD transport score (conditional parallel trends, Sant'Anna-Zhao
#'   (2020)), which is AIPW applied to the outcome change \eqn{\Delta Y}. Both are
#'   collapse-certified against the ordinary AIPW/ATT efficient influence function at the
#'   no-shift case, and the DiD point estimate is cross-checked against `DRDID::drdid()`
#'   (see tests). Ignored if `cate` carries a `design` attribute from [as_cate()] (the
#'   attribute wins, with a warning on conflict).
#' @param target Form A (Regime (i)): integer/logical index into the source rows selecting
#'   the target subpopulation. Mutually exclusive with `weights`.
#' @param weights Form B (Regime (iii)): length-n density-ratio weights \eqn{w(X_i)}.
#'   Mutually exclusive with `target`.
#' @param target_score Form A only: length-n vector of target-membership propensities
#'   \eqn{q(X_i) = \mathbb{P}(i \in \mathrm{target} \mid X_i)}, used (renormalized) as the
#'   weight on the orthogonal correction. Has an exact default when `target` is the full
#'   source (\eqn{q \equiv 1}) or exactly the treated set (\eqn{q = } `cate$e`, which
#'   recovers the efficient ATT influence function); required for any other `target`.
#' @param n_target Not supported: supplying this is an error. Inference for a genuinely
#'   external finite target sample needs per-target-unit CATE values, which this function's
#'   contract does not accept. See the scope section above.
#' @param trunc Truncation cap for weak overlap, applicable to Form B (Regime (iii)) only:
#'   `Inf` (default, no truncation), a numeric \eqn{C \ge 1}, or `"auto"` to select \eqn{C}
#'   from `trunc_grid` via the bias/SE budget `trunc_gamma`. See Details.
#' @param trunc_gamma Bias budget for `trunc = "auto"`, as a multiple of the standard error
#'   (default 0.25). Ignored unless `trunc = "auto"`.
#' @param trunc_grid Candidate caps for `trunc = "auto"`. Default `NULL` uses
#'   \eqn{\{q_{0.90}, q_{0.95}, q_{0.99}, q_{0.995}\}} of the resolved weights (plus `Inf`,
#'   always appended as the "no truncation" fallback).
#' @param level Confidence level for the interval (default 0.95).
#' @param validate Whether to validate the CATE contract (default TRUE).
#'
#' @return An object of class `cate_integration` (a list) with:
#' \describe{
#'   \item{estimate}{Scalar FATT estimate \eqn{\hat\theta} (of the \eqn{C}-capped estimand
#'     when truncation is active).}
#'   \item{phi}{Length-n transport EIF vector (consumable by [compute_variance()]).}
#'   \item{se}{Standard error.}
#'   \item{ci}{Confidence interval (length-2 numeric).}
#'   \item{level}{Confidence level.}
#'   \item{w}{Length-n centering weights actually used (post-truncation if applicable).}
#'   \item{w_aug}{Length-n weights applied to the orthogonal correction.}
#'   \item{design}{The design used.}
#'   \item{form}{`"target_index"` or `"density_ratio"`.}
#'   \item{regime}{`"internal_target"` or `"known_ratio"`.}
#'   \item{n, n_eff}{Sample size and effective sample size \eqn{(\sum w)^2 / \sum w^2} of
#'     the centering weights.}
#'   \item{trunc}{The truncation cap actually used (`Inf` if none).}
#'   \item{trunc_diag}{List with `delta_trunc`, `q_exceed`, `var_q_tau`, `bias_bound`,
#'     `se_bias_aware` (\eqn{z\cdot\mathrm{se} + \mathrm{bias\_bound}} half-width ingredient).}
#'   \item{two_sample}{Always `NULL` (Regime (ii) is out of scope; see above).}
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
#' @references Hahn, J. (1998). On the role of the propensity score in efficient
#'   semiparametric estimation of average treatment effects. \emph{Econometrica}, 66(2),
#'   315-331.
#' @export
integrate_cate <- function(cate,
                           design = c("unconfoundedness", "did"),
                           target = NULL,
                           weights = NULL,
                           target_score = NULL,
                           n_target = NULL,
                           trunc = Inf,
                           trunc_gamma = 0.25,
                           trunc_grid = NULL,
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
  if (!is.null(target_score) && !is.null(weights)) {
    stop(paste0(
      "`target_score` applies to Form A (`target`) only: it is the target-membership ",
      "propensity q(x) = P(i in target | X = x). Form B already supplies a smooth ",
      "density ratio via `weights`, which weights both terms of the score."
    ), call. = FALSE)
  }
  # Regime (ii) -- a genuinely external finite target sample -- is out of scope. Fail fast
  # rather than returning a number the variance does not describe. (See NEWS.md.)
  if (!is.null(n_target)) {
    stop(paste0(
      "`n_target` is not supported. Inference for a genuinely external finite target ",
      "covariate sample requires a variance decomposition over the TARGET rows ",
      "(Var_target(tau)/n* + Var_src(w_aug * aug)/n), which needs per-target-unit CATE ",
      "predictions that the `cate` contract does not accept. Use `target` (an internal ",
      "target subpopulation) or `weights` (a density ratio) instead."
    ), call. = FALSE)
  }

  n <- length(cate$tau)

  # Resolve the two transport weights and the target-sampling correction.
  wr <- resolve_transport_weights(
    cate, target = target, weights = weights, target_score = target_score, n = n
  )

  # Neyman-orthogonal correction (per design); reweighted by w_aug, not w_center.
  correction <- switch(
    design,
    unconfoundedness = score_aipw(cate),
    did              = score_drdid(cate)
  )

  # Resolve truncation (Inf = no-op) and compute the core DR estimate at the chosen cap.
  # .resolve_truncation() internally evaluates the untruncated case too (as part of the
  # grid, or directly when trunc = Inf), so there is no separate "core_full" to compute
  # here -- Var_Q(tau) in the bias bound is a property of (tau, w_full) alone (see
  # .weighted_var_q()), not of any DR point estimate.
  trunc_info <- .resolve_truncation(
    w_full = wr$w_center, w_aug = wr$w_aug, tau = cate$tau, correction = correction,
    r = wr$r, n = n, level = level, regime = wr$regime,
    trunc = trunc, trunc_gamma = trunc_gamma, trunc_grid = trunc_grid
  )
  core <- trunc_info$core

  new_cate_integration(
    estimate = core$psi_hat,
    phi = core$phi,
    se = core$se,
    ci = core$ci,
    var = core$var,
    level = level,
    w = core$w_used,
    w_aug = core$w_aug_used,
    design = design,
    form = wr$form,
    regime = wr$regime,
    n = n,
    n_eff = core$n_eff,
    trunc = trunc_info$trunc_used,
    trunc_diag = trunc_info$diag,
    two_sample = NULL
  )
}


#' Core transport-EIF computation for a fixed pair of weight vectors
#'
#' Given resolved (possibly truncated) centering and augmentation weights, assembles the
#' doubly-robust one-step estimate and transport EIF, checks finiteness, warns on poor
#' overlap, and computes the variance. Factored out of [integrate_cate()] so the truncation
#' grid search in [.resolve_truncation()] can call it repeatedly without duplicating the
#' estimation logic.
#'
#' @param w_center Length-n weight on the centered CATE term (either the full centering
#'   weights or a truncated/renormalized version of them).
#' @param w_aug Length-n weight on the orthogonal correction. Equal to `w_center` in the
#'   known-density-ratio regime; the renormalized target-membership propensity in the
#'   internal-target regime.
#' @param tau Length-n conditional ATT predictions.
#' @param correction Length-n Neyman-orthogonal correction (`score_aipw()`/`score_drdid()`).
#' @param r Length-n target-sampling correction (zero in the supported fixed-target modes).
#' @param n Source sample size.
#' @param level Confidence level.
#' @return List with `psi_hat`, `phi`, `n_eff`, `var`, `se`, `ci`, `w_used`, `w_aug_used`.
#' @keywords internal
.cate_core <- function(w_center, w_aug, tau, correction, r, n, level) {
  # Doubly-robust one-step estimate: plug-in mean(w_center*tau) PLUS the mean orthogonal
  # correction weighted by w_aug. This is the estimand the transport EIF is the influence
  # function OF, so the point estimate and its EIF correspond to the same functional (and
  # the sample mean of phi below is then exactly zero when E_hat[w_center] = 1). Using the
  # bare plug-in mean(w_center*tau) would pair a plug-in estimate with a DR variance --
  # inconsistent, and biased whenever the nuisances are estimated.
  #
  # The correction carries w_aug, not w_center: w_center says which units the estimand
  # averages over, whereas the correction's weight must be smooth in X for BOTH of its arms
  # to survive. Under a hard membership indicator, the arm the indicator excludes is
  # annihilated pointwise (A(1 - A) == 0) and double robustness is lost.
  psi_hat <- mean(w_center * tau) + mean(w_aug * correction) + mean(r)

  # Transport EIF: the two terms carry their own weights. r == 0 in the supported modes.
  phi <- w_center * (tau - psi_hat) + w_aug * correction + r

  # Guard non-finite EIF (reachable via validate = FALSE, or e near 0/1 slipping through):
  # compute_variance() warns on NA but not NaN/Inf, which would silently corrupt the SE.
  if (any(!is.finite(phi))) {
    stop(stringr::str_glue(
      "Transport EIF contains {sum(!is.finite(phi))} non-finite value(s). ",
      "Check propensity overlap (e near 0/1) and that tau/mu/Y are finite."
    ), call. = FALSE)
  }

  # Overlap diagnostic: effective sample size collapses under heavy covariate shift. Keyed
  # off the centering weights, which define the target subpopulation being averaged over.
  # Warn when the effective sample is below this fraction of n (poor overlap / large w).
  overlap_frac <- 0.1
  n_eff <- if (sum(w_center^2) > 0) (sum(w_center))^2 / sum(w_center^2) else 0
  if (n_eff < overlap_frac * n) {
    warning(stringr::str_glue(
      "Heavy covariate shift: effective sample size {round(n_eff, 1)} is < 10% of n = {n}. ",
      "Transport inference may be unstable (poor overlap / large density ratio)."
    ), call. = FALSE)
  }

  inf <- compute_variance(phi, estimate = psi_hat, level = level, center = TRUE)

  list(psi_hat = psi_hat, phi = phi, n_eff = n_eff, var = inf$var, se = inf$se,
       ci = inf$ci, w_used = w_center, w_aug_used = w_aug)
}


#' Weighted variance of tau under the change-of-measure dQ = w dP_src
#'
#' Estimates \eqn{\mathrm{Var}_Q(\tau) = \mathbb{E}_Q[(\tau - \mathbb{E}_Q[\tau])^2]} as the
#' \eqn{w}-weighted sample variance of `tau`, i.e. the second central moment of \eqn{\tau}
#' under the measure \eqn{Q} defined by \eqn{dQ = w\,dP_{\mathrm{src}}}. This is centered
#' at the **plug-in weighted mean of tau itself**, \eqn{\widehat{\mathbb{E}}_Q[\tau] =
#' \sum w_i\tau_i / \sum w_i}, not at the doubly-robust one-step estimate of
#' \eqn{\theta_{p+1}}: \eqn{\mathrm{Var}_Q(\tau)} is a property of \eqn{\tau} and \eqn{Q}
#' alone (the truncation-bias and two-sample propositions in the theory note both define
#' it via \eqn{\psi_3 =
#' \mathbb{E}_Q[\tau]}), and centering at the DR estimate instead would contaminate it with
#' the orthogonal correction term's own finite-sample noise -- and would not vanish exactly
#' when \eqn{\tau} is literally constant, which is the whole point of the bound (the
#' truncation bias is *exactly* zero under effect homogeneity; see tests).
#'
#' Shared by the truncation bias bound (evaluated at the untruncated weights) and the
#' two-sample variance addendum (evaluated at the final, possibly-truncated weights).
#'
#' @param w Length-n weight vector.
#' @param tau Length-n conditional ATT predictions.
#' @return Scalar estimate of \eqn{\mathrm{Var}_Q(\tau)}.
#' @keywords internal
.weighted_var_q <- function(w, tau) {
  sw <- sum(w)
  if (!is.finite(sw) || sw <= 0) {
    return(NA_real_)
  }
  m <- sum(w * tau) / sw
  sum(w * (tau - m)^2) / sw
}


#' Truncate and Hájek-renormalize a weight vector at cap C
#'
#' @param w_full Length-n untruncated weight vector.
#' @param C Truncation cap (may be `Inf`, meaning no truncation).
#' @return List with `w` (renormalized truncated weights, mean 1), `delta_c`
#'   (target weight-mass loss \eqn{\delta_C}), `norm_factor` (\eqn{1-\delta_C}).
#' @keywords internal
.truncate_weights <- function(w_full, C) {
  if (!is.finite(C)) {
    return(list(w = w_full, delta_c = 0, norm_factor = 1))
  }
  w_c_raw <- pmin(w_full, C)
  norm_factor <- mean(w_c_raw)
  if (!is.finite(norm_factor) || norm_factor <= 0) {
    stop("`trunc` is too small: all truncated weights collapse to zero.", call. = FALSE)
  }
  list(w = w_c_raw / norm_factor, delta_c = 1 - norm_factor, norm_factor = norm_factor)
}


#' Truncation bias-bound diagnostics at cap C
#'
#' Computes the Cauchy--Schwarz truncation-bias bound
#' \eqn{|\tilde B(C)| \le \{Q(w>C)\}^{1/2}\{\mathrm{Var}_Q(\tau)\}^{1/2}/(1-\delta_C)}
#' (the truncation bias-bound proposition (theory note, Prop. truncbias, eq. biasCS)), with \eqn{\mathrm{Var}_Q(\tau)} estimated against
#' the **untruncated** target measure (`w_full`) -- the bias is that of the capped
#' estimand relative to the original, uncapped one.
#'
#' @param w_full Length-n untruncated weight vector.
#' @param tau Length-n conditional ATT predictions.
#' @param C Truncation cap.
#' @param delta_c Target weight-mass loss at `C` (from `.truncate_weights()`).
#' @return List with `q_exceed`, `var_q_tau`, `bias_bound`.
#' @keywords internal
.trunc_bias_bound <- function(w_full, tau, C, delta_c) {
  var_q_tau <- .weighted_var_q(w_full, tau)
  if (!is.finite(C)) {
    return(list(q_exceed = 0, var_q_tau = var_q_tau, bias_bound = 0))
  }
  # Q(w > C) = E_src[w * 1{w > C}]; delta_C already reflects the same tail via (3.1).
  q_exceed <- mean(w_full * (w_full > C))
  bias_bound <- if (delta_c < 1) sqrt(q_exceed) * sqrt(var_q_tau) / (1 - delta_c) else Inf
  list(q_exceed = q_exceed, var_q_tau = var_q_tau, bias_bound = bias_bound)
}


#' Resolve the `trunc` argument to a final weight vector and diagnostics
#'
#' Dispatches on `trunc`: `Inf`/`NULL` (no truncation), `"auto"` (grid search over
#' `trunc_grid` for the smallest cap meeting the `trunc_gamma` bias/SE budget), or a fixed
#' finite numeric cap `\ge 1`. See [integrate_cate()]'s Truncation section for the bound
#' being budgeted. Only the centering weights are capped, and only in the
#' known-density-ratio regime, where they coincide with the augmentation weights and so the
#' bound's single-weight derivation applies; a finite cap in the internal-target regime is
#' rejected (the argument is validated first, so a malformed `trunc` still reports its own
#' problem).
#'
#' @inheritParams integrate_cate
#' @param w_full Length-n untruncated centering weight vector.
#' @param w_aug Length-n augmentation weight vector (never truncated).
#' @param tau Length-n conditional ATT predictions.
#' @param correction Length-n Neyman-orthogonal correction.
#' @param r Length-n target-sampling correction.
#' @param n Source sample size.
#' @param level Confidence level.
#' @param regime `"internal_target"` or `"known_ratio"` (from
#'   [resolve_transport_weights()]).
#' @return List with `core` (output of `.cate_core()` at the chosen cap), `trunc_used`,
#'   `diag` (list with `delta_trunc`, `q_exceed`, `var_q_tau`, `bias_bound`,
#'   `se_bias_aware`).
#' @keywords internal
.resolve_truncation <- function(w_full, w_aug, tau, correction, r, n, level, regime,
                                trunc, trunc_gamma, trunc_grid) {
  eval_at <- function(C) {
    tw <- .truncate_weights(w_full, C)
    if (tw$delta_c > 0.5) {
      stop(stringr::str_glue(
        "trunc = {round(C, 4)} discards {round(100 * tw$delta_c, 1)}% of target weight ",
        "mass (delta_C > 0.5): the truncated estimand no longer refers to the intended ",
        "target. Choose a larger `trunc`, or use `trunc = \"auto\"`."
      ), call. = FALSE)
    }
    bb <- .trunc_bias_bound(w_full, tau, C, tw$delta_c)
    # Only the centering weights are capped. Truncation is confined to the regime in which
    # the two weights coincide, so there the capped vector is the augmentation weight too.
    w_aug_used <- if (identical(regime, "known_ratio")) tw$w else w_aug
    core <- .cate_core(tw$w, w_aug_used, tau, correction, r, n, level)
    list(
      core = core,
      diag = list(
        delta_trunc = tw$delta_c, q_exceed = bb$q_exceed, var_q_tau = bb$var_q_tau,
        bias_bound = bb$bias_bound, se_bias_aware = core$se + bb$bias_bound
      )
    )
  }

  # Truncation applies to the known-density-ratio regime only: the bias bound is derived for
  # a single weight multiplying the whole score, and an internal target's centering weight
  # is a fixed membership indicator with no tail to cap.
  reject_for_regime <- function() {
    if (identical(regime, "internal_target")) {
      stop(paste0(
        "`trunc` applies to `weights` (a density ratio) only. With `target`, the ",
        "centering weight is a fixed target-membership indicator: there is no ",
        "heavy-tailed density ratio to cap, and the truncation bias bound does not ",
        "apply. Leave `trunc = Inf`, or supply a density ratio via `weights`."
      ), call. = FALSE)
    }
    invisible(NULL)
  }

  # No truncation: NULL or a numeric Inf.
  if (is.null(trunc) || (is.numeric(trunc) && length(trunc) == 1 && is.infinite(trunc))) {
    res <- eval_at(Inf)
    return(list(core = res$core, trunc_used = Inf, diag = res$diag))
  }

  # trunc = "auto": grid search, smallest cap meeting the bias/SE budget.
  if (is.character(trunc)) {
    if (!identical(trunc, "auto")) {
      stop("`trunc` must be `Inf`, a numeric cap >= 1, or the string \"auto\".",
           call. = FALSE)
    }
    validate_scalar(trunc_gamma, name = "trunc_gamma")
    if (trunc_gamma <= 0) {
      stop("`trunc_gamma` must be positive.", call. = FALSE)
    }
    reject_for_regime()
    grid <- trunc_grid
    if (is.null(grid)) {
      grid <- unname(stats::quantile(w_full, probs = c(0.90, 0.95, 0.99, 0.995),
                                     na.rm = TRUE))
    }
    grid <- sort(unique(c(grid[is.finite(grid) & grid >= 1], Inf)))

    chosen <- NULL
    for (C in grid) {
      res <- eval_at(C)
      if (res$diag$bias_bound <= trunc_gamma * res$core$se) {
        chosen <- list(C = C, res = res)
        break
      }
    }
    if (is.null(chosen)) {
      # Defensive fallback; Inf (bias_bound == 0) always satisfies the budget trivially,
      # so this branch is unreachable in practice but kept for robustness.
      chosen <- list(C = Inf, res = eval_at(Inf))
    }
    if (is.infinite(chosen$C)) {
      warning(stringr::str_glue(
        "trunc = 'auto': no cap in the grid keeps the truncation bias below ",
        "{trunc_gamma} x SE; returning the untruncated estimate. This signals weak ",
        "overlap; report delta_trunc/bias_bound as a sensitivity statement rather ",
        "than relying on the point estimate alone."
      ), call. = FALSE)
    }
    return(list(core = chosen$res$core, trunc_used = chosen$C, diag = chosen$res$diag))
  }

  # Fixed finite numeric cap.
  if (!is.numeric(trunc) || length(trunc) != 1) {
    stop("`trunc` must be `Inf`, a numeric cap >= 1, or the string \"auto\".", call. = FALSE)
  }
  validate_scalar(trunc, name = "trunc")
  if (trunc < 1) {
    stop("`trunc` must be >= 1: since E_src[w] = 1 under Assumption RC9, capping below 1 ",
         "always discards target mass without any offsetting benefit.", call. = FALSE)
  }
  reject_for_regime()
  res <- eval_at(trunc)
  list(core = res$core, trunc_used = trunc, diag = res$diag)
}


#' Resolve the centering and augmentation transport weights
#'
#' Maps the Form A (`target` index) / Form B (`weights`) inputs to the two length-n weight
#' vectors the transport score needs — `w_center` on the centered CATE term and `w_aug` on
#' the orthogonal correction — plus the target-sampling correction `r` (identically zero in
#' the supported modes; see [integrate_cate()]). The point estimate is assembled by
#' [integrate_cate()] as a doubly-robust one-step, so it is not computed here.
#'
#' \strong{Regime (iii), known density ratio (Form B).} Target membership is smooth in
#' \eqn{X} by construction, so one weight serves both terms:
#' \eqn{w^{\mathrm{ctr}} = w^{\mathrm{aug}} = w}.
#'
#' \strong{Regime (i), internal target (Form A).} Membership is a hard indicator, so the two
#' weights differ: \eqn{w^{\mathrm{ctr}}_i = (n/n^*)\mathbf{1}\{i \in \mathrm{target}\}}
#' states which units the estimand averages over, while
#' \eqn{w^{\mathrm{aug}}_i = q(X_i)/(n^*/n)} carries the correction, with
#' \eqn{q(x) = \mathbb{P}(i \in \mathrm{target} \mid X = x)} supplied via `target_score`.
#' The indicator cannot be reused on the correction: it annihilates whichever arm of the
#' correction it excludes (for the treated-set target, \eqn{A(1 - A) \equiv 0} kills the
#' untreated arm outright), which drops every control outcome from the score and forfeits
#' robustness to a misspecified \eqn{\mu_0}. When `target` is exactly the treated set,
#' `target_score` defaults to `cate$e` and \eqn{w^{\mathrm{aug}} = \hat e/\hat\pi}, the
#' efficient ATT influence function's augmentation weight.
#'
#' @param cate Validated CATE contract list.
#' @param target Form A index (integer/logical into source rows) or NULL.
#' @param weights Form B length-n density-ratio vector or NULL.
#' @param target_score Form A length-n membership-propensity vector, or NULL to use the
#'   treated-set default.
#' @param n Source sample size.
#' @return List with `w_center`, `w_aug`, `r`, `form`, `regime`.
#' @keywords internal
resolve_transport_weights <- function(cate, target, weights, target_score = NULL, n) {
  # E_src[w] should be 1 up to sampling noise; a 5% gap is a loose misnormalization screen
  # (sampling noise, unlike validate_group_weights' exact 1e-6 sum check).
  weight_mean_tol <- 0.05

  if (!is.null(weights)) {
    # Form B / Regime (iii): user-supplied density ratio, smooth in X, so one weight
    # legitimately multiplies the whole score.
    validate_numeric_vector(weights, name = "weights")
    if (length(weights) != n) {
      stop(stringr::str_glue(
        "`weights` has length {length(weights)} but n = {n} (length of cate$tau)."
      ), call. = FALSE)
    }
    if (any(weights < 0)) {
      stop("`weights` (density ratio) must be non-negative.", call. = FALSE)
    }
    if (all(weights == 0)) {
      stop("`weights` are all zero; the target subpopulation is empty.", call. = FALSE)
    }
    if (abs(mean(weights) - 1) > weight_mean_tol) {
      warning(stringr::str_glue(
        "mean(weights) = {round(mean(weights), 4)} is far from 1; the density ratio may ",
        "be misnormalized (E_src[w] should be 1)."
      ), call. = FALSE)
    }
    return(list(w_center = weights, w_aug = weights, r = numeric(n),
                form = "density_ratio", regime = "known_ratio"))
  }

  # Form A / Regime (i): target is an index/logical into the source rows.
  idx <- resolve_target_index(target, n)
  n_star <- length(idx)
  if (n_star == 0) {
    stop("`target` selects zero source rows.", call. = FALSE)
  }
  if (n_star == 1) {
    warning("`target` selects a single source row; the FATT reduces to one unit's CATE ",
            "and inference is unreliable.", call. = FALSE)
  }
  w_center <- numeric(n)
  w_center[idx] <- n / n_star  # membership indicator, scaled; == 1 for the full source

  q <- .resolve_target_score(cate, target_score = target_score, idx = idx, n = n)
  # w_aug = q(X) / P(i in target); the plug-in for P(i in target) is n*/n. For the
  # treated-set target with q = e this is ehat/pihat, matching Hahn's ATT EIF.
  w_aug <- q * (n / n_star)

  list(
    w_center = w_center,
    w_aug = w_aug,
    r = numeric(n),  # target treated as a fixed subsample of the source: r == 0
    form = "target_index",
    regime = "internal_target"
  )
}


#' Resolve the target-membership propensity for a Form A target
#'
#' Validates a user-supplied `target_score`, or supplies an exact default in the two cases
#' where membership propensity is determined by the index alone: the full source
#' (\eqn{q \equiv 1}) and the treated set (\eqn{q = e}, since membership is treatment
#' status). For any other target the membership propensity is not recoverable from the index,
#' so it is required rather than guessed: falling back to the membership indicator would
#' annihilate one arm of the orthogonal correction (see [resolve_transport_weights()]).
#'
#' @param cate Validated CATE contract list.
#' @param target_score User-supplied length-n membership propensities, or NULL.
#' @param idx Integer source-row indices selecting the target.
#' @param n Source sample size.
#' @return Length-n numeric vector of membership propensities.
#' @keywords internal
.resolve_target_score <- function(cate, target_score, idx, n) {
  if (is.null(target_score)) {
    idx_sorted <- sort(unique(as.integer(idx)))
    # Full source as target: membership is certain, q(x) == 1 exactly. This is the no-shift
    # case, and the score collapses to the ordinary AIPW/DR-DiD EIF for the ATE.
    if (identical(idx_sorted, seq_len(n))) {
      return(rep(1, n))
    }
    # Treated set as target: membership IS treatment status, so q(x) = e(x) exactly. This
    # recovers the efficient ATT influence function.
    if (identical(idx_sorted, sort(as.integer(which(cate$A == 1))))) {
      return(cate$e)
    }
    stop(paste0(
      "`target_score` is required for this `target`. The orthogonal correction is ",
      "weighted by the target-membership propensity q(x) = P(i in target | X = x), ",
      "which cannot be read off a row index: supply it as a length-n vector via ",
      "`target_score`. It has an exact default only when `target` is the full source ",
      "(q == 1) or exactly the treated set (`which(A == 1)`, q == `cate$e`)."
    ), call. = FALSE)
  }

  validate_numeric_vector(target_score, name = "target_score")
  if (length(target_score) != n) {
    stop(stringr::str_glue(
      "`target_score` has length {length(target_score)} but n = {n} (length of cate$tau)."
    ), call. = FALSE)
  }
  if (any(target_score < 0)) {
    stop("`target_score` is a membership probability and must be non-negative.",
         call. = FALSE)
  }
  if (all(target_score == 0)) {
    stop("`target_score` is all zero; no source unit can belong to the target.",
         call. = FALSE)
  }
  target_score
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
    if (any(is.na(target)) || any(target != floor(target))) {
      stop("`target` must contain whole-number row indices (no NA or fractional values).",
           call. = FALSE)
    }
    idx <- as.integer(target)
    if (any(idx < 1) || any(idx > n)) {
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
#' @param se Standard error.
#' @param ci Confidence interval (length-2 numeric).
#' @param var Variance of the estimator.
#' @param level Confidence level.
#' @param w Length-n centering weights (post-truncation if applicable).
#' @param w_aug Length-n weights applied to the orthogonal correction.
#' @param design Design string.
#' @param form `"target_index"` or `"density_ratio"`.
#' @param regime `"internal_target"` or `"known_ratio"`.
#' @param n Source sample size.
#' @param n_eff Effective sample size of the centering weights.
#' @param trunc Truncation cap actually used (`Inf` if none).
#' @param trunc_diag List of truncation diagnostics (see [integrate_cate()]).
#' @param two_sample Always `NULL`; retained for output-shape stability.
#' @return Object of class `cate_integration`.
#' @keywords internal
new_cate_integration <- function(estimate, phi, se, ci, var, level, w, w_aug, design, form,
                                 regime, n, n_eff, trunc, trunc_diag, two_sample) {
  structure(
    list(
      estimate = estimate,
      phi = phi,
      se = se,
      ci = ci,
      level = level,
      var = var,
      w = w,
      w_aug = w_aug,
      design = design,
      form = form,
      regime = regime,
      n = n,
      n_eff = n_eff,
      trunc = trunc,
      trunc_diag = trunc_diag,
      two_sample = two_sample
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
  cat(stringr::str_glue("Form:      {x$form} ({x$regime})\n"))
  cat(stringr::str_glue("Estimate:  {format(x$estimate, digits = 4, nsmall = 4)}\n"))
  cat(stringr::str_glue("SE:        {format(x$se, digits = 4, nsmall = 4)}\n"))
  ci_level <- round(100 * x$level)
  ci_lo <- format(x$ci[1], digits = 4, nsmall = 4)
  ci_hi <- format(x$ci[2], digits = 4, nsmall = 4)
  cat(stringr::str_glue("{ci_level}% CI:    [{ci_lo}, {ci_hi}]\n"))
  cat(stringr::str_glue("n:         {x$n} (effective {round(x$n_eff, 1)})\n"))
  if (is.finite(x$trunc)) {
    cat(stringr::str_glue(
      "Trunc:     C = {format(x$trunc, digits = 4)}, ",
      "delta = {format(x$trunc_diag$delta_trunc, digits = 3)}, ",
      "bias_bound = {format(x$trunc_diag$bias_bound, digits = 3)}\n"
    ))
  }
  invisible(x)
}

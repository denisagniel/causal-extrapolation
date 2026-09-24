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
#'     the target is the full source sample — the no-shift case). The target here is a
#'     fixed subsample of *this* source; there is no second sample, so `n_target` (below)
#'     does not apply.
#'   \item `weights` (Form B) — a length-\eqn{n} vector of density-ratio values
#'     \eqn{w(X_i)} that you have supplied or estimated externally, e.g. against a
#'     genuinely external target covariate sample.
#' }
#' If you have an **external** target covariate sample that is not a subset of the source,
#' estimate the density ratio yourself and pass it as `weights`: to preserve the
#' mapping-not-estimation contract, this function will not estimate a density ratio for
#' you. The reported standard error treats `weights` as **known/fixed** unless `n_target`
#' is supplied (see below); if `weights` were estimated and `n_target` is not supplied, the
#' SE is valid only when that estimation error is asymptotically negligible relative to
#' \eqn{n^{-1/2}}, and anticonservative otherwise.
#'
#' @section Two-sample variance correction:
#' When the target covariate sample used to construct `weights` (Form B) is a genuinely
#' **external** sample of size \eqn{n^*}, independent of the source, the semiparametric
#' efficiency bound for \eqn{\theta} picks up an additional term from the sampling
#' variability of that second sample:
#' \deqn{V = V_{\mathrm{src}} + \rho\,\mathrm{Var}_Q(\tau(\bX)), \qquad \rho = \lim n/n^*,}
#' where \eqn{V_{\mathrm{src}}} is exactly the variance already computed from the transport
#' EIF and \eqn{\mathrm{Var}_Q(\tau)} is the variance of the CATE under the target measure
#' \eqn{Q} (\eqn{dQ = w\,dP_{\mathrm{src}}}). Supplying `n_target` \eqn{= n^*} adds this
#' term with plug-in \eqn{\widehat\rho = n/n^*} and a weighted-variance estimate of
#' \eqn{\mathrm{Var}_Q(\tau)}; the constant on the addendum is exactly 1 (not an order
#' bound). This assumes the two samples are independent draws (no overlap); if the target
#' is instead a fixed subsample of the source (Form A), do not supply `n_target` — there is
#' no second sample and the addendum does not apply.
#'
#' @section Truncation for weak overlap:
#' When \eqn{w(\bX)} is heavy-tailed, a few source units can dominate the transport sum and
#' inflate the variance. `trunc` caps \eqn{w} at a level \eqn{C} and re-normalizes
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
#' @section Collapse property:
#' When the target equals the source (`target = seq_len(n)`, or `weights = rep(1, n)`),
#' \eqn{w \equiv 1} and the transport EIF reduces exactly to the ordinary AIPW/ATT
#' efficient influence function. This is the correctness certificate for the method (and
#' is unit-tested).
#'
#' @param cate A CATE contract list (see Details) or the output of [as_cate()].
#' @param design Identification design. `"unconfoundedness"` uses the AIPW transport score;
#'   `"did"` uses the DR-DiD transport score (conditional parallel trends, Sant'Anna-Zhao
#'   (2020)), which is AIPW applied to the outcome change \eqn{\Delta Y}. Both are
#'   collapse-certified against the ordinary AIPW/ATT efficient influence function at the
#'   no-shift case, and the DiD point estimate is cross-checked against `DRDID::drdid()`
#'   (see tests). Ignored if `cate` carries a `design` attribute from [as_cate()] (the
#'   attribute wins, with a warning on conflict).
#' @param target Form A: integer/logical index into the source rows selecting the target
#'   subpopulation. Mutually exclusive with `weights`.
#' @param weights Form B: length-n density-ratio weights \eqn{w(X_i)}. Mutually exclusive
#'   with `target`.
#' @param n_target Optional. Size \eqn{n^*} of the genuinely external target covariate
#'   sample used to construct `weights` (Form B only). When supplied, adds the two-sample
#'   variance correction described above; ignored (with a warning) for Form A, where the
#'   target is a fixed subsample of the source. Default `NULL` (weights treated as fixed).
#' @param trunc Truncation cap for weak overlap: `Inf` (default, no truncation), a numeric
#'   \eqn{C \ge 1}, or `"auto"` to select \eqn{C} from `trunc_grid` via the bias/SE budget
#'   `trunc_gamma`. See Details.
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
#'   \item{se}{Standard error (includes the two-sample addendum when `n_target` is given).}
#'   \item{ci}{Confidence interval (length-2 numeric).}
#'   \item{level}{Confidence level.}
#'   \item{w}{Length-n transport weights actually used (post-truncation if applicable).}
#'   \item{design}{The design used.}
#'   \item{form}{`"target_index"` or `"density_ratio"`.}
#'   \item{n, n_eff}{Sample size and effective sample size \eqn{(\sum w)^2 / \sum w^2}.}
#'   \item{trunc}{The truncation cap actually used (`Inf` if none).}
#'   \item{trunc_diag}{List with `delta_trunc`, `q_exceed`, `var_q_tau`, `bias_bound`,
#'     `se_bias_aware` (\eqn{z\cdot\mathrm{se} + \mathrm{bias\_bound}} half-width ingredient).}
#'   \item{two_sample}{`NULL`, or a list with `n_target`, `rho_hat`, `var_q_tau`,
#'     `addendum`, `se_source_only` when `n_target` was supplied.}
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

  n <- length(cate$tau)

  # Resolve transport weights and the target-sampling correction.
  wr <- resolve_transport_weights(cate, target = target, weights = weights, n = n)
  w_full <- wr$w
  r <- wr$r

  # Neyman-orthogonal correction (per design), reweighted by w.
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
    w_full = w_full, tau = cate$tau, correction = correction, r = r, n = n, level = level,
    trunc = trunc, trunc_gamma = trunc_gamma, trunc_grid = trunc_grid
  )
  core <- trunc_info$core

  # Two-sample variance addendum (only meaningful for Form B / an external target sample).
  ts <- .apply_two_sample_variance(
    core = core, tau = cate$tau, n = n, n_target = n_target, form = wr$form, level = level
  )

  new_cate_integration(
    estimate = core$psi_hat,
    phi = core$phi,
    se = ts$se,
    ci = ts$ci,
    var = ts$var,
    level = level,
    w = core$w_used,
    design = design,
    form = wr$form,
    n = n,
    n_eff = core$n_eff,
    trunc = trunc_info$trunc_used,
    trunc_diag = trunc_info$diag,
    two_sample = ts$diag
  )
}


#' Core transport-EIF computation for a fixed weight vector
#'
#' Given a resolved (possibly truncated) weight vector, assembles the doubly-robust
#' one-step estimate and transport EIF, checks finiteness, warns on poor overlap, and
#' computes the raw (pre-two-sample-addendum) variance. Factored out of
#' [integrate_cate()] so the truncation grid search in [.resolve_truncation()] can call it
#' repeatedly without duplicating the estimation logic.
#'
#' @param w Length-n weight vector to use (either `w_full` or a truncated/renormalized
#'   version of it).
#' @param tau Length-n conditional ATT predictions.
#' @param correction Length-n Neyman-orthogonal correction (`score_aipw()`/`score_drdid()`).
#' @param r Length-n target-sampling correction (zero in the supported fixed-target modes).
#' @param n Source sample size.
#' @param level Confidence level.
#' @return List with `psi_hat`, `phi`, `n_eff`, `var`, `se`, `ci`, `w_used`.
#' @keywords internal
.cate_core <- function(w, tau, correction, r, n, level) {
  # Doubly-robust one-step estimate: plug-in mean(w*tau) PLUS the mean orthogonal
  # correction. This is the estimand the transport EIF is the influence function OF, so
  # the point estimate and its EIF correspond to the same functional (and the sample mean
  # of phi below is then exactly zero when E_hat[w] = 1). Using the bare plug-in
  # mean(w*tau) would pair a plug-in estimate with a DR variance -- inconsistent, and
  # biased whenever the nuisances are estimated (mean(w*correction) != 0).
  psi_hat <- mean(w * tau) + mean(w * correction) + mean(r)

  # Transport EIF (theory note eq. 2). r == 0 in the supported (fixed-target) modes.
  phi <- w * (tau - psi_hat) + w * correction + r

  # Guard non-finite EIF (reachable via validate = FALSE, or e near 0/1 slipping through):
  # compute_variance() warns on NA but not NaN/Inf, which would silently corrupt the SE.
  if (any(!is.finite(phi))) {
    stop(stringr::str_glue(
      "Transport EIF contains {sum(!is.finite(phi))} non-finite value(s). ",
      "Check propensity overlap (e near 0/1) and that tau/mu/Y are finite."
    ), call. = FALSE)
  }

  # Overlap diagnostic: effective sample size collapses under heavy covariate shift.
  # Warn when the effective sample is below this fraction of n (poor overlap / large w).
  overlap_frac <- 0.1
  n_eff <- if (sum(w^2) > 0) (sum(w))^2 / sum(w^2) else 0
  if (n_eff < overlap_frac * n) {
    warning(stringr::str_glue(
      "Heavy covariate shift: effective sample size {round(n_eff, 1)} is < 10% of n = {n}. ",
      "Transport inference may be unstable (poor overlap / large density ratio)."
    ), call. = FALSE)
  }

  inf <- compute_variance(phi, estimate = psi_hat, level = level, center = TRUE)

  list(psi_hat = psi_hat, phi = phi, n_eff = n_eff, var = inf$var, se = inf$se,
       ci = inf$ci, w_used = w)
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
#' being budgeted.
#'
#' @inheritParams integrate_cate
#' @param w_full Length-n untruncated weight vector.
#' @param tau Length-n conditional ATT predictions.
#' @param correction Length-n Neyman-orthogonal correction.
#' @param r Length-n target-sampling correction.
#' @param n Source sample size.
#' @param level Confidence level.
#' @return List with `core` (output of `.cate_core()` at the chosen cap), `trunc_used`,
#'   `diag` (list with `delta_trunc`, `q_exceed`, `var_q_tau`, `bias_bound`,
#'   `se_bias_aware`).
#' @keywords internal
.resolve_truncation <- function(w_full, tau, correction, r, n, level,
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
    core <- .cate_core(tw$w, tau, correction, r, n, level)
    list(
      core = core,
      diag = list(
        delta_trunc = tw$delta_c, q_exceed = bb$q_exceed, var_q_tau = bb$var_q_tau,
        bias_bound = bb$bias_bound, se_bias_aware = core$se + bb$bias_bound
      )
    )
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
  res <- eval_at(trunc)
  list(core = res$core, trunc_used = trunc, diag = res$diag)
}


#' Add the two-sample variance correction when the target is an external sample
#'
#' Implements the additive variance correction of the two-sample transport proposition:
#' \eqn{V = V_{\mathrm{src}} + \rho\,\mathrm{Var}_Q(\tau)}, with \eqn{\widehat\rho = n/n^*}
#' and \eqn{\mathrm{Var}_Q(\tau)} the weighted variance of `tau` (via `.weighted_var_q()`)
#' under the (possibly truncated) final weights. Only applies to Form B (`weights`); a
#' no-op with a warning for Form A, where the target is a fixed subsample of the source
#' and there is no second sample.
#'
#' @param core Output of `.cate_core()` at the final (possibly truncated) weights.
#' @param tau Length-n conditional ATT predictions.
#' @param n Source sample size.
#' @param n_target Size of the external target sample, or `NULL`.
#' @param form `"target_index"` or `"density_ratio"` (from [resolve_transport_weights()]).
#' @param level Confidence level.
#' @return List with `se`, `ci`, `var`, `diag` (`NULL` unless the addendum applies).
#' @keywords internal
.apply_two_sample_variance <- function(core, tau, n, n_target, form, level) {
  if (is.null(n_target)) {
    return(list(se = core$se, ci = core$ci, var = core$var, diag = NULL))
  }
  if (identical(form, "target_index")) {
    warning(paste0(
      "`n_target` is ignored for Form A (`target`): the target is a fixed subsample of ",
      "this source sample, not an independent second sample, so there is no target- ",
      "sampling variance to add. Use Form B (`weights`) with an externally-estimated ",
      "density ratio to invoke the two-sample correction."
    ), call. = FALSE)
    return(list(se = core$se, ci = core$ci, var = core$var, diag = NULL))
  }
  validate_scalar(n_target, name = "n_target")
  if (n_target <= 0) {
    stop("`n_target` must be a positive number (the size of the external target sample).",
         call. = FALSE)
  }

  rho_hat <- n / n_target
  var_q_tau <- .weighted_var_q(core$w_used, tau)
  addendum <- rho_hat * var_q_tau / n
  var_new <- core$var + addendum
  se_new <- sqrt(var_new)

  alpha <- 1 - level
  z <- stats::qnorm(1 - alpha / 2)
  ci_new <- c(core$psi_hat - z * se_new, core$psi_hat + z * se_new)

  list(
    se = se_new, ci = ci_new, var = var_new,
    diag = list(n_target = n_target, rho_hat = rho_hat, var_q_tau = var_q_tau,
                addendum = addendum, se_source_only = core$se)
  )
}


#' Resolve transport weights and the target-sampling correction
#'
#' Maps the Form A (`target` index) / Form B (`weights`) inputs to a common length-n
#' weight vector `w` and the target-sampling correction `r` (identically zero in the
#' supported fixed-target modes; see [integrate_cate()]). The point estimate is assembled
#' by [integrate_cate()] as a doubly-robust one-step, so it is not computed here.
#'
#' @param cate Validated CATE contract list.
#' @param target Form A index (integer/logical into source rows) or NULL.
#' @param weights Form B length-n density-ratio vector or NULL.
#' @param n Source sample size.
#' @return List with `w`, `r`, `form`.
#' @keywords internal
resolve_transport_weights <- function(cate, target, weights, n) {
  # E_src[w] should be 1 up to sampling noise; a 5% gap is a loose misnormalization screen
  # (sampling noise, unlike validate_group_weights' exact 1e-6 sum check).
  weight_mean_tol <- 0.05

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
    if (all(weights == 0)) {
      stop("`weights` are all zero; the target subpopulation is empty.", call. = FALSE)
    }
    if (abs(mean(weights) - 1) > weight_mean_tol) {
      warning(stringr::str_glue(
        "mean(weights) = {round(mean(weights), 4)} is far from 1; the density ratio may ",
        "be misnormalized (E_src[w] should be 1)."
      ), call. = FALSE)
    }
    return(list(w = weights, r = numeric(n), form = "density_ratio"))
  }

  # Form A: target is an index/logical into the source rows.
  idx <- resolve_target_index(target, n)
  n_star <- length(idx)
  if (n_star == 0) {
    stop("`target` selects zero source rows.", call. = FALSE)
  }
  if (n_star == 1) {
    warning("`target` selects a single source row; the FATT reduces to one unit's CATE ",
            "and inference is unreliable.", call. = FALSE)
  }
  w <- numeric(n)
  w[idx] <- n / n_star  # empirical density ratio; == 1 when target is the full source
  list(
    w = w,
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
#' @param w Length-n transport weights (post-truncation if applicable).
#' @param design Design string.
#' @param form `"target_index"` or `"density_ratio"`.
#' @param n Source sample size.
#' @param n_eff Effective sample size.
#' @param trunc Truncation cap actually used (`Inf` if none).
#' @param trunc_diag List of truncation diagnostics (see [integrate_cate()]).
#' @param two_sample List of two-sample correction diagnostics, or `NULL`.
#' @return Object of class `cate_integration`.
#' @keywords internal
new_cate_integration <- function(estimate, phi, se, ci, var, level, w, design, form, n,
                                 n_eff, trunc, trunc_diag, two_sample) {
  structure(
    list(
      estimate = estimate,
      phi = phi,
      se = se,
      ci = ci,
      level = level,
      var = var,
      w = w,
      design = design,
      form = form,
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
  cat(stringr::str_glue("Form:      {x$form}\n"))
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
  if (!is.null(x$two_sample)) {
    cat(stringr::str_glue(
      "2-sample:  n* = {x$two_sample$n_target}, ",
      "rho = {format(x$two_sample$rho_hat, digits = 3)}, ",
      "addendum to Var = {format(x$two_sample$addendum, digits = 3)}\n"
    ))
  }
  invisible(x)
}

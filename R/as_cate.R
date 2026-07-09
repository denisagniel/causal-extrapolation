#' Build a CATE contract from a fitted learner
#'
#' Thin adapters that extract the predictions [integrate_cate()] needs from a fitted CATE
#' learner. These are **pure extractors**: they call the fitted object's own prediction
#' machinery and reshape the results into the generic contract list; they never refit a
#' model. Learner packages are optional (Suggests) — an adapter errors informatively if
#' the backing package is not installed.
#'
#' @param fit A fitted learner object (e.g. from `grf::causal_forest()`,
#'   `DoubleML::DoubleMLIRM`, `rlearner`, or a `drdid` fit), or any object with a
#'   registered `as_cate` method.
#' @param ... Additional arguments passed to methods (e.g. explicit `mu0`/`mu1` overrides
#'   for the grf method).
#'
#' @return A named list (the CATE contract; see [integrate_cate()]) carrying a `design`
#'   attribute (`"unconfoundedness"` or `"did"`).
#'
#' @seealso [integrate_cate()] for the contract definition and downstream use.
#' @export
as_cate <- function(fit, ...) {
  UseMethod("as_cate")
}


#' @rdname as_cate
#' @param mu0,mu1 Optional explicit outcome-regression predictions (length n). If omitted,
#'   the grf method recovers them from the forest's local-centering identity
#'   \eqn{\hat\mu_1 = \hat Y + (1 - \hat W)\hat\tau}, \eqn{\hat\mu_0 = \hat Y - \hat W\hat\tau},
#'   which assumes grf's internal centering.
#' @export
as_cate.causal_forest <- function(fit, mu0 = NULL, mu1 = NULL, ...) {
  if (!requireNamespace("grf", quietly = TRUE)) {
    stop("Package 'grf' is required for as_cate.causal_forest(). Install it, or pass a ",
         "generic CATE contract list to integrate_cate() directly.", call. = FALSE)
  }

  tau <- as.numeric(stats::predict(fit)$predictions)
  Y <- as.numeric(fit$Y.orig)
  A <- as.numeric(fit$W.orig)
  X <- as.data.frame(fit$X.orig)

  if (is.null(fit$W.hat) || is.null(fit$Y.hat)) {
    stop("grf fit lacks W.hat/Y.hat, needed to recover mu0/mu1 via local centering. ",
         "Pass mu0/mu1 explicitly, or refit the forest with grf's default centering.",
         call. = FALSE)
  }
  e <- as.numeric(fit$W.hat)          # grf's out-of-bag propensity estimate
  Y_hat <- as.numeric(fit$Y.hat)      # grf's out-of-bag outcome estimate

  if (is.null(mu1) || is.null(mu0)) {
    # Local-centering identity: mu1 = Y.hat + (1 - W.hat) tau, mu0 = Y.hat - W.hat tau.
    # Assumes grf's default local centering; pass mu0/mu1 to override. inform() once so
    # this does not spam per-replication loops.
    rlang::inform(
      "as_cate.causal_forest(): recovering mu0/mu1 from grf local-centering identity.",
      .frequency = "once", .frequency_id = "as_cate_grf_centering"
    )
    mu1 <- Y_hat + (1 - e) * tau
    mu0 <- Y_hat - e * tau
  } else {
    mu1 <- as.numeric(mu1)
    mu0 <- as.numeric(mu0)
  }

  cate <- list(tau = tau, mu1 = mu1, mu0 = mu0, e = e, A = A, Y = Y, X = X)
  attr(cate, "design") <- "unconfoundedness"
  cate
}


#' @rdname as_cate
#' @export
as_cate.DoubleML <- function(fit, ...) {
  if (!requireNamespace("DoubleML", quietly = TRUE)) {
    stop("Package 'DoubleML' is required for as_cate.DoubleML(). Install it, or pass a ",
         "generic CATE contract list to integrate_cate() directly.", call. = FALSE)
  }

  # DoubleML stores nuisance predictions in fit$predictions, keyed by learner name.
  preds <- fit$predictions
  if (is.null(preds)) {
    stop("This DoubleML fit does not store nuisance predictions. Re-fit with ",
         "`store_predictions = TRUE`, or pass a generic CATE contract list.", call. = FALSE)
  }
  get_pred <- function(key) {
    if (is.null(preds[[key]])) {
      stop(stringr::str_glue(
        "DoubleML fit is missing prediction '{key}'. Available: ",
        "{stringr::str_c(names(preds), collapse = ', ')}. Pass a generic contract instead."
      ), call. = FALSE)
    }
    as.numeric(preds[[key]])
  }

  e <- get_pred("ml_m")    # propensity
  mu0 <- get_pred("ml_g0") # E[Y | X, A = 0]
  mu1 <- get_pred("ml_g1") # E[Y | X, A = 1]
  tau <- mu1 - mu0

  data_model <- fit$data
  if (length(data_model$d_cols) > 1) {
    stop(stringr::str_glue(
      "DoubleML fit has {length(data_model$d_cols)} treatment variables; as_cate() ",
      "supports a single binary treatment. Subset to one treatment, or build the ",
      "contract manually."
    ), call. = FALSE)
  }
  Y <- as.numeric(data_model$data[[data_model$y_col]])
  A <- as.numeric(data_model$data[[data_model$d_cols[1]]])
  X <- as.data.frame(data_model$data[, data_model$x_cols, drop = FALSE])

  cate <- list(tau = tau, mu1 = mu1, mu0 = mu0, e = e, A = A, Y = Y, X = X)
  attr(cate, "design") <- "unconfoundedness"
  cate
}


#' @rdname as_cate
#' @param X Covariate frame at which to predict the CATE (required for the rlearner
#'   method, which needs prediction points). Also stored in the contract.
#' @param A,Y Treatment (0/1) and outcome vectors (length n) accompanying `X`.
#' @export
as_cate.rlearner <- function(fit, X, A, Y, ...) {
  if (!requireNamespace("rlearner", quietly = TRUE)) {
    stop("Package 'rlearner' is required for as_cate.rlearner(). Install it, or pass a ",
         "generic CATE contract list to integrate_cate() directly.", call. = FALSE)
  }
  if (missing(X) || missing(A) || missing(Y)) {
    stop("as_cate.rlearner() needs `X`, `A`, and `Y` (the data the nuisances were fit on).",
         call. = FALSE)
  }
  if (!all(purrr::map_lgl(as.data.frame(X), is.numeric))) {
    stop("as_cate.rlearner() requires an all-numeric X (no factor columns) for prediction.",
         call. = FALSE)
  }

  X_mat <- as.matrix(X)
  tau <- as.numeric(stats::predict(fit, X_mat))

  # rlearner nuisance fits expose p_hat (propensity) and m_hat (marginal outcome mean).
  p_hat <- fit$p_hat
  m_hat <- fit$m_hat
  if (is.null(p_hat) || is.null(m_hat)) {
    stop("This rlearner fit does not expose p_hat / m_hat nuisances; pass a generic ",
         "CATE contract list to integrate_cate() directly.", call. = FALSE)
  }
  e <- as.numeric(p_hat)
  m_hat <- as.numeric(m_hat)
  # m_hat = E[Y|X] = mu0 + p * tau  =>  mu0 = m_hat - p*tau, mu1 = m_hat + (1-p)*tau.
  mu0 <- m_hat - e * tau
  mu1 <- m_hat + (1 - e) * tau

  cate <- list(tau = tau, mu1 = mu1, mu0 = mu0, e = e,
               A = as.numeric(A), Y = as.numeric(Y), X = as.data.frame(X))
  attr(cate, "design") <- "unconfoundedness"
  cate
}


#' @rdname as_cate
#' @export
as_cate.drdid <- function(fit, ...) {
  if (!requireNamespace("drdid", quietly = TRUE)) {
    stop("Package 'drdid' is required for as_cate.drdid(). Install it, or pass a ",
         "generic CATE contract list (design = 'did') to integrate_cate() directly.",
         call. = FALSE)
  }
  # drdid fits vary in stored internals; require the DiD contract to be assembled by the
  # user rather than guessing at unstable slot names.
  stop("as_cate.drdid() is not yet implemented: drdid fit internals are not stable across ",
       "versions. Assemble the DiD contract (tau, dY, m0_dY, e, A, X) manually and call ",
       "integrate_cate(design = 'did').", call. = FALSE)
}


#' @rdname as_cate
#' @export
as_cate.default <- function(fit, ...) {
  cls <- stringr::str_c(class(fit), collapse = ", ")
  stop(stringr::str_glue(
    "as_cate() has no method for class '{cls}'. Supported: causal_forest (grf), ",
    "DoubleML, rlearner. For other learners, build the generic CATE contract list ",
    "directly - see ?integrate_cate for the required slots."
  ), call. = FALSE)
}

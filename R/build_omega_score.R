#' Influence-function scores for estimated cohort weights
#'
#' Builds the per-unit influence functions of the estimated cohort weights
#' \eqn{\widehat\omega_g = \widehat{\P}(G_i = g \mid A_{ip} = 1)}, which are required to
#' propagate the \emph{estimation} uncertainty in \eqn{\widehat\omega} through the Path 1
#' aggregation. For the proportion estimator
#' \deqn{\widehat\omega_g = \frac{\sum_i 1\{G_i = g, A_{ip} = 1\}}{\sum_i 1\{A_{ip} = 1\}},}
#' the influence function is (paper, Appendix \code{app:eif1}; regularity condition RC3)
#' \deqn{\phi_{\omega_g,i} =
#'   \frac{1\{G_i = g, A_{ip} = 1\} - \omega_g \cdot 1\{A_{ip} = 1\}}{\P(A_{ip} = 1)},}
#' with \eqn{\P(A_{ip} = 1)} and \eqn{\omega_g} replaced by their sample analogues.
#'
#' @section Exactly-zero certificate:
#' Because the cohorts \eqn{\mathcal{G}} partition the treated set \eqn{\{A_{ip} = 1\}} and
#' \eqn{\sum_g \widehat\omega_g = 1} identically, the returned matrix satisfies
#' \eqn{\sum_{g} \phi_{\omega_g,i} = 0} for \emph{every} unit \eqn{i}, exactly (up to
#' floating-point rounding). Consequently the aggregation contribution
#' \eqn{\sum_g \theta_{g\cdot} \phi_{\omega_g,i}} vanishes identically whenever the
#' within-group effects \eqn{\theta_{g\cdot}} are all equal: under exact
#' time-and-cohort homogeneity, estimating \eqn{\omega} costs nothing. This identity is
#' unit-tested and is the sharpest available check that the term is implemented correctly.
#'
#' Units with \eqn{A_{ip} = 0} receive a row of exact zeros: they carry no information
#' about the composition of the treated population.
#'
#' @param G Cohort (group) label for each unit, length \eqn{n}. Units with
#'   \code{treated_by_p == 0} may carry any value, including \code{NA}; their scores are
#'   zero regardless. Cohort labels of \emph{treated} units must all appear in
#'   \code{groups}, since otherwise the cohorts do not partition the treated set and the
#'   zero certificate above is false.
#' @param treated_by_p A 0/1 (or logical) indicator of \eqn{A_{ip} = 1}, i.e. whether the
#'   unit is treated by the last observed period \eqn{p}. Length \eqn{n}.
#' @param groups Vector of cohort labels defining the columns of the result, in the order
#'   used by the corresponding \code{omega} vector (typically \code{gt_object$groups}).
#'
#' @return An \eqn{n \times |\texttt{groups}|} numeric matrix of per-unit scores, with
#'   \code{colnames} set to \code{as.character(groups)} and an attribute \code{"omega"}
#'   holding the proportion estimates \eqn{\widehat\omega_g} whose influence functions
#'   these are. Pass the matrix to [path1_aggregate()] (or [aggregate_groups()]) as
#'   \code{omega_scores} together with \code{omega_estimated = TRUE}.
#'
#' @seealso [path1_aggregate()], [aggregate_groups()]
#'
#' @examples
#' set.seed(20260925)
#' n <- 200
#' treated_by_p <- rbinom(n, 1, 0.75)
#' G <- rep(NA_real_, n)
#' G[treated_by_p == 1] <- sample(0:1, sum(treated_by_p), replace = TRUE)
#'
#' S <- build_omega_score(G, treated_by_p, groups = 0:1)
#' dim(S)
#' attr(S, "omega")          # the omega-hat these scores belong to
#' max(abs(rowSums(S)))      # exactly-zero certificate
#'
#' @export
build_omega_score <- function(G, treated_by_p, groups) {
  if (length(groups) < 1) {
    stop("build_omega_score() requires at least one group in `groups`.", call. = FALSE)
  }
  if (anyDuplicated(groups) > 0) {
    stop("`groups` must not contain duplicated labels.", call. = FALSE)
  }

  n <- length(G)
  if (length(treated_by_p) != n) {
    stop(stringr::str_glue(
      "`G` and `treated_by_p` must have the same length: got {n} and ",
      "{length(treated_by_p)}."
    ), call. = FALSE)
  }
  if (n == 0) {
    stop("`G` and `treated_by_p` must be non-empty.", call. = FALSE)
  }

  # Coerce the indicator, refusing anything that is not cleanly 0/1: a silently truncated
  # indicator would corrupt both omega_hat and P(A_ip = 1).
  if (is.logical(treated_by_p)) {
    treated_by_p <- as.integer(treated_by_p)
  }
  if (!is.numeric(treated_by_p) || anyNA(treated_by_p) ||
        !all(treated_by_p %in% c(0, 1))) {
    stop("`treated_by_p` must be a 0/1 (or logical) indicator with no NA values.",
         call. = FALSE)
  }

  ind_treated <- as.numeric(treated_by_p == 1)
  n_treated <- sum(ind_treated)
  if (n_treated == 0) {
    stop("`treated_by_p` marks no treated units; omega is not identified.", call. = FALSE)
  }

  # Cohorts must partition the treated set (otherwise sum_g omega_hat_g < 1 and the
  # exactly-zero certificate documented above silently fails).
  treated_idx <- which(ind_treated == 1)
  G_treated <- G[treated_idx]
  unseen <- setdiff(unique(G_treated), groups)
  if (length(unseen) > 0) {
    unseen <- as.character(unseen)
    unseen_str <- stringr::str_c(unseen[seq_len(min(5, length(unseen)))], collapse = ", ")
    stop(stringr::str_glue(
      "`groups` must partition the treated set: treated units carry cohort label(s) ",
      "not present in `groups` ({unseen_str}). Include every treated cohort (and use ",
      "NA, not a stray label, for untreated units)."
    ), call. = FALSE)
  }

  p_treated <- n_treated / n

  # Membership indicators 1{G_i = g, A_ip = 1}, n x q. NA cohort labels are FALSE here,
  # which is what we want for untreated units.
  membership <- vapply(
    groups,
    function(g) as.numeric(ind_treated == 1 & !is.na(G) & G == g),
    numeric(n)
  )
  if (!is.matrix(membership)) {
    membership <- matrix(membership, nrow = n, ncol = length(groups))
  }

  omega_hat <- colSums(membership) / n_treated

  # phi_{omega_g,i} = [1{G_i = g, A_ip = 1} - omega_g 1{A_ip = 1}] / P(A_ip = 1).
  scores <- (membership - outer(ind_treated, omega_hat)) / p_treated

  colnames(scores) <- as.character(groups)
  names(omega_hat) <- as.character(groups)
  attr(scores, "omega") <- omega_hat
  scores
}

#' Estimated-weight contribution to an aggregated influence function
#'
#' Computes the per-unit term \eqn{\sum_g \texttt{value}_g \, \phi_{\omega_g,i}} that the
#' functional delta method adds to the Path 1 influence function when the cohort weights
#' \eqn{\omega} are estimated rather than known (paper, Appendix \code{app:eif1}, step 3).
#'
#' @param omega_scores An \eqn{n \times q} matrix of per-unit weight scores, as returned by
#'   [build_omega_score()].
#' @param values_g Numeric vector of length \eqn{q} holding the per-group values
#'   \eqn{\theta_{g\cdot}} that multiply each weight in the aggregation functional.
#' @return A numeric vector of length \eqn{n}.
#' @keywords internal
.omega_contribution <- function(omega_scores, values_g) {
  omega_scores <- .validate_omega_scores(omega_scores, n_groups = length(values_g))
  as.numeric(omega_scores %*% values_g)
}

#' Validate an omega score matrix against an expected shape
#'
#' @param omega_scores Candidate score matrix.
#' @param n_groups Expected number of columns (groups).
#' @param n Expected number of rows (units); `NULL` to skip the check.
#' @param name Variable name for error messages.
#' @return The validated matrix (coerced to a base matrix), invisibly usable.
#' @keywords internal
.validate_omega_scores <- function(omega_scores, n_groups, n = NULL,
                                   name = "omega_scores") {
  if (!is.matrix(omega_scores) || !is.numeric(omega_scores)) {
    stop(stringr::str_glue(
      "{name} must be a numeric matrix (see build_omega_score()), got ",
      "{class(omega_scores)[1]}."
    ), call. = FALSE)
  }
  if (anyNA(omega_scores)) {
    stop(stringr::str_glue("{name} must not contain NA values."), call. = FALSE)
  }
  if (ncol(omega_scores) != n_groups) {
    stop(stringr::str_glue(
      "{name} has {ncol(omega_scores)} columns but there are {n_groups} groups. ",
      "These must match, in the same order as `omega`."
    ), call. = FALSE)
  }
  if (!is.null(n) && nrow(omega_scores) != n) {
    stop(stringr::str_glue(
      "{name} has {nrow(omega_scores)} rows but n = {n}. These must match."
    ), call. = FALSE)
  }
  omega_scores
}

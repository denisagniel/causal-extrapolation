#' Assemble per-cell EIFs into a jointly-aligned score matrix
#'
#' Reassembles the per-\eqn{(g,t)}-cell efficient influence functions stored on a
#' `gt_object` into a single \eqn{n \times J} score matrix whose rows are in guaranteed
#' correspondence across cells. Every first-stage backend in this package stores the EIFs
#' as an independent *list* of length-\eqn{n} columns (`gt_object$phi`) — for example
#' [as_gt_object.MP()] splits `did::att_gt()`'s `x$inffunc` matrix column by column — which
#' discards the joint structure needed to estimate cross-cell covariances. This function
#' restores it.
#'
#' @section Why row keys are mandatory:
#' Nothing in the `gt_object` contract guarantees that the \eqn{j}th EIF vector orders its
#' units the same way as the \eqn{j'}th. If they disagree, the assembled matrix has rows out
#' of correspondence, and *every* off-diagonal covariance computed from it is attenuated
#' toward zero — silently, with no error and no warning, because the result is still a
#' perfectly well-formed matrix of the right dimensions. This function therefore refuses to
#' guess: with `require_ids = TRUE` (the default) it errors unless a reliable row key is
#' available. Supplying `ids` as a *list* of per-cell id vectors additionally lets it
#' *repair* a known misordering.
#'
#' @param gt_object A `gt_object` carrying non-`NULL` `phi` (see [new_gt_object()]).
#' @param ids Row keys. Either
#'   \describe{
#'     \item{`NULL` (default)}{use `gt_object$ids`; if that is also `NULL`, behavior is
#'       governed by `require_ids`.}
#'     \item{an atomic vector of length \eqn{n}}{a single key shared by every cell. This
#'       documents the row identities but *cannot* detect a per-cell permutation.}
#'     \item{a list of \eqn{J} atomic vectors of length \eqn{n}}{per-cell keys. Each cell's
#'       EIF is reordered onto the first cell's key, so a permuted cell is repaired. All
#'       cells must carry the same *set* of ids.}
#'   }
#' @param cluster Optional cluster identifier, length \eqn{n}. If supplied, scores are
#'   summed within cluster, yielding an \eqn{n_{\text{eff}} \times J} matrix with one row
#'   per cluster (the standard cluster-robust influence-function aggregation). May be
#'   unnamed (interpreted in row-key order) or named by unit id (looked up by name, so
#'   ordering does not matter).
#' @param require_ids Logical, default `TRUE`. When no row key is available, error rather
#'   than assume that all cells share a common row order. Set `FALSE` only when you know
#'   the backend guarantees a consistent order; a warning is then emitted and
#'   `seq_len(n)` is used as the key.
#'
#' @return A numeric matrix with `rownames` giving the row key (unit id, or cluster id when
#'   `cluster` is supplied) and `colnames` giving the cell label `"g<g>_t<t>"`, in the row
#'   order of `gt_object$data`. Attributes:
#'   \describe{
#'     \item{`cells`}{tibble of `g`, `t`, `k` and the column index `j`.}
#'     \item{`clustered`}{logical, whether rows are clusters.}
#'     \item{`n_eff`}{number of rows (independent units or clusters).}
#'     \item{`J`}{number of cells (columns).}
#'   }
#'   Scaling follows the package convention: entries are \eqn{O_p(1)} per-unit scores with
#'   \eqn{\mathrm{Var}(\widehat\theta_j) = \mathrm{Var}(\Phi_{\cdot j}) / n_{\text{eff}}},
#'   matching [compute_variance()]. No rescaling is applied.
#'
#' @seealso [estimate_score_cov()] for the covariance of the returned matrix.
#'
#' @examples
#' \dontrun{
#' library(did)
#' data(mpdta)
#' att <- att_gt(yname = "lemp", gname = "first.treat", idname = "countyreal",
#'               tname = "year", data = mpdta)
#' gt <- as_gt_object(att)
#'
#' # did does not return unit ids on the object, so key the rows explicitly.
#' Phi <- build_score_matrix(gt, ids = sort(unique(mpdta$countyreal)))
#' dim(Phi)
#' estimate_score_cov(Phi)$shrink_used
#' }
#'
#' @export
build_score_matrix <- function(gt_object, ids = NULL, cluster = NULL,
                               require_ids = TRUE) {
  validate_gt_object(gt_object, name = "gt_object")

  phi_list <- gt_object$phi
  if (is.null(phi_list) || length(phi_list) == 0) {
    stop(
      "build_score_matrix() requires per-cell EIFs, but gt_object$phi is NULL or empty. ",
      "Rebuild the gt_object with extract_eif = TRUE (or supply phi to new_gt_object()).",
      call. = FALSE
    )
  }

  df <- gt_object$data
  J <- length(phi_list)
  validate_lengths_match(phi_list, seq_len(nrow(df)),
                         name_x = "gt_object$phi", name_y = "gt_object$data rows")

  # All cells must span the same number of units, or there is no matrix to build.
  n <- length(phi_list[[1]])
  phi_lengths <- vapply(phi_list, length, integer(1))
  if (!all(phi_lengths == n)) {
    bad <- which(phi_lengths != n)
    stop(stringr::str_glue(
      "All EIF vectors must have the same length; cell(s) ",
      "{stringr::str_c(bad[seq_len(min(5, length(bad)))], collapse = ', ')} differ from n = {n}."
    ), call. = FALSE)
  }

  # ---- Resolve row keys --------------------------------------------------------------
  if (is.null(ids)) {
    ids <- gt_object$ids
  }
  if (is.null(ids)) {
    if (require_ids) {
      stop(
        "build_score_matrix() has no reliable row key: `ids` is NULL and ",
        "gt_object$ids is NULL. Rows of different cells' EIF vectors are then only in ",
        "correspondence if the first-stage backend happens to order units identically ",
        "across cells, which is not guaranteed and would silently attenuate every ",
        "cross-cell covariance. Supply `ids` (a length-n unit identifier, or a list of ",
        "one per cell), or pass require_ids = FALSE to accept the row-order assumption ",
        "explicitly.",
        call. = FALSE
      )
    }
    warning(
      "build_score_matrix(require_ids = FALSE): no unit ids available, so the existing ",
      "row order is assumed to be consistent across all cells. Cross-cell covariances ",
      "are only valid if that assumption holds.",
      call. = FALSE
    )
    ids <- seq_len(n)
  }

  if (is.list(ids)) {
    if (length(ids) != J) {
      stop(stringr::str_glue(
        "`ids` supplied as a list must have one per cell: got {length(ids)} id vectors ",
        "for {J} cells."
      ), call. = FALSE)
    }
    for (j in seq_len(J)) {
      .check_id_vector(ids[[j]], n = n, name = stringr::str_glue("ids[[{j}]]"))
    }
    reference_ids <- ids[[1]]
  } else {
    .check_id_vector(ids, n = n, name = "ids")
    reference_ids <- ids
  }

  Phi <- .align_scores(phi_list, ids, reference_ids)

  cells <- tibble::tibble(
    g = df$g,
    t = df$t,
    k = if ("k" %in% names(df)) df$k else df$t - df$g,
    j = seq_len(J)
  )
  dimnames(Phi) <- list(as.character(reference_ids),
                        paste0("g", cells$g, "_t", cells$t))

  clustered <- !is.null(cluster)
  if (clustered) {
    cluster_map <- .resolve_cluster_map(cluster, reference_ids)
    Phi <- .cluster_scores(Phi, cluster_map)
  }

  attr(Phi, "cells") <- cells
  attr(Phi, "clustered") <- clustered
  attr(Phi, "n_eff") <- nrow(Phi)
  attr(Phi, "J") <- ncol(Phi)
  Phi
}

#' Align a list of per-cell EIF vectors onto a common row key
#'
#' @param phi_list List of \eqn{J} length-\eqn{n} numeric EIF vectors.
#' @param ids Either a length-\eqn{n} atomic row key shared by all cells, or a list of
#'   \eqn{J} length-\eqn{n} per-cell row keys.
#' @param reference_ids The target row order (length \eqn{n}).
#' @return An \eqn{n \times J} numeric matrix whose row \eqn{i} corresponds to
#'   `reference_ids[i]` in every column.
#' @keywords internal
.align_scores <- function(phi_list, ids, reference_ids) {
  J <- length(phi_list)
  n <- length(reference_ids)

  # Common key: all cells already share reference_ids, so the only work is to put the
  # shared key into the requested order.
  if (!is.list(ids)) {
    ord <- match(as.character(reference_ids), as.character(ids))
    if (anyNA(ord)) {
      stop("`ids` does not cover every reference id.", call. = FALSE)
    }
    out <- fast_cbind_list(lapply(phi_list, function(p) p[ord]))
    return(matrix(as.numeric(out), nrow = n, ncol = J))
  }

  ref_chr <- as.character(reference_ids)
  out <- matrix(NA_real_, nrow = n, ncol = J)
  for (j in seq_len(J)) {
    ord <- match(ref_chr, as.character(ids[[j]]))
    if (anyNA(ord)) {
      stop(stringr::str_glue(
        "Every cell must carry the same set of unit ids: cell {j}'s ids do not cover ",
        "{sum(is.na(ord))} of the {n} reference ids. Cross-cell alignment is impossible, ",
        "so no score matrix is produced."
      ), call. = FALSE)
    }
    out[, j] <- phi_list[[j]][ord]
  }
  out
}

#' Sum score-matrix rows within cluster
#'
#' The cluster-robust influence function for a sum-of-units estimator is the within-cluster
#' sum of the unit-level scores; the resulting rows are independent across clusters.
#'
#' @param Phi An \eqn{n \times J} score matrix with unit-level rows.
#' @param cluster_map Character (or factor) vector of length \eqn{n}, in the row order of
#'   `Phi`, giving each row's cluster.
#' @return An \eqn{n_{\text{clusters}} \times J} matrix with `rownames` the cluster labels
#'   (in order of first appearance sorted by label) and the same `colnames` as `Phi`.
#' @keywords internal
.cluster_scores <- function(Phi, cluster_map) {
  f <- factor(cluster_map, levels = sort(unique(as.character(cluster_map))))
  # rowsum() is the vectorized group-sum: O(nJ), no per-cluster subsetting.
  out <- rowsum(Phi, group = f, reorder = TRUE)
  colnames(out) <- colnames(Phi)
  out
}

#' Validate a candidate row-key vector
#'
#' @param x Candidate id vector.
#' @param n Required length.
#' @param name Variable name for error messages.
#' @keywords internal
.check_id_vector <- function(x, n, name = "ids") {
  if (is.null(x) || !is.atomic(x)) {
    stop(stringr::str_glue("{name} must be an atomic vector of unit identifiers."),
         call. = FALSE)
  }
  if (length(x) != n) {
    stop(stringr::str_glue(
      "{name} has length {length(x)} but the EIF vectors have length n = {n}. ",
      "These must match."
    ), call. = FALSE)
  }
  if (anyNA(x)) {
    stop(stringr::str_glue("{name} must not contain NA values."), call. = FALSE)
  }
  if (anyDuplicated(x) > 0) {
    n_dup <- sum(duplicated(x))
    stop(stringr::str_glue(
      "{name} contains {n_dup} duplicated identifier(s); row keys must be unique or ",
      "alignment is ambiguous."
    ), call. = FALSE)
  }
  invisible(TRUE)
}

#' Resolve a cluster argument into a vector in reference-id order
#'
#' @param cluster User-supplied cluster vector, optionally named by unit id.
#' @param reference_ids The row key of the unit-level score matrix.
#' @return Character vector of length `length(reference_ids)`, in that order.
#' @keywords internal
.resolve_cluster_map <- function(cluster, reference_ids) {
  n <- length(reference_ids)
  if (!is.atomic(cluster)) {
    stop("`cluster` must be an atomic vector of cluster identifiers.", call. = FALSE)
  }
  if (length(cluster) != n) {
    stop(stringr::str_glue(
      "`cluster` has length {length(cluster)} but there are {n} units. These must match."
    ), call. = FALSE)
  }
  if (anyNA(cluster)) {
    stop("`cluster` must not contain NA values.", call. = FALSE)
  }

  if (!is.null(names(cluster))) {
    # Named => look up by unit id, so the caller's ordering is irrelevant.
    ord <- match(as.character(reference_ids), names(cluster))
    if (anyNA(ord)) {
      stop(stringr::str_glue(
        "`cluster` is named, so it is matched by unit id, but {sum(is.na(ord))} of the ",
        "{n} unit ids are missing from names(cluster)."
      ), call. = FALSE)
    }
    cluster <- cluster[ord]
  }

  as.character(cluster)
}

#' Safe Matrix Inversion with Singularity Check
#'
#' Computes the inverse of X'X (or the weighted Gram matrix X'WX) with
#' condition number checking to prevent crashes from singular or
#' near-singular matrices.
#'
#' @param X Numeric matrix (n x p).
#' @param tol Tolerance for condition number (default 1e-8). If kappa(X'X) > 1/tol,
#'   an error is raised.
#' @param weights Optional numeric vector of length `nrow(X)`, strictly
#'   positive. If supplied, inverts the weighted Gram matrix `t(X) %*% (weights * X)`
#'   instead of the unweighted `X'X`.
#'
#' @return The inverse of X'X (or X'WX, if `weights` is supplied).
#' @keywords internal
safe_matrix_inverse <- function(X, tol = 1e-8, weights = NULL) {
  if (!is.matrix(X) && !is.numeric(X)) {
    stop("X must be a numeric matrix")
  }

  if (is.vector(X)) {
    X <- matrix(X, ncol = 1)
  }

  n <- nrow(X)
  p <- ncol(X)

  # Check minimum observations
  if (n < p) {
    stop(stringr::str_glue(
      "Insufficient observations for matrix inversion: need at least {p} observations, got {n}"
    ))
  }

  if (is.null(weights)) {
    XtX <- crossprod(X)
  } else {
    if (length(weights) != n) {
      stop(stringr::str_glue(
        "weights must have length {n} (nrow(X)), got {length(weights)}."
      ))
    }
    if (any(weights <= 0)) {
      stop("weights must all be strictly positive.")
    }
    XtX <- crossprod(X, weights * X)
  }

  # Check condition number for near-singularity
  cond_num <- kappa(XtX, exact = TRUE)

  if (cond_num > 1/tol || is.infinite(cond_num)) {
    stop(stringr::str_glue(
      "Matrix X'X is near-singular or singular (condition number = {format(cond_num, scientific = TRUE, digits = 2)}).
Possible causes:
  - Repeated time values (creates exact linear dependence)
  - Insufficient distinct observations (need at least p = {p} distinct times)
  - Poorly scaled time values (try centering/scaling)
  - Numerical instability"
    ))
  }

  solve(XtX)
}

#' Fast matrix construction from list of vectors
#'
#' Efficiently constructs a matrix from a list of column vectors. For small lists
#' (< 100 columns), uses do.call(cbind). For large lists, uses direct matrix
#' construction which is O(n) instead of O(n^2).
#'
#' @param vec_list List of numeric vectors (all same length)
#' @param threshold Number of columns above which to use optimized method (default 100)
#' @return Matrix with length(vec_list) columns
#' @keywords internal
fast_cbind_list <- function(vec_list, threshold = 100) {
  if (length(vec_list) == 0) {
    stop("vec_list is empty", call. = FALSE)
  }

  # For small lists, do.call is fine
  if (length(vec_list) < threshold) {
    mat <- do.call(cbind, vec_list)
    if (is.null(dim(mat))) {
      # Single vector case
      n <- length(vec_list[[1]])
      mat <- matrix(mat, nrow = n, ncol = length(vec_list))
    }
    return(mat)
  }

  # For large lists, use direct matrix construction (much faster)
  n_rows <- length(vec_list[[1]])
  n_cols <- length(vec_list)

  # Pre-allocate matrix
  mat <- matrix(0, nrow = n_rows, ncol = n_cols)

  # Fill columns (vectorized, O(n) not O(n^2))
  for (j in seq_along(vec_list)) {
    mat[, j] <- vec_list[[j]]
  }

  mat
}


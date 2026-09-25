#' Aggregate values and EIFs across groups with weights
#'
#' @param values_g Numeric vector of per-group values.
#' @param eif_list List of numeric EIF vectors per group (same length as values_g).
#' @param omega Numeric vector of group weights (same length as values_g).
#' @param omega_scores Optional \eqn{n \times q} matrix of per-unit influence functions for
#'   \emph{estimated} group weights, as returned by [build_omega_score()]. Supply this only
#'   when `omega` was estimated from the same sample: the returned EIF then additionally
#'   carries the functional-delta-method term
#'   \eqn{\sum_g \texttt{values\_g}_g \, \phi_{\omega_g,i}} (paper, Appendix
#'   \code{app:eif1}). Default `NULL` treats `omega` as fixed and known, which reproduces
#'   this function's historical behavior exactly.
#'
#' @return A list with aggregated value `value` and EIF vector `phi`.
#'
#' @details
#' The point estimate never depends on `omega_scores`; only the propagated influence
#' function does. Omitting `omega_scores` when `omega` was in fact estimated understates
#' the variance (except in the degenerate case where all `values_g` are equal, in which
#' case the extra term is identically zero -- see [build_omega_score()]).
#'
#' @examples
#' # Per-group estimates
#' values_g <- c(0.5, 0.3, 0.7)  # Three groups
#'
#' # Per-group EIF vectors (n=50 observations)
#' set.seed(20260304)
#' eif_list <- list(
#'   rnorm(50, sd = 0.1),
#'   rnorm(50, sd = 0.1),
#'   rnorm(50, sd = 0.1)
#' )
#'
#' # Group weights (proportional to group size)
#' omega <- c(0.5, 0.3, 0.2)
#'
#' # Aggregate
#' result <- aggregate_groups(values_g, eif_list, omega)
#'
#' print(result$value)  # Weighted average: 0.5*0.5 + 0.3*0.3 + 0.2*0.7
#' print(length(result$phi))  # EIF vector of length 50
#'
#' @seealso [build_omega_score()] for constructing `omega_scores`.
#'
#' @export
aggregate_groups <- function(values_g, eif_list, omega, omega_scores = NULL) {
  # Input validation
  validate_numeric_vector(values_g, name = "values_g", allow_na = FALSE)
  validate_numeric_vector(omega, name = "omega", allow_na = FALSE)

  if (!is.list(eif_list)) {
    stop("eif_list must be a list of numeric vectors", call. = FALSE)
  }

  # Check length consistency
  n_groups <- length(values_g)
  validate_lengths_match(eif_list, values_g, name_x = "eif_list", name_y = "values_g")
  validate_lengths_match(omega, values_g, name_x = "omega", name_y = "values_g")

  # Validate group weights properties
  validate_group_weights(omega, n_groups = n_groups, name = "omega", warn_sum = TRUE)

  # Perform aggregation
  value <- sum(omega * values_g)
  phi <- purrr::map2(omega, eif_list, \(w, phi_vec) w * phi_vec) |>
    purrr::reduce(`+`)

  # Estimated-omega term from the functional delta method. Strictly additive: when
  # omega_scores is NULL (the default) phi is returned untouched, so existing callers that
  # treat omega as known are unaffected.
  if (!is.null(omega_scores)) {
    omega_scores <- .validate_omega_scores(
      omega_scores, n_groups = n_groups, n = length(phi)
    )
    phi <- phi + .omega_contribution(omega_scores, values_g)
  }

  list(value = value, phi = phi)
}






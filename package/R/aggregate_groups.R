#' Aggregate values and EIFs across groups with weights
#'
#' @param values_g Numeric vector of per-group values.
#' @param eif_list List of numeric EIF vectors per group (same length as values_g).
#' @param omega Numeric vector of group weights (same length as values_g).
#'
#' @return A list with aggregated value `value` and EIF vector `phi`.
#' @export
aggregate_groups <- function(values_g, eif_list, omega) {
  stopifnot(length(values_g) == length(eif_list), length(values_g) == length(omega))
  value <- sum(omega * values_g)
  phi <- Reduce(`+`, Map(function(w, phi) w * phi, omega, eif_list))
  list(value = value, phi = phi)
}






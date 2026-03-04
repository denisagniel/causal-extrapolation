#' Aggregate values and EIFs across groups with weights
#'
#' @param values_g Numeric vector of per-group values.
#' @param eif_list List of numeric EIF vectors per group (same length as values_g).
#' @param omega Numeric vector of group weights (same length as values_g).
#'
#' @return A list with aggregated value `value` and EIF vector `phi`.
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
#' @export
aggregate_groups <- function(values_g, eif_list, omega) {
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
  phi <- Reduce(`+`, Map(function(w, phi_vec) w * phi_vec, omega, eif_list))

  list(value = value, phi = phi)
}






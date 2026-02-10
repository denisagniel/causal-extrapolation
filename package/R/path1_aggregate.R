#' Path 1: aggregate group-time ATTs assuming constant effect within group
#'
#' For each group, computes the (weighted) average of tau_hat over observed (g,t)
#' cells, then aggregates across groups with omega. Propagates EIFs by
#' within-group averaging then aggregation.
#'
#' @param gt_object An object of class gt_object (data, phi, groups, n).
#' @param omega Numeric vector of group weights (length = number of groups).
#' @return A list with tau_future (scalar), phi_future (length-n vector), and
#'   tau_g (per-group means) and phi_g (list of EIF vectors per group) for optional use.
#' @export
path1_aggregate <- function(gt_object, omega) {
  stopifnot(inherits(gt_object, "gt_object"))
  df <- gt_object$data
  phi_rows <- gt_object$phi
  groups <- gt_object$groups
  n <- gt_object$n
  if (length(phi_rows) != nrow(df)) stop("Length of phi must match rows of data.")
  if (length(omega) != length(groups)) stop("omega must have length equal to number of groups.")

  tau_g <- numeric(length(groups))
  phi_g <- vector("list", length(groups))
  names(phi_g) <- groups

  for (i in seq_along(groups)) {
    g <- groups[i]
    idx <- which(df$g == g)
    tau_g[i] <- mean(df$tau_hat[idx])
    # EIF for group mean = mean of EIFs over cells in that group (equal weight)
    phi_mat <- do.call(cbind, phi_rows[idx])
    if (is.null(dim(phi_mat))) phi_mat <- matrix(phi_mat, nrow = n, ncol = 1)
    phi_g[[i]] <- as.numeric(rowMeans(phi_mat))
  }

  agg <- aggregate_groups(tau_g, phi_g, omega)
  list(
    tau_future = agg$value,
    phi_future = agg$phi,
    tau_g = tau_g,
    phi_g = phi_g
  )
}

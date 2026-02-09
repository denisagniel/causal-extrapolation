#' Estimate group-time ATTs and EIFs using did
#'
#' Wrapper around the `did` package to estimate group-time average treatment effects
#' (ATTs) and obtain efficient influence functions (EIFs) per group-time cell.
#' If EIFs are not directly exposed by `did`, an approximation path can be used
#' (e.g., bootstrap linearization), which is documented and opt-in.
#'
#' @param data A data.frame or tibble with at least columns for outcome `Y`,
#'   group `G`, time `t`, treatment timing (as required by `did`), and optional covariates `X`.
#' @param y,g,t Bare column names (or strings) for outcome, group, and time.
#' @param x Optional character vector of covariate names to carry along.
#' @param cluster Optional bare name or string for cluster id for variance.
#' @param ... Additional arguments passed to did estimation functions.
#'
#' @return An object of class `gt_object` (list) with elements:
#' - data: tibble with columns g, t, tau_hat
#' - phi: list-column of EIF vectors aligned with rows in `data`
#' - times: unique observed times used
#' - groups: unique groups
#' - n: sample size
#' - ids: optional unit identifiers if available
#'
#' @export
estimate_group_time_ATT <- function(data, y, g, t, x = NULL, cluster = NULL, ...) {
  # NSE handling
  y <- rlang::ensym(y); g <- rlang::ensym(g); t <- rlang::ensym(t)
  if (!is.null(cluster)) cluster <- rlang::ensym(cluster)

  df <- tibble::as_tibble(data)
  n <- nrow(df)

  # Minimal example using did::att_gt; users must supply columns needed by did
  # including treatment timing (e.g., G == cohort) and D indicator as per did docs.
  if (!requireNamespace("did", quietly = TRUE)) {
    stop("Package 'did' is required. Please install it.")
  }

  # We attempt a flexible call; users can pass ... to att_gt
  att <- did::att_gt(yname = rlang::as_name(y),
                     tname = rlang::as_name(t),
                     idname = NULL,
                     gname = rlang::as_name(g),
                     data = df,
                     ...)
  # Extract estimates and EIFs using helper
  ext <- did_extract_gt(att)
  est_df <- ext$data
  phi_list <- ext$phi

  res <- list(
    data = est_df,
    phi = phi_list,
    times = sort(unique(est_df$t)),
    groups = sort(unique(est_df$g)),
    event_times = sort(unique(est_df$k)),
    n = n,
    ids = NULL,
    meta = list(call = match.call(), did_object = att)
  )
  class(res) <- c("gt_object", "extrapolateATT")
  res
}


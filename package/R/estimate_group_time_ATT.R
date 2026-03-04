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
  # Input validation
  if (!is.data.frame(data)) {
    stop("data must be a data.frame or tibble", call. = FALSE)
  }

  df <- tibble::as_tibble(data)
  n <- nrow(df)

  if (n == 0) {
    stop("data is empty (0 rows)", call. = FALSE)
  }

  # NSE handling
  y <- rlang::ensym(y)
  g <- rlang::ensym(g)
  t <- rlang::ensym(t)
  if (!is.null(cluster)) cluster <- rlang::ensym(cluster)

  # Validate required columns exist
  y_name <- rlang::as_name(y)
  g_name <- rlang::as_name(g)
  t_name <- rlang::as_name(t)

  required_cols <- c(y_name, g_name, t_name)
  missing_cols <- setdiff(required_cols, names(df))

  if (length(missing_cols) > 0) {
    stop(stringr::str_glue(
      "data is missing required columns: {stringr::str_c(missing_cols, collapse = ', ')}. ",
      "Available columns: {stringr::str_c(names(df), collapse = ', ')}"
    ), call. = FALSE)
  }

  # Minimal example using did::att_gt; users must supply columns needed by did
  # including treatment timing (e.g., G == cohort) and D indicator as per did docs.
  if (!requireNamespace("did", quietly = TRUE)) {
    stop("Package 'did' is required. Please install it.", call. = FALSE)
  }

  # Handle cluster argument
  if (!is.null(cluster)) {
    warning(
      "cluster argument is not yet implemented; using default 'did' variance estimation",
      call. = FALSE
    )
  }

  # We attempt a flexible call; users can pass ... to att_gt
  att <- did::att_gt(yname = y_name,
                     tname = t_name,
                     idname = NULL,
                     gname = g_name,
                     data = df,
                     ...)

  # Convert to gt_object using new converter
  gt_obj <- as_gt_object(att, extract_eif = TRUE)

  # Add call to metadata
  gt_obj$meta$call <- match.call()

  gt_obj
}


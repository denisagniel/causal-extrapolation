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
#' @param id Bare column name (or string) for the unit identifier. Strongly
#'   recommended: passing `id` lets `did::att_gt()` align each unit's EIF
#'   contribution consistently across group-time cells, which downstream
#'   aggregation (Path 1) and extrapolation (Path 2) EIF propagation assumes
#'   (see Appendix, Regularity Condition RC2). If omitted, `did::att_gt()` is
#'   called with `idname = NULL`; the returned EIF vectors are then only
#'   correct if `did` orders rows identically across every group-time cell
#'   given the same panel, which is not guaranteed by `did`'s own contract and
#'   should not be relied on. A warning is issued in this case.
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
estimate_group_time_ATT <- function(data, y, g, t, id = NULL, x = NULL, cluster = NULL, ...) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("data must be a data.frame or tibble", call. = FALSE)
  }

  df <- tibble::as_tibble(data)
  n <- nrow(df)

  if (n == 0) {
    stop("data is empty (0 rows)", call. = FALSE)
  }

  # NSE handling. enquo() (not is.null() + ensym()) so a bare-symbol argument
  # is never evaluated as an expression in the caller's frame -- is.null(x)
  # on an unevaluated promise forces evaluation and errors with "object not
  # found" for exactly the common case of passing a column name unquoted.
  y <- rlang::ensym(y)
  g <- rlang::ensym(g)
  t <- rlang::ensym(t)
  cluster_quo <- rlang::enquo(cluster)
  id_quo <- rlang::enquo(id)
  cluster <- if (rlang::quo_is_null(cluster_quo)) NULL else rlang::as_name(rlang::ensym(cluster))
  id_name <- if (rlang::quo_is_null(id_quo)) NULL else rlang::as_name(rlang::ensym(id))

  # Validate required columns exist
  y_name <- rlang::as_name(y)
  g_name <- rlang::as_name(g)
  t_name <- rlang::as_name(t)

  required_cols <- c(y_name, g_name, t_name, id_name)
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

  if (is.null(id_name)) {
    warning(
      "estimate_group_time_ATT() called without `id`: did::att_gt() will be run with ",
      "idname = NULL. The returned per-unit EIF vectors are then only correctly aligned ",
      "across group-time cells if did's internal row ordering happens to be consistent, ",
      "which is not part of did's documented contract. Pass `id` (a unit identifier column) ",
      "to guarantee correct alignment for the EIF propagation used by extrapolate_ATT() ",
      "and path1_aggregate().",
      call. = FALSE
    )
  }

  # We attempt a flexible call; users can pass ... to att_gt
  att <- did::att_gt(yname = y_name,
                     tname = t_name,
                     idname = id_name,
                     gname = g_name,
                     data = df,
                     ...)

  # Convert to gt_object using new converter
  gt_obj <- as_gt_object(att, extract_eif = TRUE)

  # Add call to metadata
  gt_obj$meta$call <- match.call()

  gt_obj
}


##' Extract τ_gt and EIFs from a did object
##'
##' Pull per-group-time ATT estimates and EIF vectors from an object returned by
##' `did::att_gt()`. Uses the `inffunc` matrix (n × J) whose columns align with
##' the rows of `summary(att_gt)$gt`.
##'
##' @param did_obj An object from `did::att_gt()`.
##' @param ids Optional vector of unit ids to align EIFs.
##'
##' @return A list with `data` tibble (g, t, k, tau_hat) and `phi` list of EIF vectors.
##' @export
did_extract_gt <- function(did_obj, ids = NULL) {
  if (!inherits(did_obj, "att_gt")) stop("did_obj must be an att_gt object.")
  s <- did::summary.att_gt(did_obj)
  gt_df <- tibble::as_tibble(s$gt)
  if (!"group" %in% names(gt_df) || !"t" %in% names(gt_df) || !"att" %in% names(gt_df)) {
    stop("Unexpected structure of summary(att_gt)$gt")
  }
  data <- tibble::tibble(
    g = gt_df$group,
    t = gt_df$t,
    k = gt_df$t - gt_df$group,
    tau_hat = gt_df$att
  )
  # inffunc: n x J, where J = nrow(data); column j corresponds to row j of gt
  if (is.null(did_obj$inffunc)) stop("att_gt$inffunc not found; update 'did' or check call options.")
  IF <- did_obj$inffunc
  if (ncol(IF) != nrow(data)) stop("Mismatch between inffunc columns and group-time rows.")
  phi <- lapply(seq_len(nrow(data)), function(j) as.numeric(IF[, j]))
  list(data = data, phi = phi)
}


# Tests for build_score_matrix(): reassembling the per-(g,t)-cell EIFs that every backend
# shreds into an independent list of columns (see R/from_did.R: `phi <- purrr::map(...)`)
# back into a single, jointly-aligned n x J score matrix.
#
# The safety property under test is NOT "does it produce a matrix" -- that is trivial --
# but "does it refuse to produce a matrix whose rows are not in correspondence". Silently
# mismatched rows would attenuate any downstream cross-cell covariance toward zero with no
# warning, which is exactly the failure mode that makes a joint-covariance estimate
# worthless.

# gt_object with known, cell-distinguishable EIF columns and explicit unit ids.
make_gt_for_scores <- function(n = 40, n_groups = 2, n_times = 3, seed = 20260925) {
  set.seed(seed)
  groups <- 0:(n_groups - 1)
  data <- expand.grid(t = seq_len(n_times), g = groups)[, c("g", "t")]
  data$tau_hat <- stats::rnorm(nrow(data), mean = 0.5, sd = 0.1)
  data$k <- data$t - data$g

  # Column j = j * base + noise_j, so columns are correlated AND distinguishable: a
  # permuted column shows up as a changed covariance, not just a changed ordering.
  base <- stats::rnorm(n)
  phi <- lapply(seq_len(nrow(data)), function(j) j * base + stats::rnorm(n, sd = 0.3))

  ids <- paste0("u", sprintf("%03d", seq_len(n)))

  gt_obj <- list(
    data = tibble::as_tibble(data),
    phi = phi,
    times = sort(unique(data$t)),
    groups = groups,
    event_times = sort(unique(data$k)),
    n = n,
    ids = ids,
    meta = list()
  )
  class(gt_obj) <- c("gt_object", "extrapolateATT")
  gt_obj
}


test_that("build_score_matrix() assembles an n x J matrix with cell and id keys", {
  gt <- make_gt_for_scores(n = 40, n_groups = 2, n_times = 3)
  J <- nrow(gt$data)

  Phi <- build_score_matrix(gt)

  expect_true(is.matrix(Phi))
  expect_equal(dim(Phi), c(40L, J))
  expect_equal(rownames(Phi), gt$ids)
  # One column per (g,t) cell, labelled and ordered as in gt_object$data.
  expect_equal(colnames(Phi), paste0("g", gt$data$g, "_t", gt$data$t))
  for (j in seq_len(J)) {
    expect_equal(unname(Phi[, j]), gt$phi[[j]], tolerance = 0)
  }
  expect_false(attr(Phi, "clustered"))
  expect_equal(attr(Phi, "n_eff"), 40L)
  expect_equal(attr(Phi, "J"), J)
})

test_that("build_score_matrix() preserves the joint cross-cell covariance structure", {
  gt <- make_gt_for_scores(n = 400, n_groups = 2, n_times = 3)
  Phi <- build_score_matrix(gt)

  S <- stats::cov(Phi)
  # The construction phi_j = j * base + noise makes off-diagonal covariances large and
  # positive; this is the structure the old list-of-columns representation discarded.
  expect_true(all(S[upper.tri(S)] > 0))
  expect_gt(min(abs(S[upper.tri(S)])), 0.1)
})

test_that("build_score_matrix() hard-errors when require_ids = TRUE and no ids exist", {
  gt <- make_gt_for_scores(n = 40)
  gt$ids <- NULL

  expect_error(
    build_score_matrix(gt, require_ids = TRUE),
    "require_ids"
  )
})

test_that("build_score_matrix() falls back to row order only when require_ids = FALSE, with a warning", {
  gt <- make_gt_for_scores(n = 40)
  gt$ids <- NULL

  expect_warning(
    Phi <- build_score_matrix(gt, require_ids = FALSE),
    "row order"
  )
  expect_equal(dim(Phi), c(40L, nrow(gt$data)))
  expect_equal(rownames(Phi), as.character(seq_len(40)))
})

test_that("MISALIGNMENT REGRESSION: a permuted cell is repaired when per-cell ids are supplied", {
  gt <- make_gt_for_scores(n = 40, n_groups = 2, n_times = 3)
  J <- nrow(gt$data)
  reference <- build_score_matrix(gt)

  # Corrupt cell 2: permute its EIF vector, exactly as a backend that does not key rows
  # would silently do.
  set.seed(1)
  perm <- sample.int(40)
  gt_bad <- gt
  gt_bad$phi[[2]] <- gt$phi[[2]][perm]

  # Sanity: without repair this really is a different matrix.
  expect_false(isTRUE(all.equal(gt_bad$phi[[2]], gt$phi[[2]])))

  # Per-cell ids: cell 2's ids are permuted the same way, so the permutation is
  # recoverable. build_score_matrix() must undo it.
  ids_per_cell <- rep(list(gt$ids), J)
  ids_per_cell[[2]] <- gt$ids[perm]

  repaired <- build_score_matrix(gt_bad, ids = ids_per_cell)

  expect_equal(repaired, reference, tolerance = 0)
  # The sharpest check: the repaired column is the ORIGINAL cell-2 column, not the
  # permuted one.
  expect_equal(unname(repaired[, 2]), gt$phi[[2]], tolerance = 0)
})

test_that("MISALIGNMENT REGRESSION: an unkeyable permuted cell errors rather than silently mismatching", {
  gt <- make_gt_for_scores(n = 40, n_groups = 2, n_times = 3)
  set.seed(1)
  gt$phi[[2]] <- gt$phi[[2]][sample.int(40)]
  gt$ids <- NULL

  # No row key anywhere => build_score_matrix() must refuse, not guess.
  expect_error(build_score_matrix(gt, require_ids = TRUE), "require_ids")
})

test_that("build_score_matrix() rejects per-cell ids whose id sets disagree", {
  gt <- make_gt_for_scores(n = 40, n_groups = 2, n_times = 3)
  J <- nrow(gt$data)

  ids_per_cell <- rep(list(gt$ids), J)
  ids_per_cell[[3]][1] <- "not_a_real_unit"

  expect_error(
    build_score_matrix(gt, ids = ids_per_cell),
    "same set of unit ids"
  )
})

test_that("build_score_matrix() rejects duplicated and wrong-length ids", {
  gt <- make_gt_for_scores(n = 40, n_groups = 2, n_times = 3)

  dup_ids <- gt$ids
  dup_ids[2] <- dup_ids[1]
  expect_error(build_score_matrix(gt, ids = dup_ids), "duplicated")

  expect_error(build_score_matrix(gt, ids = gt$ids[-1]), "length")

  expect_error(
    build_score_matrix(gt, ids = rep(list(gt$ids), 2)),
    "one per cell"
  )
})

test_that("build_score_matrix() requires EIFs on the gt_object", {
  gt <- make_gt_for_scores(n = 40)
  # Keep the field but empty it, mirroring as_gt_object(extract_eif = FALSE).
  gt["phi"] <- list(NULL)

  expect_error(build_score_matrix(gt), "EIF")
})

test_that("build_score_matrix() rejects ragged EIF vectors", {
  gt <- make_gt_for_scores(n = 40, n_groups = 2, n_times = 3)
  gt$phi[[4]] <- gt$phi[[4]][-1]

  expect_error(build_score_matrix(gt), "length")
})

test_that("build_score_matrix() clusters by summing scores within cluster", {
  gt <- make_gt_for_scores(n = 40, n_groups = 2, n_times = 3)
  J <- nrow(gt$data)
  unclustered <- build_score_matrix(gt)

  # 10 clusters of 4 units each.
  cluster <- rep(paste0("c", 1:10), each = 4)

  Phi_c <- build_score_matrix(gt, cluster = cluster)

  expect_equal(dim(Phi_c), c(10L, J))
  expect_true(attr(Phi_c, "clustered"))
  expect_equal(attr(Phi_c, "n_eff"), 10L)
  # Cluster rows are ordered by sorted cluster label.
  expect_equal(rownames(Phi_c), sort(paste0("c", 1:10)))

  # Each clustered row is the SUM of its members' unclustered rows.
  for (cl in 1:10) {
    members <- which(cluster == paste0("c", cl))
    expect_equal(
      unname(Phi_c[paste0("c", cl), ]),
      unname(colSums(unclustered[members, , drop = FALSE])),
      tolerance = 1e-12
    )
  }
})

test_that("build_score_matrix() accepts a named cluster vector keyed by unit id", {
  gt <- make_gt_for_scores(n = 40, n_groups = 2, n_times = 3)

  cluster <- stats::setNames(rep(paste0("c", 1:10), each = 4), gt$ids)
  # Shuffle the named vector: lookup must be by name, not by position.
  cluster_shuffled <- cluster[sample.int(40)]

  a <- build_score_matrix(gt, cluster = cluster)
  b <- build_score_matrix(gt, cluster = cluster_shuffled)

  expect_equal(a, b, tolerance = 0)
})

test_that("build_score_matrix() validates cluster length and completeness", {
  gt <- make_gt_for_scores(n = 40, n_groups = 2, n_times = 3)

  expect_error(build_score_matrix(gt, cluster = rep("c1", 39)), "length")
  expect_error(
    build_score_matrix(gt, cluster = c(NA, rep("c1", 39))),
    "NA"
  )

  bad_names <- stats::setNames(rep("c1", 40), c("nope", gt$ids[-1]))
  expect_error(build_score_matrix(gt, cluster = bad_names), "unit ids")
})

test_that("build_score_matrix() works end-to-end on real did::att_gt() output", {
  skip_if_not_installed("did")

  data("mpdta", package = "did", envir = environment())
  att <- did::att_gt(
    yname = "lemp", gname = "first.treat", idname = "countyreal",
    tname = "year", data = mpdta, bstrap = FALSE
  )
  gt <- as_gt_object(att, extract_eif = TRUE)

  # did does not hand back the unit ids on the object, so keying must be explicit.
  expect_error(build_score_matrix(gt, require_ids = TRUE), "require_ids")

  ids <- sort(unique(mpdta$countyreal))
  Phi <- build_score_matrix(gt, ids = ids)

  expect_equal(dim(Phi), c(length(ids), nrow(gt$data)))
  expect_equal(unname(as.matrix(Phi)), unname(as.matrix(att$inffunc)),
               tolerance = 0, ignore_attr = TRUE)

  # The reassembled matrix reproduces each cell's variance, i.e. the diagonal of the joint
  # covariance agrees with the per-cell marginal the package already used.
  diag_var <- diag(stats::cov(Phi))
  marginal_var <- vapply(gt$phi, stats::var, numeric(1))
  expect_equal(unname(diag_var), unname(marginal_var), tolerance = 1e-10)
})

# Calibration of did::att_gt()'s influence-function scaling against this package's
# variance convention.
#
# compute_variance() implements Var(theta_hat) = var(phi) / n, i.e. it expects each
# gt_object$phi[[j]] to be an O_p(1) per-unit score with Var(phi_j) = n * Var(theta_hat_j).
# did::att_gt() returns x$inffunc, and this package's `from_did.R` backend copies its
# columns into gt_object$phi verbatim (no rescaling). If did's own convention differed --
# e.g. if inffunc were already divided by n -- every variance this package reports from a
# did first stage would be wrong by a factor of n.
#
# Measured finding (did 2.3.0, mpdta, n = 500 counties): the conventions AGREE. did's
# analytic standard error is exactly
#   se_j = sqrt( mean((phi_ij - mean_i phi_ij)^2) / n ),
# i.e. the 1/n-denominator sample variance of the raw inffunc column, divided by n. The
# only discrepancy versus compute_variance() is that compute_variance() uses stats::var()
# (1/(n-1) denominator), giving a fixed ratio of sqrt(n/(n-1)) = 1.001002 at n = 500.
# There is NO factor-of-n rescaling to apply. These tests pin that down so a did upgrade
# that changes the convention is a test failure rather than a silent numerical error.

test_that("did::att_gt() inffunc obeys var(phi_j)/n == se_j^2 (package variance convention)", {
  skip_if_not_installed("did")

  data("mpdta", package = "did", envir = environment())

  # bstrap = FALSE so att$se is did's ANALYTIC influence-function SE rather than a
  # multiplier-bootstrap SE. Against the default (bstrap = TRUE) the same ratios hold to
  # within bootstrap noise (measured range 0.91-1.03), which is enough to rule out a
  # factor-of-n error but not tight enough to pin the exact denominator convention.
  att <- did::att_gt(
    yname = "lemp", gname = "first.treat", idname = "countyreal",
    tname = "year", data = mpdta, bstrap = FALSE
  )

  # did returns inffunc as a (possibly sparse / Matrix-backed) n x J object.
  Phi <- as.matrix(att$inffunc)

  n <- nrow(Phi)
  J <- ncol(Phi)
  expect_equal(J, length(att$att))
  # n is the number of *units*, not the number of panel rows.
  expect_equal(n, dplyr::n_distinct(mpdta$countyreal))

  expect_false(is.null(att$se))
  se_did <- unname(att$se)

  # (a) did's convention, reproduced exactly: 1/n-denominator variance of the raw column.
  se_n_denom <- vapply(
    seq_len(J),
    function(j) sqrt(mean((Phi[, j] - mean(Phi[, j]))^2) / n),
    numeric(1)
  )
  expect_equal(se_n_denom, se_did, tolerance = 1e-10)

  # (b) This package's convention (stats::var, 1/(n-1) denominator), which therefore
  # differs from did's by exactly sqrt(n / (n - 1)) -- a fixed, negligible, and
  # deliberately-unpatched O(1/n) discrepancy, NOT a scaling error.
  se_from_phi <- vapply(seq_len(J), function(j) sqrt(stats::var(Phi[, j]) / n), numeric(1))
  expect_equal(se_from_phi / se_did, rep(sqrt(n / (n - 1)), J), tolerance = 1e-10)

  # Guard the thing that actually matters: no factor-of-n (or 1/n) rescaling.
  expect_equal(se_from_phi, se_did, tolerance = 1e-2)
})

test_that("did::att_gt() inffunc columns are mean-zero per-unit scores", {
  skip_if_not_installed("did")

  data("mpdta", package = "did", envir = environment())

  att <- did::att_gt(
    yname = "lemp", gname = "first.treat", idname = "countyreal",
    tname = "year", data = mpdta, bstrap = FALSE
  )
  Phi <- as.matrix(att$inffunc)

  # An influence function is mean-zero in sample up to the first-stage solve tolerance.
  expect_true(all(abs(colMeans(Phi)) < 1e-8))
})

test_that("as_gt_object() preserves did's inffunc scaling into gt_object$phi", {
  skip_if_not_installed("did")

  data("mpdta", package = "did", envir = environment())

  att <- did::att_gt(
    yname = "lemp", gname = "first.treat", idname = "countyreal",
    tname = "year", data = mpdta, bstrap = FALSE
  )
  gt <- as_gt_object(att, extract_eif = TRUE)

  Phi <- as.matrix(att$inffunc)

  # No rescaling anywhere in the backend: phi[[j]] is column j verbatim.
  for (j in seq_len(ncol(Phi))) {
    expect_equal(gt$phi[[j]], as.numeric(Phi[, j]), tolerance = 0)
  }

  # compute_variance() on a single cell reproduces that cell's se up to the
  # sqrt(n/(n-1)) denominator difference documented above.
  cv <- compute_variance(gt$phi[[1]], estimate = gt$data$tau_hat[1])
  n <- nrow(Phi)
  expect_equal(cv$se, unname(att$se[1]) * sqrt(n / (n - 1)), tolerance = 1e-10)
})

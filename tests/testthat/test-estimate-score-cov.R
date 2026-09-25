# Tests for estimate_score_cov(): the (optionally shrunk) J x J covariance of the joint
# per-(g,t)-cell score matrix produced by build_score_matrix().
#
# The contract is deliberately explicit about conditioning: with J cells and only n_eff
# independent units, an unshrunk sample covariance is singular once J >= n_eff and badly
# conditioned well before that. estimate_score_cov() must never hand back a confidently
# wrong inverse -- it either shrinks, or reports ok = FALSE.

# Score matrix with a known, non-trivial correlation structure (AR(1)-like).
make_score_matrix <- function(n = 400, J = 5, rho = 0.7, seed = 20260925) {
  set.seed(seed)
  Sigma <- rho^abs(outer(seq_len(J), seq_len(J), "-"))
  L <- chol(Sigma)
  Phi <- matrix(stats::rnorm(n * J), nrow = n) %*% L
  colnames(Phi) <- paste0("cell", seq_len(J))
  rownames(Phi) <- paste0("u", seq_len(n))
  Phi
}


test_that("estimate_score_cov() returns the documented contract", {
  Phi <- make_score_matrix(n = 400, J = 5)

  res <- estimate_score_cov(Phi)

  expect_named(
    res,
    c("Sigma", "Sigma_inv", "shrink_used", "alpha", "kappa", "rank", "n_eff", "J", "ok")
  )
  expect_true(is.matrix(res$Sigma))
  expect_equal(dim(res$Sigma), c(5L, 5L))
  expect_equal(res$Sigma, t(res$Sigma), tolerance = 1e-12)
  expect_equal(colnames(res$Sigma), colnames(Phi))
  expect_equal(res$n_eff, 400L)
  expect_equal(res$J, 5L)
  expect_true(res$ok)
  expect_equal(res$rank, 5L)
  expect_true(is.finite(res$kappa))
})

test_that("estimate_score_cov(shrink = 'none') reproduces the sample covariance exactly", {
  Phi <- make_score_matrix(n = 400, J = 5)

  res <- estimate_score_cov(Phi, shrink = "none")

  expect_equal(res$shrink_used, "none")
  expect_equal(res$alpha, 0)
  expect_equal(res$Sigma, stats::cov(Phi), tolerance = 1e-12)
  # And it recovers the AR(1) structure it was generated from.
  expect_equal(res$Sigma[1, 2] / sqrt(res$Sigma[1, 1] * res$Sigma[2, 2]), 0.7,
               tolerance = 0.1)
})

test_that("estimate_score_cov() inverse actually inverts Sigma", {
  Phi <- make_score_matrix(n = 400, J = 5)
  res <- estimate_score_cov(Phi, shrink = "none")

  expect_equal(unname(res$Sigma %*% res$Sigma_inv), diag(5), tolerance = 1e-8)
})

test_that("estimate_score_cov(shrink = 'diagonal') discards all off-diagonal covariance", {
  Phi <- make_score_matrix(n = 400, J = 5)

  res <- estimate_score_cov(Phi, shrink = "diagonal")

  expect_equal(res$shrink_used, "diagonal")
  expect_equal(res$alpha, 1)
  expect_equal(res$Sigma, diag(diag(stats::cov(Phi))), tolerance = 1e-12,
               ignore_attr = TRUE)
  # Diagonal shrinkage is always invertible when every cell has positive variance.
  expect_true(res$ok)
})

test_that("estimate_score_cov(shrink = 'ledoit-wolf') is a strict convex combination", {
  Phi <- make_score_matrix(n = 400, J = 20)

  res <- estimate_score_cov(Phi, shrink = "ledoit-wolf")

  expect_equal(res$shrink_used, "ledoit-wolf")
  expect_gt(res$alpha, 0)
  expect_lt(res$alpha, 1)

  S_hat <- stats::cov(Phi)
  expected <- (1 - res$alpha) * S_hat + res$alpha * diag(diag(S_hat))
  expect_equal(res$Sigma, expected, tolerance = 1e-12)

  # Shrinkage strictly improves conditioning relative to the raw sample covariance.
  expect_lt(res$kappa, kappa(S_hat, exact = TRUE))
})

test_that("estimate_score_cov() honors an explicitly supplied alpha", {
  Phi <- make_score_matrix(n = 400, J = 5)
  S_hat <- stats::cov(Phi)

  res <- estimate_score_cov(Phi, shrink = "ledoit-wolf", alpha = 0.25)

  expect_equal(res$alpha, 0.25)
  expect_equal(res$Sigma, 0.75 * S_hat + 0.25 * diag(diag(S_hat)), tolerance = 1e-12)

  expect_error(estimate_score_cov(Phi, alpha = -0.1), "alpha")
  expect_error(estimate_score_cov(Phi, alpha = 1.5), "alpha")
})

test_that("estimate_score_cov(shrink = 'auto') leaves a well-conditioned problem alone", {
  # n_eff / J = 400 / 5 = 80 >= min_ratio, so no shrinkage is warranted.
  Phi <- make_score_matrix(n = 400, J = 5)

  res <- estimate_score_cov(Phi, shrink = "auto", min_ratio = 10)

  expect_equal(res$shrink_used, "none")
  expect_equal(res$alpha, 0)
  expect_true(res$ok)
})

test_that("estimate_score_cov(shrink = 'auto') warns and shrinks below min_ratio", {
  # n_eff / J = 60 / 20 = 3 < 10.
  Phi <- make_score_matrix(n = 60, J = 20)

  expect_warning(
    res <- estimate_score_cov(Phi, shrink = "auto", min_ratio = 10),
    "min_ratio"
  )
  expect_equal(res$shrink_used, "ledoit-wolf")
  expect_gt(res$alpha, 0)
  expect_true(res$ok)
})

test_that("estimate_score_cov() reports ok = FALSE instead of a bogus inverse when singular", {
  # A duplicated cell column makes the sample covariance exactly rank-deficient: this is
  # the collinear-cell case that an "optimal" combination engine would otherwise invert.
  Phi <- make_score_matrix(n = 200, J = 4)
  Phi <- cbind(Phi, Phi[, 1])
  colnames(Phi)[5] <- "cell1_dup"

  expect_warning(
    res <- estimate_score_cov(Phi, shrink = "none"),
    "singular|invert"
  )
  expect_false(res$ok)
  expect_null(res$Sigma_inv)
  expect_lt(res$rank, 5L)
  # Sigma itself is still returned, so the caller can inspect the degeneracy.
  expect_equal(dim(res$Sigma), c(5L, 5L))
})

test_that("estimate_score_cov() recovers invertibility for the singular case under shrinkage", {
  Phi <- make_score_matrix(n = 200, J = 4)
  Phi <- cbind(Phi, Phi[, 1])

  res <- estimate_score_cov(Phi, shrink = "diagonal")

  expect_true(res$ok)
  expect_false(is.null(res$Sigma_inv))
  expect_equal(unname(res$Sigma %*% res$Sigma_inv), diag(5), tolerance = 1e-8)
})

test_that("estimate_score_cov() handles J = 1", {
  Phi <- make_score_matrix(n = 100, J = 1)

  res <- estimate_score_cov(Phi, shrink = "none")

  expect_equal(res$J, 1L)
  expect_equal(dim(res$Sigma), c(1L, 1L))
  expect_equal(as.numeric(res$Sigma), stats::var(Phi[, 1]), tolerance = 1e-12)
  expect_true(res$ok)
})

test_that("estimate_score_cov() validates its inputs", {
  Phi <- make_score_matrix(n = 50, J = 3)

  expect_error(estimate_score_cov(as.data.frame(Phi)), "matrix")
  expect_error(estimate_score_cov(Phi[1, , drop = FALSE]), "at least 2")
  expect_error(estimate_score_cov(Phi, min_ratio = -1), "min_ratio")

  Phi_na <- Phi
  Phi_na[3, 2] <- NA
  expect_error(estimate_score_cov(Phi_na), "NA")

  Phi_const <- Phi
  Phi_const[, 2] <- 1
  expect_error(estimate_score_cov(Phi_const), "zero variance")
})

test_that("estimate_score_cov() composes with build_score_matrix() on real did output", {
  skip_if_not_installed("did")

  data("mpdta", package = "did", envir = environment())
  att <- did::att_gt(
    yname = "lemp", gname = "first.treat", idname = "countyreal",
    tname = "year", data = mpdta, bstrap = FALSE
  )
  gt <- as_gt_object(att, extract_eif = TRUE)
  ids <- sort(unique(mpdta$countyreal))

  Phi <- build_score_matrix(gt, ids = ids)
  res <- estimate_score_cov(Phi, shrink = "auto")

  expect_true(res$ok)
  expect_equal(res$n_eff, length(ids))
  expect_equal(res$J, nrow(gt$data))

  # The diagonal is the per-cell variance the package already reports, so Sigma[j,j]/n is
  # cell j's variance -- the joint object is a strict generalization, not a new convention.
  n <- res$n_eff
  se_from_Sigma <- sqrt(diag(res$Sigma) / n)
  se_from_phi <- vapply(gt$phi, function(p) sqrt(stats::var(p) / n), numeric(1))
  expect_equal(unname(se_from_Sigma), unname(se_from_phi), tolerance = 1e-10)

  # And the off-diagonals are genuinely non-zero: cells share units, so the independence
  # implicitly assumed by the old list-of-columns representation is false.
  off <- res$Sigma[upper.tri(res$Sigma)]
  expect_gt(max(abs(off)), 0)
})

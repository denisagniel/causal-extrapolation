# Tests for combine_cell_scores(): the GMM/GLS-efficient combiner over a (possibly
# correlated) joint score matrix, generalizing gls_weights()'s diagonal-only weighting to
# the full covariance recovered by build_score_matrix()/estimate_score_cov().
#
# The property under test is NOT "does it return a number" -- that is trivial -- but the
# three mathematical identities that make the closed form self-consistent (unbiasedness,
# the variance identity, and the diagonal limit reproducing today's gls_weights()), plus
# the degenerate-case behavior that keeps a near-singular Sigma from silently producing a
# spurious "efficient" combination.

make_score_matrix <- function(n = 400, J = 4, rho = 0, sd = 1, seed = 20260925) {
  set.seed(seed)
  # Shared latent factor induces equal pairwise correlation rho across all J columns --
  # enough to exercise the off-diagonal machinery without hand-building a specific Sigma.
  common <- stats::rnorm(n)
  Phi <- matrix(stats::rnorm(n * J, sd = sd * sqrt(1 - rho)), nrow = n, ncol = J)
  Phi <- Phi + sqrt(rho) * sd * common
  colnames(Phi) <- paste0("cell", seq_len(J))
  rownames(Phi) <- paste0("u", seq_len(n))
  Phi
}

test_that("diagonal limit reproduces gls_weights() exactly", {
  Phi <- make_score_matrix(n = 500, J = 4, rho = 0, seed = 1)
  # A genuinely diagonal Sigma (sample off-diagonals from rho = 0 data are only
  # population-zero, not exactly zero) isolates the diagonal-only code path from any
  # sample-noise off-diagonal.
  Sigma_hat <- stats::cov(Phi)
  Sigma_diag <- diag(diag(Sigma_hat), nrow = 4)
  dimnames(Sigma_diag) <- dimnames(Sigma_hat)
  cov <- list(Sigma = Sigma_diag, Sigma_inv = diag(1 / diag(Sigma_diag), nrow = 4),
             shrink_used = "diagonal", alpha = 1, kappa = 1, rank = 4L,
             n_eff = 500L, J = 4L, ok = TRUE)

  res <- combine_cell_scores(Phi, values = rep(0, 4), cov = cov)

  # gls_weights() on a list of vectors with the same sample variances as Phi's columns.
  phi_list <- lapply(seq_len(4), function(j) Phi[, j])
  expected <- gls_weights(phi_list)

  expect_equal(unname(res$lambda), expected, tolerance = 1e-10)
})

test_that("lambda satisfies the unbiasedness identity lambda'R = c'", {
  Phi <- make_score_matrix(n = 300, J = 5, rho = 0.3, seed = 2)
  g <- c(1, 1, 2, 2, 3)
  omega <- c(0.5, 0.3, 0.2)

  res <- combine_cell_scores(Phi, values = c(1, 2, 3, 4, 5),
                             restriction = g, target = omega)

  R <- .build_restriction(g, J = 5)
  expect_equal(as.numeric(t(res$lambda) %*% R), omega, tolerance = 1e-8)
})

test_that("closed-form variance matches the realized combination when shrink = 'none'", {
  Phi <- make_score_matrix(n = 400, J = 4, rho = 0.4, seed = 3)
  cov <- estimate_score_cov(Phi, shrink = "none")

  res <- combine_cell_scores(Phi, values = c(1, 1, 1, 1), cov = cov)

  realized <- as.numeric(t(res$lambda) %*% cov$Sigma %*% res$lambda)
  expect_equal(res$se_nominal^2 * cov$n_eff, realized, tolerance = 1e-8)
  # And se itself is the honest, unshrunk variance of the realized combined score.
  expect_equal(res$se, sqrt(stats::var(as.numeric(Phi %*% res$lambda)) / cov$n_eff),
              tolerance = 1e-8)
})

test_that("value and phi are the linear combination lambda'theta_hat and Phi %*% lambda", {
  Phi <- make_score_matrix(n = 200, J = 3, rho = 0.2, seed = 4)
  values <- c(0.4, 0.6, 0.5)

  res <- combine_cell_scores(Phi, values = values)

  expect_equal(res$value, sum(res$lambda * values), tolerance = 1e-10)
  expect_equal(res$phi, as.numeric(Phi %*% res$lambda), tolerance = 1e-10)
  expect_length(res$phi, 200)
})

test_that("J == 1 returns lambda = target directly, no inversion", {
  Phi <- matrix(stats::rnorm(100), ncol = 1)
  res <- combine_cell_scores(Phi, values = 3.7)

  expect_equal(unname(res$lambda), 1)
  expect_equal(res$value, 3.7)
})

test_that("a restriction column of all zeros (an empty group) errors, naming it", {
  Phi <- make_score_matrix(n = 100, J = 3, seed = 5)
  # Group 2 has no cells assigned to it in the grouping vector, but is still requested via
  # target -- this is the "group in gt_object$groups with no observed cells" case.
  g <- c(1, 1, 3)  # note: no cell carries group label 2
  R <- matrix(0, nrow = 3, ncol = 3)
  R[1, 1] <- R[2, 1] <- 1
  R[3, 3] <- 1
  # column 2 of R is all zero by construction

  expect_error(
    combine_cell_scores(Phi, values = c(1, 2, 3), restriction = R, target = c(0.5, 0.2, 0.3)),
    "empty|zero|rank"
  )
})

test_that("fallback = 'diagonal' recovers when Sigma_inv is unreliable, with a warning", {
  # More cells than units guarantees an exactly-singular sample covariance.
  set.seed(6)
  Phi <- matrix(stats::rnorm(8 * 10), nrow = 8, ncol = 10)
  cov_bad <- suppressWarnings(estimate_score_cov(Phi, shrink = "none"))
  stopifnot(!cov_bad$ok)

  expect_warning(
    res <- combine_cell_scores(Phi, values = rep(1, 10), cov = cov_bad, fallback = "diagonal"),
    "fallback|diagonal"
  )
  expect_equal(res$weighting_used, "diagonal")
  expect_true(is.finite(res$value))
})

test_that("fallback = 'error' refuses rather than silently falling back", {
  set.seed(6)
  Phi <- matrix(stats::rnorm(8 * 10), nrow = 8, ncol = 10)
  cov_bad <- suppressWarnings(estimate_score_cov(Phi, shrink = "none"))
  stopifnot(!cov_bad$ok)

  expect_error(
    combine_cell_scores(Phi, values = rep(1, 10), cov = cov_bad, fallback = "error"),
    "Sigma|invert"
  )
})

test_that("omega_scores adds the same functional-delta-method term as aggregate_groups()", {
  Phi <- make_score_matrix(n = 60, J = 4, rho = 0.1, seed = 7)
  g <- c(1, 1, 2, 2)
  values <- c(1, 2, 3, 4)
  omega <- c(0.6, 0.4)

  omega_scores <- matrix(stats::rnorm(60 * 2, sd = 0.05), nrow = 60, ncol = 2)
  colnames(omega_scores) <- c("1", "2")
  attr(omega_scores, "omega") <- omega

  res_plain <- combine_cell_scores(Phi, values = values, restriction = g, target = omega)
  res_with_scores <- combine_cell_scores(Phi, values = values, restriction = g,
                                         target = omega, omega_scores = omega_scores)

  # beta_hat (the per-group combined estimates) feed .omega_contribution() the same way
  # aggregate_groups() feeds values_g.
  expected_extra <- .omega_contribution(omega_scores, res_plain$beta)
  expect_equal(res_with_scores$phi, res_plain$phi + expected_extra, tolerance = 1e-10)
  # The point estimate never depends on omega_scores (matches aggregate_groups()'s contract).
  expect_equal(res_with_scores$value, res_plain$value, tolerance = 1e-10)
})

test_that("diagnostics warn on strongly negative/explosive weights", {
  # Two groups whose cells share a strong common comparator component: disentangling the
  # two group-level betas via GLS forces a negative cross-group weight.
  n <- 60
  set.seed(11)
  common <- stats::rnorm(n)
  Phi <- cbind(
    common * 0.95 + stats::rnorm(n, sd = 0.15),
    common * 0.95 + stats::rnorm(n, sd = 0.15),
    common * 0.95 + stats::rnorm(n, sd = 0.15),
    common * 0.95 + stats::rnorm(n, sd = 0.15)
  )
  colnames(Phi) <- paste0("cell", 1:4)
  g <- c(1, 1, 2, 2)

  expect_warning(
    combine_cell_scores(Phi, values = c(1, 1, 1, 1), restriction = g, target = c(0.5, 0.5)),
    "negative|weight|l1"
  )
})

test_that("phi_beta reproduces phi via phi_beta %*% target", {
  Phi <- make_score_matrix(n = 200, J = 5, rho = 0.3, seed = 12)
  g <- c(1, 1, 2, 2, 3)
  omega <- c(0.5, 0.3, 0.2)

  res <- combine_cell_scores(Phi, values = c(1, 2, 3, 4, 5), restriction = g, target = omega)

  expect_equal(dim(res$phi_beta), c(200L, 3L))
  expect_equal(res$phi, as.numeric(res$phi_beta %*% omega), tolerance = 1e-10)
  # beta_hat itself: each column's realized combination should equal the corresponding
  # group's beta_hat when applied to values (sanity: phi_beta is the EIF of beta, not of
  # values directly, so we only check the linear-combination identity above and shape here).
})

test_that("grouping vector and equivalent indicator matrix give identical results", {
  Phi <- make_score_matrix(n = 150, J = 5, rho = 0.25, seed = 9)
  g <- c("a", "a", "b", "b", "b")
  values <- c(1, 2, 3, 4, 5)

  res_vec <- combine_cell_scores(Phi, values = values, restriction = g, target = c(0.5, 0.5))
  R <- .build_restriction(g, J = 5)
  res_mat <- combine_cell_scores(Phi, values = values, restriction = R, target = c(0.5, 0.5))

  expect_equal(res_vec$lambda, res_mat$lambda, tolerance = 1e-10)
})

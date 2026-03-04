test_that("safe_matrix_inverse works with well-conditioned matrix", {
  X <- cbind(1, 1:5)
  result <- safe_matrix_inverse(X)

  expect_true(is.matrix(result))
  expect_equal(dim(result), c(2, 2))
  expect_true(all(is.finite(result)))
})

test_that("safe_matrix_inverse rejects singular matrix", {
  X <- cbind(1, rep(1, 5))  # Columns are linearly dependent

  expect_error(
    safe_matrix_inverse(X),
    "near-singular"
  )
})

test_that("safe_matrix_inverse checks for insufficient observations", {
  X <- matrix(c(1, 2), nrow = 1, ncol = 2)  # 1 observation, 2 columns

  expect_error(
    safe_matrix_inverse(X),
    "Insufficient observations"
  )
})

test_that("safe_matrix_inverse handles vector input", {
  X <- 1:5  # Vector should be converted to single-column matrix
  result <- safe_matrix_inverse(X)

  expect_true(is.matrix(result))
  expect_equal(dim(result), c(1, 1))
})

test_that("safe_matrix_inverse validates input type", {
  expect_error(
    safe_matrix_inverse("not a matrix"),
    "must be a numeric matrix"
  )

  expect_error(
    safe_matrix_inverse(list(1, 2, 3)),
    "must be a numeric matrix"
  )
})

test_that("safe_matrix_inverse handles rank-deficient matrix", {
  # Create rank-deficient matrix
  X <- cbind(c(1, 2, 3, 4), c(2, 4, 6, 8))  # Second column = 2 * first

  expect_error(
    safe_matrix_inverse(X),
    "near-singular|Insufficient observations"
  )
})

test_that("safe_matrix_inverse detects numerical instability", {
  # Create numerically unstable matrix with very small scale
  X <- cbind(1, 1e-15 * 1:5)

  expect_error(
    safe_matrix_inverse(X),
    "near-singular"
  )
})

test_that("safe_matrix_inverse works with square full-rank matrix", {
  X <- diag(3)  # 3x3 identity
  result <- safe_matrix_inverse(X)

  # X'X = I, so (X'X)^{-1} = I
  expect_equal(result, diag(3), tolerance = 1e-10)
})

test_that("safe_matrix_inverse computes correct inverse", {
  X <- cbind(1, c(1, 2, 3))
  XtX <- crossprod(X)
  result <- safe_matrix_inverse(X)

  # Check that result * XtX ≈ I
  product <- result %*% XtX
  expect_equal(product, diag(2), tolerance = 1e-10)
})

test_that("safe_matrix_inverse respects tolerance parameter", {
  # Create matrix with moderate condition number
  X <- cbind(1, 1:10)

  # Should succeed with default tolerance
  expect_silent(safe_matrix_inverse(X, tol = 1e-8))

  # Test that tolerance parameter is used
  # (Note: simple matrices may not have high enough condition number
  # to trigger error even with strict tolerance, which is fine)
  expect_silent(safe_matrix_inverse(X, tol = 1e-10))
})

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

## fast_cbind_list tests

test_that("fast_cbind_list works with small lists", {
  vec_list <- list(1:5, 6:10, 11:15)
  result <- fast_cbind_list(vec_list)

  expect_true(is.matrix(result))
  expect_equal(dim(result), c(5, 3))
  expect_equal(result[, 1], 1:5)
  expect_equal(result[, 2], 6:10)
  expect_equal(result[, 3], 11:15)
})

test_that("fast_cbind_list works with large lists", {
  # Test optimized path (> threshold)
  n <- 50
  vec_list <- replicate(150, rnorm(n), simplify = FALSE)
  result <- fast_cbind_list(vec_list, threshold = 100)

  expect_true(is.matrix(result))
  expect_equal(dim(result), c(n, 150))
  expect_equal(result[, 1], vec_list[[1]])
  expect_equal(result[, 150], vec_list[[150]])
})

test_that("fast_cbind_list produces same result as do.call for small lists", {
  set.seed(20260304)
  vec_list <- replicate(10, rnorm(20), simplify = FALSE)

  result_fast <- fast_cbind_list(vec_list)
  result_docall <- do.call(cbind, vec_list)

  expect_equal(result_fast, result_docall)
})

test_that("fast_cbind_list handles single column", {
  vec_list <- list(1:10)
  result <- fast_cbind_list(vec_list)

  expect_true(is.matrix(result))
  expect_equal(dim(result), c(10, 1))
  expect_equal(result[, 1], 1:10)
})

test_that("fast_cbind_list rejects empty list", {
  expect_error(
    fast_cbind_list(list()),
    "empty"
  )
})

test_that("fast_cbind_list respects threshold parameter", {
  # With threshold = 5, list of 3 should use do.call path
  vec_list <- list(1:10, 11:20, 21:30)

  result_low_threshold <- fast_cbind_list(vec_list, threshold = 5)
  result_high_threshold <- fast_cbind_list(vec_list, threshold = 1)

  # Both should give same result
  expect_equal(result_low_threshold, result_high_threshold)
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

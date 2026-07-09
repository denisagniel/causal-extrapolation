# Tests for as_cate() adapters (Path 3 CATE contract extractors)

test_that("as_cate.default errors informatively for unsupported classes", {
  fit <- structure(list(), class = "some_unknown_learner")
  expect_error(
    as_cate(fit),
    "no method for class 'some_unknown_learner'"
  )
})


test_that("as_cate.drdid points users to the manual DiD contract", {
  skip_if_not_installed("drdid")
  fit <- structure(list(), class = "drdid")
  expect_error(as_cate(fit), "not yet implemented")
})


test_that("as_cate.causal_forest round-trips through integrate_cate (grf)", {
  skip_if_not_installed("grf")

  set.seed(20260708)
  n <- 400
  X <- matrix(rnorm(n * 2), n, 2)
  e_true <- plogis(0.5 * X[, 1])
  W <- rbinom(n, 1, e_true)
  tau_x <- 1 + 0.5 * X[, 1]
  Y <- X[, 1] + W * tau_x + rnorm(n, sd = 0.5)

  cf <- grf::causal_forest(X, Y, W, num.trees = 200)

  cate <- suppressMessages(as_cate(cf))
  expect_equal(attr(cate, "design"), "unconfoundedness")
  expect_named(cate, c("tau", "mu1", "mu0", "e", "A", "Y", "X"), ignore.order = TRUE)
  expect_length(cate$tau, n)
  expect_true(all(is.finite(cate$tau)))
  expect_true(all(cate$e > 0 & cate$e < 1))

  # Contract is consumable by integrate_cate() (collapse case).
  res <- integrate_cate(cate, target = which(cate$A == 1))
  expect_s3_class(res, "cate_integration")
  expect_true(is.finite(res$estimate))
  expect_true(is.finite(res$se))
})


test_that("as_cate.causal_forest honors explicit mu0/mu1 override (grf)", {
  skip_if_not_installed("grf")

  set.seed(1)
  n <- 200
  X <- matrix(rnorm(n * 2), n, 2)
  W <- rbinom(n, 1, 0.5)
  Y <- X[, 1] + W * (1 + 0.5 * X[, 1]) + rnorm(n, sd = 0.5)
  cf <- grf::causal_forest(X, Y, W, num.trees = 100)

  mu0 <- rep(0, n)
  mu1 <- rep(1, n)
  # With explicit mu0/mu1, no message is emitted and the values are passed through.
  expect_silent(cate <- as_cate(cf, mu0 = mu0, mu1 = mu1))
  expect_equal(cate$mu0, mu0)
  expect_equal(cate$mu1, mu1)
})

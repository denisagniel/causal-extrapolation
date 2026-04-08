test_that("compute_variance works with basic EIF vector", {
  set.seed(20260304)
  phi <- rnorm(100, mean = 0, sd = 0.1)
  result <- compute_variance(phi, estimate = 0.5, level = 0.95)

  expect_type(result, "list")
  expect_named(result, c("var", "se", "ci", "level"))
  expect_true(result$var > 0)
  expect_equal(result$se, sqrt(result$var))
  expect_length(result$ci, 2)
  expect_true(result$ci[1] < result$ci[2])
})

test_that("compute_variance computes correct variance", {
  set.seed(20260304)
  n <- 100
  phi <- rnorm(n, mean = 0.5, sd = 0.1)

  result <- compute_variance(phi, center = FALSE)

  # Should match var(phi) / n
  expected_var <- var(phi) / n
  expect_equal(result$var, expected_var)
})

test_that("compute_variance centers phi when requested", {
  set.seed(20260304)
  phi <- rnorm(100, mean = 2, sd = 0.1)

  result_centered <- compute_variance(phi, center = TRUE)
  result_uncentered <- compute_variance(phi, center = FALSE)

  # Note: Both centered and uncentered use var() which centers internally,
  # so results should be similar. The center parameter just pre-centers before var().
  # Both should produce valid finite variance estimates
  expect_true(is.finite(result_centered$var))
  expect_true(is.finite(result_uncentered$var))
  expect_true(result_centered$var > 0)
  expect_true(result_uncentered$var > 0)

  # They should be approximately equal since var() centers anyway
  expect_equal(result_centered$var, result_uncentered$var, tolerance = 0.01)
})

test_that("compute_variance handles NA values with warning", {
  phi_with_na <- c(rnorm(10), NA, rnorm(10))

  expect_warning(
    result <- compute_variance(phi_with_na),
    "contains .* NA value"
  )

  # Should compute variance on non-NA values
  expect_true(is.finite(result$var))
  expect_true(result$var > 0)
})

test_that("compute_variance requires at least 2 non-NA observations", {
  expect_error(
    compute_variance(c(1, NA)),
    "Insufficient non-NA observations"
  )

  expect_error(
    compute_variance(5),
    "Insufficient non-NA observations"
  )
})

test_that("compute_variance computes confidence intervals correctly", {
  set.seed(20260304)
  phi <- rnorm(100, sd = 0.1)
  estimate <- 0.5

  result <- compute_variance(phi, estimate = estimate, level = 0.95)

  # CI should be centered on estimate
  ci_midpoint <- mean(result$ci)
  expect_equal(ci_midpoint, estimate, tolerance = 1e-10)

  # Width should be 2 * z * se
  z <- qnorm(0.975)
  expected_width <- 2 * z * result$se
  actual_width <- diff(result$ci)
  expect_equal(actual_width, expected_width, tolerance = 1e-10)
})

test_that("compute_variance respects confidence level", {
  set.seed(20260304)
  phi <- rnorm(100, sd = 0.1)

  result_95 <- compute_variance(phi, estimate = 0.5, level = 0.95)
  result_99 <- compute_variance(phi, estimate = 0.5, level = 0.99)

  # 99% CI should be wider than 95% CI
  width_95 <- diff(result_95$ci)
  width_99 <- diff(result_99$ci)
  expect_gt(width_99, width_95)
})

test_that("compute_variance returns NA CI when estimate is NULL", {
  phi <- rnorm(100, sd = 0.1)
  result <- compute_variance(phi, estimate = NULL, level = 0.95)

  expect_true(all(is.na(result$ci)))
  expect_true(is.finite(result$var))
  expect_true(is.finite(result$se))
})

test_that("compute_variance validates confidence level", {
  phi <- rnorm(100)

  expect_error(
    compute_variance(phi, level = 0),
    "must be in \\(0, 1\\)"
  )

  expect_error(
    compute_variance(phi, level = 1),
    "must be in \\(0, 1\\)"
  )

  expect_error(
    compute_variance(phi, level = 1.5),
    "must be in \\(0, 1\\)"
  )
})

test_that("compute_variance validates estimate is scalar", {
  phi <- rnorm(100)

  expect_error(
    compute_variance(phi, estimate = c(0.5, 0.6)),
    "must be a numeric scalar"
  )

  expect_error(
    compute_variance(phi, estimate = NA_real_),
    "must be finite"
  )
})

test_that("compute_variance rejects Inf in phi", {
  phi <- c(rnorm(10), Inf)

  expect_error(
    compute_variance(phi),
    "contains .* Inf value"
  )
})

test_that("compute_variance handles length = 2 edge case", {
  phi <- c(1, 3)
  result <- compute_variance(phi, center = FALSE)

  # Should compute variance without error
  expect_true(is.finite(result$var))
  expect_equal(result$var, var(phi) / 2)
})

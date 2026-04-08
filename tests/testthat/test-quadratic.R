test_that("dh_quadratic produces finite weights", {
  times <- 1:5
  w <- dh_quadratic(times, future_time = 7)
  expect_length(w, length(times))
  expect_true(all(is.finite(w)))
})

test_that("hg_quadratic applies weights correctly", {
  times <- 1:5
  h <- hg_quadratic(times, future_time = 6)
  w <- dh_quadratic(times, future_time = 6)
  tau <- c(1, 2, 3, 4, 5)
  expect_equal(h(tau), sum(w * tau))
})

test_that("dh_quadratic requires at least p = 3 observations", {
  expect_error(
    dh_quadratic(times = c(1, 2), future_time = 3),
    "Quadratic model requires at least 3 observations"
  )
})

test_that("dh_quadratic detects exactly repeated time values", {
  times_repeated <- c(1, 1, 1, 1, 1)  # All identical
  expect_error(
    dh_quadratic(times_repeated, future_time = 4),
    "near-singular"
  )
})

test_that("dh_quadratic handles minimum case p = 3", {
  times <- c(1, 2, 3)
  w <- dh_quadratic(times, future_time = 4)
  expect_length(w, 3)
  expect_true(all(is.finite(w)))
})

test_that("hg_quadratic extrapolates quadratically", {
  # Perfect quadratic sequence: tau = times^2
  times <- 1:5
  tau <- times^2
  h <- hg_quadratic(times, future_time = 6)

  # Should extrapolate to 6^2 = 36
  expect_equal(h(tau), 36, tolerance = 1e-8)
})

test_that("hg_quadratic handles constant sequence", {
  times <- 1:5
  tau <- rep(3, 5)  # Constant
  h <- hg_quadratic(times, future_time = 6)

  # Should predict constant value
  result <- h(tau)
  expect_equal(result, 3, tolerance = 1e-10)
})

test_that("hg_quadratic handles linear sequence", {
  # Linear sequence: should be fitted well by quadratic
  times <- 1:5
  tau <- times * 2
  h <- hg_quadratic(times, future_time = 6)

  # Should extrapolate to 6 * 2 = 12
  expect_equal(h(tau), 12, tolerance = 1e-8)
})

test_that("dh_quadratic handles large but well-scaled time values", {
  # Center large times to avoid numerical issues
  times <- c(0, 5, 10, 15, 20)  # Use differences instead of absolute years
  w <- dh_quadratic(times, future_time = 25)
  expect_true(all(is.finite(w)))
  expect_length(w, 5)
})

test_that("dh_quadratic handles negative times", {
  times <- c(-5, -3, -1, 0, 2)
  w <- dh_quadratic(times, future_time = 4)
  expect_true(all(is.finite(w)))
})

test_that("hg_quadratic and dh_quadratic are consistent", {
  times <- c(1, 3, 5, 7, 9)
  tau <- rnorm(5)
  future_time <- 11

  h <- hg_quadratic(times, future_time)
  w <- dh_quadratic(times, future_time)

  # hg should use dh internally
  expect_equal(h(tau), sum(w * tau))
})

test_that("dh_quadratic handles non-consecutive times", {
  times <- c(1, 5, 10, 20, 30)
  w <- dh_quadratic(times, future_time = 40)
  expect_true(all(is.finite(w)))
})

test_that("hg_quadratic fits parabola correctly", {
  # Exact parabola: tau = a + b*t + c*t^2
  times <- 0:4
  a <- 1; b <- 2; c <- 0.5
  tau <- a + b * times + c * times^2

  h <- hg_quadratic(times, future_time = 5)
  expected <- a + b * 5 + c * 5^2

  expect_equal(h(tau), expected, tolerance = 1e-10)
})

test_that("quadratic model generalizes linear model", {
  # When data is linear, quadratic should reduce to linear fit
  times <- 1:5
  tau <- 2 + 3 * times  # Linear: tau = 2 + 3*t

  h_quad <- hg_quadratic(times, future_time = 6)
  h_linear <- hg_linear(times, future_time = 6)

  # Both should give similar results for linear data
  result_quad <- h_quad(tau)
  result_linear <- h_linear(tau)

  expect_equal(result_quad, result_linear, tolerance = 1e-8)
})

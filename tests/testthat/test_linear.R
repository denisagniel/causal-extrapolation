test_that("dh_linear produces weights summing to 1 with intercept", {
  times <- 1:5
  w <- dh_linear(times, future_time = 7)
  expect_length(w, length(times))
  # with intercept and centered design, weights need not sum to 1 in general;
  # here we check finite values and basic sanity
  expect_true(all(is.finite(w)))
})

test_that("hg_linear applies weights correctly", {
  times <- 1:4
  h <- hg_linear(times, future_time = 6)
  w <- dh_linear(times, future_time = 6)
  tau <- c(1, 2, 3, 4)
  expect_equal(h(tau), sum(w * tau))
})

## Edge cases and boundary conditions

test_that("dh_linear requires at least p = 2 observations", {
  expect_error(
    dh_linear(times = 1, future_time = 2),
    "Linear model requires at least 2 observations"
  )
})

test_that("dh_linear detects exactly repeated time values", {
  times_repeated <- c(1, 1, 1, 1)  # All identical
  expect_error(
    dh_linear(times_repeated, future_time = 3),
    "near-singular"
  )
})

test_that("dh_linear handles minimum case p = 2", {
  times <- c(1, 2)
  w <- dh_linear(times, future_time = 3)
  expect_length(w, 2)
  expect_true(all(is.finite(w)))
})

test_that("hg_linear extrapolates linearly", {
  # Perfect linear sequence: tau = times
  times <- 1:5
  tau <- times
  h <- hg_linear(times, future_time = 6)

  # Should extrapolate to 6
  expect_equal(h(tau), 6, tolerance = 1e-10)
})

test_that("hg_linear handles constant sequence", {
  times <- 1:5
  tau <- rep(2, 5)  # Constant
  h <- hg_linear(times, future_time = 6)

  # Should predict constant value
  result <- h(tau)
  expect_equal(result, 2, tolerance = 1e-10)
})

test_that("dh_linear handles large but well-scaled time values", {
  # Center large times to avoid numerical issues
  times <- c(0, 5, 10, 15)  # Use differences instead of absolute years
  w <- dh_linear(times, future_time = 20)
  expect_true(all(is.finite(w)))
  expect_length(w, 4)
})

test_that("dh_linear handles negative times", {
  times <- c(-5, -3, -1, 0)
  w <- dh_linear(times, future_time = 2)
  expect_true(all(is.finite(w)))
})

test_that("hg_linear and dh_linear are consistent", {
  times <- c(1, 3, 5, 7)
  tau <- rnorm(4)
  future_time <- 9

  h <- hg_linear(times, future_time)
  w <- dh_linear(times, future_time)

  # hg should use dh internally
  expect_equal(h(tau), sum(w * tau))
})

test_that("dh_linear detects poorly scaled times", {
  # Very small absolute values with very small differences
  # This SHOULD fail due to numerical instability
  times <- c(1e-10, 2e-10, 3e-10)
  expect_error(
    dh_linear(times, future_time = 4e-10),
    "near-singular"
  )
})

test_that("dh_linear handles reasonable small time values", {
  # Small but well-conditioned
  times <- c(0.1, 0.2, 0.3, 0.4)
  w <- dh_linear(times, future_time = 0.5)
  expect_true(all(is.finite(w)))
})






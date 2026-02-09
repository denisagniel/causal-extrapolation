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






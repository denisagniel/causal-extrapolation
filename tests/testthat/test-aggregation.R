test_that("aggregate_groups combines values with weights", {
  values_g <- c(0.5, 0.3, 0.7)
  omega <- c(0.5, 0.3, 0.2)
  eif_list <- list(rnorm(50), rnorm(50), rnorm(50))

  result <- aggregate_groups(values_g, eif_list, omega)

  expect_type(result, "list")
  expect_named(result, c("value", "phi"))

  # Check weighted sum
  expected_value <- sum(omega * values_g)
  expect_equal(result$value, expected_value)

  # Check phi is numeric vector
  expect_true(is.numeric(result$phi))
  expect_length(result$phi, 50)
})

test_that("aggregate_groups validates input lengths", {
  values_g <- c(0.5, 0.3)
  omega <- c(0.5, 0.5)
  eif_list_wrong <- list(rnorm(50))  # Too short

  expect_error(
    aggregate_groups(values_g, eif_list_wrong, omega),
    "Length mismatch"
  )
})

test_that("aggregate_groups validates omega length matches values", {
  values_g <- c(0.5, 0.3)
  omega <- c(0.5, 0.3, 0.2)  # Too long
  eif_list <- list(rnorm(50), rnorm(50))

  expect_error(
    aggregate_groups(values_g, eif_list, omega),
    "Length mismatch"
  )
})

test_that("aggregate_groups rejects negative weights", {
  values_g <- c(0.5, 0.3)
  omega <- c(0.6, -0.1)
  eif_list <- list(rnorm(50), rnorm(50))

  expect_error(
    aggregate_groups(values_g, eif_list, omega),
    "must be non-negative"
  )
})

test_that("aggregate_groups warns if weights don't sum to 1", {
  values_g <- c(0.5, 0.3)
  omega <- c(0.5, 0.3)  # sums to 0.8
  eif_list <- list(rnorm(50), rnorm(50))

  expect_warning(
    aggregate_groups(values_g, eif_list, omega),
    "does not sum to 1"
  )
})

test_that("aggregate_groups handles single group", {
  values_g <- 0.5
  omega <- 1.0
  eif_list <- list(rnorm(50))

  result <- aggregate_groups(values_g, eif_list, omega)

  expect_equal(result$value, 0.5)
  expect_equal(result$phi, eif_list[[1]])
})

test_that("aggregate_groups validates numeric inputs", {
  eif_list <- list(rnorm(50), rnorm(50))
  omega <- c(0.5, 0.5)

  expect_error(
    aggregate_groups(c("a", "b"), eif_list, omega),
    "must be numeric"
  )

  expect_error(
    aggregate_groups(c(0.5, 0.5), eif_list, c("a", "b")),
    "must be numeric"
  )
})

test_that("aggregate_groups rejects non-list eif_list", {
  values_g <- c(0.5, 0.3)
  omega <- c(0.5, 0.5)

  expect_error(
    aggregate_groups(values_g, rnorm(100), omega),
    "must be a list"
  )
})

test_that("aggregate_groups propagates EIFs correctly", {
  set.seed(20260304)
  n <- 50
  values_g <- c(0.5, 0.3)
  omega <- c(0.6, 0.4)
  eif1 <- rnorm(n, mean = 1)
  eif2 <- rnorm(n, mean = 2)
  eif_list <- list(eif1, eif2)

  result <- aggregate_groups(values_g, eif_list, omega)

  # Manual computation
  expected_phi <- omega[1] * eif1 + omega[2] * eif2
  expect_equal(result$phi, expected_phi)
})

test_that("aggregate_groups handles equal weights correctly", {
  values_g <- c(0.2, 0.4, 0.6)
  omega <- rep(1/3, 3)
  eif_list <- list(rnorm(50), rnorm(50), rnorm(50))

  result <- aggregate_groups(values_g, eif_list, omega)

  # Should be simple average
  expected_value <- mean(values_g)
  expect_equal(result$value, expected_value, tolerance = 1e-10)
})

test_that("aggregate_groups with zero weights", {
  values_g <- c(0.5, 0.3, 0.7)
  omega <- c(1.0, 0.0, 0.0)  # Only first group counts
  eif_list <- list(rnorm(50, mean = 1), rnorm(50, mean = 2), rnorm(50, mean = 3))

  result <- aggregate_groups(values_g, eif_list, omega)

  expect_equal(result$value, 0.5)
  # phi should match first group's EIF
  expect_equal(result$phi, eif_list[[1]])
})

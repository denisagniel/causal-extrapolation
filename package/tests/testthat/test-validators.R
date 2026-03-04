test_that("validate_numeric_vector accepts valid numeric vectors", {
  x <- rnorm(10)
  expect_silent(validate_numeric_vector(x))
  expect_silent(validate_numeric_vector(1:5))
})

test_that("validate_numeric_vector rejects non-numeric input", {
  expect_error(
    validate_numeric_vector(c("a", "b", "c")),
    "must be numeric"
  )
  expect_error(
    validate_numeric_vector(list(1, 2, 3)),
    "must be numeric"
  )
})

test_that("validate_numeric_vector catches NA values", {
  x_with_na <- c(1, 2, NA, 4)
  expect_error(
    validate_numeric_vector(x_with_na, allow_na = FALSE),
    "contains .* NA value"
  )
  expect_silent(validate_numeric_vector(x_with_na, allow_na = TRUE))
})

test_that("validate_numeric_vector catches Inf values", {
  x_with_inf <- c(1, 2, Inf, 4)
  expect_error(
    validate_numeric_vector(x_with_inf),
    "contains .* Inf value"
  )
})

test_that("validate_eif_list accepts valid EIF lists", {
  n <- 50
  phi <- list(rnorm(n), rnorm(n), rnorm(n))
  expect_silent(validate_eif_list(phi, n))
})

test_that("validate_eif_list rejects non-list input", {
  expect_error(
    validate_eif_list(rnorm(10), 10),
    "must be a list"
  )
})

test_that("validate_eif_list catches length mismatches", {
  phi <- list(rnorm(50), rnorm(40), rnorm(50))
  expect_error(
    validate_eif_list(phi, 50),
    "must have length n = 50"
  )
})

test_that("validate_eif_list catches empty list", {
  expect_error(
    validate_eif_list(list(), 10),
    "empty list"
  )
})

test_that("validate_group_weights accepts valid weights", {
  omega <- c(0.6, 0.4)
  expect_silent(validate_group_weights(omega, 2, warn_sum = FALSE))
})

test_that("validate_group_weights warns if weights don't sum to 1", {
  omega <- c(0.5, 0.3)  # sums to 0.8
  expect_warning(
    validate_group_weights(omega, 2, warn_sum = TRUE),
    "does not sum to 1"
  )
})

test_that("validate_group_weights rejects negative weights", {
  omega <- c(0.6, -0.1)
  expect_error(
    validate_group_weights(omega, 2),
    "must be non-negative"
  )
})

test_that("validate_group_weights checks length matches n_groups", {
  omega <- c(0.5, 0.5)
  expect_error(
    validate_group_weights(omega, 3),
    "must have length 3"
  )
})

test_that("validate_confidence_level accepts valid levels", {
  expect_silent(validate_confidence_level(0.95))
  expect_silent(validate_confidence_level(0.99))
  expect_silent(validate_confidence_level(0.50))
})

test_that("validate_confidence_level rejects out-of-range values", {
  expect_error(validate_confidence_level(0), "must be in \\(0, 1\\)")
  expect_error(validate_confidence_level(1), "must be in \\(0, 1\\)")
  expect_error(validate_confidence_level(1.5), "must be in \\(0, 1\\)")
  expect_error(validate_confidence_level(-0.05), "must be in \\(0, 1\\)")
})

test_that("validate_confidence_level rejects non-scalar input", {
  expect_error(
    validate_confidence_level(c(0.95, 0.99)),
    "must be a scalar"
  )
})

test_that("validate_gt_object accepts valid gt_object", {
  gt_obj <- make_mock_gt_object()
  expect_silent(validate_gt_object(gt_obj))
})

test_that("validate_gt_object rejects non-gt_object", {
  bad_obj <- list(data = data.frame())
  expect_error(
    validate_gt_object(bad_obj),
    "must be a gt_object"
  )
})

test_that("validate_gt_object catches missing required fields", {
  incomplete_obj <- list(data = data.frame(), phi = list())
  class(incomplete_obj) <- "gt_object"
  expect_error(
    validate_gt_object(incomplete_obj),
    "missing required fields"
  )
})

test_that("validate_gt_object checks phi and data alignment", {
  gt_obj <- make_mock_gt_object(n = 50, n_groups = 2, n_times = 3)
  # Corrupt by removing one phi element
  gt_obj$phi <- gt_obj$phi[-1]
  expect_error(
    validate_gt_object(gt_obj),
    "phi has length"
  )
})

test_that("validate_gt_object checks required columns in data", {
  gt_obj <- make_mock_gt_object()
  # Remove required column
  gt_obj$data$tau_hat <- NULL
  expect_error(
    validate_gt_object(gt_obj),
    "data is missing required columns"
  )
})

test_that("validate_scalar accepts valid scalars", {
  expect_silent(validate_scalar(1.5))
  expect_silent(validate_scalar(0))
  expect_silent(validate_scalar(-10))
})

test_that("validate_scalar rejects non-scalar input", {
  expect_error(validate_scalar(c(1, 2)), "must be a numeric scalar")
  expect_error(validate_scalar("text"), "must be a numeric scalar")
})

test_that("validate_scalar rejects NA and Inf", {
  expect_error(validate_scalar(NA_real_), "must be finite")
  expect_error(validate_scalar(Inf), "must be finite")
})

test_that("validate_lengths_match accepts matching lengths", {
  x <- 1:5
  y <- rnorm(5)
  expect_silent(validate_lengths_match(x, y))
})

test_that("validate_lengths_match catches length mismatches", {
  x <- 1:5
  y <- rnorm(3)
  expect_error(
    validate_lengths_match(x, y),
    "Length mismatch"
  )
})

test_that("new_gt_object creates valid gt_object with minimal inputs", {
  data <- data.frame(
    g = c(1, 1, 2, 2),
    t = c(2, 3, 3, 4),
    tau_hat = c(0.5, 0.6, 0.4, 0.5)
  )

  gt <- new_gt_object(data, n = 100)

  expect_s3_class(gt, "gt_object")
  expect_s3_class(gt, "extrapolateATT")
  expect_equal(gt$data$g, data$g)
  expect_equal(gt$data$t, data$t)
  expect_equal(gt$data$tau_hat, data$tau_hat)
  expect_null(gt$phi)
  expect_equal(gt$n, 100)
  expect_equal(gt$times, c(2, 3, 4))
  expect_equal(gt$groups, c(1, 2))
})

test_that("new_gt_object computes event time k if missing", {
  data <- data.frame(
    g = c(1, 1, 2),
    t = c(2, 3, 3),
    tau_hat = c(0.5, 0.6, 0.4)
  )

  gt <- new_gt_object(data, n = 100)

  expect_equal(gt$data$k, c(1, 2, 1))
  expect_equal(gt$event_times, c(1, 2))
})

test_that("new_gt_object preserves existing k column", {
  data <- data.frame(
    g = c(1, 1, 2),
    t = c(2, 3, 3),
    k = c(10, 20, 30),  # Non-standard k values
    tau_hat = c(0.5, 0.6, 0.4)
  )

  gt <- new_gt_object(data, n = 100)

  expect_equal(gt$data$k, c(10, 20, 30))
})

test_that("new_gt_object accepts EIF list", {
  data <- data.frame(
    g = c(1, 1, 2),
    t = c(2, 3, 3),
    tau_hat = c(0.5, 0.6, 0.4)
  )

  phi <- list(
    rnorm(100),
    rnorm(100),
    rnorm(100)
  )

  gt <- new_gt_object(data, phi = phi, n = 100)

  expect_length(gt$phi, 3)
  expect_equal(length(gt$phi[[1]]), 100)
  expect_equal(gt$n, 100)
})

test_that("new_gt_object infers n from phi", {
  data <- data.frame(
    g = c(1, 1),
    t = c(2, 3),
    tau_hat = c(0.5, 0.6)
  )

  phi <- list(rnorm(50), rnorm(50))

  gt <- new_gt_object(data, phi = phi)

  expect_equal(gt$n, 50)
})

test_that("new_gt_object accepts se vector", {
  data <- data.frame(
    g = c(1, 1, 2),
    t = c(2, 3, 3),
    tau_hat = c(0.5, 0.6, 0.4)
  )

  se <- c(0.1, 0.12, 0.09)

  gt <- new_gt_object(data, se = se, n = 100)

  expect_equal(gt$data$se, se)
  expect_null(gt$phi)
})

test_that("new_gt_object validates required columns", {
  # Missing g
  expect_error(
    new_gt_object(data.frame(t = 1, tau_hat = 0.5)),
    "Missing: g"
  )

  # Missing t
  expect_error(
    new_gt_object(data.frame(g = 1, tau_hat = 0.5)),
    "Missing: t"
  )

  # Missing tau_hat
  expect_error(
    new_gt_object(data.frame(g = 1, t = 2)),
    "Missing: tau_hat"
  )
})

test_that("new_gt_object validates phi length", {
  data <- data.frame(
    g = c(1, 1, 2),
    t = c(2, 3, 3),
    tau_hat = c(0.5, 0.6, 0.4)
  )

  # Wrong number of EIF vectors
  phi <- list(rnorm(100), rnorm(100))  # 2 vectors, but 3 rows in data

  expect_error(
    new_gt_object(data, phi = phi),
    "phi has length 2 but data has 3 rows"
  )
})

test_that("new_gt_object validates phi vector lengths", {
  data <- data.frame(
    g = c(1, 1),
    t = c(2, 3),
    tau_hat = c(0.5, 0.6)
  )

  # Mismatched EIF vector lengths
  phi <- list(rnorm(100), rnorm(50))

  expect_error(
    new_gt_object(data, phi = phi),
    "All EIF vectors in phi must have the same length"
  )
})

test_that("new_gt_object validates se length", {
  data <- data.frame(
    g = c(1, 1, 2),
    t = c(2, 3, 3),
    tau_hat = c(0.5, 0.6, 0.4)
  )

  se <- c(0.1, 0.12)  # 2 values, but 3 rows

  expect_error(
    new_gt_object(data, se = se, n = 100),
    "se has length 2 but data has 3 rows"
  )
})

test_that("new_gt_object validates n against phi", {
  data <- data.frame(
    g = c(1, 1),
    t = c(2, 3),
    tau_hat = c(0.5, 0.6)
  )

  phi <- list(rnorm(100), rnorm(100))

  # n doesn't match phi length
  expect_error(
    new_gt_object(data, phi = phi, n = 50),
    "n = 50 does not match length of EIF vectors \\(100\\)"
  )
})

test_that("new_gt_object warns when no uncertainty quantification", {
  data <- data.frame(
    g = c(1, 1),
    t = c(2, 3),
    tau_hat = c(0.5, 0.6)
  )

  expect_warning(
    new_gt_object(data, n = 100),
    "No uncertainty quantification provided"
  )
})

test_that("new_gt_object warns when n not provided and phi is NULL", {
  data <- data.frame(
    g = c(1, 1),
    t = c(2, 3),
    tau_hat = c(0.5, 0.6)
  )

  expect_warning(
    gt <- new_gt_object(data),
    "Sample size n not provided"
  )

  expect_true(is.na(gt$n))
})

test_that("new_gt_object accepts metadata", {
  data <- data.frame(
    g = c(1, 1),
    t = c(2, 3),
    tau_hat = c(0.5, 0.6)
  )

  meta <- list(source = "custom", notes = "test data")

  gt <- new_gt_object(data, n = 100, meta = meta)

  expect_equal(gt$meta$source, "custom")
  expect_equal(gt$meta$notes, "test data")
})

test_that("new_gt_object accepts ids", {
  data <- data.frame(
    g = c(1, 1),
    t = c(2, 3),
    tau_hat = c(0.5, 0.6)
  )

  ids <- 1:100

  gt <- new_gt_object(data, n = 100, ids = ids)

  expect_equal(gt$ids, ids)
})

test_that("new_gt_object validates ids length", {
  data <- data.frame(
    g = c(1, 1),
    t = c(2, 3),
    tau_hat = c(0.5, 0.6)
  )

  ids <- 1:50

  expect_error(
    new_gt_object(data, n = 100, ids = ids),
    "ids has length 50 but n = 100"
  )
})

test_that("new_gt_object validates input types", {
  # data must be data.frame
  expect_error(
    new_gt_object(list(g = 1, t = 2, tau_hat = 0.5)),
    "data must be a data.frame or tibble"
  )

  # phi must be list
  data <- data.frame(g = 1, t = 2, tau_hat = 0.5)
  expect_error(
    new_gt_object(data, phi = c(1, 2, 3)),
    "phi must be a list of EIF vectors"
  )
})

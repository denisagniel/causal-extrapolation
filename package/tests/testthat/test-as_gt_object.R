test_that("as_gt_object.gt_object validates and returns unchanged", {
  data <- data.frame(
    g = c(1, 1, 2),
    t = c(2, 3, 3),
    tau_hat = c(0.5, 0.6, 0.4)
  )

  gt <- new_gt_object(data, n = 100)

  # Should pass through unchanged
  gt2 <- as_gt_object(gt)

  expect_identical(gt2, gt)
})

test_that("as_gt_object.data.frame works with minimal inputs", {
  data <- data.frame(
    g = c(1, 1, 2, 2),
    t = c(2, 3, 3, 4),
    tau_hat = c(0.5, 0.6, 0.4, 0.5)
  )

  gt <- as_gt_object(data, n = 100)

  expect_s3_class(gt, "gt_object")
  expect_equal(gt$data$g, data$g)
  expect_equal(gt$data$tau_hat, data$tau_hat)
  expect_null(gt$phi)
  expect_equal(gt$n, 100)
  expect_equal(gt$meta$source, "manual (data.frame)")
})

test_that("as_gt_object.data.frame accepts phi", {
  data <- data.frame(
    g = c(1, 1, 2),
    t = c(2, 3, 3),
    tau_hat = c(0.5, 0.6, 0.4)
  )

  phi <- list(rnorm(100), rnorm(100), rnorm(100))

  gt <- as_gt_object(data, phi = phi, n = 100)

  expect_length(gt$phi, 3)
  expect_equal(length(gt$phi[[1]]), 100)
})

test_that("as_gt_object.data.frame accepts se", {
  data <- data.frame(
    g = c(1, 1, 2),
    t = c(2, 3, 3),
    tau_hat = c(0.5, 0.6, 0.4)
  )

  se <- c(0.1, 0.12, 0.09)

  gt <- as_gt_object(data, se = se, n = 100)

  expect_equal(gt$data$se, se)
  expect_null(gt$phi)
})

test_that("as_gt_object.data.frame accepts metadata", {
  data <- data.frame(
    g = c(1, 1),
    t = c(2, 3),
    tau_hat = c(0.5, 0.6)
  )

  meta <- list(source = "custom method", notes = "test")

  gt <- as_gt_object(data, n = 100, meta = meta)

  expect_equal(gt$meta$source, "custom method")
  expect_equal(gt$meta$notes, "test")
})

test_that("as_gt_object.data.frame adds default source if not in meta", {
  data <- data.frame(
    g = c(1, 1),
    t = c(2, 3),
    tau_hat = c(0.5, 0.6)
  )

  meta <- list(notes = "test")

  gt <- as_gt_object(data, n = 100, meta = meta)

  # Should NOT overwrite user's source
  expect_equal(gt$meta$notes, "test")
  # But if no source, should add default
  gt2 <- as_gt_object(data, n = 100, meta = list(other = "thing"))
  expect_equal(gt2$meta$source, "manual (data.frame)")
})

test_that("as_gt_object.default gives informative error", {
  # Test with unsupported class
  obj <- structure(list(x = 1), class = "unsupported_class")

  expect_error(
    as_gt_object(obj),
    "No method for converting class 'unsupported_class'"
  )

  expect_error(
    as_gt_object(obj),
    "Supported classes: AGGTEobj"
  )

  expect_error(
    as_gt_object(obj),
    "data.frame"
  )
})

test_that("as_gt_object dispatches correctly on class", {
  # Test S3 dispatch

  # data.frame
  df <- data.frame(g = 1, t = 2, tau_hat = 0.5)
  expect_s3_class(as_gt_object(df, n = 100), "gt_object")

  # gt_object
  gt <- new_gt_object(df, n = 100)
  expect_identical(as_gt_object(gt), gt)

  # Unsupported
  expect_error(as_gt_object(list(x = 1)), "No method")
})

test_that("as_gt_object validates inputs via new_gt_object", {
  # Missing required columns
  data <- data.frame(g = 1, t = 2)  # Missing tau_hat

  expect_error(
    as_gt_object(data, n = 100),
    "Missing: tau_hat"
  )

  # Invalid phi length
  data <- data.frame(g = c(1, 1), t = c(2, 3), tau_hat = c(0.5, 0.6))
  phi <- list(rnorm(100))  # Only 1 vector, but 2 rows

  expect_error(
    as_gt_object(data, phi = phi, n = 100),
    "phi has length 1 but data has 2 rows"
  )
})

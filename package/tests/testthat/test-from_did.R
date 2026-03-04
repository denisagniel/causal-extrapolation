test_that("as_gt_object.AGGTEobj extracts basic structure", {
  # Create mock did::att_gt object
  mock_did <- structure(
    list(
      group = c(1, 1, 2, 2),
      t = c(2, 3, 3, 4),
      att = c(0.5, 0.6, 0.4, 0.5),
      se = c(0.1, 0.12, 0.09, 0.11),
      inffunc = NULL  # No EIF for this test
    ),
    class = "AGGTEobj"
  )

  expect_warning(
    gt <- as_gt_object(mock_did, extract_eif = TRUE),
    "x\\$inffunc is NULL"
  )

  expect_s3_class(gt, "gt_object")
  expect_equal(gt$data$g, c(1, 1, 2, 2))
  expect_equal(gt$data$t, c(2, 3, 3, 4))
  expect_equal(gt$data$k, c(1, 2, 1, 2))
  expect_equal(gt$data$tau_hat, c(0.5, 0.6, 0.4, 0.5))
  expect_equal(gt$data$se, c(0.1, 0.12, 0.09, 0.11))
  expect_null(gt$phi)
  expect_equal(gt$meta$source, "did::att_gt")
})

test_that("as_gt_object.AGGTEobj extracts EIFs", {
  # Create mock did::att_gt object with EIF
  n <- 100
  J <- 3  # 3 group-time pairs

  mock_did <- structure(
    list(
      group = c(1, 1, 2),
      t = c(2, 3, 3),
      att = c(0.5, 0.6, 0.4),
      se = c(0.1, 0.12, 0.09),
      inffunc = matrix(rnorm(n * J), nrow = n, ncol = J)
    ),
    class = "AGGTEobj"
  )

  gt <- as_gt_object(mock_did, extract_eif = TRUE)

  expect_s3_class(gt, "gt_object")
  expect_length(gt$phi, 3)  # 3 group-time pairs
  expect_equal(length(gt$phi[[1]]), 100)  # n = 100
  expect_equal(length(gt$phi[[2]]), 100)
  expect_equal(length(gt$phi[[3]]), 100)
  expect_equal(gt$n, 100)
})

test_that("as_gt_object.AGGTEobj skips EIF extraction when extract_eif = FALSE", {
  mock_did <- structure(
    list(
      group = c(1, 1),
      t = c(2, 3),
      att = c(0.5, 0.6),
      se = c(0.1, 0.12),
      inffunc = matrix(rnorm(100 * 2), nrow = 100, ncol = 2)
    ),
    class = "AGGTEobj"
  )

  gt <- as_gt_object(mock_did, extract_eif = FALSE)

  expect_null(gt$phi)
  expect_true(is.na(gt$n) || is.null(gt$n))
})

test_that("as_gt_object.AGGTEobj validates dimension mismatch", {
  # inffunc has wrong number of columns
  mock_did <- structure(
    list(
      group = c(1, 1, 2),  # 3 group-time pairs
      t = c(2, 3, 3),
      att = c(0.5, 0.6, 0.4),
      inffunc = matrix(rnorm(100 * 2), nrow = 100, ncol = 2)  # Only 2 columns!
    ),
    class = "AGGTEobj"
  )

  expect_error(
    as_gt_object(mock_did, extract_eif = TRUE),
    "Dimension mismatch.*inffunc has 2 columns.*3 group-time pairs"
  )
})

test_that("as_gt_object.AGGTEobj rejects aggte output", {
  # Mock did::aggte object (no 'group' field)
  mock_aggte <- structure(
    list(
      overall.att = 0.5,
      overall.se = 0.1
      # No 'group' field - this is aggte, not att_gt
    ),
    class = "AGGTEobj"
  )

  expect_error(
    as_gt_object(mock_aggte),
    "x must be output from did::att_gt\\(\\), not did::aggte\\(\\)"
  )
})

test_that("as_gt_object.AGGTEobj validates class", {
  # Not an AGGTEobj
  mock_obj <- list(
    group = c(1, 1),
    t = c(2, 3),
    att = c(0.5, 0.6)
  )

  expect_error(
    as_gt_object.AGGTEobj(mock_obj),
    "Expected class 'AGGTEobj'"
  )
})

test_that("as_gt_object.AGGTEobj stores original object in meta", {
  mock_did <- structure(
    list(
      group = c(1, 1),
      t = c(2, 3),
      att = c(0.5, 0.6),
      se = c(0.1, 0.12),
      inffunc = NULL
    ),
    class = "AGGTEobj"
  )

  suppressWarnings(
    gt <- as_gt_object(mock_did)
  )

  expect_equal(gt$meta$source, "did::att_gt")
  expect_identical(gt$meta$did_object, mock_did)
  expect_true("did_version" %in% names(gt$meta))
})

test_that("as_gt_object.AGGTEobj handles missing se", {
  mock_did <- structure(
    list(
      group = c(1, 1),
      t = c(2, 3),
      att = c(0.5, 0.6),
      se = NULL,  # No SE
      inffunc = NULL
    ),
    class = "AGGTEobj"
  )

  suppressWarnings(
    gt <- as_gt_object(mock_did)
  )

  expect_false("se" %in% names(gt$data))
})

test_that("as_gt_object.AGGTEobj computes event time correctly", {
  mock_did <- structure(
    list(
      group = c(2010, 2010, 2011),
      t = c(2012, 2013, 2012),
      att = c(0.5, 0.6, 0.4),
      inffunc = NULL
    ),
    class = "AGGTEobj"
  )

  suppressWarnings(
    gt <- as_gt_object(mock_did)
  )

  expect_equal(gt$data$k, c(2, 3, 1))
  expect_equal(gt$event_times, c(1, 2, 3))
})

test_that("did_extract_gt is deprecated but still works", {
  mock_did <- structure(
    list(
      group = c(1, 1),
      t = c(2, 3),
      att = c(0.5, 0.6),
      inffunc = matrix(rnorm(100 * 2), nrow = 100, ncol = 2)
    ),
    class = "AGGTEobj"
  )

  expect_warning(
    result <- did_extract_gt(mock_did),
    "deprecated"
  )

  expect_true(is.list(result))
  expect_true("data" %in% names(result))
  expect_true("phi" %in% names(result))
  expect_s3_class(result$data, "tbl_df")
  expect_equal(nrow(result$data), 2)
  expect_length(result$phi, 2)
})

test_that("as_gt_object.AGGTEobj integration with downstream functions", {
  # Create realistic mock
  set.seed(123)
  n <- 50
  J <- 4

  mock_did <- structure(
    list(
      group = c(1, 1, 2, 2),
      t = c(2, 3, 3, 4),
      att = c(0.5, 0.6, 0.4, 0.5),
      se = c(0.1, 0.12, 0.09, 0.11),
      inffunc = matrix(rnorm(n * J), nrow = n, ncol = J)
    ),
    class = "AGGTEobj"
  )

  gt <- as_gt_object(mock_did)

  # Should pass validation
  expect_silent(validate_gt_object(gt))

  # Should have correct structure for downstream use
  expect_true(all(c("data", "phi", "times", "groups", "event_times", "n") %in% names(gt)))
  expect_equal(nrow(gt$data), length(gt$phi))
  expect_equal(gt$n, n)
})

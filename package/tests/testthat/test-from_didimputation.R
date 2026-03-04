test_that("as_gt_object.did_imputation validates input", {
  # Not a data.frame
  expect_error(
    as_gt_object.did_imputation(list(x = 1)),
    "must be a data.frame"
  )
})

test_that("as_gt_object.did_imputation requires horizon results", {
  # Missing required columns
  mock_result <- data.frame(x = 1, y = 2)

  expect_error(
    as_gt_object.did_imputation(mock_result),
    "missing columns"
  )
})

test_that("as_gt_object.did_imputation requires cohort_timing", {
  # Valid didimputation output but no cohort_timing
  mock_result <- data.frame(
    term = c("0", "1", "2"),
    estimate = c(0.5, 0.6, 0.7),
    std.error = c(0.1, 0.12, 0.14)
  )

  expect_error(
    as_gt_object.did_imputation(mock_result),
    "cohort_timing is required"
  )
})

test_that("as_gt_object.did_imputation works with single cohort", {
  # Mock didimputation output (horizon = TRUE)
  mock_result <- data.frame(
    term = c("0", "1", "2", "3"),
    estimate = c(0.5, 0.6, 0.7, 0.8),
    std.error = c(0.1, 0.12, 0.14, 0.16),
    stringsAsFactors = FALSE
  )

  # Convert (single cohort)
  suppressMessages(
    gt_obj <- as_gt_object.did_imputation(
      mock_result,
      cohort_timing = 2010,
      base_time = 2010
    )
  )

  expect_s3_class(gt_obj, "gt_object")
  expect_equal(nrow(gt_obj$data), 4)
  expect_equal(gt_obj$data$g, rep(2010, 4))
  expect_equal(gt_obj$data$t, c(2010, 2011, 2012, 2013))
  expect_equal(gt_obj$data$k, c(0, 1, 2, 3))
  expect_equal(gt_obj$data$tau_hat, c(0.5, 0.6, 0.7, 0.8))
  expect_equal(gt_obj$data$se, c(0.1, 0.12, 0.14, 0.16))
  expect_equal(gt_obj$meta$source, "didimputation")
})

test_that("as_gt_object.did_imputation infers base_time from cohort", {
  mock_result <- data.frame(
    term = c("0", "1"),
    estimate = c(0.5, 0.6),
    std.error = c(0.1, 0.12),
    stringsAsFactors = FALSE
  )

  # Don't provide base_time
  expect_message(
    gt_obj <- as_gt_object.did_imputation(mock_result, cohort_timing = 2010),
    "Assuming base_time = 2010"
  )

  expect_equal(gt_obj$data$t, c(2010, 2011))
})

test_that("as_gt_object.did_imputation works with multiple cohorts", {
  mock_result <- data.frame(
    term = c("0", "1", "2"),
    estimate = c(0.5, 0.6, 0.7),
    std.error = c(0.1, 0.12, 0.14),
    stringsAsFactors = FALSE
  )

  cohort_info <- data.frame(
    cohort = c(2010, 2011),
    first_treat_time = c(2010, 2011)
  )

  suppressMessages(
    gt_obj <- as_gt_object.did_imputation(
      mock_result,
      cohort_timing = cohort_info
    )
  )

  expect_s3_class(gt_obj, "gt_object")
  expect_equal(nrow(gt_obj$data), 6)  # 3 event times × 2 cohorts
  expect_equal(unique(gt_obj$data$g), c(2010, 2011))

  # Check first cohort
  cohort1 <- gt_obj$data[gt_obj$data$g == 2010, ]
  expect_equal(cohort1$t, c(2010, 2011, 2012))
  expect_equal(cohort1$tau_hat, c(0.5, 0.6, 0.7))

  # Check second cohort
  cohort2 <- gt_obj$data[gt_obj$data$g == 2011, ]
  expect_equal(cohort2$t, c(2011, 2012, 2013))
  expect_equal(cohort2$tau_hat, c(0.5, 0.6, 0.7))
})

test_that("as_gt_object.did_imputation handles no EIF", {
  mock_result <- data.frame(
    term = c("0", "1"),
    estimate = c(0.5, 0.6),
    std.error = c(0.1, 0.12),
    stringsAsFactors = FALSE
  )

  suppressMessages(
    gt_obj <- as_gt_object.did_imputation(
      mock_result,
      cohort_timing = 2010
    )
  )

  expect_null(gt_obj$phi)
  expect_true("se" %in% names(gt_obj$data))
})

test_that("as_gt_object.did_imputation stores metadata", {
  mock_result <- data.frame(
    term = c("0", "1"),
    estimate = c(0.5, 0.6),
    std.error = c(0.1, 0.12),
    stringsAsFactors = FALSE
  )

  suppressMessages(
    gt_obj <- as_gt_object.did_imputation(
      mock_result,
      cohort_timing = 2010
    )
  )

  expect_equal(gt_obj$meta$source, "didimputation")
  expect_equal(gt_obj$meta$method, "Borusyak, Jaravel, & Spiess (2021)")
  expect_true(!is.null(gt_obj$meta$event_study_original))
})

test_that("as_gt_object.did_imputation filters non-numeric terms", {
  # didimputation sometimes includes "treat" term
  mock_result <- data.frame(
    term = c("treat", "0", "1", "2"),
    estimate = c(0.55, 0.5, 0.6, 0.7),
    std.error = c(0.11, 0.1, 0.12, 0.14),
    stringsAsFactors = FALSE
  )

  suppressMessages(
    gt_obj <- as_gt_object.did_imputation(
      mock_result,
      cohort_timing = 2010
    )
  )

  # Should only include numeric event times (0, 1, 2)
  expect_equal(nrow(gt_obj$data), 3)
  expect_equal(gt_obj$data$k, c(0, 1, 2))
})

test_that("as_gt_object.did_imputation validates cohort_timing format", {
  mock_result <- data.frame(
    term = c("0", "1"),
    estimate = c(0.5, 0.6),
    std.error = c(0.1, 0.12),
    stringsAsFactors = FALSE
  )

  # Invalid cohort_timing (not scalar or data.frame)
  expect_error(
    as_gt_object.did_imputation(mock_result, cohort_timing = c(2010, 2011)),
    "must be either"
  )
})

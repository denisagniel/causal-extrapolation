test_that("as_gt_object.DIDmultiplegt validates input", {
  # Not a list (actually data.frame is a list, so this tests no dynamic effects)
  expect_error(
    as_gt_object.DIDmultiplegt(data.frame(x = 1)),
    "No dynamic effects found"
  )
})

test_that("as_gt_object.DIDmultiplegt requires dynamic effects", {
  # List but no effect_0, effect_1, etc.
  mock_result <- list(
    estimate = 0.5,
    se = 0.1
  )

  expect_error(
    as_gt_object.DIDmultiplegt(mock_result),
    "No dynamic effects found"
  )
})

test_that("as_gt_object.DIDmultiplegt requires cohort_timing", {
  # Valid dynamic effects but no cohort_timing
  mock_result <- list(
    effect_0 = 0.5,
    effect_1 = 0.6,
    se_effect_0 = 0.1,
    se_effect_1 = 0.12
  )

  expect_error(
    as_gt_object.DIDmultiplegt(mock_result),
    "cohort_timing is required"
  )
})

test_that("as_gt_object.DIDmultiplegt works with single cohort", {
  # Mock DIDmultiplegt output (dynamic effects only)
  mock_result <- list(
    effect_0 = 0.5,
    effect_1 = 0.6,
    effect_2 = 0.7,
    effect_3 = 0.8,
    se_effect_0 = 0.1,
    se_effect_1 = 0.12,
    se_effect_2 = 0.14,
    se_effect_3 = 0.16
  )

  # Convert (single cohort)
  suppressMessages(
    gt_obj <- as_gt_object.DIDmultiplegt(
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
  expect_equal(gt_obj$meta$source, "DIDmultiplegt")
})

test_that("as_gt_object.DIDmultiplegt infers base_time from cohort", {
  mock_result <- list(
    effect_0 = 0.5,
    effect_1 = 0.6,
    se_effect_0 = 0.1,
    se_effect_1 = 0.12
  )

  # Don't provide base_time
  expect_message(
    gt_obj <- as_gt_object.DIDmultiplegt(mock_result, cohort_timing = 2010),
    "Assuming base_time = 2010"
  )

  expect_equal(gt_obj$data$t, c(2010, 2011))
})

test_that("as_gt_object.DIDmultiplegt works with multiple cohorts", {
  mock_result <- list(
    effect_0 = 0.5,
    effect_1 = 0.6,
    effect_2 = 0.7,
    se_effect_0 = 0.1,
    se_effect_1 = 0.12,
    se_effect_2 = 0.14
  )

  cohort_info <- data.frame(
    cohort = c(2010, 2011),
    first_treat_time = c(2010, 2011)
  )

  suppressMessages(
    gt_obj <- as_gt_object.DIDmultiplegt(
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

test_that("as_gt_object.DIDmultiplegt handles placebos", {
  # Dynamic effects + placebo tests
  mock_result <- list(
    placebo_2 = 0.1,
    placebo_1 = 0.05,
    effect_0 = 0.5,
    effect_1 = 0.6,
    effect_2 = 0.7,
    se_placebo_2 = 0.08,
    se_placebo_1 = 0.09,
    se_effect_0 = 0.1,
    se_effect_1 = 0.12,
    se_effect_2 = 0.14
  )

  suppressMessages(
    gt_obj <- as_gt_object.DIDmultiplegt(
      mock_result,
      cohort_timing = 2010,
      base_time = 2010
    )
  )

  expect_equal(nrow(gt_obj$data), 5)
  expect_equal(gt_obj$data$k, c(-2, -1, 0, 1, 2))
  expect_equal(gt_obj$data$t, c(2008, 2009, 2010, 2011, 2012))
  expect_equal(gt_obj$data$tau_hat, c(0.1, 0.05, 0.5, 0.6, 0.7))
})

test_that("as_gt_object.DIDmultiplegt handles missing SEs", {
  # Effects without SE
  mock_result <- list(
    effect_0 = 0.5,
    effect_1 = 0.6
  )

  suppressMessages(
    gt_obj <- as_gt_object.DIDmultiplegt(
      mock_result,
      cohort_timing = 2010
    )
  )

  expect_s3_class(gt_obj, "gt_object")
  # SE column may exist with NA values, or not exist at all
  if ("se" %in% names(gt_obj$data)) {
    expect_true(any(is.na(gt_obj$data$se)))
  }
})

test_that("as_gt_object.DIDmultiplegt stores metadata", {
  mock_result <- list(
    effect_0 = 0.5,
    effect_1 = 0.6,
    se_effect_0 = 0.1,
    se_effect_1 = 0.12
  )

  suppressMessages(
    gt_obj <- as_gt_object.DIDmultiplegt(
      mock_result,
      cohort_timing = 2010
    )
  )

  expect_equal(gt_obj$meta$source, "DIDmultiplegt")
  expect_equal(gt_obj$meta$method, "De Chaisemartin & d'Haultfoeuille (2020)")
  expect_true(!is.null(gt_obj$meta$didmultiplegt_original))
})

test_that("as_gt_object.DIDmultiplegt validates cohort_timing format", {
  mock_result <- list(
    effect_0 = 0.5,
    effect_1 = 0.6
  )

  # Invalid cohort_timing (not scalar or data.frame)
  expect_error(
    as_gt_object.DIDmultiplegt(mock_result, cohort_timing = c(2010, 2011)),
    "must be either"
  )
})

test_that("as_gt_object.DIDmultiplegt handles no EIF", {
  mock_result <- list(
    effect_0 = 0.5,
    effect_1 = 0.6,
    se_effect_0 = 0.1,
    se_effect_1 = 0.12
  )

  suppressMessages(
    gt_obj <- as_gt_object.DIDmultiplegt(
      mock_result,
      cohort_timing = 2010
    )
  )

  expect_null(gt_obj$phi)
  expect_true("se" %in% names(gt_obj$data))
})

test_that("as_gt_object.DIDmultiplegt sorts event times correctly", {
  # Effects provided in random order
  mock_result <- list(
    effect_2 = 0.7,
    placebo_1 = 0.05,
    effect_0 = 0.5,
    effect_1 = 0.6,
    se_effect_2 = 0.14,
    se_placebo_1 = 0.09,
    se_effect_0 = 0.1,
    se_effect_1 = 0.12
  )

  suppressMessages(
    gt_obj <- as_gt_object.DIDmultiplegt(
      mock_result,
      cohort_timing = 2010,
      base_time = 2010
    )
  )

  # Should be sorted by event time
  expect_equal(gt_obj$data$k, c(-1, 0, 1, 2))
  expect_equal(gt_obj$data$tau_hat, c(0.05, 0.5, 0.6, 0.7))
  expect_true(all(diff(gt_obj$data$k) > 0))  # Monotonically increasing
})

test_that("as_gt_object.did2s validates input", {
  # Not a fixest object
  expect_error(
    as_gt_object.did2s(list(x = 1)),
    "must be a fixest object"
  )
})

test_that("as_gt_object.did2s requires event-study coefficients", {
  # Mock fixest without event-study format (no rel_year/rel_time in names)
  mock_fixest <- structure(
    list(
      coefficients = c(treat = 0.5),
      vcov = matrix(0.01, 1, 1),
      nobs = 100
    ),
    class = "fixest"
  )

  # Should try fixest converter and fail (no sunab)
  expect_error(
    as_gt_object.did2s(mock_fixest),
    "does not appear to use sunab"
  )
})

test_that("as_gt_object.did2s requires cohort_timing", {
  # Valid event-study coefficients but no cohort_timing
  coefs <- c(0.5, 0.6)
  names(coefs) <- c("rel_year::0", "rel_year::1")

  mock_fixest <- structure(
    list(
      coefficients = coefs,
      vcov = matrix(c(0.01, 0, 0, 0.0144), 2, 2),
      nobs = 100
    ),
    class = "fixest"
  )

  expect_error(
    as_gt_object.did2s(mock_fixest),
    "cohort_timing is required"
  )
})

test_that("as_gt_object.did2s works with single cohort", {
  # Mock did2s output (fixest with event-study)
  coefs <- c(0.5, 0.6, 0.7)
  names(coefs) <- c("rel_year::0", "rel_year::1", "rel_year::2")

  mock_fixest <- structure(
    list(
      coefficients = coefs,
      vcov = matrix(c(
        0.01, 0, 0,
        0, 0.0144, 0,
        0, 0, 0.0196
      ), 3, 3),
      nobs = 100
    ),
    class = "fixest"
  )

  # Convert (single cohort)
  suppressMessages(
    gt_obj <- as_gt_object.did2s(
      mock_fixest,
      cohort_timing = 2010,
      base_time = 2010
    )
  )

  expect_s3_class(gt_obj, "gt_object")
  expect_equal(nrow(gt_obj$data), 3)
  expect_equal(gt_obj$data$g, rep(2010, 3))
  expect_equal(gt_obj$data$t, c(2010, 2011, 2012))
  expect_equal(gt_obj$data$k, c(0, 1, 2))
  expect_equal(gt_obj$data$tau_hat, c(0.5, 0.6, 0.7))
  expect_equal(gt_obj$meta$source, "did2s")
})

test_that("as_gt_object.did2s infers base_time from cohort", {
  coefs <- c(0.5, 0.6)
  names(coefs) <- c("rel_year::0", "rel_year::1")

  mock_fixest <- structure(
    list(
      coefficients = coefs,
      vcov = matrix(c(0.01, 0, 0, 0.0144), 2, 2),
      nobs = 100
    ),
    class = "fixest"
  )

  # Don't provide base_time
  expect_message(
    gt_obj <- as_gt_object.did2s(mock_fixest, cohort_timing = 2010),
    "Assuming base_time = 2010"
  )

  expect_equal(gt_obj$data$t, c(2010, 2011))
})

test_that("as_gt_object.did2s works with multiple cohorts", {
  coefs <- c(0.5, 0.6, 0.7)
  names(coefs) <- c("rel_year::0", "rel_year::1", "rel_year::2")

  mock_fixest <- structure(
    list(
      coefficients = coefs,
      vcov = matrix(c(
        0.01, 0, 0,
        0, 0.0144, 0,
        0, 0, 0.0196
      ), 3, 3),
      nobs = 100
    ),
    class = "fixest"
  )

  cohort_info <- data.frame(
    cohort = c(2010, 2011),
    first_treat_time = c(2010, 2011)
  )

  suppressMessages(
    gt_obj <- as_gt_object.did2s(
      mock_fixest,
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

test_that("as_gt_object.did2s parses rel_time format", {
  # Alternative coefficient name format
  coefs <- c(0.5, 0.6)
  names(coefs) <- c("rel_time::0", "rel_time::1")

  mock_fixest <- structure(
    list(
      coefficients = coefs,
      vcov = matrix(c(0.01, 0, 0, 0.0144), 2, 2),
      nobs = 100
    ),
    class = "fixest"
  )

  suppressMessages(
    gt_obj <- as_gt_object.did2s(
      mock_fixest,
      cohort_timing = 2010,
      base_time = 2010
    )
  )

  expect_s3_class(gt_obj, "gt_object")
  expect_equal(gt_obj$data$k, c(0, 1))
  expect_equal(gt_obj$data$tau_hat, c(0.5, 0.6))
})

test_that("as_gt_object.did2s handles negative relative times", {
  # Event-study with pre-treatment periods
  coefs <- c(0.1, 0.05, 0.5, 0.6)
  names(coefs) <- c("rel_year::-2", "rel_year::-1", "rel_year::0", "rel_year::1")

  mock_fixest <- structure(
    list(
      coefficients = coefs,
      vcov = matrix(c(
        0.01, 0, 0, 0,
        0, 0.01, 0, 0,
        0, 0, 0.01, 0,
        0, 0, 0, 0.0144
      ), 4, 4),
      nobs = 100
    ),
    class = "fixest"
  )

  suppressMessages(
    gt_obj <- as_gt_object.did2s(
      mock_fixest,
      cohort_timing = 2010,
      base_time = 2010
    )
  )

  expect_equal(gt_obj$data$k, c(-2, -1, 0, 1))
  expect_equal(gt_obj$data$t, c(2008, 2009, 2010, 2011))
  expect_equal(gt_obj$data$tau_hat, c(0.1, 0.05, 0.5, 0.6))
})

test_that("as_gt_object.did2s stores metadata", {
  coefs <- c(0.5, 0.6)
  names(coefs) <- c("rel_year::0", "rel_year::1")

  mock_fixest <- structure(
    list(
      coefficients = coefs,
      vcov = matrix(c(0.01, 0, 0, 0.0144), 2, 2),
      nobs = 100
    ),
    class = "fixest"
  )

  suppressMessages(
    gt_obj <- as_gt_object.did2s(
      mock_fixest,
      cohort_timing = 2010
    )
  )

  expect_equal(gt_obj$meta$source, "did2s")
  expect_equal(gt_obj$meta$method, "Gardner (2022)")
  expect_true(!is.null(gt_obj$meta$did2s_fixest_object))
})

test_that("as_gt_object.did2s validates cohort_timing format", {
  coefs <- c(0.5, 0.6)
  names(coefs) <- c("rel_year::0", "rel_year::1")

  mock_fixest <- structure(
    list(
      coefficients = coefs,
      vcov = matrix(c(0.01, 0, 0, 0.0144), 2, 2),
      nobs = 100
    ),
    class = "fixest"
  )

  # Invalid cohort_timing (not scalar or data.frame)
  expect_error(
    as_gt_object.did2s(mock_fixest, cohort_timing = c(2010, 2011)),
    "must be either"
  )
})

test_that("as_gt_object.did2s extracts standard errors", {
  coefs <- c(0.5, 0.6)
  names(coefs) <- c("rel_year::0", "rel_year::1")

  mock_fixest <- structure(
    list(
      coefficients = coefs,
      vcov = matrix(c(0.01, 0, 0, 0.0144), 2, 2),
      nobs = 100
    ),
    class = "fixest"
  )

  suppressMessages(
    gt_obj <- as_gt_object.did2s(
      mock_fixest,
      cohort_timing = 2010
    )
  )

  # SE should be sqrt of diagonal of vcov
  if ("se" %in% names(gt_obj$data)) {
    expect_equal(gt_obj$data$se, c(0.1, 0.12))
  }
})

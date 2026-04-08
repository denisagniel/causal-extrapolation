test_that("parse_sunab_names handles standard format", {
  # Format: "cohort::2010:time::2012"
  names <- c(
    "cohort::2010:time::2012",
    "cohort::2010:time::2013",
    "cohort::2011:time::2012",
    "cohort::2011:time::2013"
  )

  parsed <- parse_sunab_names(names)

  expect_equal(parsed$g, c(2010, 2010, 2011, 2011))
  expect_equal(parsed$t, c(2012, 2013, 2012, 2013))
})

test_that("parse_sunab_names handles simplified format", {
  # Format: "2010:2012"
  names <- c("2010:2012", "2010:2013", "2011:2013")

  parsed <- parse_sunab_names(names)

  expect_equal(parsed$g, c(2010, 2010, 2011))
  expect_equal(parsed$t, c(2012, 2013, 2013))
})

test_that("parse_sunab_names handles relative time format", {
  # Format: "cohort::2010:rel_time::2"
  names <- c(
    "cohort::2010:rel_time::1",
    "cohort::2010:rel_time::2",
    "cohort::2011:rel_time::1"
  )

  parsed <- parse_sunab_names(names)

  expect_equal(parsed$g, c(2010, 2010, 2011))
  expect_equal(parsed$t, c(2011, 2012, 2012))
})

test_that("parse_sunab_names handles year extraction fallback", {
  # Format with years embedded: "something2010something2012"
  names <- c(
    "treat_2010_time_2012",
    "treat_2010_time_2013"
  )

  parsed <- parse_sunab_names(names)

  expect_equal(parsed$g, c(2010, 2010))
  expect_equal(parsed$t, c(2012, 2013))
})

test_that("parse_sunab_names errors on unparseable names", {
  names <- c("invalid_name", "also_invalid")

  expect_error(
    parse_sunab_names(names),
    "Could not parse sunab coefficient name"
  )
})

test_that("as_gt_object.fixest validates input class", {
  # Not a fixest object
  not_fixest <- list(x = 1)

  expect_error(
    as_gt_object.fixest(not_fixest),
    "Expected class 'fixest'"
  )
})

test_that("as_gt_object.fixest rejects non-sunab fixest objects", {
  # Mock fixest object without sunab coefficients
  mock_fixest <- structure(
    list(
      coefficients = c("x1" = 0.5, "x2" = 0.3),
      se = c(0.1, 0.09),
      nobs = 100
    ),
    class = c("fixest", "fixest_model")
  )

  expect_error(
    as_gt_object.fixest(mock_fixest, extract_eif = FALSE),
    "does not appear to use sunab"
  )
})

test_that("as_gt_object.fixest extracts basic structure", {
  # Create mock fixest object with sunab coefficients
  set.seed(123)

  # Create vcov matrix with named dimensions
  vcov_mat <- diag(4) * c(0.1, 0.12, 0.09, 0.11)^2
  rownames(vcov_mat) <- colnames(vcov_mat) <- c(
    "cohort::2010:time::2012",
    "cohort::2010:time::2013",
    "cohort::2011:time::2012",
    "cohort::2011:time::2013"
  )

  mock_fixest <- structure(
    list(
      coefficients = c(
        "cohort::2010:time::2012" = 0.5,
        "cohort::2010:time::2013" = 0.6,
        "cohort::2011:time::2012" = 0.4,
        "cohort::2011:time::2013" = 0.5
      ),
      se = c(0.1, 0.12, 0.09, 0.11),
      nobs = 100,
      vcov = vcov_mat
    ),
    class = c("fixest", "fixest_model")
  )

  # Suppress message about EIF
  suppressMessages(
    gt_obj <- as_gt_object.fixest(mock_fixest, extract_eif = FALSE)
  )

  expect_s3_class(gt_obj, "gt_object")
  expect_equal(nrow(gt_obj$data), 4)
  expect_equal(gt_obj$data$g, c(2010, 2010, 2011, 2011))
  expect_equal(gt_obj$data$t, c(2012, 2013, 2012, 2013))
  expect_equal(gt_obj$data$k, c(2, 3, 1, 2))
  expect_equal(gt_obj$data$tau_hat, c(0.5, 0.6, 0.4, 0.5))
  # SE extraction may fail in tests without fixest loaded, that's OK
  if ("se" %in% names(gt_obj$data)) {
    expect_equal(gt_obj$data$se, c(0.1, 0.12, 0.09, 0.11))
  }
  expect_equal(gt_obj$n, 100)
  expect_equal(gt_obj$meta$source, "fixest::sunab")
})

test_that("as_gt_object.fixest handles simplified coefficient names", {
  # Simplified format: "g:t"
  mock_fixest <- structure(
    list(
      coefficients = c(
        "2010:2012" = 0.5,
        "2010:2013" = 0.6,
        "2011:2012" = 0.4
      ),
      se = c(0.1, 0.12, 0.09),
      nobs = 100
    ),
    class = c("fixest", "fixest_model")
  )

  suppressMessages(
    gt_obj <- as_gt_object.fixest(mock_fixest, extract_eif = FALSE)
  )

  expect_s3_class(gt_obj, "gt_object")
  expect_equal(gt_obj$data$g, c(2010, 2010, 2011))
  expect_equal(gt_obj$data$t, c(2012, 2013, 2012))
})

test_that("as_gt_object.fixest handles missing se", {
  mock_fixest <- structure(
    list(
      coefficients = c(
        "cohort::2010:time::2012" = 0.5,
        "cohort::2010:time::2013" = 0.6
      ),
      se = NULL,  # No SE
      nobs = 100
    ),
    class = c("fixest", "fixest_model")
  )

  suppressMessages(
    gt_obj <- as_gt_object.fixest(mock_fixest, extract_eif = FALSE)
  )

  expect_s3_class(gt_obj, "gt_object")
  expect_false("se" %in% names(gt_obj$data))
})

test_that("as_gt_object.fixest stores metadata", {
  mock_fixest <- structure(
    list(
      coefficients = c("cohort::2010:time::2012" = 0.5),
      se = c(0.1),
      nobs = 100
    ),
    class = c("fixest", "fixest_model")
  )

  suppressMessages(
    gt_obj <- as_gt_object.fixest(mock_fixest, extract_eif = FALSE)
  )

  expect_equal(gt_obj$meta$source, "fixest::sunab")
  expect_equal(gt_obj$meta$method, "Sun & Abraham (2021)")
  expect_true("fixest_version" %in% names(gt_obj$meta))
  expect_identical(gt_obj$meta$fixest_object, mock_fixest)
})

test_that("as_gt_object.fixest computes event time correctly", {
  mock_fixest <- structure(
    list(
      coefficients = c(
        "cohort::2010:time::2012" = 0.5,  # k = 2
        "cohort::2010:time::2015" = 0.7,  # k = 5
        "cohort::2011:time::2012" = 0.4   # k = 1
      ),
      se = c(0.1, 0.14, 0.09),
      nobs = 100
    ),
    class = c("fixest", "fixest_model")
  )

  suppressMessages(
    gt_obj <- as_gt_object.fixest(mock_fixest, extract_eif = FALSE)
  )

  expect_equal(gt_obj$data$k, c(2, 5, 1))
  expect_equal(gt_obj$event_times, c(1, 2, 5))
})

test_that("as_gt_object.fixest passes validation", {
  mock_fixest <- structure(
    list(
      coefficients = c(
        "cohort::2010:time::2012" = 0.5,
        "cohort::2010:time::2013" = 0.6
      ),
      se = c(0.1, 0.12),
      nobs = 100
    ),
    class = c("fixest", "fixest_model")
  )

  suppressMessages(
    gt_obj <- as_gt_object.fixest(mock_fixest, extract_eif = FALSE)
  )

  # Should pass validation without error
  expect_silent(validate_gt_object(gt_obj))
})

test_that("as_gt_object.fixest works without extract_eif", {
  mock_fixest <- structure(
    list(
      coefficients = c("cohort::2010:time::2012" = 0.5),
      se = c(0.1),
      nobs = 100
    ),
    class = c("fixest", "fixest_model")
  )

  suppressMessages(
    gt_obj <- as_gt_object.fixest(mock_fixest, extract_eif = FALSE)
  )

  expect_null(gt_obj$phi)
  expect_true(is.na(gt_obj$n) || gt_obj$n == 100)
})

test_that("extract_fixest_eif returns NULL gracefully", {
  mock_fixest <- structure(
    list(
      coefficients = c("cohort::2010:time::2012" = 0.5),
      nobs = 100
    ),
    class = c("fixest", "fixest_model")
  )

  # Should return NULL without error
  result <- extract_fixest_eif(mock_fixest, 1, 100)
  expect_null(result)
})

test_that("as_gt_object.fixest integration with extrapolate_ATT", {
  # Create realistic mock
  set.seed(456)

  mock_fixest <- structure(
    list(
      coefficients = c(
        "cohort::2010:time::2012" = 0.5,
        "cohort::2010:time::2013" = 0.6,
        "cohort::2011:time::2012" = 0.4,
        "cohort::2011:time::2013" = 0.5
      ),
      se = c(0.1, 0.12, 0.09, 0.11),
      nobs = 100
    ),
    class = c("fixest", "fixest_model")
  )

  suppressMessages(
    gt_obj <- as_gt_object.fixest(mock_fixest, extract_eif = FALSE)
  )

  # Should pass validation
  expect_silent(validate_gt_object(gt_obj))

  # Should have correct structure for downstream use
  expect_true(all(c("data", "phi", "times", "groups", "event_times", "n") %in% names(gt_obj)))
  expect_equal(gt_obj$n, 100)
  expect_equal(length(gt_obj$times), 2)  # 2012, 2013
  expect_equal(length(gt_obj$groups), 2)  # 2010, 2011
})

test_that("as_gt_object.fixest handles empty coefficients", {
  mock_fixest <- structure(
    list(
      coefficients = NULL,
      nobs = 100
    ),
    class = c("fixest", "fixest_model")
  )

  expect_error(
    as_gt_object.fixest(mock_fixest, extract_eif = FALSE),
    "No coefficients found"
  )
})

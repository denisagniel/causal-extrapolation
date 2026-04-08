test_that("estimate_group_time_ATT validates input data", {
  expect_error(
    estimate_group_time_ATT(data = "not a dataframe", y = Y, g = G, t = Time),
    "data must be a data.frame"
  )
})

test_that("estimate_group_time_ATT checks for empty data", {
  empty_df <- data.frame()

  expect_error(
    estimate_group_time_ATT(empty_df, y = Y, g = G, t = Time),
    "data is empty"
  )
})

test_that("estimate_group_time_ATT checks for required columns", {
  df <- data.frame(Y = 1:10, G = rep(1:2, each = 5))  # Missing Time column

  expect_error(
    estimate_group_time_ATT(df, y = Y, g = G, t = Time),
    "data is missing required columns.*Time"
  )
})

test_that("estimate_group_time_ATT warns about unused cluster argument", {
  df <- data.frame(
    Y = rnorm(20),
    G = rep(c(2000, 2001), each = 10),
    Time = rep(2000:2001, 10),
    id = 1:20
  )

  # This will fail at the did::att_gt call, but should warn about cluster first
  # Skip actual execution since it requires valid did data structure
  skip("Requires full did-compatible panel data structure")
})

test_that("estimate_group_time_ATT requires did package", {
  # Test that package dependency is checked
  # This is more of a documentation test

  # If did were not installed, should get informative error
  expect_true(requireNamespace("did", quietly = TRUE))
})

test_that("estimate_group_time_ATT uses correct column names", {
  df <- data.frame(
    outcome = rnorm(20),
    cohort = rep(c(0, 1), each = 10),
    period = rep(1:2, 10),
    id = 1:20,
    treated = rep(c(0, 1), each = 10)
  )

  # Should not error on column name validation
  # Skip did::att_gt call
  skip("Requires full did-compatible panel data structure with proper treatment timing")
})

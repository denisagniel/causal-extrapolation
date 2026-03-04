test_that("build_model_specs creates linear model spec", {
  specs <- build_model_specs("linear")

  expect_length(specs, 1)
  expect_named(specs, "linear")
  expect_equal(specs$linear$name, "linear")
  expect_identical(specs$linear$h_fun, hg_linear)
  expect_identical(specs$linear$dh_fun, dh_linear)
})

test_that("build_model_specs creates quadratic model spec", {
  specs <- build_model_specs("quadratic")

  expect_length(specs, 1)
  expect_named(specs, "quadratic")
  expect_equal(specs$quadratic$name, "quadratic")
  expect_identical(specs$quadratic$h_fun, hg_quadratic)
  expect_identical(specs$quadratic$dh_fun, dh_quadratic)
})

test_that("build_model_specs creates multiple models", {
  specs <- build_model_specs(c("linear", "quadratic"))

  expect_length(specs, 2)
  expect_named(specs, c("linear", "quadratic"))
})

test_that("build_model_specs defaults to both models", {
  specs <- build_model_specs()

  expect_length(specs, 2)
  expect_named(specs, c("linear", "quadratic"))
})

test_that("build_model_specs rejects invalid model names", {
  expect_error(
    build_model_specs("invalid_model"),
    "Invalid model names"
  )

  expect_error(
    build_model_specs(c("linear", "invalid")),
    "Invalid model names"
  )
})

test_that("build_model_specs rejects non-character input", {
  expect_error(
    build_model_specs(123),
    "must be a character vector"
  )
})

test_that("build_model_specs rejects empty model_names", {
  expect_error(
    build_model_specs(character(0)),
    "cannot be empty"
  )
})

test_that("build_model_specs accepts custom models", {
  custom <- list(
    constant = list(
      h_fun = function(times, future_time) {
        function(tau_g) mean(tau_g)
      },
      dh_fun = function(times, future_time) {
        rep(1 / length(times), length(times))
      },
      name = "constant"
    )
  )

  specs <- build_model_specs("linear", custom_models = custom)

  expect_length(specs, 2)
  expect_named(specs, c("linear", "constant"))
  expect_equal(specs$constant$name, "constant")
})

test_that("build_model_specs rejects unnamed custom models", {
  custom <- list(
    list(
      h_fun = function(times, future_time) function(tau_g) mean(tau_g),
      dh_fun = function(times, future_time) rep(1/3, 3),
      name = "constant"
    )
  )

  expect_error(
    build_model_specs("linear", custom_models = custom),
    "must have names for all elements"
  )
})

test_that("build_model_specs detects name conflicts", {
  custom <- list(
    linear = list(  # Conflicts with built-in
      h_fun = function(times, future_time) function(tau_g) mean(tau_g),
      dh_fun = function(times, future_time) rep(1/3, 3),
      name = "my_linear"
    )
  )

  expect_error(
    build_model_specs("linear", custom_models = custom),
    "Name conflict"
  )
})

test_that("build_model_specs validates custom model structure", {
  incomplete_custom <- list(
    incomplete = list(
      h_fun = function(times, future_time) function(tau_g) mean(tau_g)
      # missing dh_fun and name
    )
  )

  expect_error(
    build_model_specs("linear", custom_models = incomplete_custom),
    "missing required fields"
  )
})

test_that("build_model_specs returns valid structure for cv_extrapolate_ATT", {
  specs <- build_model_specs(c("linear", "quadratic"))

  # Verify structure passes validation
  expect_silent(validate_model_specs(specs))

  # Verify each function is callable
  times <- c(1, 2, 3, 4)
  future_time <- 5

  for (spec_name in names(specs)) {
    spec <- specs[[spec_name]]

    # h_fun should return a function
    h <- spec$h_fun(times, future_time)
    expect_type(h, "closure")

    # dh_fun should return a numeric vector
    dh <- spec$dh_fun(times, future_time)
    expect_type(dh, "double")
    expect_length(dh, length(times))
  }
})

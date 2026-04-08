# Tests for integrate_covariates() (Path 3: Covariate Integration)

test_that("integrate_covariates works with linear model and finite-population", {
  # Setup: Simple linear conditional model tau(X) = 2 + 1.5 * X
  # Groups have different X means: mu_g = c(-1, 0, 1)
  # Target has mu_target = 0.5

  set.seed(703)
  n <- 100
  q <- 3
  alpha <- 2.0
  beta_true <- 1.5
  mu_g <- c(-1, 0, 1)

  # Create gt_object with group-time ATTs from conditional model
  # theta_gt = alpha + beta * mu_g[g]
  gt_data <- tibble::tibble(
    g = rep(1:q, each = 2),
    t = rep(1:2, times = q),
    tau_hat = alpha + beta_true * mu_g[rep(1:q, each = 2)],
    k = 0
  )

  # Add attributes for mu_g (to be extracted by integrate_covariates)
  attr(gt_data, "mu_g") <- mu_g
  attr(gt_data, "alpha") <- alpha
  attr(gt_data, "beta") <- beta_true

  # Create EIF vectors
  phi <- replicate(nrow(gt_data), rnorm(n, sd = 0.1), simplify = FALSE)

  gt_obj <- list(
    data = gt_data,
    phi = phi,
    times = sort(unique(gt_data$t)),
    groups = sort(unique(gt_data$g)),
    n = n
  )
  class(gt_obj) <- c("gt_object", "extrapolateATT")

  # Conditional model
  conditional_model <- function(X_df, beta) {
    beta[1] + beta[2] * X_df$X
  }

  # Target sample (mu_target = 0.5)
  x_target <- data.frame(X = rnorm(200, mean = 0.5, sd = 1))

  # Integrate
  result <- integrate_covariates(
    gt_obj, conditional_model,
    x_target = x_target,
    validate = TRUE
  )

  # Expected: tau_future ≈ 2 + 1.5 * 0.5 = 2.75
  expect_type(result, "list")
  expect_s3_class(result, "integrated_att")
  expect_true("tau_future" %in% names(result))
  expect_true("phi_future" %in% names(result))
  expect_true("beta" %in% names(result))
  expect_true("strategy" %in% names(result))

  # Check beta recovery (should be close to c(2, 1.5))
  expect_length(result$beta, 2)
  expect_equal(result$beta[1], alpha, tolerance = 0.1)
  expect_equal(result$beta[2], beta_true, tolerance = 0.1)

  # Check tau_future
  true_fatt <- alpha + beta_true * 0.5  # 2.75
  expect_equal(result$tau_future, true_fatt, tolerance = 0.2)

  # Check strategy
  expect_equal(result$strategy, "finite_population")
  expect_equal(result$n_integrated, 200)
})


test_that("integrate_covariates works with Monte Carlo sampling", {
  set.seed(704)
  n <- 100
  q <- 3
  alpha <- 2.0
  beta_true <- 1.5
  mu_g <- c(-1, 0, 1)

  gt_data <- tibble::tibble(
    g = rep(1:q, each = 2),
    t = rep(1:2, times = q),
    tau_hat = alpha + beta_true * mu_g[rep(1:q, each = 2)],
    k = 0
  )
  attr(gt_data, "mu_g") <- mu_g

  phi <- replicate(nrow(gt_data), rnorm(n, sd = 0.1), simplify = FALSE)

  gt_obj <- list(
    data = gt_data,
    phi = phi,
    times = sort(unique(gt_data$t)),
    groups = sort(unique(gt_data$g)),
    n = n
  )
  class(gt_obj) <- c("gt_object", "extrapolateATT")

  conditional_model <- function(X_df, beta) {
    beta[1] + beta[2] * X_df$X
  }

  # Monte Carlo sampler
  sampler <- function(n_draw) {
    data.frame(X = rnorm(n_draw, mean = 0.5, sd = 1))
  }

  # Integrate via MC
  result <- integrate_covariates(
    gt_obj, conditional_model,
    sampler = sampler, n_mc = 5000
  )

  expect_s3_class(result, "integrated_att")
  expect_equal(result$strategy, "monte_carlo")
  expect_equal(result$n_integrated, 5000)

  # Check tau_future
  true_fatt <- alpha + beta_true * 0.5  # 2.75
  expect_equal(result$tau_future, true_fatt, tolerance = 0.2)
})


test_that("integrate_covariates validates inputs", {
  set.seed(705)
  n <- 50

  # Invalid gt_object
  expect_error(
    integrate_covariates(list(bad = "object"), function(x, b) x),
    "gt_object must be of class"
  )

  # Non-function conditional_model
  gt_obj <- list(
    data = tibble::tibble(g = 1, t = 1, tau_hat = 1, k = 0),
    phi = list(rnorm(n)),
    times = 1, groups = 1, n = n
  )
  class(gt_obj) <- c("gt_object", "extrapolateATT")

  expect_error(
    integrate_covariates(gt_obj, "not_a_function"),
    "conditional_model must be a function"
  )

  # Missing both x_target and sampler
  expect_error(
    integrate_covariates(gt_obj, function(x, b) x),
    "Must provide either x_target"
  )
})


test_that("integrate_covariates extracts mu_g from attributes", {
  set.seed(706)
  n <- 100
  alpha <- 2.0
  beta_true <- 1.5
  mu_g <- c(-1, 0, 1)

  # Create gt_object WITH attributes
  gt_data <- tibble::tibble(
    g = rep(1:3, each = 2),
    t = rep(1:2, times = 3),
    tau_hat = alpha + beta_true * mu_g[rep(1:3, each = 2)],
    k = 0
  )
  attr(gt_data, "mu_g") <- mu_g

  phi <- replicate(nrow(gt_data), rnorm(n, sd = 0.1), simplify = FALSE)

  gt_obj <- list(
    data = gt_data,
    phi = phi,
    times = 1:2,
    groups = 1:3,
    n = n
  )
  class(gt_obj) <- c("gt_object", "extrapolateATT")

  conditional_model <- function(X_df, beta) beta[1] + beta[2] * X_df$X
  x_target <- data.frame(X = rnorm(100, mean = 0))

  # Should work without explicit x_group (extracts from attributes)
  expect_message(
    result <- integrate_covariates(gt_obj, conditional_model, x_target = x_target),
    "Using x_group extracted from gt_object attributes"
  )

  expect_s3_class(result, "integrated_att")
  expect_true(!is.null(result$beta))
})


test_that("print.integrated_att works", {
  set.seed(707)
  result <- list(
    tau_future = 2.75,
    phi_future = rnorm(100),
    beta = c(2.0, 1.5),
    n_integrated = 200,
    strategy = "finite_population"
  )
  class(result) <- c("integrated_att", "extrapolateATT")

  # Should print without error
  expect_output(print(result), "Integrated ATT")
  expect_output(print(result), "2.7500")
  expect_output(print(result), "finite_population")
  expect_output(print(result), "200")
  expect_output(print(result), "Beta:")
})


test_that("integrate_covariates works end-to-end with dgp_helpers", {
  skip_if_not_installed("extrapolateATT")

  # Use actual DGP helpers from simulations
  dgp_path <- "../../sims/scripts/dgp_helpers.R"
  if (!file.exists(dgp_path)) {
    skip("DGP helpers not found (test requires sims/scripts/dgp_helpers.R)")
  }
  source(dgp_path, local = TRUE)

  set.seed(708)
  q <- 3
  p <- 5
  n <- 100
  alpha <- 2.0
  beta_val <- 1.5
  mu_g <- c(-1, 0, 1)
  mu_target <- 0.5

  # Generate theta_gt from conditional model
  theta_gt <- make_theta_gt_conditional(
    q = q, p = p, alpha = alpha, beta = beta_val,
    mu_g = mu_g, sigma_X = 1.0, seed = 708
  )

  # Add noise and EIF
  gt <- add_noise_and_eif(theta_gt, n = n, sigma_tau = 0.1, seed = 708)

  # Conditional model
  conditional_model <- function(X_df, beta) {
    beta[1] + beta[2] * X_df$X
  }

  # Target covariates
  x_target <- generate_target_covariates(
    n_target = 200, mu_target = mu_target, sigma_X = 1.0, seed = 708
  )

  # Integrate (should extract x_group from attributes)
  expect_message(
    result <- integrate_covariates(gt, conditional_model, x_target = x_target),
    "Using x_group"
  )

  # True FATT
  true_fatt <- true_fatt_conditional(alpha, beta_val, mu_target)  # 2.75

  # Check result
  expect_equal(result$tau_future, true_fatt, tolerance = 0.3)
  expect_s3_class(result, "integrated_att")
})

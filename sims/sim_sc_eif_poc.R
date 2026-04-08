# Proof of Concept: EIF-Based Inference for Synthetic Control
#
# Goal: Show that EIF-based variance estimation provides better coverage than
#       existing methods (placebo, conformal) for SC with multiple treated units
#
# Setting: N = 100 (50 treated, 50 control), T_0 = 10 pre-treatment periods
#          DGP violates parallel trends but satisfies conditional parallel trends

library(tidyverse)

# 1. Data Generating Process -----------------------------------------------

#' Generate panel data with conditional parallel trends
#'
#' Key features:
#' - Unconditional parallel trends VIOLATED (treated units have different trends)
#' - Conditional parallel trends SATISFIED given Y_pre
#' - Factor model structure: Y_it = lambda_i * f_t + epsilon_it
#'
#' @param N Total number of units
#' @param N_treated Number of treated units
#' @param T_0 Number of pre-treatment periods
#' @param T_post Number of post-treatment periods
#' @param tau True treatment effect
#' @param signal_noise Signal-to-noise ratio
#'
#' @return List with data, true_tau, and other parameters
generate_sc_data <- function(N = 100,
                             N_treated = 50,
                             T_0 = 10,
                             T_post = 5,
                             tau = 1.0,
                             signal_noise = 2) {

  N_control <- N - N_treated
  T_total <- T_0 + T_post

  # Unit-specific loadings (treated units have systematically different loadings)
  # This creates violation of unconditional parallel trends
  lambda_treated <- rnorm(N_treated, mean = 1.5, sd = 0.5)
  lambda_control <- rnorm(N_control, mean = 1.0, sd = 0.5)
  lambda <- c(lambda_treated, lambda_control)

  # Time factors (common trend)
  f <- cumsum(rnorm(T_total, mean = 0.1, sd = 0.1))

  # Generate outcomes
  Y <- matrix(NA, nrow = N, ncol = T_total)

  for (i in 1:N) {
    # Factor model: Y_it = lambda_i * f_t + epsilon_it
    Y[i, ] <- lambda[i] * f + rnorm(T_total, sd = 1 / signal_noise)
  }

  # Treatment assignment
  D <- c(rep(1, N_treated), rep(0, N_control))

  # Add treatment effect to post-treatment periods for treated units
  for (i in 1:N_treated) {
    Y[i, (T_0 + 1):T_total] <- Y[i, (T_0 + 1):T_total] + tau
  }

  # Create long-format data
  data <- expand_grid(
    unit = 1:N,
    time = 1:T_total
  ) |>
    mutate(
      D = rep(D, each = T_total),
      Y = as.vector(t(Y)),
      post = time > T_0,
      lambda = rep(lambda, each = T_total)
    )

  # Pre-treatment outcomes for each unit (wide format for SC)
  Y_pre <- Y[, 1:T_0]

  list(
    data = data,
    Y = Y,
    Y_pre = Y_pre,
    D = D,
    tau = tau,
    T_0 = T_0,
    T_post = T_post,
    lambda = lambda
  )
}


# 2. SC Weight Estimation --------------------------------------------------

#' Estimate SC weights for each treated unit
#'
#' Finds weights w_i for control units that minimize pre-treatment fit:
#'   min ||Y_{treated,pre} - sum_j w_j Y_{j,pre}||^2
#'   subject to: w >= 0, sum(w) = 1
#'
#' @param Y_pre_treated Pre-treatment outcomes for one treated unit (vector of length T_0)
#' @param Y_pre_control Pre-treatment outcomes for control units (matrix N_control x T_0)
#'
#' @return Vector of weights (length N_control)
estimate_sc_weights <- function(Y_pre_treated, Y_pre_control) {

  # Use quadprog to solve constrained optimization
  require(quadprog)

  N_control <- nrow(Y_pre_control)

  # Ensure Y_pre_treated is a vector
  Y_pre_treated <- as.vector(Y_pre_treated)

  # Transpose Y_pre_control so that columns are units, rows are time periods
  # This makes the matrix multiplication work correctly
  X <- t(Y_pre_control)  # T_0 x N_control

  # Quadratic programming formulation:
  # min 0.5 * w' Q w - d' w
  # subject to: A' w >= b

  # Q = X'X where X is the control outcomes (N_control x N_control)
  Q <- t(X) %*% X

  # d = X'y where y is the treated outcome (N_control x 1)
  d <- t(X) %*% Y_pre_treated

  # Constraints:
  # 1. sum(w) = 1  (equality)
  # 2. w >= 0      (inequality)

  # A matrix: first column for sum(w)=1, then identity for w>=0
  A <- cbind(rep(1, N_control), diag(N_control))

  # b vector: 1 for equality, 0 for inequalities
  b <- c(1, rep(0, N_control))

  # meq: first constraint is equality
  result <- solve.QP(
    Dmat = Q + diag(1e-8, N_control),  # Add small ridge for numerical stability
    dvec = d,
    Amat = A,
    bvec = b,
    meq = 1
  )

  weights <- result$solution

  # Numerical cleanup
  weights[weights < 1e-6] <- 0
  weights <- weights / sum(weights)

  return(weights)
}


# 3. Outcome Model Estimation ----------------------------------------------

#' Estimate outcome model m(Y_pre) = E[Y_t | D=0, Y_pre]
#'
#' Uses ridge regression on control units to predict post-treatment outcomes
#' from pre-treatment outcomes
#'
#' @param Y_pre_control Pre-treatment outcomes for controls (N_control x T_0)
#' @param Y_post_control Post-treatment outcomes for controls (N_control x T_post)
#' @param t_target Which post-treatment period to predict (1 to T_post)
#' @param lambda Ridge penalty parameter
#'
#' @return Function that predicts Y_t given Y_pre
estimate_outcome_model_ridge <- function(Y_pre_control,
                                        Y_post_control,
                                        t_target,
                                        lambda = 0.1) {

  require(glmnet)

  # Fit ridge regression: Y_post[,t_target] ~ Y_pre
  fit <- glmnet(
    x = Y_pre_control,
    y = Y_post_control[, t_target],
    alpha = 0,  # Ridge regression
    lambda = lambda,
    standardize = TRUE
  )

  # Return prediction function
  function(Y_pre_new) {
    as.vector(predict(fit, newx = matrix(Y_pre_new, nrow = 1), s = lambda))
  }
}


# 4. SC Estimators ---------------------------------------------------------

#' Standard SC estimator (weights only)
#'
#' @param dgp Output from generate_sc_data()
#' @param t_target Which post-treatment period to estimate
#'
#' @return List with ATT estimate and weights for each treated unit
estimate_sc_standard <- function(dgp, t_target = 1) {

  N_treated <- sum(dgp$D == 1)
  N_control <- sum(dgp$D == 0)
  T_0 <- dgp$T_0

  # Split data
  Y_pre_treated <- dgp$Y_pre[dgp$D == 1, ]
  Y_pre_control <- dgp$Y_pre[dgp$D == 0, ]

  t_post <- T_0 + t_target
  Y_post_treated <- dgp$Y[dgp$D == 1, t_post]
  Y_post_control <- dgp$Y[dgp$D == 0, t_post]

  # Estimate weights for each treated unit
  weights_list <- vector("list", N_treated)
  predicted_Y0 <- numeric(N_treated)

  for (i in 1:N_treated) {
    weights <- estimate_sc_weights(Y_pre_treated[i, ], Y_pre_control)
    weights_list[[i]] <- weights
    predicted_Y0[i] <- sum(weights * Y_post_control)
  }

  # ATT estimate
  att <- mean(Y_post_treated - predicted_Y0)

  list(
    att = att,
    weights = weights_list,
    predicted_Y0 = predicted_Y0,
    Y1 = Y_post_treated
  )
}


#' Augmented SC estimator (SC weights + outcome model)
#'
#' @param dgp Output from generate_sc_data()
#' @param t_target Which post-treatment period to estimate
#' @param lambda Ridge penalty
#'
#' @return List with ATT estimate, weights, and outcome model
estimate_sc_augmented <- function(dgp, t_target = 1, lambda = 0.1) {

  N_treated <- sum(dgp$D == 1)
  N_control <- sum(dgp$D == 0)
  T_0 <- dgp$T_0
  T_post <- dgp$T_post

  # Split data
  Y_pre_treated <- dgp$Y_pre[dgp$D == 1, ]
  Y_pre_control <- dgp$Y_pre[dgp$D == 0, ]

  t_post <- T_0 + t_target
  Y_post_treated <- dgp$Y[dgp$D == 1, t_post]

  # Post-treatment outcomes for controls (all periods)
  Y_post_control_full <- dgp$Y[dgp$D == 0, (T_0 + 1):(T_0 + T_post)]
  Y_post_control_target <- Y_post_control_full[, t_target]

  # Estimate outcome model on controls
  m_hat <- estimate_outcome_model_ridge(
    Y_pre_control,
    Y_post_control_full,
    t_target = t_target,
    lambda = lambda
  )

  # Predict for all units
  m_treated <- sapply(1:N_treated, function(i) m_hat(Y_pre_treated[i, ]))
  m_control <- sapply(1:N_control, function(i) m_hat(Y_pre_control[i, ]))

  # SC weights for each treated unit
  weights_list <- vector("list", N_treated)
  sc_predictions <- numeric(N_treated)

  for (i in 1:N_treated) {
    weights <- estimate_sc_weights(Y_pre_treated[i, ], Y_pre_control)
    weights_list[[i]] <- weights

    # SC prediction using weights
    sc_predictions[i] <- sum(weights * Y_post_control_target)
  }

  # Augmented estimator:
  # tau_hat = mean(Y1 - Y0_sc) + mean(Y0_sc - m_treated)
  # Equivalent to: mean(Y1 - m_treated)
  att_augmented <- mean(Y_post_treated - m_treated)

  list(
    att = att_augmented,
    weights = weights_list,
    m_treated = m_treated,
    m_control = m_control,
    Y1 = Y_post_treated,
    Y0_control = Y_post_control_target,
    m_hat = m_hat
  )
}


# 5. EIF-Based Variance Estimation -----------------------------------------

#' Compute EIF-based variance for augmented SC
#'
#' EIF has three components:
#' 1. Treated residuals: (Y_1i - m(Y_pre,i)) / P(D=1)
#' 2. Treated centering: (m(Y_pre,i) - theta) / P(D=1)
#' 3. Control contribution: weighted residuals from controls
#'
#' @param dgp Original DGP
#' @param fit Output from estimate_sc_augmented()
#' @param t_target Which post-treatment period
#'
#' @return Variance estimate
compute_eif_variance <- function(dgp, fit, t_target = 1) {

  N <- length(dgp$D)
  N_treated <- sum(dgp$D == 1)
  N_control <- sum(dgp$D == 0)
  P_D1 <- N_treated / N

  # Initialize EIF values
  psi <- numeric(N)

  # Treated units
  idx_treated <- which(dgp$D == 1)

  for (i in 1:N_treated) {
    # Residual: Y_1i - m(Y_pre,i)
    residual <- fit$Y1[i] - fit$m_treated[i]

    # Centering: m(Y_pre,i) - theta
    centering <- fit$m_treated[i] - fit$att

    # EIF for treated unit i
    psi[idx_treated[i]] <- (residual + centering) / P_D1
  }

  # Control units
  idx_control <- which(dgp$D == 0)

  # For each control unit, compute weighted contribution
  # Weight = how much this control contributes to each treated unit's SC
  for (j in 1:N_control) {

    # Residual for control j
    residual_j <- fit$Y0_control[j] - fit$m_control[j]

    # Weight: average weight across treated units
    # (How much does control j contribute to synthetic controls?)
    total_weight <- 0
    for (i in 1:N_treated) {
      total_weight <- total_weight + fit$weights[[i]][j]
    }
    avg_weight <- total_weight / N_treated

    # EIF for control unit j
    # This is the "control contribution" term
    psi[idx_control[j]] <- avg_weight * residual_j / (1 - P_D1)
  }

  # Variance: Var(psi) = E[psi^2] (since E[psi] = 0 by construction)
  variance <- mean(psi^2)

  return(variance)
}


# 6. Comparison: Placebo Variance ------------------------------------------

#' Placebo-based variance estimation (Abadie et al. style)
#'
#' Apply SC to control units (pretend they're treated)
#' Use distribution of placebo effects to estimate variance
#'
#' @param dgp Original DGP
#' @param t_target Which post-treatment period
#'
#' @return Variance estimate
compute_placebo_variance <- function(dgp, t_target = 1) {

  # Apply SC to each control unit
  N_control <- sum(dgp$D == 0)
  T_0 <- dgp$T_0

  Y_pre_control <- dgp$Y_pre[dgp$D == 0, ]

  t_post <- T_0 + t_target
  Y_post_control <- dgp$Y[dgp$D == 0, t_post]

  placebo_effects <- numeric(N_control)

  for (i in 1:N_control) {
    # Hold out control i, use remaining controls
    Y_pre_i <- Y_pre_control[i, ]
    Y_pre_others <- Y_pre_control[-i, ]
    Y_post_others <- Y_post_control[-i]

    # Estimate SC weights for control i
    tryCatch({
      weights <- estimate_sc_weights(Y_pre_i, Y_pre_others)
      predicted <- sum(weights * Y_post_others)
      placebo_effects[i] <- Y_post_control[i] - predicted
    }, error = function(e) {
      placebo_effects[i] <- NA
    })
  }

  # Variance: empirical variance of placebo effects
  variance <- var(placebo_effects, na.rm = TRUE)

  return(variance)
}


# 7. Simulation Study ------------------------------------------------------

#' Run one simulation replication
#'
#' @param ... Parameters passed to generate_sc_data()
#'
#' @return Tibble with estimates and inference
simulate_once <- function(...) {

  # Generate data
  dgp <- generate_sc_data(...)

  # Estimate effects
  fit_standard <- estimate_sc_standard(dgp, t_target = 1)
  fit_augmented <- estimate_sc_augmented(dgp, t_target = 1)

  # Compute variances
  var_eif <- compute_eif_variance(dgp, fit_augmented, t_target = 1)
  var_placebo <- compute_placebo_variance(dgp, t_target = 1)

  # Standard errors
  N <- length(dgp$D)
  se_eif <- sqrt(var_eif / N)
  se_placebo <- sqrt(var_placebo / sum(dgp$D == 1))  # SE for treated units only

  # 95% CIs
  ci_eif <- fit_augmented$att + c(-1.96, 1.96) * se_eif
  ci_placebo_standard <- fit_standard$att + c(-1.96, 1.96) * se_placebo
  ci_placebo_augmented <- fit_augmented$att + c(-1.96, 1.96) * se_placebo

  # Check coverage
  true_tau <- dgp$tau

  tibble(
    true_tau = true_tau,

    # Estimates
    att_standard = fit_standard$att,
    att_augmented = fit_augmented$att,

    # Variances
    var_eif = var_eif,
    var_placebo = var_placebo,

    # Standard errors
    se_eif = se_eif,
    se_placebo = se_placebo,

    # Coverage (95% CI contains true tau?)
    cover_eif = ci_eif[1] <= true_tau && true_tau <= ci_eif[2],
    cover_placebo_standard = ci_placebo_standard[1] <= true_tau && true_tau <= ci_placebo_standard[2],
    cover_placebo_augmented = ci_placebo_augmented[1] <= true_tau && true_tau <= ci_placebo_augmented[2],

    # CI width
    width_eif = ci_eif[2] - ci_eif[1],
    width_placebo = ci_placebo_standard[2] - ci_placebo_standard[1]
  )
}


#' Run simulation study
#'
#' @param n_sim Number of simulation replications
#' @param ... Parameters passed to generate_sc_data()
#'
#' @return Summary of simulation results
run_simulation <- function(n_sim = 1000, ...) {

  cat("Running", n_sim, "simulations...\n")

  results <- map_dfr(1:n_sim, function(i) {
    if (i %% 100 == 0) cat("  Replication", i, "/", n_sim, "\n")

    tryCatch({
      simulate_once(...)
    }, error = function(e) {
      # Return NA row if simulation fails
      tibble(
        true_tau = NA_real_,
        att_standard = NA_real_,
        att_augmented = NA_real_,
        var_eif = NA_real_,
        var_placebo = NA_real_,
        se_eif = NA_real_,
        se_placebo = NA_real_,
        cover_eif = NA,
        cover_placebo_standard = NA,
        cover_placebo_augmented = NA,
        width_eif = NA_real_,
        width_placebo = NA_real_
      )
    })
  })

  # Summarize
  summary <- tibble(
    n_sim = n_sim,
    n_success = sum(!is.na(results$att_augmented)),

    # Bias
    bias_standard = mean(results$att_standard - results$true_tau, na.rm = TRUE),
    bias_augmented = mean(results$att_augmented - results$true_tau, na.rm = TRUE),

    # RMSE
    rmse_standard = sqrt(mean((results$att_standard - results$true_tau)^2, na.rm = TRUE)),
    rmse_augmented = sqrt(mean((results$att_augmented - results$true_tau)^2, na.rm = TRUE)),

    # Coverage (target: 0.95)
    coverage_eif = mean(results$cover_eif, na.rm = TRUE),
    coverage_placebo_standard = mean(results$cover_placebo_standard, na.rm = TRUE),
    coverage_placebo_augmented = mean(results$cover_placebo_augmented, na.rm = TRUE),

    # Average CI width
    width_eif = mean(results$width_eif, na.rm = TRUE),
    width_placebo = mean(results$width_placebo, na.rm = TRUE),

    # Average SE
    se_eif = mean(results$se_eif, na.rm = TRUE),
    se_placebo = mean(results$se_placebo, na.rm = TRUE)
  )

  list(
    summary = summary,
    results = results
  )
}


# 8. Main Analysis ---------------------------------------------------------

if (FALSE) {  # Set to TRUE to run

  # Test single replication
  set.seed(123)
  test <- simulate_once(
    N = 100,
    N_treated = 50,
    T_0 = 10,
    T_post = 5,
    tau = 1.0,
    signal_noise = 2
  )

  print(test)

  # Run full simulation
  set.seed(456)
  sim_results <- run_simulation(
    n_sim = 1000,
    N = 100,
    N_treated = 50,
    T_0 = 10,
    T_post = 5,
    tau = 1.0,
    signal_noise = 2
  )

  print(sim_results$summary)

  # Expected result:
  # - coverage_eif ≈ 0.95 (EIF-based CI has correct coverage)
  # - coverage_placebo < 0.95 or > 0.95 (placebo may over/under-cover)
  # - width_eif < width_placebo (EIF is more efficient)

}

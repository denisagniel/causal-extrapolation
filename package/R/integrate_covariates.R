#' Integrate conditional ATT over target covariate distribution (Path 3)
#'
#' Implements Path 3 identification: estimate conditional ATT tau(X) = m(X; beta)
#' from group-time ATTs, then integrate over the future covariate distribution.
#' Robust to regime change if tau(X) captures structural parameters (Lucas critique).
#'
#' @param gt_object A gt_object with group-time ATTs and EIF vectors.
#' @param conditional_model Function(X_df, beta) -> numeric vector of tau(X_i) values.
#'   Should take a data frame of covariates and parameter vector beta, and return
#'   conditional ATT for each row.
#' @param x_group Optional data frame with group-level covariate means (columns: g, X variables).
#'   Used to estimate beta. If NULL, will attempt to extract from gt_object attributes.
#' @param x_target Optional data frame of target covariates (finite-population).
#'   If provided, computes empirical average over target sample.
#' @param sampler Optional function(n) -> data frame that generates draws from target
#'   covariate distribution (Monte Carlo integration).
#' @param n_mc Number of Monte Carlo draws if using sampler (default 5000).
#' @param weights Optional weights for x_target (default equal weights).
#' @param validate Whether to validate inputs (default TRUE).
#'
#' @details
#' Path 3 assumes:
#' 1. Structural stability: tau(x) is time-invariant
#' 2. Parametric specification: tau(x) = m(x; beta) with known m
#' 3. Target distribution: access to F_X^{p+1} via x_target or sampler
#'
#' The function:
#' 1. Estimates beta by fitting conditional model to observed group-time ATTs
#' 2. Integrates m(x; beta) over target distribution
#' 3. Propagates EIF via full Jacobian chain rule through beta estimation
#'
#' @return A list with:
#'   \item{tau_future}{Scalar FATT estimate}
#'   \item{phi_future}{Length-n EIF vector for variance estimation}
#'   \item{beta}{Estimated parameter vector}
#'   \item{n_integrated}{Number of target units (finite-pop) or MC draws}
#'   \item{strategy}{"finite_population" or "monte_carlo"}
#'
#' @examples
#' \dontrun{
#' # Linear-in-covariates model: tau(X) = alpha + beta * X
#' conditional_model <- function(X_df, beta) {
#'   beta[1] + beta[2] * X_df$X
#' }
#'
#' # Group-level covariate means
#' x_group <- data.frame(g = c(1, 2, 3), X_mean = c(-1, 0, 1))
#'
#' # Target sample
#' x_target <- data.frame(X = rnorm(200, mean = 0.5, sd = 1))
#'
#' # Integrate
#' result <- integrate_covariates(
#'   gt_object, conditional_model,
#'   x_group = x_group, x_target = x_target
#' )
#' }
#'
#' @export
integrate_covariates <- function(gt_object,
                                  conditional_model,
                                  x_group = NULL,
                                  x_target = NULL,
                                  sampler = NULL,
                                  n_mc = 5000,
                                  weights = NULL,
                                  validate = TRUE) {

  # Input validation
  if (validate) {
    if (!inherits(gt_object, "gt_object")) {
      stop("gt_object must be of class 'gt_object'", call. = FALSE)
    }
    if (!is.function(conditional_model)) {
      stop("conditional_model must be a function", call. = FALSE)
    }
    if (is.null(x_target) && is.null(sampler)) {
      stop("Must provide either x_target (finite-population) or sampler (Monte Carlo)",
           call. = FALSE)
    }
    if (!is.null(x_target) && !is.null(sampler)) {
      warning("Both x_target and sampler provided; using x_target (finite-population)")
      sampler <- NULL
    }
  }

  # Extract group-level information
  df <- gt_object$data
  groups <- gt_object$groups
  n <- gt_object$n

  # Attempt to extract x_group from gt_object attributes if not provided
  if (is.null(x_group)) {
    if (!is.null(attr(df, "mu_g"))) {
      # Attributes from make_theta_gt_conditional
      mu_g <- attr(df, "mu_g")
      x_group <- data.frame(g = groups, X_mean = mu_g)
      message("Using x_group extracted from gt_object attributes")
    } else {
      stop("x_group not provided and could not be extracted from gt_object attributes",
           call. = FALSE)
    }
  }

  # Step 1: Estimate beta from group-time ATTs
  beta_hat <- estimate_beta_from_groups(df, x_group, conditional_model)

  # Step 2: Compute Jacobian components for EIF propagation
  jacobian_info <- compute_jacobian_linear(df, x_group, beta_hat)

  # Step 3: Integrate over target distribution with full EIF
  if (!is.null(x_target)) {
    result <- integrate_finite_population(
      gt_object, conditional_model, beta_hat,
      x_target, weights, jacobian_info
    )
  } else {
    result <- integrate_monte_carlo(
      gt_object, conditional_model, beta_hat,
      sampler, n_mc, jacobian_info
    )
  }

  # Add beta to result
  result$beta <- beta_hat

  # Return with class
  structure(result, class = c("integrated_att", "extrapolateATT"))
}


#' Estimate beta from group-level ATTs (internal)
#'
#' @keywords internal
estimate_beta_from_groups <- function(df, x_group, conditional_model) {
  # Compute group-level averages of observed theta_gt
  group_means <- df %>%
    dplyr::group_by(g) %>%
    dplyr::summarize(theta_g_mean = mean(tau_hat), .groups = "drop")

  # Merge with group-level covariate means
  group_data <- dplyr::left_join(group_means, x_group, by = "g")

  # For linear-in-covariates: theta_g = alpha + beta * X_mean_g
  # Use simple least squares: solve for (alpha, beta)
  if ("X_mean" %in% names(group_data)) {
    # Linear model: y = alpha + beta * x
    X_mat <- cbind(1, group_data$X_mean)
    y_vec <- group_data$theta_g_mean
    beta_hat <- solve(t(X_mat) %*% X_mat) %*% t(X_mat) %*% y_vec
    return(as.numeric(beta_hat))  # c(alpha, beta)
  } else {
    stop("Automatic beta estimation currently only supports 'X_mean' column in x_group",
         call. = FALSE)
  }
}


#' Compute Jacobian for linear-in-covariates model (internal)
#'
#' Computes ∂β/∂θ_gt for each group-time cell using the implicit function theorem.
#' For linear model tau(X) = alpha + beta_X * X, and theta_gt = alpha + beta_X * mu_g.
#'
#' @return List with H_inv (inverse Hessian), cell_gradients (gradient per cell),
#'   and cell_info (data frame mapping cells to groups)
#' @keywords internal
compute_jacobian_linear <- function(df, x_group, beta_hat) {
  # Merge df with x_group to get mu_X for each cell
  cell_data <- dplyr::left_join(df, x_group, by = "g")

  # For linear model: theta_gt = alpha + beta_X * mu_g
  # Weighted least squares minimizes: Σ w_gt (θ_gt - α - β_X μ_g)²
  # Use equal weights for simplicity (could use inverse variance if available)
  w_gt <- rep(1, nrow(df))

  # Hessian: H = Σ w_gt * [1, mu_g]' * [1, mu_g]
  # For p parameters, this is p x p matrix
  X_design <- cbind(1, cell_data$X_mean)  # n_cells x 2 matrix
  H <- t(X_design) %*% diag(w_gt) %*% X_design  # 2 x 2

  # Invert Hessian (with safety check)
  H_inv <- safe_matrix_inverse(H)

  # Gradient for each cell: ∇_gt = w_gt * [1, mu_g]'
  cell_gradients <- lapply(seq_len(nrow(df)), function(j) {
    w_gt[j] * c(1, cell_data$X_mean[j])
  })

  list(
    H_inv = H_inv,
    cell_gradients = cell_gradients,
    cell_data = cell_data
  )
}


#' Integrate over finite-population target sample with full EIF (internal)
#'
#' @keywords internal
integrate_finite_population <- function(gt_object, conditional_model, beta,
                                        x_target, weights, jacobian_info) {
  n_target <- nrow(x_target)
  if (is.null(weights)) {
    weights <- rep(1 / n_target, n_target)
  } else {
    weights <- weights / sum(weights)
  }

  # Apply conditional model to target covariates
  tau_target <- conditional_model(x_target, beta)

  # Weighted average
  tau_future <- sum(weights * tau_target)

  # --- Full EIF propagation via Jacobian chain rule ---
  #
  # EIF: phi_i = Σ_{g,t} (∂Ψ₃/∂θ_gt) * φ_{gt,i}
  # where ∂Ψ₃/∂θ_gt = (∂Ψ₃/∂β)' * (∂β/∂θ_gt)
  #
  # Step 1: Compute ∂Ψ₃/∂β
  # For linear model tau(X) = alpha + beta_X * X:
  # Ψ₃ = (1/n*) Σ_i [alpha + beta_X * X_i*]
  # ∂Ψ₃/∂alpha = 1
  # ∂Ψ₃/∂beta_X = mean(X_target)

  dPsi_dbeta <- c(1, mean(x_target[[1]]))  # [1, mean(X*)]

  # Step 2: Compute ∂β/∂θ_gt for each cell via chain rule
  # ∂β/∂θ_gt = H^(-1) * ∇_gt
  H_inv <- jacobian_info$H_inv
  cell_gradients <- jacobian_info$cell_gradients

  # Step 3: Compute Jacobian weight for each cell
  # w_gt = (∂Ψ₃/∂β)' * H^(-1) * ∇_gt
  jacobian_weights <- vapply(cell_gradients, function(nabla_gt) {
    as.numeric(t(dPsi_dbeta) %*% H_inv %*% nabla_gt)
  }, numeric(1))

  # Step 4: Weighted sum of EIF vectors
  # phi_future_i = Σ_j w_j * φ_j,i
  n <- gt_object$n
  phi_future <- numeric(n)
  for (j in seq_along(gt_object$phi)) {
    phi_future <- phi_future + jacobian_weights[j] * gt_object$phi[[j]]
  }

  list(
    tau_future = tau_future,
    phi_future = phi_future,
    n_integrated = n_target,
    strategy = "finite_population"
  )
}


#' Integrate via Monte Carlo sampling with full EIF (internal)
#'
#' @keywords internal
integrate_monte_carlo <- function(gt_object, conditional_model, beta,
                                  sampler, n_mc, jacobian_info) {
  # Generate MC draws
  x_draws <- sampler(n_mc)

  # Apply conditional model
  tau_draws <- conditional_model(x_draws, beta)

  # MC average
  tau_future <- mean(tau_draws)

  # --- Full EIF propagation (same as finite-population) ---
  # MC integration error is O(1/sqrt(n_mc)), negligible for large n_mc

  dPsi_dbeta <- c(1, mean(x_draws[[1]]))  # [1, mean(X)]

  H_inv <- jacobian_info$H_inv
  cell_gradients <- jacobian_info$cell_gradients

  jacobian_weights <- vapply(cell_gradients, function(nabla_gt) {
    as.numeric(t(dPsi_dbeta) %*% H_inv %*% nabla_gt)
  }, numeric(1))

  n <- gt_object$n
  phi_future <- numeric(n)
  for (j in seq_along(gt_object$phi)) {
    phi_future <- phi_future + jacobian_weights[j] * gt_object$phi[[j]]
  }

  list(
    tau_future = tau_future,
    phi_future = phi_future,
    n_integrated = n_mc,
    strategy = "monte_carlo"
  )
}


#' Extract Path 3 result for downstream use
#'
#' @param x Result from integrate_covariates()
#' @param ... Additional arguments (ignored)
#' @export
print.integrated_att <- function(x, ...) {
  cat("Integrated ATT (Path 3: Covariate Integration)\n")
  cat("------------------------------------------------\n")
  cat(stringr::str_glue("Estimate: {format(x$tau_future, digits = 4, nsmall = 4)}\n"))
  cat(stringr::str_glue("Strategy: {x$strategy}\n"))
  cat(stringr::str_glue("N integrated: {x$n_integrated}\n"))
  if (!is.null(x$beta)) {
    cat(stringr::str_glue("Beta: [{stringr::str_c(round(x$beta, 4), collapse = ', ')}]\n"))
  }
  invisible(x)
}

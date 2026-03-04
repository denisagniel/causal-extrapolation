# Simulation Section 7.7: Model Selection via Time-Series Cross-Validation
# Demonstrates the CV procedure from Section 5.2 using package functions

# Load package (use devtools if not installed)
if (requireNamespace("extrapolateATT", quietly = TRUE)) {
  library(extrapolateATT)
} else {
  devtools::load_all("package")
}

set.seed(20260304)

# ------------------------------------------------------------------------------
# Data Generation
# ------------------------------------------------------------------------------

# True DGP: Quadratic in event time
# theta_{gt} = alpha_g + beta_g * (t - g) + gamma_g * (t - g)^2

n <- 1000  # sample size
n_groups <- 3
n_periods <- 10
p <- 10  # last observed period

# Group parameters
alpha <- c(-0.5, 0.0, 0.5)      # baseline effects
beta <- c(0.3, 0.4, 0.2)         # linear slopes
gamma <- c(-0.05, -0.03, -0.04)  # quadratic terms (negative = decay)

# Treatment adoption times (cohorts)
cohorts <- 1:n_groups
G <- rep(cohorts, each = n / n_groups)

# Generate group-time ATTs (true effects)
theta_gt_true <- matrix(NA, nrow = n_groups, ncol = n_periods)
for (g in cohorts) {
  for (t in 1:n_periods) {
    event_time <- t - g
    if (event_time >= 0) {
      theta_gt_true[g, t] <- alpha[g] + beta[g] * event_time + gamma[g] * event_time^2
    }
  }
}

# Simulate first-stage estimates with noise
se_gt <- 0.1
theta_gt_est <- theta_gt_true + matrix(rnorm(n_groups * n_periods, 0, se_gt),
                                       nrow = n_groups, ncol = n_periods)

# Generate EIF vectors (influence functions)
# For this simulation, we'll use simple i.i.d. Gaussian EIFs
phi_list <- list()
for (g in cohorts) {
  for (t in 1:n_periods) {
    event_time <- t - g
    if (event_time >= 0) {
      phi_list[[length(phi_list) + 1]] <- rnorm(n, mean = 0, sd = se_gt)
    }
  }
}

# Convert to gt_object format
gt_data <- data.frame(
  g = integer(0),
  t = integer(0),
  tau_hat = numeric(0),
  k = integer(0)
)

for (g in cohorts) {
  for (t in 1:n_periods) {
    event_time <- t - g
    if (event_time >= 0) {
      gt_data <- rbind(gt_data, data.frame(
        g = g,
        t = t,
        tau_hat = theta_gt_est[g, t],
        k = event_time
      ))
    }
  }
}

# Create gt_object
gt_object <- list(
  data = gt_data,
  phi = phi_list,
  times = sort(unique(gt_data$t)),
  groups = cohorts,
  event_times = sort(unique(gt_data$k)),
  n = n
)
class(gt_object) <- c("gt_object", "extrapolateATT")

# Weights (group proportions)
omega <- table(G) / n

# ------------------------------------------------------------------------------
# Candidate Models (using package functions)
# ------------------------------------------------------------------------------

# Built-in models: linear and quadratic
models_builtin <- build_model_specs(c("linear", "quadratic"))

# Custom spline model (df=4)
spline_model <- list(
  spline = list(
    h_fun = function(times, future_time) {
      force(times)
      force(future_time)
      function(tau_g) {
        # Fit natural spline with df=4
        df_spline <- data.frame(
          tau = tau_g,
          time = times
        )
        fit <- lm(tau ~ splines::ns(time, df = 4), data = df_spline)

        # Predict at future_time
        newdata <- data.frame(time = future_time)
        as.numeric(predict(fit, newdata = newdata))
      }
    },
    dh_fun = function(times, future_time) {
      # Jacobian for spline: weights from projection
      p <- length(times)
      X <- cbind(1, splines::ns(times, df = 4))
      xstar <- c(1, splines::ns(future_time, knots = attr(splines::ns(times, df = 4), "knots"),
                                Boundary.knots = attr(splines::ns(times, df = 4), "Boundary.knots")))

      # Safe inversion
      XtX_inv <- solve(crossprod(X))
      w <- as.numeric(t(xstar) %*% XtX_inv %*% t(X))
      w
    },
    name = "Spline (df=4)"
  )
)

# Combine all models
models <- c(models_builtin, spline_model)

# ------------------------------------------------------------------------------
# Time-Series Cross-Validation (using package function)
# ------------------------------------------------------------------------------

cat("Running time-series cross-validation...\n")

cv_result <- cv_extrapolate_ATT(
  gt_object,
  model_specs = models,
  horizons = 1:3,
  future_value = p + 1,
  time_scale = "calendar",
  compute_coverage = FALSE
)

# Print results
print(cv_result)
cat("\n")
summary(cv_result)

# Extract results for tables
results_by_model <- cv_result$results

# Reshape for paper table
table_data <- data.frame(
  Model = character(3),
  h1 = numeric(3),
  h2 = numeric(3),
  h3 = numeric(3),
  Avg_MSPE = numeric(3),
  Selected = character(3),
  stringsAsFactors = FALSE
)

model_order <- c("linear", "quadratic", "spline")
model_names <- c("Linear", "Quadratic", "Spline (df=4)")

for (i in seq_along(model_order)) {
  model_key <- model_order[i]
  model_data <- results_by_model[results_by_model$model == model_key, ]

  table_data$Model[i] <- model_names[i]
  table_data$h1[i] <- model_data$mspe[model_data$horizon == 1]
  table_data$h2[i] <- model_data$mspe[model_data$horizon == 2]
  table_data$h3[i] <- model_data$mspe[model_data$horizon == 3]
  table_data$Avg_MSPE[i] <- cv_result$avg_mspe$avg_mspe[cv_result$avg_mspe$model == model_key]
  table_data$Selected[i] <- ifelse(cv_result$best_model == model_key, "✓", "")
}

cat("\nTable for paper:\n")
print(table_data)

# Save table
write.csv(table_data,
          file = "latex/Estimating_policy_effects_in_the_presence_of_heterogeneity/sim_tables/section7_model_selection.csv",
          row.names = FALSE)

# ------------------------------------------------------------------------------
# Extrapolate to p+1 using selected model
# ------------------------------------------------------------------------------

best_model <- cv_result$best_model
best_spec <- models[[best_model]]

cat("\nExtrapolating to period", p + 1, "using", best_model, "model...\n")

result <- extrapolate_ATT(
  gt_object,
  h_fun = best_spec$h_fun,
  dh_fun = best_spec$dh_fun,
  future_value = p + 1,
  time_scale = "calendar",
  per_group = FALSE,
  omega = as.numeric(omega)
)

# True FATT at p+1
theta_p1_true <- numeric(n_groups)
for (g in cohorts) {
  event_time <- (p + 1) - g
  theta_p1_true[g] <- alpha[g] + beta[g] * event_time + gamma[g] * event_time^2
}
fatt_true <- sum(omega * theta_p1_true)

cat("True FATT:", round(fatt_true, 3), "\n")
cat("Predicted FATT (", best_model, "):", round(result$tau_future, 3), "\n")
cat("Error:", round(result$tau_future - fatt_true, 3), "\n")

# ------------------------------------------------------------------------------
# Scenario 2: True model NOT in candidate set (Cubic DGP)
# ------------------------------------------------------------------------------

cat("\n" , rep("=", 70), "\n", sep = "")
cat("Scenario 2: True DGP is Cubic (not in candidate set)\n")
cat(rep("=", 70), "\n\n", sep = "")

# Cubic coefficients
delta <- c(0.01, 0.008, 0.012)

# Generate cubic true effects
theta_gt_cubic <- matrix(NA, nrow = n_groups, ncol = n_periods)
for (g in cohorts) {
  for (t in 1:n_periods) {
    event_time <- t - g
    if (event_time >= 0) {
      theta_gt_cubic[g, t] <- alpha[g] + beta[g] * event_time +
        gamma[g] * event_time^2 + delta[g] * event_time^3
    }
  }
}

theta_gt_cubic_est <- theta_gt_cubic + matrix(rnorm(n_groups * n_periods, 0, se_gt),
                                               nrow = n_groups, ncol = n_periods)

# Generate new EIF vectors
phi_list_cubic <- list()
for (g in cohorts) {
  for (t in 1:n_periods) {
    event_time <- t - g
    if (event_time >= 0) {
      phi_list_cubic[[length(phi_list_cubic) + 1]] <- rnorm(n, mean = 0, sd = se_gt)
    }
  }
}

# Create new gt_data
gt_data_cubic <- data.frame(
  g = integer(0),
  t = integer(0),
  tau_hat = numeric(0),
  k = integer(0)
)

for (g in cohorts) {
  for (t in 1:n_periods) {
    event_time <- t - g
    if (event_time >= 0) {
      gt_data_cubic <- rbind(gt_data_cubic, data.frame(
        g = g,
        t = t,
        tau_hat = theta_gt_cubic_est[g, t],
        k = event_time
      ))
    }
  }
}

# Create gt_object for cubic scenario
gt_object_cubic <- list(
  data = gt_data_cubic,
  phi = phi_list_cubic,
  times = sort(unique(gt_data_cubic$t)),
  groups = cohorts,
  event_times = sort(unique(gt_data_cubic$k)),
  n = n
)
class(gt_object_cubic) <- c("gt_object", "extrapolateATT")

# Run CV again
cat("Running CV on cubic data...\n")

cv_result_cubic <- cv_extrapolate_ATT(
  gt_object_cubic,
  model_specs = models,
  horizons = 1:3,
  future_value = p + 1,
  time_scale = "calendar",
  compute_coverage = FALSE
)

print(cv_result_cubic)

# Create table for cubic scenario
table_data_cubic <- data.frame(
  Model = character(3),
  h1 = numeric(3),
  h2 = numeric(3),
  h3 = numeric(3),
  Avg_MSPE = numeric(3),
  Selected = character(3),
  stringsAsFactors = FALSE
)

results_cubic <- cv_result_cubic$results

for (i in seq_along(model_order)) {
  model_key <- model_order[i]
  model_data <- results_cubic[results_cubic$model == model_key, ]

  table_data_cubic$Model[i] <- model_names[i]
  table_data_cubic$h1[i] <- model_data$mspe[model_data$horizon == 1]
  table_data_cubic$h2[i] <- model_data$mspe[model_data$horizon == 2]
  table_data_cubic$h3[i] <- model_data$mspe[model_data$horizon == 3]
  table_data_cubic$Avg_MSPE[i] <- cv_result_cubic$avg_mspe$avg_mspe[cv_result_cubic$avg_mspe$model == model_key]
  table_data_cubic$Selected[i] <- ifelse(cv_result_cubic$best_model == model_key, "✓", "")
}

cat("\nTable for paper (cubic scenario):\n")
print(table_data_cubic)

# Save cubic table
write.csv(table_data_cubic,
          file = "latex/Estimating_policy_effects_in_the_presence_of_heterogeneity/sim_tables/section7_model_selection_cubic.csv",
          row.names = FALSE)

cat("\n")
cat("Best approximation:", cv_result_cubic$best_model, "\n")
cat("(Spline or quadratic should win as most flexible approximations)\n")

cat("\n========================================\n")
cat("Simulation complete. Tables saved to:\n")
cat("  - sim_tables/section7_model_selection.csv\n")
cat("  - sim_tables/section7_model_selection_cubic.csv\n")
cat("========================================\n")

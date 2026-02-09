# Demo: linear extrapolation with synthetic data

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(ggplot2)
})

# Synthetic group-time true effects with linear trend
q <- 3
p <- 5
m <- 2
times <- seq_len(p)
future_time <- p + m
groups <- seq_len(q)

true_alpha <- c(0.5, -0.2, 0.1)
true_beta  <- c(0.3, 0.1, 0.2)

tau_true <- lapply(seq_len(q), function(g) true_alpha[g] + true_beta[g] * times)
tau_future_true <- sapply(seq_len(q), function(g) true_alpha[g] + true_beta[g] * future_time)

# Estimated tau with noise; placeholder EIFs with mean ~0
n <- 1000
tau_hat <- lapply(tau_true, function(v) v + rnorm(length(v), sd = 0.1))
phi_list <- lapply(seq_len(q * p), function(i) rnorm(n, sd = 0.2))

df <- tibble(
  g = rep(groups, each = p),
  t = rep(times, q),
  tau_hat = as.numeric(unlist(tau_hat))
)

gt_object <- list(
  data = df,
  phi = phi_list,
  times = times,
  groups = groups,
  n = n,
  ids = NULL
)
class(gt_object) <- c("gt_object", "extrapolateATT")

# Extrapolate with linear model and aggregate with equal weights
h_fun <- hg_linear
dh_fun <- dh_linear
omega <- rep(1 / q, q)

ex <- extrapolate_ATT(gt_object, h_fun = h_fun, dh_fun = dh_fun, future_time = future_time, omega = omega, per_group = FALSE)

inference <- compute_variance(ex$phi_future, estimate = ex$tau_future, level = 0.95)

message(sprintf("Estimated ATT at time %d: %.3f (SE=%.3f)", future_time, ex$tau_future, inference$se))

dir.create("sims/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(list(ex = ex, inference = inference), file = file.path("sims/results", "demo_linear_results.rds"))

# Simple plot of past and extrapolated per group
plot_df <- df %>% mutate(type = "observed") %>%
  bind_rows(tibble(g = groups, t = future_time, tau_hat = ex$tau_g_future$tau_future, type = "extrapolated"))

gg <- ggplot(plot_df, aes(x = t, y = tau_hat, color = factor(g), linetype = type)) +
  geom_point() + geom_line() +
  labs(title = "Linear extrapolation of group effects", color = "group", linetype = "type") +
  theme_minimal()

ggsave(filename = file.path("sims/results", "demo_linear_plot.png"), plot = gg, width = 7, height = 4, dpi = 150)






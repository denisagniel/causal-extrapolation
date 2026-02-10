# Section 1: Backward-looking ATT vs FATT (narrative)
# Message: Interpreting the backward-looking ATT as the policy-relevant effect
# can be wrong when effects evolve.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(ggplot2)
})

source("sims/scripts/dgp_helpers.R")

q <- 3
p <- 5
omega <- rep(1 / q, q)
future_time <- p + 1

# Grid of slope strengths (same slope for all groups)
slope_grid <- seq(-0.2, 0.2, by = 0.05)
alpha_g <- c(0.2, 0, -0.1)  # fixed intercepts

results <- tibble(
  slope = slope_grid,
  true_backward_att = NA_real_,
  true_fatt = NA_real_
)

for (i in seq_along(slope_grid)) {
  beta_g <- rep(slope_grid[i], q)
  theta_gt <- make_theta_gt(q, p, spec = "linear", alpha_g = alpha_g, beta_g = beta_g, seed = 42)
  results$true_backward_att[i] <- true_backward_att(theta_gt)
  results$true_fatt[i] <- true_fatt_from_dgp(omega, future_time, q, "linear", alpha_g = alpha_g, beta_g = beta_g)
}

dir.create("sims/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(results, "sims/results/section1_backward_vs_fatt.rds")

# Plot: true ATT vs true FATT as function of slope
gg <- ggplot(results, aes(x = slope)) +
  geom_line(aes(y = true_backward_att, color = "Backward-looking ATT")) +
  geom_line(aes(y = true_fatt, color = "FATT (p+1)")) +
  geom_point(aes(y = true_backward_att, color = "Backward-looking ATT"), size = 1.5) +
  geom_point(aes(y = true_fatt, color = "FATT (p+1)"), size = 1.5) +
  labs(
    title = "Backward-looking ATT vs FATT when effects vary in event time",
    x = "Slope of effect in event time",
    y = "True effect",
    color = ""
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("sims/results/section1_plot.png", plot = gg, width = 7, height = 4, dpi = 150)
message("Section 1 done: results and plot saved to sims/results/")

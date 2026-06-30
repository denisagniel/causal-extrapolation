# Create validation plot: Predictions vs. Realized ATTs

library(tidyverse)

cat("Creating validation plot...\n")

# Load data
val_full <- readRDS("application/results/validation_full.rds")

# Reshape for plotting
plot_data <- val_full %>%
  select(year, realized, path1, path2, path3) %>%
  pivot_longer(cols = c(realized, path1, path2, path3),
               names_to = "method",
               values_to = "att") %>%
  mutate(
    method = case_when(
      method == "realized" ~ "Realized",
      method == "path1" ~ "Path 1: Homogeneity",
      method == "path2" ~ "Path 2: Model Selection",
      method == "path3" ~ "Path 3: Covariates"
    ),
    method = factor(method, levels = c("Realized",
                                       "Path 1: Homogeneity",
                                       "Path 2: Model Selection",
                                       "Path 3: Covariates"))
  )

# Create plot
p <- ggplot(plot_data, aes(x = year, y = att, color = method, linetype = method)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  scale_color_manual(values = c("Realized" = "black",
                                "Path 1: Homogeneity" = "#E69F00",
                                "Path 2: Model Selection" = "#56B4E9",
                                "Path 3: Covariates" = "#009E73")) +
  scale_linetype_manual(values = c("Realized" = "solid",
                                   "Path 1: Homogeneity" = "dashed",
                                   "Path 2: Model Selection" = "dotted",
                                   "Path 3: Covariates" = "dotdash")) +
  labs(
    x = "Year",
    y = "ATT (deaths per 100,000)",
    color = NULL,
    linetype = NULL,
    title = "Predictions vs. Realized ATTs (2016-2022)",
    subtitle = "Stand-your-ground laws and firearm homicide"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    legend.direction = "vertical",
    panel.grid.minor = element_blank()
  ) +
  scale_x_continuous(breaks = 2016:2022)

# Save plot
ggsave("application/figures/validation_plot.pdf", p,
       width = 8, height = 6, units = "in")

cat("Saved: application/figures/validation_plot.pdf\n")

# Also save PNG for quick viewing
ggsave("application/figures/validation_plot.png", p,
       width = 8, height = 6, units = "in", dpi = 300)

cat("Saved: application/figures/validation_plot.png\n")

cat("\nValidation plot created successfully.\n")

# Create validation plot: predictions (with EIF-based 95% CIs) vs realized ATTs.
# Paths 1 & 2 only; Path 3 deferred pending the DiD transport influence function.

library(tidyverse)
library(fs)

cat("Creating validation plot...\n")

dir_create("application/figures")

val_full <- readRDS("application/results/validation_full.rds")

# Long form with per-path CI bounds for ribbons.
plot_data <- bind_rows(
  val_full %>% transmute(year, method = "Realized", att = realized,
                         lo = NA_real_, hi = NA_real_),
  val_full %>% transmute(year, method = "Path 1: Homogeneity", att = path1,
                         lo = lo_path1, hi = hi_path1),
  val_full %>% transmute(year, method = "Path 2: Model selection", att = path2,
                         lo = lo_path2, hi = hi_path2)
) %>%
  mutate(method = factor(method, levels = c("Realized",
                                            "Path 1: Homogeneity",
                                            "Path 2: Model selection")))

pal <- c("Realized" = "black",
         "Path 1: Homogeneity" = "#E69F00",
         "Path 2: Model selection" = "#56B4E9")

p <- ggplot(plot_data, aes(x = year, y = att, color = method, fill = method)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.15, color = NA) +
  geom_line(aes(linetype = method), linewidth = 1) +
  geom_point(size = 2.5) +
  scale_color_manual(values = pal) +
  scale_fill_manual(values = pal, na.value = NA) +
  scale_linetype_manual(values = c("Realized" = "solid",
                                   "Path 1: Homogeneity" = "dashed",
                                   "Path 2: Model selection" = "dotted")) +
  labs(x = "Year", y = "ATT (deaths per 100,000)",
       color = NULL, fill = NULL, linetype = NULL,
       title = "Predictions vs. realized ATTs (2016-2022)",
       subtitle = "Stand-your-ground laws and firearm homicide; 95% EIF-based intervals") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", legend.direction = "vertical",
        panel.grid.minor = element_blank()) +
  scale_x_continuous(breaks = 2016:2022)

ggsave("application/figures/validation_plot.pdf", p, width = 8, height = 6, units = "in")
ggsave("application/figures/validation_plot.png", p, width = 8, height = 6,
       units = "in", dpi = 300)

cat("Saved: application/figures/validation_plot.{pdf,png}\n")
cat("\nValidation plot created successfully.\n")

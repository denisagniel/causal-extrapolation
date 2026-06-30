# Phase 1: Data Preparation & Exploration
# Real Application: Stand-Your-Ground Laws and Firearm Homicide
# Training: 1981-2015, Validation: 2016-2022

library(tidyverse)

# Load raw data
raw_data <- read_csv("application/data/underlying-data_firearm-homicide.csv",
                     show_col_types = FALSE)

cat("Raw data dimensions:", nrow(raw_data), "x", ncol(raw_data), "\n")
cat("Years:", min(raw_data$year), "-", max(raw_data$year), "\n")
cat("States:", length(unique(raw_data$state_residence_abb)), "\n")

# Aggregate deaths by state-year (sum across race categories)
# Key variables: deaths, population, covariates, treatments
analysis_data <- raw_data %>%
  group_by(state_residence_abb, year) %>%
  summarize(
    # Outcome
    deaths = sum(deaths, na.rm = TRUE),
    population = first(population),  # Same for both race categories

    # Treatment: Stand-Your-Ground law
    syg = first(syg),

    # Other treatments (for context)
    ubc = first(ubc),
    ma20 = first(ma20),
    cc_pc = first(cc_pc),
    cc_si = first(cc_si),

    # Covariates for Path 3
    poverty_rate = first(Poverty.Rate),
    urbanization = first(Percent.Urban.Households),
    pct_black = first(Percent.Black),
    unemployment = first(Unemployment.Rate),
    pct_hispanic = first(Percent.Hispanic),

    .groups = "drop"
  ) %>%
  rename(state = state_residence_abb)

# Compute outcome: deaths per 100,000
analysis_data <- analysis_data %>%
  mutate(deaths_per_100k = (deaths / population) * 100000)

# Identify SYG treatment cohorts (year each state first adopted)
syg_cohorts <- analysis_data %>%
  filter(syg == 1) %>%
  group_by(state) %>%
  summarize(cohort = min(year), .groups = "drop")

# Join cohort info back
analysis_data <- analysis_data %>%
  left_join(syg_cohorts, by = "state") %>%
  mutate(
    cohort = replace_na(cohort, 0),  # 0 for never-treated
    treated = (cohort > 0)
  )

# Check for balanced panel
panel_check <- analysis_data %>%
  group_by(state) %>%
  summarize(
    n_years = n(),
    year_min = min(year),
    year_max = max(year),
    .groups = "drop"
  )

cat("\nPanel structure:\n")
print(table(panel_check$n_years))
cat("Expected:", length(unique(analysis_data$year)), "years per state\n")

# Summary of SYG adoption
cat("\nSYG adoption summary:\n")
cat("Never treated:", sum(analysis_data$cohort == 0 & analysis_data$year == 2022), "states\n")
cat("Treated states:", length(unique(syg_cohorts$state)), "\n")
cat("Adoption years:", paste(sort(unique(syg_cohorts$cohort)), collapse = ", "), "\n")

# Check pre-treatment trends (simple event study visual check)
# Focus on training period 1981-2015
training_data <- analysis_data %>%
  filter(year <= 2015, cohort > 0) %>%
  mutate(
    event_time = year - cohort,
    # Restrict to +/- 10 years for visibility
    event_time_binned = case_when(
      event_time < -10 ~ -11,
      event_time > 10 ~ 11,
      TRUE ~ event_time
    )
  )

# Simple pre-trends check: mean outcome by event time
pretrends_check <- training_data %>%
  filter(event_time_binned >= -10, event_time_binned < 0) %>%
  group_by(event_time_binned) %>%
  summarize(
    mean_deaths = mean(deaths_per_100k, na.rm = TRUE),
    se_deaths = sd(deaths_per_100k, na.rm = TRUE) / sqrt(n()),
    n_states = n(),
    .groups = "drop"
  ) %>%
  arrange(event_time_binned)

cat("\nPre-treatment mean deaths per 100k by event time:\n")
print(pretrends_check)

# Check for missing data in key variables
missing_summary <- analysis_data %>%
  summarize(
    n_obs = n(),
    deaths_missing = sum(is.na(deaths)),
    population_missing = sum(is.na(population)),
    syg_missing = sum(is.na(syg)),
    poverty_missing = sum(is.na(poverty_rate)),
    urbanization_missing = sum(is.na(urbanization)),
    pct_black_missing = sum(is.na(pct_black))
  )

cat("\nMissing data summary:\n")
print(missing_summary)

# Summary statistics for training period (1981-2015)
training_summary <- analysis_data %>%
  filter(year <= 2015) %>%
  summarize(
    mean_deaths_per_100k = mean(deaths_per_100k, na.rm = TRUE),
    sd_deaths_per_100k = sd(deaths_per_100k, na.rm = TRUE),
    mean_poverty = mean(poverty_rate, na.rm = TRUE),
    mean_urbanization = mean(urbanization, na.rm = TRUE),
    mean_pct_black = mean(pct_black, na.rm = TRUE)
  )

cat("\nTraining period summary statistics (1981-2015):\n")
print(training_summary)

# Save analysis-ready dataset
saveRDS(analysis_data, "application/results/analysis_data.rds")
cat("\nSaved: application/results/analysis_data.rds\n")

# Save key summaries for reference
write_csv(syg_cohorts, "application/results/syg_cohorts.csv")
write_csv(pretrends_check, "application/results/pretrends_check.csv")
cat("Saved: application/results/syg_cohorts.csv\n")
cat("Saved: application/results/pretrends_check.csv\n")

cat("\n=== Phase 1 Complete ===\n")
cat("Next: Run 02_estimate_gt_atts.R\n")

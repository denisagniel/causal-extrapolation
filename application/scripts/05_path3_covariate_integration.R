# Phase 2.4: Path 3 - Direct CATE + Covariate Transport (conditional DR-DiD)
# ----------------------------------------------------------------------------
# Path 3 estimates the covariate-conditional effect tau(x) directly from unit-level
# (state-level) data under conditional parallel trends, then transports it to the future
# treated covariate distribution, assembling the doubly-robust transport influence function
# via the package (integrate_cate(design = "did")). This replaces the old, invalid
# lm(att ~ covariates) ecological regression (audit C1).
#
# Design (conditional DiD collapse of the staggered panel):
#   - A          = early-adopter treated states (cohort in 1..2015) vs never-treated controls.
#     States adopting SYG in 2016+ are excluded from the source (they are treated in the
#     validation window, so they belong to neither a clean treated nor control arm here).
#   - dY         = post-minus-pre change in deaths-per-100k on the training window
#     (pre = 1981-1990, post = 2006-2015): the outcome change conditional parallel trends
#     restricts. Under conditional PT, DR-DiD is AIPW applied to dY.
#   - X          = baseline covariates (training-window means), dropping urbanization
#     (100% missing among treated).
#   - Transport  = for each future year t in 2016-2022, reweight the source to the early
#     adopters' covariate distribution in year t (Form B density ratio, estimated by
#     probabilistic classification, trimmed + self-normalized).
#
# Two CATE learners are compared (per the plan):
#   - Parametric conditional DR-DiD (primary): linear working models for m0, m1, e.
#   - Causal forest on dY (robustness): grf. At n ~ 43 states this is expected to be noisy;
#     we report it honestly as a sensitivity check, not the primary estimate.
#
# Honest limits: the effective sample size collapses under covariate shift (n_eff reported),
# and with ~43 states / 23 treated the conditional effect is weakly identified. Report
# whatever the method yields; do not tune for a favorable number.
#
# Trimming sensitivity (checked 2026-07-09): mean prediction over 2016-2022 is -0.10 at the
# 95th-pct trim, -0.43 at the 99th-pct trim, and -0.45 untrimmed. Trimming pulls the estimate
# UP toward the historical mean, so the reported (trimmed) numbers are the LEAST-underpredicting
# variant; the underprediction finding is robust to (indeed conservative under) this choice.
# ============================================================================

library(tidyverse)
library(fs)

devtools::load_all(".")

set.seed(20260709)
dir_create("application/results")

message("=== Phase 2.4: Path 3 - Direct CATE + Covariate Transport (DiD) ===\n")

data <- readr::read_rds("application/results/analysis_data.rds")

# Covariates usable for transport (urbanization dropped: 100% missing among treated).
covs <- c("poverty_rate", "pct_black", "unemployment", "pct_hispanic")

# Early adopters (treated in training window) drive the FATT transport target.
early_adopters <- data %>%
  filter(cohort > 0, cohort <= 2015) %>%
  distinct(state, cohort)

message("Early-adopter (treated) states: ", nrow(early_adopters))
message("Never-treated control states: ",
        n_distinct(data$state[data$cohort == 0]), "\n")

# ---------------------------------------------------------------------------
# 1. Build the conditional-DiD source contract on the training window (<= 2015).
# ---------------------------------------------------------------------------
train <- data %>%
  filter(year <= 2015, cohort == 0 | (cohort > 0 & cohort <= 2015))

# Outcome change dY = mean(post) - mean(pre) per state (conditional PT is on this change).
dY_tbl <- train %>%
  mutate(win = case_when(year <= 1990 ~ "pre",
                         year >= 2006 ~ "post",
                         TRUE ~ NA_character_)) %>%
  filter(!is.na(win)) %>%
  group_by(state, win) %>%
  summarize(y = mean(deaths_per_100k, na.rm = TRUE), .groups = "drop") %>%
  pivot_wider(names_from = win, values_from = y) %>%
  mutate(dY = post - pre)

# Baseline covariates per state = training-window means; A = treated indicator.
X_tbl <- train %>%
  group_by(state) %>%
  summarize(across(all_of(covs), ~mean(.x, na.rm = TRUE)),
            A = as.integer(first(cohort > 0)), .groups = "drop")

src <- dY_tbl %>%
  select(state, dY) %>%
  inner_join(X_tbl, by = "state") %>%
  drop_na()

message("Source contract: ", nrow(src), " states ( ",
        sum(src$A), " treated, ", sum(1 - src$A), " control )\n")

X_src <- src[, covs]
A_src <- src$A
dY_src <- src$dY
fm_cov <- paste(covs, collapse = " + ")

# ---------------------------------------------------------------------------
# 2. Two CATE learners -> generic DiD contract (tau, dY, m0_dY, e, A, X).
#    integrate_cate() forms m1 = m0_dY + tau internally (DR-DiD constraint).
# ---------------------------------------------------------------------------
clip <- function(p, lo = 0.05, hi = 0.95) pmin(pmax(p, lo), hi)

# (a) Parametric: linear outcome-change regressions per arm + logistic propensity.
build_contract_parametric <- function() {
  df <- bind_cols(dY = dY_src, X_src); df$A <- A_src
  fm_dY <- as.formula(paste("dY ~", fm_cov))
  m0 <- predict(lm(fm_dY, data = df[df$A == 0, ]), newdata = df)
  m1 <- predict(lm(fm_dY, data = df[df$A == 1, ]), newdata = df)
  e <- clip(predict(glm(as.formula(paste("A ~", fm_cov)), data = df,
                        family = binomial), type = "response"))
  list(tau = as.numeric(m1 - m0), dY = dY_src, m0_dY = as.numeric(m0),
       e = as.numeric(e), A = A_src, X = as.data.frame(X_src))
}

# (b) Causal forest on the CHANGE dY (conditional DiD = unconfoundedness on dY). Recover
#     m0 from grf's local-centering identity m0 = Y.hat - e * tau.
build_contract_forest <- function() {
  if (!requireNamespace("grf", quietly = TRUE)) return(NULL)
  Xm <- as.matrix(X_src)
  cf <- grf::causal_forest(Xm, dY_src, A_src, num.trees = 2000, seed = 20260709)
  tau <- as.numeric(predict(cf)$predictions)
  e <- clip(as.numeric(cf$W.hat))
  m0 <- as.numeric(cf$Y.hat) - e * tau
  list(tau = tau, dY = dY_src, m0_dY = m0, e = e,
       A = A_src, X = as.data.frame(X_src))
}

# ---------------------------------------------------------------------------
# 3. Per-year covariate transport. Target = early adopters' covariates in year t.
#    Density ratio w = dF_target/dF_source estimated by pooled-logistic classification,
#    trimmed at the 95th percentile and self-normalized so E_src[w] = 1.
# ---------------------------------------------------------------------------
transport_weights_for_year <- function(t) {
  tgt <- data %>%
    filter(state %in% early_adopters$state, year == t) %>%
    select(all_of(covs)) %>%
    drop_na()
  pool <- bind_rows(mutate(as.data.frame(X_src), .lab = 0),
                    mutate(as.data.frame(tgt), .lab = 1))
  cl <- suppressWarnings(
    glm(as.formula(paste(".lab ~", fm_cov)), data = pool, family = binomial))
  ps <- predict(cl, newdata = as.data.frame(X_src), type = "response")
  w <- (ps / (1 - ps)) * (nrow(X_src) / nrow(tgt))  # density ratio, base-rate corrected
  # Trim extreme ratios at the 95th percentile (overlap guard). NOTE the bias direction:
  # trimming CAPS the most up-weighted source units, pulling the estimate TOWARD the source
  # (historical) mean. A sensitivity check (see header) confirms the untrimmed estimates are
  # even lower, so trimming makes Path 3 look LESS like an underprediction, not more -- the
  # underprediction finding is conservative w.r.t. this choice, not manufactured by it.
  w <- pmin(w, stats::quantile(w, 0.95))
  w / mean(w)                                       # self-normalize: E_src[w] = 1
}

predict_path3 <- function(build_contract, label) {
  contract <- build_contract()
  if (is.null(contract)) return(NULL)
  future_years <- 2016:2022
  n_src <- length(contract$tau)
  rows <- purrr::map_dfr(future_years, function(t) {
    w <- transport_weights_for_year(t)
    # Suppress ONLY the expected misnormalization warning (weights are self-normalized, so
    # mean(w) = 1 by construction); the substantive heavy-covariate-shift/overlap warning is
    # allowed through so poor overlap is surfaced, not hidden.
    res <- withCallingHandlers(
      integrate_cate(contract, design = "did", weights = w, level = 0.95),
      warning = function(cnd) {
        if (grepl("misnormalized", conditionMessage(cnd))) invokeRestart("muffleWarning")
      })
    tibble(year = t, att_pred = res$estimate, se_pred = res$se,
           ci_lower = res$ci[1], ci_upper = res$ci[2], n_eff = res$n_eff)
  })
  message("Path 3 (", label, ") predictions 2016-2022:")
  print(rows)
  # Report the overlap diagnostic explicitly: effective sample vs the 43 source states.
  message(sprintf("  overlap: n_eff ranges %.0f-%.0f of %d source states (low => heavy shift)\n",
                  min(rows$n_eff), max(rows$n_eff), n_src))
  rows
}

message("--- Learner (a): parametric conditional DR-DiD (primary) ---")
pred_param <- predict_path3(build_contract_parametric, "parametric")

message("--- Learner (b): causal forest on dY (robustness) ---")
pred_forest <- predict_path3(build_contract_forest, "causal forest")

# ---------------------------------------------------------------------------
# 4. Cohort weights omega_g (match Paths 1-2 for the validation join).
# ---------------------------------------------------------------------------
omega_tbl <- readr::read_csv("application/results/syg_cohorts.csv",
                             show_col_types = FALSE) %>%
  filter(cohort > 0, cohort <= 2015) %>%
  count(cohort, name = "n_states") %>%
  mutate(omega = n_states / sum(n_states))

# Primary = parametric; forest carried as a sensitivity result.
readr::write_rds(list(
  predictions = pred_param %>% select(year, att_pred, se_pred, ci_lower, ci_upper),
  predictions_forest = if (!is.null(pred_forest))
    pred_forest %>% select(year, att_pred, se_pred, ci_lower, ci_upper) else NULL,
  n_eff = pred_param$n_eff,
  omega = omega_tbl,
  covariates = covs,
  method = "Direct CATE + covariate transport (conditional DR-DiD, parametric)",
  method_forest = "Direct CATE + covariate transport (conditional DR-DiD, causal forest)"
), "application/results/path3_covariate_integration.rds")

message("Saved: application/results/path3_covariate_integration.rds")
message("\n=== Phase 2.4 Complete ===")
message("Next: Run 06_validation.R")

# Global variable declarations to avoid R CMD check NOTEs
# These variables are used in dplyr/tidyr pipelines and ggplot2

utils::globalVariables(c(
  # Used in integrate_covariates.R
  "g", "tau_hat", "n_cells",
  # Used in cv_extrapolate_ATT.R
  "model", "coverage", "horizon", "mspe",
  # Used in average_models.R
  "weight"
))

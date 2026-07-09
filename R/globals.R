# Global variable declarations to avoid R CMD check NOTEs
# These variables are used in dplyr/tidyr pipelines and ggplot2

utils::globalVariables(c(
  # Used in dplyr pipelines across the package (e.g. aggregation helpers)
  "g", "tau_hat",
  # Used in cv_extrapolate_ATT.R
  "model", "coverage", "horizon", "mspe",
  # Used in average_models.R
  "weight"
))

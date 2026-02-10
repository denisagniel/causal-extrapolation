# Run full simulation suite (sections 1-6 from simulation-ideas.md)
# Run from project root: source("sims/run_all.R") or Rscript sims/run_all.R

set.seed(123)

# Optional config: create sims/config/sim_config.R to set n_replicates, n, sigma_tau, etc.
if (file.exists("sims/config/sim_config.R")) {
  source("sims/config/sim_config.R")
}

devtools::load_all("package")
source("sims/scripts/dgp_helpers.R")

source("sims/scripts/sim_section1_backward_vs_fatt.R")
source("sims/scripts/sim_section2_path1_homogeneity.R")
source("sims/scripts/sim_section3_path2_spec.R")
source("sims/scripts/sim_section4_eif_coverage.R")
source("sims/scripts/sim_section5_path1_vs_path2.R")
source("sims/scripts/sim_section6_omega.R")

message("All simulation sections completed. Results in sims/results/")

# Run full simulation suite (sections 1-6 from simulation-ideas.md, plus 4b locally)
# Run from project root: source("sims/run_all.R") or Rscript sims/run_all.R
#
# Heavy sections (4b full 1000 reps, section 7 estimated CATE) run on O2.
# See sims/slurm/README_O2.md for cluster instructions.

set.seed(123)

# Optional config: create sims/config/sim_config.R to set n_replicates, n, sigma_tau, etc.
if (file.exists("sims/config/sim_config.R")) {
  source("sims/config/sim_config.R")
}

# Load package (repo root layout; fall back to package/ for older checkouts)
if (file.exists("DESCRIPTION")) devtools::load_all(".") else devtools::load_all("package")
source("sims/scripts/dgp_helpers.R")

source("sims/scripts/sim_section1_backward_vs_fatt.R")
source("sims/scripts/sim_section2_path1_homogeneity.R")
source("sims/scripts/sim_section3_path2_spec.R")
source("sims/scripts/sim_section4_eif_coverage.R")
source("sims/scripts/sim_section5_path1_vs_path2.R")
source("sims/scripts/sim_section6_omega.R")
source("sims/scripts/sim_section7_path3_covariates.R")

# Section 4b: real did::att_gt() first stage (local run uses n_replicates = 200;
# full 1000-rep run lives on O2 — see sims/slurm/).
if (!exists("n_replicates")) n_replicates <- 200L
source("sims/scripts/sim_section4b_real_firststage.R")
rm(n_replicates)  # reset so subsequent scripts use their own defaults

message("All simulation sections completed. Results in sims/results/")
message("For full 1000-rep runs of sections 4b and 7 (estimated CATE): see sims/slurm/README_O2.md")

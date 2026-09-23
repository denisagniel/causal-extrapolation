#!/usr/bin/env Rscript
# =============================================================================
# purge_failed_tasks.R -- delete all-NA (DGP-failed) task_*.rds so --resume
# regenerates them, leaving good task files untouched.
# =============================================================================
# Motivation: the resumed run wrote task files even for reps whose DGP threw
# (MDDID_FITTED_DIR was unset -> fitted objects "not found" -> run_one.R emitted
# an all-NA row per estimator). The idempotent skip in run_replication.R keys on
# task file EXISTENCE, so those poisoned files would be skipped on a plain resume.
# This script identifies FAILED task files and removes them (plus any lingering
# partials/unit_*.rds), so resume recomputes only those. A task file is failed if
# EITHER (a) EVERY row has an NA estimate (whole-DGP failure), OR (b) ANY row
# recorded a failure in the error_msg column (a per-estimator or DGP failure whose
# error TEXT was persisted by run_one.R). Detecting error_msg catches poisoned
# tasks that carry some good rows but also genuine failures -- a plain all-NA check
# would miss those.
#
# Usage:
#   Rscript slurm/purge_failed_tasks.R --scratch-dir <dir> [--apply]
# Default is a DRY RUN (lists what would be deleted). Pass --apply to delete.
# =============================================================================

suppressPackageStartupMessages(library(optparse))
opt <- parse_args(OptionParser(option_list = list(
  make_option("--scratch-dir", type = "character", dest = "scratch_dir",
              help = "Run scratch dir containing task_*.rds"),
  make_option("--apply", action = "store_true", default = FALSE, dest = "apply",
              help = "Actually delete (default: dry run)")
)))
stopifnot(!is.null(opt$scratch_dir), dir.exists(opt$scratch_dir))

task_files <- list.files(opt$scratch_dir, pattern = "^task_[0-9]+\\.rds$", full.names = TRUE)
cat(sprintf("Scanning %d task files in %s\n", length(task_files), opt$scratch_dir))

# A task file is FAILED if: unreadable/empty, OR every row has an NA estimate
# (whole-DGP failure), OR any row recorded a non-NA error_msg (per-estimator or
# DGP failure whose text was persisted by run_one.R).
is_failed <- function(f) {
  x <- tryCatch(readRDS(f), error = function(e) NULL)
  if (is.null(x) || !"estimate" %in% names(x) || nrow(x) == 0) return(TRUE)  # unreadable/empty -> regenerate
  if (all(is.na(x$estimate))) return(TRUE)                                   # whole-DGP failure
  if ("error_msg" %in% names(x) && any(!is.na(x$error_msg))) return(TRUE)    # recorded failure text
  FALSE
}

failed <- character(0)
for (i in seq_along(task_files)) {
  if (is_failed(task_files[i])) failed <- c(failed, task_files[i])
  if (i %% 500 == 0) cat(sprintf("  ...scanned %d/%d (%d failed so far)\n", i, length(task_files), length(failed)))
}

cat(sprintf("\nFound %d failed / unreadable task files (of %d).\n", length(failed), length(task_files)))
if (length(failed)) {
  cat("Examples:\n"); cat(paste0("  ", head(basename(failed), 10)), sep = "\n"); cat("\n")
}

partials_dir <- file.path(opt$scratch_dir, "partials")
partials <- if (dir.exists(partials_dir)) list.files(partials_dir, pattern = "^unit_[0-9]+\\.rds$", full.names = TRUE) else character(0)

if (!opt$apply) {
  cat(sprintf("\nDRY RUN. Would delete %d task files and %d lingering partials.\n",
              length(failed), length(partials)))
  cat("Re-run with --apply to delete.\n")
} else {
  n1 <- sum(file.remove(failed))
  n2 <- if (length(partials)) sum(file.remove(partials)) else 0L
  cat(sprintf("\nDeleted %d failed task files and %d partials.\n", n1, n2))
  cat("Now resubmit with MDDID_FITTED_DIR set (see runbook).\n")
}

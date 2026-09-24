# Tests for integrate_cate() (Path 3: direct CATE + covariate transport)

test_that("ATT collapse certificate: target = treated reproduces Hahn's ATT EIF", {
  # Regime (i) certificate. With target = the treated set and the unconfoundedness design,
  # the transport EIF must reproduce the efficient ATT influence function exactly:
  #   phi = (A/pi) (tau - theta) + (e/pi) * aug,
  #   aug = A (Y - mu1)/e - (1 - A)(Y - mu0)/(1 - e).
  # Note the two DIFFERENT weights: the hard indicator A/pi centers tau, while the SMOOTH
  # propensity e/pi carries the augmentation. Weighting the augmentation by A/pi instead
  # would annihilate its (1 - A) branch (since A(1 - A) == 0), discarding every untreated
  # outcome and destroying double robustness with respect to mu0.
  n <- 400
  cate <- make_cate_input(n = n, d = 1, seed = 20260708)
  target <- which(cate$A == 1)

  res <- integrate_cate(cate, design = "unconfoundedness", target = target)

  pi_hat <- mean(cate$A)
  aug <- cate$A * (cate$Y - cate$mu1) / cate$e -
    (1 - cate$A) * (cate$Y - cate$mu0) / (1 - cate$e)
  w_center <- cate$A / pi_hat        # == (n / n_star) 1{i in target}
  w_aug <- cate$e / pi_hat           # == target_score / P(i in target)

  psi_ref <- mean(w_center * cate$tau) + mean(w_aug * aug)
  phi_ref <- w_center * (cate$tau - psi_ref) + w_aug * aug

  expect_equal(res$estimate, psi_ref, tolerance = 1e-12)
  expect_equal(res$phi, phi_ref, tolerance = 1e-10)
  # One-step estimate => EIF exactly mean-zero (mean(w_center) == 1 by construction).
  expect_equal(mean(res$phi), 0, tolerance = 1e-10)

  # The sharpest regression check against the single-weight bug: under that bug every
  # untreated unit's influence-function contribution was identically zero.
  expect_true(any(res$phi[cate$A == 0] != 0))
  expect_false(all(res$phi[cate$A == 0] == 0))
})


test_that("ATE collapse certificate: target = full source reduces to AIPW/ATE EIF", {
  cate <- make_cate_input(n = 400, d = 1, seed = 20260708)

  # Target = full source sample => both weights are identically 1, r == 0. At w == 1 for
  # EVERY unit the score averages tau over the whole population, so the functional here is
  # the ATE, not the ATT: this is the no-shift certificate against the ordinary AIPW/ATE
  # efficient influence function.
  res <- integrate_cate(cate, design = "unconfoundedness", target = seq_len(400))

  # Estimate is the ordinary AIPW/ATE one-step: plug-in mean(tau) + mean(AIPW correction).
  correction <- cate$A * (cate$Y - cate$mu1) / cate$e -
    (1 - cate$A) * (cate$Y - cate$mu0) / (1 - cate$e)
  aipw_onestep <- mean(cate$tau) + mean(correction)
  expect_equal(res$estimate, aipw_onestep, tolerance = 1e-12)

  # phi must equal the hand-computed ordinary AIPW EIF (centered on the same estimate) to
  # machine precision -- the no-shift (ATE) collapse certificate.
  ref <- reference_aipw_eif(cate, res$estimate)
  expect_equal(res$phi, ref, tolerance = 1e-10)
  # And the EIF is exactly mean-zero (estimate is the functional the EIF corresponds to).
  expect_equal(mean(res$phi), 0, tolerance = 1e-10)

  # w is identically 1 in the no-shift case.
  expect_equal(res$w, rep(1, 400), tolerance = 1e-12)
  expect_equal(res$form, "target_index")
})


test_that("weights = rep(1, n) matches target = seq_len(n) (Form B no-shift)", {
  cate <- make_cate_input(n = 300, d = 2, seed = 11)

  res_a <- integrate_cate(cate, design = "unconfoundedness", target = seq_len(300))
  res_b <- integrate_cate(cate, design = "unconfoundedness", weights = rep(1, 300))

  expect_equal(res_a$estimate, res_b$estimate, tolerance = 1e-12)
  expect_equal(res_a$phi, res_b$phi, tolerance = 1e-10)
})


test_that("Form A and Form B are distinct estimators for a hard target subset", {
  # Updated: Form A (an internal target) and Form B (a density ratio) no longer coincide
  # when handed the same hard membership weight, and must not. Form B applies its weight to
  # both terms of the score, which is correct for a smooth density ratio; a hard indicator
  # used that way annihilates the untreated arm of the correction. Form A therefore weights
  # the correction by the smooth membership propensity instead. This test now pins down both
  # the Form B assembly and the fact that the two forms differ.
  cate <- make_cate_input(n = 500, d = 1, seed = 22)
  idx <- which(cate$A == 1)               # treated units (the FATT target)
  n <- 500
  n_star <- length(idx)

  # Implied hard membership weight for this index target.
  w_implied <- numeric(n)
  w_implied[idx] <- n / n_star

  res_a <- integrate_cate(cate, design = "unconfoundedness", target = idx)
  res_b <- integrate_cate(cate, design = "unconfoundedness", weights = w_implied)

  # Form B: single weight on the whole score, exactly as documented for Regime (iii).
  correction <- cate$A * (cate$Y - cate$mu1) / cate$e -
    (1 - cate$A) * (cate$Y - cate$mu0) / (1 - cate$e)
  psi_b <- mean(w_implied * cate$tau) + mean(w_implied * correction)
  expect_equal(res_b$estimate, psi_b, tolerance = 1e-12)
  expect_equal(res_b$phi, w_implied * (cate$tau - psi_b) + w_implied * correction,
               tolerance = 1e-10)

  # Both forms average tau over the same units, so their centering weights agree...
  expect_equal(res_a$w, w_implied, tolerance = 1e-12)
  # ... but the augmentation weights, and hence the scores, do not.
  expect_false(isTRUE(all.equal(res_a$w_aug, res_b$w_aug)))
  expect_false(isTRUE(all.equal(res_a$phi, res_b$phi)))
  # Form A keeps the untreated arm alive; Form B with a hard weight discards it.
  expect_true(any(res_a$phi[cate$A == 0] != 0))
  expect_true(all(res_b$phi[cate$A == 0] == 0))
})


test_that("logical and integer target specifications agree", {
  cate <- make_cate_input(n = 250, d = 1, seed = 33)
  mask <- cate$A == 1

  res_logical <- integrate_cate(cate, design = "unconfoundedness", target = mask)
  res_integer <- integrate_cate(cate, design = "unconfoundedness", target = which(mask))

  expect_equal(res_logical$estimate, res_integer$estimate, tolerance = 1e-12)
  expect_equal(res_logical$phi, res_integer$phi, tolerance = 1e-12)
})


test_that("known-DGP: oracle CATE recovers the in-sample FATT with finite inference", {
  # With oracle (correctly specified) nuisances, the AIPW correction is mean-zero in the
  # population, so the one-step estimate is close to the in-sample FATT (up to O(n^-1/2)
  # noise in the empirical correction), and the EIF is exactly mean-zero.
  cate <- make_cate_input(n = 800, d = 1, seed = 20260709)
  idx <- which(cate$A == 1)
  res <- integrate_cate(cate, design = "unconfoundedness", target = idx)

  expect_equal(res$estimate, attr(cate, "true_fatt"), tolerance = 0.1)
  expect_true(is.finite(res$se) && res$se > 0)
  expect_true(res$ci[1] < res$estimate && res$estimate < res$ci[2])
  # One-step estimate => EIF centered exactly on its own estimand.
  expect_equal(mean(res$phi), 0, tolerance = 1e-10)
})


test_that("d > 1 covariates: assembly matches a manual vectorized computation", {
  cate <- make_cate_input(n = 300, d = 3, seed = 44)
  idx <- which(cate$A == 1)
  res <- integrate_cate(cate, design = "unconfoundedness", target = idx)

  # Manual reconstruction with the two weights and the one-step psi. Updated: the correction
  # now carries the smooth membership propensity e/pihat rather than the hard indicator, so
  # that both of its arms contribute.
  n <- 300
  w_center <- numeric(n); w_center[idx] <- n / length(idx)
  w_aug <- cate$e * (n / length(idx))
  correction <- cate$A * (cate$Y - cate$mu1) / cate$e -
    (1 - cate$A) * (cate$Y - cate$mu0) / (1 - cate$e)
  psi <- mean(w_center * cate$tau) + mean(w_aug * correction)  # one-step estimate
  phi_manual <- w_center * (cate$tau - psi) + w_aug * correction

  expect_equal(res$phi, phi_manual, tolerance = 1e-10)
  expect_equal(res$estimate, psi, tolerance = 1e-12)
})


test_that("DiD ATE collapse certificate: target = full source reduces to DR-DiD EIF", {
  cate <- make_cate_input(n = 400, d = 1, design = "did", seed = 20260708)

  # Target = full source sample => both weights are identically 1, r == 0. As in the
  # unconfoundedness case, averaging over EVERY unit makes this the ATE functional.
  res <- integrate_cate(cate, design = "did", target = seq_len(400))

  # DR-DiD correction = AIPW on the change dY with m1 = m0_dY + tau.
  m1 <- cate$m0_dY + cate$tau
  correction <- cate$A * (cate$dY - m1) / cate$e -
    (1 - cate$A) * (cate$dY - cate$m0_dY) / (1 - cate$e)
  onestep <- mean(cate$tau) + mean(correction)
  expect_equal(res$estimate, onestep, tolerance = 1e-12)

  # phi must equal the hand-computed ordinary DR-DiD EIF, centered on the same estimate.
  ref <- (cate$tau - res$estimate) + correction
  expect_equal(res$phi, ref, tolerance = 1e-10)
  expect_equal(mean(res$phi), 0, tolerance = 1e-10)

  expect_equal(res$w, rep(1, 400), tolerance = 1e-12)
  expect_equal(res$form, "target_index")
  expect_equal(res$design, "did")
})


test_that("DiD one-step matches its own EIF with misspecified nuisances", {
  # Same regression guard as the unconfoundedness case: with misspecified nuisances the
  # mean orthogonal correction is non-zero, so plug-in and one-step differ. The reported
  # estimate must be the one-step (the estimand the EIF is the IF of); then mean(phi) == 0.
  cate <- make_cate_input(n = 2000, d = 1, design = "did", seed = 20260710)
  # Corrupt the nuisances so mean(w*correction) != 0.
  cate$m0_dY <- 0.5 * cate$X$x1
  cate$tau   <- 0.8 + 0.3 * cate$X$x1
  cate$e     <- plogis(0.4 * cate$X$x1)

  idx <- which(cate$A == 1)
  res <- integrate_cate(cate, design = "did", target = idx)

  # Updated: the DR-DiD correction now carries the smooth membership propensity e/pihat, so
  # the comparison group's outcome-change data is retained. Under the hard indicator the
  # entire (1 - A) branch vanished -- discarding exactly the comparison-group information the
  # DiD identification strategy rests on.
  n <- 2000
  w_center <- numeric(n); w_center[idx] <- n / length(idx)
  w_aug <- cate$e * (n / length(idx))
  m1 <- cate$m0_dY + cate$tau
  correction <- cate$A * (cate$dY - m1) / cate$e -
    (1 - cate$A) * (cate$dY - cate$m0_dY) / (1 - cate$e)
  onestep <- mean(w_center * cate$tau) + mean(w_aug * correction)
  plugin  <- mean(cate$tau[idx])

  expect_equal(res$estimate, onestep, tolerance = 1e-10)
  expect_true(abs(res$estimate - plugin) > 1e-3)   # genuinely differs from plug-in
  expect_equal(mean(res$phi), 0, tolerance = 1e-10) # EIF centered on its own estimand
  expect_true(any(res$phi[cate$A == 0] != 0))       # comparison group contributes
})


test_that("DiD point estimate cross-checks against DRDID::drdid()", {
  skip_if_not_installed("DRDID")
  set.seed(20260709)
  n <- 4000
  x <- rnorm(n)
  e <- plogis(0.6 * x)
  A <- rbinom(n, 1, e)
  tau_x <- 1 + 0.5 * x        # true conditional DiD effect
  m0 <- 0.3 * x              # E[dY | X, A = 0]
  dY <- m0 + A * tau_x + rnorm(n, sd = 0.5)

  cate <- list(tau = tau_x, dY = dY, m0_dY = m0, e = e, A = A,
               X = data.frame(x1 = x))
  res <- integrate_cate(cate, design = "did", target = which(A == 1))

  # Reconstruct a 2-period long panel for DRDID: any y_pre works since it differences it
  # out (y_post - y_pre = dY).
  y_pre <- rnorm(n)
  dat <- data.frame(
    id = rep(seq_len(n), 2), time = rep(c(0, 1), each = n),
    y = c(y_pre, y_pre + dY), d = rep(A, 2), x1 = rep(x, 2)
  )
  fit <- DRDID::drdid(yname = "y", tname = "time", idname = "id", dname = "d",
                      xformla = ~x1, data = dat, panel = TRUE,
                      estMethod = "imp", inffunc = TRUE)

  # Point estimates target the same treated-ATT estimand; agree within Monte Carlo error.
  expect_equal(res$estimate, fit$ATT, tolerance = 0.05)
  expect_equal(mean(res$phi), 0, tolerance = 1e-10)
  # SE is finite/positive. We deliberately do NOT assert res$se == fit$se: integrate_cate
  # Form A uses a hard target weight 1{A=1}, whereas Sant'Anna-Zhao's ATT influence function
  # uses the smooth propensity weight e/E[A]. The two variances differ by construction even
  # at the same point estimand, so an SE-equality assertion would be a false certificate.
  expect_true(is.finite(res$se) && res$se > 0)
})


test_that("compute_variance integration: se/ci match a direct call", {
  cate <- make_cate_input(n = 350, d = 1, seed = 66)
  idx <- which(cate$A == 1)
  res <- integrate_cate(cate, design = "unconfoundedness", target = idx)

  direct <- compute_variance(res$phi, estimate = res$estimate, level = 0.95)
  expect_equal(res$se, direct$se, tolerance = 1e-12)
  expect_equal(res$ci, direct$ci, tolerance = 1e-12)
  expect_equal(res$var, direct$var, tolerance = 1e-12)
})


test_that("overlap diagnostic fires under heavy covariate shift", {
  cate <- make_cate_input(n = 300, d = 1, seed = 77)
  # Concentrate nearly all weight on a single unit => tiny effective sample size.
  w <- numeric(300)
  w[1] <- 300  # mean(w) == 1, but n_eff ~ 1
  expect_warning(
    integrate_cate(cate, design = "unconfoundedness", weights = w),
    "effective sample size"
  )
})


test_that("input validation: errors are informative", {
  cate <- make_cate_input(n = 100, d = 1, seed = 88)

  # Neither target nor weights.
  expect_error(
    integrate_cate(cate, design = "unconfoundedness"),
    "exactly one of"
  )
  # Both target and weights.
  expect_error(
    integrate_cate(cate, design = "unconfoundedness",
                   target = seq_len(100), weights = rep(1, 100)),
    "only one of"
  )
  # External covariate frame as target.
  expect_error(
    integrate_cate(cate, design = "unconfoundedness",
                   target = data.frame(x1 = rnorm(50))),
    "does not estimate a density ratio"
  )
  # Wrong-length weights.
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", weights = rep(1, 50)),
    "length 50 but n = 100"
  )
  # Propensity out of (0, 1).
  bad <- cate
  bad$e[1] <- 0
  expect_error(
    integrate_cate(bad, design = "unconfoundedness", target = seq_len(100)),
    "must lie strictly in \\(0, 1\\)"
  )
  # Missing slot.
  bad2 <- cate
  bad2$mu1 <- NULL
  expect_error(
    integrate_cate(bad2, design = "unconfoundedness", target = seq_len(100)),
    "missing required slots"
  )
})


test_that("one-step estimate matches its own EIF with estimated (biased) nuisances", {
  # The regression that the oracle tests missed: with misspecified nuisances the mean
  # orthogonal correction is non-zero, so the plug-in and one-step estimators differ.
  # The reported estimate must be the one-step (plug-in + mean correction), i.e. the
  # estimand the EIF is the influence function of; then mean(phi) == 0 in Form A.
  cate <- make_cate_input(n = 2000, d = 1, seed = 20260710)
  # Corrupt the nuisances so mean(w*correction) != 0.
  cate$mu0 <- 0.5 * cate$X$x1
  cate$mu1 <- cate$mu0 + (0.8 + 0.3 * cate$X$x1)
  cate$tau <- cate$mu1 - cate$mu0
  cate$e   <- plogis(0.4 * cate$X$x1)

  idx <- which(cate$A == 1)
  res <- integrate_cate(cate, design = "unconfoundedness", target = idx)

  # Updated: the correction is weighted by e/pihat, not by the hard indicator.
  n <- 2000
  w_center <- numeric(n); w_center[idx] <- n / length(idx)
  w_aug <- cate$e * (n / length(idx))
  correction <- cate$A * (cate$Y - cate$mu1) / cate$e -
    (1 - cate$A) * (cate$Y - cate$mu0) / (1 - cate$e)
  onestep <- mean(w_center * cate$tau) + mean(w_aug * correction)
  plugin  <- mean(cate$tau[idx])

  expect_equal(res$estimate, onestep, tolerance = 1e-10)
  expect_true(abs(res$estimate - plugin) > 1e-3)  # genuinely differs from plug-in
  expect_equal(mean(res$phi), 0, tolerance = 1e-10)  # EIF centered on its own estimand
})


test_that("non-finite EIF is caught (e slipping to boundary with validate = FALSE)", {
  cate <- make_cate_input(n = 100, d = 1, seed = 121)
  cate$e[1] <- 0  # division by zero in the AIPW correction
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", target = seq_len(100),
                   validate = FALSE),
    "non-finite"
  )
})


test_that("all-zero and non-integer targets error", {
  cate <- make_cate_input(n = 100, d = 1, seed = 131)
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", weights = rep(0, 100)),
    "all zero"
  )
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", target = c(1, 2.5)),
    "whole-number"
  )
})


test_that("single-unit target warns", {
  cate <- make_cate_input(n = 100, d = 1, seed = 141)
  # target_score must be supplied: a one-row target is neither the full source nor the
  # treated set, so its membership propensity has no exact default.
  # A one-row target also trips the effective-sample-size diagnostic, so both warnings are
  # asserted rather than left to leak into the test report.
  expect_warning(
    expect_warning(
      integrate_cate(cate, design = "unconfoundedness", target = 1L,
                     target_score = cate$e),
      "single source row"
    ),
    "effective sample size"
  )
})


test_that("misnormalized weights trigger a warning", {
  cate <- make_cate_input(n = 200, d = 1, seed = 99)
  expect_warning(
    integrate_cate(cate, design = "unconfoundedness", weights = rep(2, 200)),
    "misnormalized"
  )
})


test_that("as_cate design attribute overrides and warns on conflict", {
  cate <- make_cate_input(n = 150, d = 1, seed = 101)
  attr(cate, "design") <- "unconfoundedness"
  # Requesting 'did' conflicts with the carried 'unconfoundedness'.
  expect_warning(
    integrate_cate(cate, design = "did", target = seq_len(150)),
    "conflicts with the design"
  )
})


test_that("print.cate_integration produces a readable summary", {
  cate <- make_cate_input(n = 200, d = 1, seed = 111)
  res <- integrate_cate(cate, design = "unconfoundedness", target = which(cate$A == 1))
  expect_output(print(res), "Path 3: CATE integration")
  expect_output(print(res), "Estimate:")
  expect_output(print(res), "unconfoundedness")
})


# --- Truncation (Task 3: bias-aware weight capping for weak overlap) ------------------

test_that("trunc = Inf is a no-op (matches the untruncated default)", {
  cate <- make_cate_input(n = 300, d = 1, seed = 555)
  idx <- which(cate$A == 1)
  res_default <- integrate_cate(cate, design = "unconfoundedness", target = idx)
  res_inf <- integrate_cate(cate, design = "unconfoundedness", target = idx, trunc = Inf)

  expect_equal(res_default$estimate, res_inf$estimate, tolerance = 1e-12)
  expect_equal(res_default$se, res_inf$se, tolerance = 1e-12)
  expect_true(is.infinite(res_inf$trunc))
  expect_equal(res_inf$trunc_diag$delta_trunc, 0)
  expect_equal(res_inf$trunc_diag$bias_bound, 0)
  expect_null(res_inf$two_sample)
})


test_that("truncation strictly reduces SE under heavy-tailed weights", {
  n <- 500
  set.seed(2026)
  cate <- make_cate_input(n = n, d = 1, seed = 2026)
  # Moderate lognormal heavy tail (mean 1); capping at the 90th percentile discards
  # ~16% of target weight mass -- well under the 50% guard -- while still stabilizing
  # the handful of large weights in the tail.
  w_raw <- exp(rnorm(n, mean = 0, sd = 1.0))
  w <- w_raw / mean(w_raw)
  C <- unname(stats::quantile(w, 0.90))

  res_full  <- suppressWarnings(integrate_cate(cate, design = "unconfoundedness",
                                               weights = w))
  res_trunc <- suppressWarnings(integrate_cate(cate, design = "unconfoundedness",
                                               weights = w, trunc = C))

  expect_true(res_trunc$se < res_full$se)
  expect_equal(res_trunc$trunc, C)
  expect_true(res_trunc$trunc_diag$delta_trunc > 0)
  expect_true(res_trunc$trunc_diag$delta_trunc < 0.5)
  expect_true(res_trunc$trunc_diag$q_exceed >= 0)
  expect_true(res_trunc$trunc_diag$bias_bound >= 0)
  # w used for estimation is Hajek-renormalized: mean 1.
  expect_equal(mean(res_trunc$w), 1, tolerance = 1e-10)
})


test_that("truncation bias bound is exactly zero when tau is constant on target", {
  n <- 400
  cate <- make_cate_input(n = n, d = 1, seed = 77)
  cate$tau <- rep(2.5, n)  # constant CATE => Var_Q(tau) == 0 under ANY measure Q
  cate$mu1 <- cate$mu0 + cate$tau
  w_raw <- c(rep(0.5, n - 4), c(40, 50, 60, 70))
  w <- w_raw / mean(w_raw)

  res <- suppressWarnings(integrate_cate(cate, design = "unconfoundedness", weights = w,
                                         trunc = 3))
  expect_equal(res$trunc_diag$var_q_tau, 0, tolerance = 1e-10)
  expect_equal(res$trunc_diag$bias_bound, 0, tolerance = 1e-10)
})


test_that("trunc = 'auto' selects a cap satisfying the bias/SE budget", {
  n <- 500
  set.seed(909)
  cate <- make_cate_input(n = n, d = 1, seed = 909)
  w_raw <- exp(rnorm(n, mean = 0, sd = 1.0))
  w <- w_raw / mean(w_raw)

  res <- suppressWarnings(integrate_cate(cate, design = "unconfoundedness", weights = w,
                                         trunc = "auto", trunc_gamma = 0.25))
  expect_true(is.numeric(res$trunc))
  expect_true(res$trunc_diag$bias_bound <= 0.25 * res$se + 1e-8)
})


test_that("trunc must be >= 1", {
  cate <- make_cate_input(n = 100, d = 1, seed = 33)
  # The argument's own validation runs before the regime gate, so a malformed cap reports
  # its own problem rather than the (also-applicable) internal-target restriction.
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", target = which(cate$A == 1),
                   trunc = 0.5),
    ">= 1"
  )
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", weights = rep(1, 100), trunc = 0.5),
    ">= 1"
  )
})


test_that("trunc errors when weight-mass loss exceeds 50%", {
  n <- 100
  cate <- make_cate_input(n = n, d = 1, seed = 44)
  # 90% of units carry negligible weight; 10% carry almost all the mass (mean 1 overall).
  w_raw <- c(rep(0.05, 0.9 * n), rep(9.55, 0.1 * n))
  w <- w_raw / mean(w_raw)
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", weights = w, trunc = 1),
    "discards"
  )
})


# --- External target samples: `n_target` is out of scope -------------------------------
# Updated: these tests previously asserted an additive variance addendum rho*Var_Q(tau)/n
# on top of the source-EIF variance. That decomposition does not describe inference for a
# genuinely external target sample (the correct bound replaces the source centering term
# with Var_target(tau)/n*, and needs per-target-unit CATE values the contract does not
# accept), so `n_target` now errors rather than returning a number its SE misdescribes.

test_that("n_target errors for Form B (external-target inference is out of scope)", {
  n <- 400
  cate <- make_cate_input(n = n, d = 1, seed = 606)
  w <- rep(1, n)

  expect_error(
    integrate_cate(cate, design = "unconfoundedness", weights = w, n_target = 200),
    "`n_target` is not supported"
  )
})


test_that("n_target errors for Form A too", {
  cate <- make_cate_input(n = 200, d = 1, seed = 707)
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", target = which(cate$A == 1),
                   n_target = 100),
    "not supported"
  )
})


test_that("n_target errors regardless of its value", {
  cate <- make_cate_input(n = 200, d = 1, seed = 808)
  w <- rep(1, 200)
  # Previously -5 was rejected as non-positive; the argument is now rejected outright, so
  # no value of it reaches the variance computation.
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", weights = w, n_target = -5),
    "not supported"
  )
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", weights = w, n_target = 250),
    "not supported"
  )
})


test_that("two_sample is always NULL in the supported regimes", {
  cate <- make_cate_input(n = 300, d = 1, seed = 909)
  res_a <- integrate_cate(cate, design = "unconfoundedness", target = which(cate$A == 1))
  res_b <- integrate_cate(cate, design = "unconfoundedness", weights = rep(1, 300))
  expect_null(res_a$two_sample)
  expect_null(res_b$two_sample)
})


# --- Regime (i): target_score contract -------------------------------------------------

test_that("target_score is required for a target that is neither full source nor treated", {
  cate <- make_cate_input(n = 300, d = 1, seed = 1212)
  idx <- which(cate$A == 1)[1:20]        # an arbitrary subset of the treated
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", target = idx),
    "`target_score` is required"
  )
})


test_that("target_score = cate$e reproduces the treated-set default", {
  cate <- make_cate_input(n = 300, d = 1, seed = 1313)
  idx <- which(cate$A == 1)
  res_default  <- integrate_cate(cate, design = "unconfoundedness", target = idx)
  res_explicit <- integrate_cate(cate, design = "unconfoundedness", target = idx,
                                 target_score = cate$e)
  expect_equal(res_default$estimate, res_explicit$estimate, tolerance = 1e-12)
  expect_equal(res_default$phi, res_explicit$phi, tolerance = 1e-12)
})


test_that("a custom target_score enters as q / P(i in target)", {
  cate <- make_cate_input(n = 300, d = 1, seed = 1414)
  n <- 300
  idx <- which(cate$X$x1 > 0)
  q <- plogis(2 * cate$X$x1)             # arbitrary but valid membership propensity
  res <- integrate_cate(cate, design = "unconfoundedness", target = idx, target_score = q)

  w_center <- numeric(n); w_center[idx] <- n / length(idx)
  w_aug <- q * (n / length(idx))
  expect_equal(res$w, w_center, tolerance = 1e-12)
  expect_equal(res$w_aug, w_aug, tolerance = 1e-12)

  correction <- cate$A * (cate$Y - cate$mu1) / cate$e -
    (1 - cate$A) * (cate$Y - cate$mu0) / (1 - cate$e)
  psi <- mean(w_center * cate$tau) + mean(w_aug * correction)
  expect_equal(res$estimate, psi, tolerance = 1e-12)
  expect_equal(res$phi, w_center * (cate$tau - psi) + w_aug * correction, tolerance = 1e-10)
})


test_that("target_score validation: length, sign, and Form B conflict", {
  cate <- make_cate_input(n = 200, d = 1, seed = 1515)
  idx <- which(cate$A == 1)
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", target = idx,
                   target_score = rep(0.5, 50)),
    "length 50 but n = 200"
  )
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", target = idx,
                   target_score = rep(-0.1, 200)),
    "non-negative"
  )
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", target = idx,
                   target_score = rep(0, 200)),
    "all zero"
  )
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", weights = rep(1, 200),
                   target_score = rep(0.5, 200)),
    "applies to Form A"
  )
})


# --- Truncation scope: Regime (iii) only -----------------------------------------------

test_that("a finite trunc is rejected for an internal target", {
  cate <- make_cate_input(n = 200, d = 1, seed = 1616)
  idx <- which(cate$A == 1)
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", target = idx, trunc = 2),
    "applies to `weights`"
  )
  expect_error(
    integrate_cate(cate, design = "unconfoundedness", target = idx, trunc = "auto"),
    "applies to `weights`"
  )
  # trunc = Inf (the default) remains a no-op there.
  res <- integrate_cate(cate, design = "unconfoundedness", target = idx, trunc = Inf)
  expect_true(is.infinite(res$trunc))
})

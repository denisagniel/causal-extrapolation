# Tests for integrate_cate() (Path 3: direct CATE + covariate transport)

test_that("collapse certificate: target = source reduces to AIPW/ATT EIF", {
  cate <- make_cate_input(n = 400, d = 1, seed = 20260708)

  # Target = full source sample => w == 1, r == 0.
  res <- integrate_cate(cate, design = "unconfoundedness", target = seq_len(400))

  # Estimate is the ordinary AIPW/ATT one-step: plug-in mean(tau) + mean(AIPW correction).
  correction <- cate$A * (cate$Y - cate$mu1) / cate$e -
    (1 - cate$A) * (cate$Y - cate$mu0) / (1 - cate$e)
  aipw_onestep <- mean(cate$tau) + mean(correction)
  expect_equal(res$estimate, aipw_onestep, tolerance = 1e-12)

  # phi must equal the hand-computed ordinary AIPW EIF (centered on the same estimate) to
  # machine precision -- the collapse certificate.
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


test_that("Form A (index) == Form B (implied weights) for a strict subset", {
  cate <- make_cate_input(n = 500, d = 1, seed = 22)
  idx <- which(cate$A == 1)               # treated units (the FATT target)
  n <- 500
  n_star <- length(idx)

  # Implied empirical density ratio for this index target.
  w_implied <- numeric(n)
  w_implied[idx] <- n / n_star

  res_a <- integrate_cate(cate, design = "unconfoundedness", target = idx)
  res_b <- integrate_cate(cate, design = "unconfoundedness", weights = w_implied)

  expect_equal(res_a$estimate, res_b$estimate, tolerance = 1e-10)
  expect_equal(res_a$phi, res_b$phi, tolerance = 1e-10)
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

  # Manual reconstruction of eq. (2) with w = (n/n_star) 1{idx} and the one-step psi.
  n <- 300
  w <- numeric(n); w[idx] <- n / length(idx)
  correction <- cate$A * (cate$Y - cate$mu1) / cate$e -
    (1 - cate$A) * (cate$Y - cate$mu0) / (1 - cate$e)
  psi <- mean(w * cate$tau) + mean(w * correction)  # one-step estimate
  phi_manual <- w * (cate$tau - psi) + w * correction

  expect_equal(res$phi, phi_manual, tolerance = 1e-10)
  expect_equal(res$estimate, psi, tolerance = 1e-12)
})


test_that("DiD design is gated off until the DR-DiD score is validated", {
  cate <- make_cate_input(n = 400, d = 1, design = "did", seed = 55)
  expect_error(
    integrate_cate(cate, design = "did", weights = rep(1, 400)),
    "not yet available"
  )
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

  w <- numeric(2000); w[idx] <- 2000 / length(idx)
  correction <- cate$A * (cate$Y - cate$mu1) / cate$e -
    (1 - cate$A) * (cate$Y - cate$mu0) / (1 - cate$e)
  onestep <- mean(w * cate$tau) + mean(w * correction)
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
  expect_warning(
    integrate_cate(cate, design = "unconfoundedness", target = 1L),
    "single source row"
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

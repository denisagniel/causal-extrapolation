# Tests for integrate_cate() (Path 3: direct CATE + covariate transport)

test_that("collapse certificate: target = source reduces to AIPW/ATT EIF", {
  cate <- make_cate_input(n = 400, d = 1, seed = 20260708)

  # Target = full source sample => w == 1, r == 0.
  res <- integrate_cate(cate, design = "unconfoundedness", target = seq_len(400))

  # Point estimate is the mean of tau over the (full) target.
  expect_equal(res$estimate, mean(cate$tau), tolerance = 1e-12)

  # phi must equal the hand-computed ordinary AIPW EIF to machine precision.
  ref <- reference_aipw_eif(cate, res$estimate)
  expect_equal(res$phi, ref, tolerance = 1e-10)

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
  # With oracle tau supplied, the point estimate is exactly the in-sample FATT
  # (mean of tau over the treated). The AIPW correction is mean-zero at the truth, so
  # it perturbs only the EIF/variance, not the point estimate.
  cate <- make_cate_input(n = 800, d = 1, seed = 20260709)
  idx <- which(cate$A == 1)
  res <- integrate_cate(cate, design = "unconfoundedness", target = idx)

  expect_equal(res$estimate, attr(cate, "true_fatt"), tolerance = 1e-12)
  expect_true(is.finite(res$se) && res$se > 0)
  expect_true(res$ci[1] < res$estimate && res$estimate < res$ci[2])
  # EIF is mean-zero in the population; the empirical mean is small (O(1/sqrt(n))).
  expect_lt(abs(mean(res$phi)), 0.05)
})


test_that("d > 1 covariates: assembly matches a manual vectorized computation", {
  cate <- make_cate_input(n = 300, d = 3, seed = 44)
  idx <- which(cate$A == 1)
  res <- integrate_cate(cate, design = "unconfoundedness", target = idx)

  # Manual reconstruction of eq. (2) with w = (n/n_star) 1{idx}.
  n <- 300
  w <- numeric(n); w[idx] <- n / length(idx)
  psi <- mean(cate$tau[idx])
  correction <- cate$A * (cate$Y - cate$mu1) / cate$e -
    (1 - cate$A) * (cate$Y - cate$mu0) / (1 - cate$e)
  phi_manual <- w * (cate$tau - psi) + w * correction

  expect_equal(res$phi, phi_manual, tolerance = 1e-10)
  expect_equal(res$estimate, psi, tolerance = 1e-12)
})


test_that("DiD design: w == 1 gives DR-DiD score + (tau - psi)", {
  cate <- make_cate_input(n = 400, d = 1, design = "did", seed = 55)
  res <- integrate_cate(cate, design = "did", weights = rep(1, 400))

  psi <- mean(1 * cate$tau)  # mean(w * tau) with w == 1
  drdid_score <- (cate$A - cate$e) / (cate$e * (1 - cate$e)) * (cate$dY - cate$m0_dY)
  phi_manual <- (cate$tau - psi) + drdid_score

  expect_equal(res$estimate, psi, tolerance = 1e-12)
  expect_equal(res$phi, phi_manual, tolerance = 1e-10)
  expect_equal(res$design, "did")
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

# Tests for build_omega_score() and the estimated-cohort-weight (omega-hat) variance
# contribution in aggregate_groups() / path1_aggregate().
#
# Theory: main.tex app:eif1 gives the Path 1 EIF as
#   phi_{psi1,i} = sum_g omega_g phi_{theta_g.,i} + sum_g theta_g. phi_{omega_g,i},
# with (RC3, main.tex:820)
#   phi_{omega_g,i} = [1{G_i = g, A_ip = 1} - omega_g * 1{A_ip = 1}] / P(A_ip = 1).
# The package previously implemented only the FIRST sum, i.e. it treated omega as
# fixed/known. When omega is in fact estimated from the same sample, that understates the
# variance. These tests pin down the second term.

# Build a unit-level cohort/treatment configuration for the omega-score tests.
make_omega_config <- function(n = 600, n_groups = 2, frac_untreated = 0.25,
                              seed = 20260925) {
  set.seed(seed)
  groups <- 0:(n_groups - 1)
  treated_by_p <- as.integer(stats::runif(n) > frac_untreated)
  # Cohort label. Untreated units get NA: they must contribute exactly zero to every
  # phi_{omega_g} regardless of their label, and NA makes an accidental dependence loud.
  G <- rep(NA_real_, n)
  n_treated <- sum(treated_by_p == 1)
  # Deliberately UNEVEN cohort shares, so omega_hat is not the uniform vector.
  probs <- seq_len(n_groups)
  probs <- probs / sum(probs)
  G[treated_by_p == 1] <- sample(groups, n_treated, replace = TRUE, prob = probs)
  list(G = G, treated_by_p = treated_by_p, groups = groups, n = n)
}

# gt_object whose per-group time-averaged effects theta_g. are exactly `tau_g`.
make_gt_with_group_means <- function(tau_g, n, n_times = 3, seed = 20260925) {
  set.seed(seed)
  n_groups <- length(tau_g)
  groups <- 0:(n_groups - 1)
  data <- expand.grid(t = seq_len(n_times), g = groups)[, c("g", "t")]
  # Constant tau_hat within group => the equal-weighted within-group mean is exactly tau_g.
  data$tau_hat <- rep(tau_g, each = n_times)
  data$k <- data$t - data$g

  phi <- replicate(nrow(data), stats::rnorm(n, sd = 0.1), simplify = FALSE)

  gt_obj <- list(
    data = tibble::as_tibble(data),
    phi = phi,
    times = sort(unique(data$t)),
    groups = groups,
    event_times = sort(unique(data$k)),
    n = n,
    ids = NULL,
    meta = list()
  )
  class(gt_obj) <- c("gt_object", "extrapolateATT")
  gt_obj
}


test_that("build_omega_score() returns an n x |groups| matrix matching the RC3 formula", {
  cfg <- make_omega_config(n = 400, n_groups = 3)

  S <- build_omega_score(cfg$G, cfg$treated_by_p, cfg$groups)

  expect_true(is.matrix(S))
  expect_equal(dim(S), c(cfg$n, length(cfg$groups)))
  expect_equal(colnames(S), as.character(cfg$groups))

  # Hand-computed reference, cell by cell.
  p_treated <- mean(cfg$treated_by_p == 1)
  omega_hat <- vapply(
    cfg$groups,
    function(g) sum(cfg$treated_by_p == 1 & !is.na(cfg$G) & cfg$G == g) /
      sum(cfg$treated_by_p == 1),
    numeric(1)
  )
  ref <- vapply(seq_along(cfg$groups), function(j) {
    g <- cfg$groups[j]
    ind_gt <- as.numeric(cfg$treated_by_p == 1 & !is.na(cfg$G) & cfg$G == g)
    ind_t <- as.numeric(cfg$treated_by_p == 1)
    (ind_gt - omega_hat[j] * ind_t) / p_treated
  }, numeric(cfg$n))

  expect_equal(unname(S), unname(ref), tolerance = 1e-12, ignore_attr = TRUE)
  # The attached omega_hat is the proportion estimator whose EIF these scores are.
  expect_equal(unname(attr(S, "omega")), unname(omega_hat), tolerance = 1e-12)
  expect_equal(sum(attr(S, "omega")), 1, tolerance = 1e-12)
})

test_that("build_omega_score() scores are exactly zero for units with A_ip = 0", {
  cfg <- make_omega_config(n = 400, n_groups = 3)
  S <- build_omega_score(cfg$G, cfg$treated_by_p, cfg$groups)

  untreated <- cfg$treated_by_p == 0
  expect_true(any(untreated))
  expect_true(all(S[untreated, ] == 0))
})

test_that("build_omega_score() scores are mean-zero in each column", {
  cfg <- make_omega_config(n = 400, n_groups = 3)
  S <- build_omega_score(cfg$G, cfg$treated_by_p, cfg$groups)

  # By construction of the proportion estimator, sum_i phi_{omega_g,i} = 0 exactly.
  expect_true(all(abs(colMeans(S)) < 1e-12))
})

test_that("EXACTLY-ZERO CERTIFICATE: omega scores sum to zero across groups per unit", {
  # Since the cohorts partition {A_ip = 1} and sum_g omega_hat_g = 1 identically,
  #   sum_g phi_{omega_g,i} = [1{A_ip=1} - 1 * 1{A_ip=1}] / P(A_ip=1) = 0
  # for EVERY unit i. This is the structural certificate the omega term must satisfy.
  for (q in c(2, 3, 5)) {
    cfg <- make_omega_config(n = 500, n_groups = q, seed = 20260925 + q)
    S <- build_omega_score(cfg$G, cfg$treated_by_p, cfg$groups)
    expect_equal(rowSums(S), rep(0, cfg$n), tolerance = 1e-12)
  }
})

test_that(".omega_contribution() is exactly zero when all group values are equal", {
  cfg <- make_omega_config(n = 500, n_groups = 4)
  S <- build_omega_score(cfg$G, cfg$treated_by_p, cfg$groups)

  # sum_g theta * phi_{omega_g,i} = theta * sum_g phi_{omega_g,i} = theta * 0 = 0.
  contrib <- .omega_contribution(S, rep(2.5, length(cfg$groups)))
  expect_length(contrib, cfg$n)
  expect_equal(contrib, rep(0, cfg$n), tolerance = 1e-12)

  # Non-degenerate check: unequal values give a genuinely non-zero contribution.
  contrib2 <- .omega_contribution(S, c(0.1, 0.9, 2.0, -1.5))
  expect_gt(stats::var(contrib2), 0)
})

test_that("EXACTLY-ZERO CERTIFICATE: path1_aggregate() omega term vanishes when all theta_g. are equal", {
  # This is the failing test that motivated the fix. With every theta_g. set literally
  # equal, the estimated-omega contribution sum_g theta_g. phi_{omega_g,i} must be exactly
  # zero, so the omega_estimated = TRUE EIF must coincide with the omega-known EIF to
  # machine precision. Before the fix, path1_aggregate() had no omega_estimated argument
  # at all (it silently assumed omega was known), so this test could not even be
  # expressed against the old API.
  cfg <- make_omega_config(n = 500, n_groups = 3)
  tau_g <- rep(0.42, 3)
  gt <- make_gt_with_group_means(tau_g, n = cfg$n)

  S <- build_omega_score(cfg$G, cfg$treated_by_p, cfg$groups)
  omega <- attr(S, "omega")

  known <- path1_aggregate(gt, omega = omega)
  est <- path1_aggregate(gt, omega = omega, omega_estimated = TRUE, omega_scores = S)

  # Point estimates are untouched by the variance term.
  expect_equal(est$tau_future, known$tau_future, tolerance = 1e-12)
  # The certificate: the EIFs agree to machine precision.
  expect_equal(est$phi_future, known$phi_future, tolerance = 1e-12)
  # And the difference really is the (zero) omega contribution, not a dropped term.
  expect_equal(max(abs(est$phi_future - known$phi_future)), 0, tolerance = 1e-12)
})

test_that("estimating omega strictly INCREASES the propagated variance when theta_g. differ", {
  # Estimating omega adds a second, orthogonal-in-expectation source of sampling noise.
  # With unequal theta_g. the omega contribution is non-degenerate, so the propagated
  # variance must be strictly larger than the omega-known variance.
  cfg <- make_omega_config(n = 800, n_groups = 3)
  tau_g <- c(0.1, 0.8, 2.0)  # deliberately spread out
  gt <- make_gt_with_group_means(tau_g, n = cfg$n)

  S <- build_omega_score(cfg$G, cfg$treated_by_p, cfg$groups)
  omega <- attr(S, "omega")

  known <- path1_aggregate(gt, omega = omega)
  est <- path1_aggregate(gt, omega = omega, omega_estimated = TRUE, omega_scores = S)

  v_known <- compute_variance(known$phi_future, estimate = known$tau_future)
  v_est <- compute_variance(est$phi_future, estimate = est$tau_future)

  expect_gt(v_est$var, v_known$var)
  expect_gt(v_est$se, v_known$se)
  # The CI must be strictly wider, not just numerically different.
  expect_gt(diff(v_est$ci), diff(v_known$ci))
})

test_that("path1_aggregate() default behavior is unchanged (purely additive fix)", {
  # The new argument must not perturb any existing call pattern.
  gt <- make_mock_gt_object(n = 50, n_groups = 2, n_times = 3)

  for (w in c("equal", "gls")) {
    a <- path1_aggregate(gt, omega = c(0.6, 0.4), weighting = w)
    b <- path1_aggregate(gt, omega = c(0.6, 0.4), weighting = w, omega_estimated = FALSE)
    expect_identical(a, b)
  }

  # NULL omega path too.
  expect_identical(path1_aggregate(gt), path1_aggregate(gt, omega_estimated = FALSE))
})

test_that("aggregate_groups() default behavior is unchanged and omega_scores is additive", {
  set.seed(20260925)
  values_g <- c(0.5, 0.3, 0.7)
  eif_list <- replicate(3, stats::rnorm(50, sd = 0.1), simplify = FALSE)
  omega <- c(0.5, 0.3, 0.2)

  base <- aggregate_groups(values_g, eif_list, omega)
  expect_identical(base, aggregate_groups(values_g, eif_list, omega, omega_scores = NULL))

  cfg <- make_omega_config(n = 50, n_groups = 3)
  S <- build_omega_score(cfg$G, cfg$treated_by_p, cfg$groups)

  with_scores <- aggregate_groups(values_g, eif_list, omega, omega_scores = S)
  # Point estimate unchanged; EIF gains exactly the omega contribution.
  expect_equal(with_scores$value, base$value, tolerance = 1e-12)
  expect_equal(
    with_scores$phi - base$phi,
    .omega_contribution(S, values_g),
    tolerance = 1e-12
  )
})

test_that("path1_aggregate() errors informatively on malformed omega_estimated usage", {
  gt <- make_mock_gt_object(n = 50, n_groups = 2, n_times = 3)

  expect_error(
    path1_aggregate(gt, omega = c(0.5, 0.5), omega_estimated = TRUE),
    "omega_scores"
  )

  cfg <- make_omega_config(n = 50, n_groups = 3)
  S_wrong_groups <- build_omega_score(cfg$G, cfg$treated_by_p, cfg$groups)
  expect_error(
    path1_aggregate(gt, omega = c(0.5, 0.5), omega_estimated = TRUE,
                    omega_scores = S_wrong_groups),
    "columns"
  )

  cfg2 <- make_omega_config(n = 77, n_groups = 2)
  S_wrong_n <- build_omega_score(cfg2$G, cfg2$treated_by_p, cfg2$groups)
  expect_error(
    path1_aggregate(gt, omega = c(0.5, 0.5), omega_estimated = TRUE,
                    omega_scores = S_wrong_n),
    "rows"
  )
})

test_that("build_omega_score() validates its inputs", {
  cfg <- make_omega_config(n = 100, n_groups = 2)

  expect_error(
    build_omega_score(cfg$G[-1], cfg$treated_by_p, cfg$groups),
    "length"
  )
  expect_error(
    build_omega_score(cfg$G, rep(2L, cfg$n), cfg$groups),
    "0/1"
  )
  expect_error(
    build_omega_score(cfg$G, rep(0L, cfg$n), cfg$groups),
    "no treated"
  )
  expect_error(
    build_omega_score(cfg$G, cfg$treated_by_p, numeric(0)),
    "at least one group"
  )
  # Cohorts must partition the treated set, otherwise the zero certificate is false.
  G_bad <- cfg$G
  G_bad[which(cfg$treated_by_p == 1)[1]] <- 99
  expect_error(
    build_omega_score(G_bad, cfg$treated_by_p, cfg$groups),
    "partition"
  )
})

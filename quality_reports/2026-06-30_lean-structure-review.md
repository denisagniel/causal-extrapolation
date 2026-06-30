# Lean Paper — Structure & Arc Review

**Date:** 2026-06-30
**Object:** `inst/paper/main-lean.tex` (post Phase-0/1 framing + §1–4 rewrites)
**Purpose:** Evaluate section layout and narrative arc before resuming any prose writing. Recommendations to accept/reject; nothing edited.

---

## Current structure (8 sections, ~25.5pp budgeted)

| § | Title | Budget | Status |
|---|-------|--------|--------|
| 1 | Introduction | 3.0 | framing done (Fundamental Promise + dual contribution) |
| 2 | Setting and Notation | 2.0 | drafted; incl. 2.4 first-stage EIF |
| 3 | Forward-Looking Estimands | 2.5 | FATT/FATU/FATE family done |
| 4 | Identification via Extrapolation Functions | 7.5 | 3 paths done; Path 3 reframed |
| 5 | Semiparametric Inference | 3.0 | EIF propagation + model selection |
| 6 | Simulations | 3.0 | structure only; **numbers pending Phases 2–3** |
| 7 | Application: SYG | 3.0 | structure only; **numbers pending Phases 2–3** |
| 8 | Discussion | 2.0 | drafted |

---

## PART A — Layout

### A1. §4 at 7.5pp is the structural risk (MAJOR)
Nearly a third of the paper. Outline's own note: realistic total ~27.5pp vs. 20–25 target, and §4 is where the overage lives.
- **Recommendation:** Hard-target §4 ≤ 6.5pp. Budget: General Framework 1.0, each path 1.5 (=4.5), Synthesis 0.5, slack 0.5. Push all proofs to supplement (already planned), keep each path to {assumption(s) → proposition → 1 interpretive paragraph → when-it-applies}. Path 3 currently runs longest (it carries 3 assumptions + FATU/FATE extension) — let it be the worked one, compress 1–2 to match.

### A2. §2.4 "First-stage EIF" placement (MAJOR — the one real ordering call)
Influence-function machinery sits in *Setting*, two sections before estimands exist. Front-loads formalism before the §3 payoff.
- **Option (a) keep:** it defines `φ_gt` notation used later; cost is a heavy §2.
- **Option (b) move to §5:** §2 becomes clean setup (panel framework, group-time ATTs, first-stage *identification* only); all EIF/asymptotic-linearity content consolidates in §5 where Paths 1–3 EIFs already live. **Recommended** — matches "all inference in §5," keeps §2 ≤ 2pp, and §5 is where asymptotic linearity is actually used.
- Decision needed from you.

### A3. §6/§7 cannot be written yet (sequencing, not a flaw)
Numbers depend on Phases 2–3. Current tables are fabricated (audit M7). Two honest holding patterns:
- Replace tables with `[results pending]` placeholders + keep design prose. (Chosen earlier.)
- Or defer §6/§7 entirely until after the code work.
- **Recommendation:** placeholder the tables now so the skeleton is coherent and non-misleading; write real §6/§7 after Phase 3. Do not attempt final empirical prose this session.

### A4. Subsection balance in §3 (MINOR)
Five subsections (Challenge, FATT, FATU, FATE, ID-challenge) for 2.5pp. FATU/FATE are short variants of FATT. Fine as is, but if §3 runs long, collapse FATU+FATE into one "Variants: FATU and FATE" subsection.

---

## PART B — Narrative / argument arc

### B1. The §4 unifying device: `h(g,t;γ)` vs. "what is invariant" (MAJOR — conceptual)
The General Framework organizes the three paths around an extrapolation function `h(g,t;γ)` applied to `θ_gt`. This fits Paths 1–2 exactly. **Path 3 no longer passes through `θ_gt`** (it estimates `τ(x)` directly) — I bridged this in prose, but the common device is now genuinely strained: two paths share `h(·)`, one doesn't.
- **Option (a):** keep `h(·)` as the device for Paths 1–2, present Path 3 as the deliberate break ("rather than extrapolating the marginal, hold the conditional fixed"). Honest, but the "unifying framework" subsection oversells unity.
- **Option (b) recommended:** reorganize the framing around **what is assumed invariant** — effects (P1), temporal form (P2), conditional effect (P3) — which is already the abstract's language and genuinely covers all three. The `h(·)` function becomes a device *within* Paths 1–2, not the §4-wide umbrella. This is more honest and needs only a rewrite of the General Framework subsection.
- Decision needed.

### B2. Arc holds, with one thread to pay off (GOOD + minor)
Fundamental Promise → dynamic effects break it → take dynamics less/more seriously → three paths → future estimands. Strong and intact. The intro promises a mapping onto cross-field traditions (parameter invariance / transport / dynamics modeling); make sure each path header echoes its tradition so the promise is paid. Cheap to do.

### B3. Contribution framing is now coherent (GOOD)
"Plug existing estimator → forward map → propagate EIF" is stated and true of all three paths. This both unifies them and correctly disclaims novelty in estimation. Keep it prominent in §1.2 and §4.1.

### B4. Title vs. content (MINOR)
New title "Should We Keep the Policy?" leads with the repeal (FATT) question. Fine — but ensure the abstract/intro give adopt (FATU) and universal (FATE) visible billing so the title isn't read as FATT-only.

---

## Decisions (LOCKED 2026-06-30 — all recommendations accepted)
1. **§2.4 EIF → move to §5.** §2 becomes clean setup (panel framework, group-time ATTs, first-stage *identification* only). All EIF/asymptotic-linearity content consolidates in §5.
2. **§4 framing → "what is assumed invariant"** (effects / temporal form / conditional effect) as the §4-wide umbrella. The `h(g,t;γ)` extrapolation function is demoted to a device *within* Paths 1–2, not the unifying frame for all three.
3. **§4 length → hard target ≤6.5pp** (framework 1.0, each path 1.5, synthesis 0.5, slack 0.5). Path 3 is the worked path; compress Paths 1–2 to match.
4. **§6/§7 → placeholder tables now, write real empirical prose after Phase 3.**

These reshape the structure but are NOT yet executed in main-lean.tex (only §1–4 content rewrites done this session). Execution deferred — user evaluating structure, not writing heavily now.

# Managed scientific and conversion constants

```labkit-change
schema: 1
id: LK-20260713-managed-calculation-constants
date: 2026-07-13
type: refactor
compatibility: compatible
component: `labkit.dta` | `2.0.0 -> 2.0.1`
component: `labkit.rhs` | `1.0.0 -> 1.0.1`
component: `labkit.biosignal` | `1.0.0 -> 1.0.1`
component: `labkit_ChronoOverlay_app` | `1.3.5 -> 1.3.6`
component: `labkit_CSC_app` | `1.3.9 -> 1.3.10`
component: `labkit_NerveResponseAnalysis_app` | `1.3.4 -> 1.3.5`
component: `labkit_ResponseReviewStats_app` | `1.3.4 -> 1.3.5`
```

## Context

Scientific coefficients, device-format gains, unit conversions, and numeric
tolerances were sometimes left as unexplained literals or repeated across
callers, making origin and change impact difficult to audit.

## Decision and rationale

Give each semantic calculation constant one named owner and a nearby source or
purpose comment, while exempting ordinary indices and explicit UI geometry
that do not encode scientific meaning.

## Changes

- Named and documented Rec.601, sRGB/CIE, DTA/RHS gains, SI conversions,
  tolerances, and empirical policies across facades and apps.
- Centralized repeated CSC charge-density, CIC display-unit, and curvature
  tolerance contracts.
- Added repository-wide magic-number and rectangle-interaction guardrails.

## User and data impact

Calculation results are preserved, but future changes now expose the constant's
meaning and provenance instead of silently editing an unexplained literal.

## Compatibility and migration

No user migration is required. Public function call contracts and output
schemas are unchanged by this record.

## Validation

`MagicNumberGovernanceTest`, rectangle governance, facade tests, and affected
app tests cover centralized ownership and preserved numeric behavior.

## Evidence

Source comments use the `Constant:` marker and guardrail diagnostics name the
unmanaged file and line. Branch checkpoint `125338c0` carries the governance
work before the final squash merge.

## Known limitations and follow-up

The scanner targets semantically suspicious precision and notation; review is
still required for simple integers or short decimals whose meaning is hidden.

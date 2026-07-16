# Facade contract baseline and release validation hardening

```labkit-change
schema: 1
id: LK-20260623-facade-contract-baseline-and-release-validation-hardening
date: 2026-06-23
type: ci
compatibility: compatible
introduced: `labkit.biosignal` | `1.0.0`
introduced: `labkit.dta` | `1.0.0`
introduced: `labkit.rhs` | `1.0.0`
introduced: `labkit.ui` | `2.0.0`
component: `labkit.ui` | `2.0.0 -> 2.1.0`
component: `labkit.ui` | `2.2.0 -> 2.2.1`
component: `labkit_DICPostprocess_app` | `1.0.0 -> 1.0.1`
component: `labkit_DICPreprocess_app` | `1.0.0 -> 1.0.1`
component: `labkit_CurvatureMeasurement_app` | `1.0.0 -> 1.0.1`
```

## Context

- Reusable facades gained explicit compatibility contracts before the later
  app-version and launcher-version work.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.biosignal` `1.0.0`
- `labkit.dta` `1.0.0`
- `labkit.rhs` `1.0.0`
- `labkit.ui` `2.0.0 -> 2.2.1`
- DIC Pre/Post and Curvature `1.0.0 -> 1.0.1`
- Release tags `v2.4.1` and `v2.4.2`

- Added facade contract metadata and requirement checks.
- Hardened app lifecycle and release validation contracts.
- Routed MATLAB CI shards through build tasks.

## User and data impact

- Reusable facades gained explicit compatibility contracts before the later
  app-version and launcher-version work.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commits `a25b79f9`, `3673e548`, `49d9f41b`, and `7e39b558`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

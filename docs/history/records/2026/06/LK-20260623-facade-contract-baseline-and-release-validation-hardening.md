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

Reusable packages exposed public MATLAB functions, but apps had no
machine-checkable way to state which API versions they required. Release and CI
checks also needed one consistent build-task entry path.

## Decision and rationale

Give each reusable package version metadata and let apps declare compatible
ranges that are checked at launch and in tests. Route MATLAB CI shards through
the same build tasks used by maintainers so release validation exercises the
documented commands.

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

An incompatible app/package combination could fail with a direct requirement
message instead of producing a later missing-function error. Existing project
and result data were unaffected.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

The listed commits introduced contract, lifecycle, and CI build-task tests.
Release tags `v2.4.1` and `v2.4.2` identify the shipped checkpoints; exact local
commands were not recorded.

## Evidence

- Main commits `a25b79f9`, `3673e548`, `49d9f41b`, and `7e39b558`.

## Known limitations and follow-up

App and launcher display versions were added in the separate version-metadata
change later the same day.

# Facade contract baseline and release validation hardening

```labkit-change
id: CHG-20260623-facade-contract-baseline-and-release-validation-hardening
date: 2026-06-23
type: ci
compatibility: compatible
component: labkit.biosignal | new -> 1.0.0
component: labkit.dta | new -> 1.0.0
component: labkit.rhs | new -> 1.0.0
component: labkit.ui | new -> 2.2.1
component: labkit_DICPostprocess_app | 1.0.0 -> 1.0.1
component: labkit_DICPreprocess_app | 1.0.0 -> 1.0.1
component: labkit_CurvatureMeasurement_app | 1.0.0 -> 1.0.1
```

## Why

Reusable packages exposed public MATLAB functions, but apps had no machine-checkable way to state which API versions they required. Release and CI checks also needed one consistent build-task entry path.

### Accepted choice

Give each reusable package version metadata and let apps declare compatible ranges that are checked at launch and in tests. Route MATLAB CI shards through the same build tasks used by maintainers so release validation exercises the documented commands.

## What changed

- `labkit.biosignal` `1.0.0`
- `labkit.dta` `1.0.0`
- `labkit.rhs` `1.0.0`
- DIC Pre/Post and Curvature `1.0.0 -> 1.0.1`
- Release tags `v2.4.1` and `v2.4.2`

- Added facade contract metadata and requirement checks.
- Hardened app lifecycle and release validation contracts.
- Routed MATLAB CI shards through build tasks.

## Impact

An incompatible app/package combination could fail with a direct requirement message instead of producing a later missing-function error. Existing project and result data were unaffected.

## Compatibility and limits

The contract metadata described the existing public facades and was additive for app callers. Apps with an incompatible declared requirement now failed at launch with a version diagnostic instead of continuing unpredictably.

### Remaining limits

App and launcher display versions were added in the separate version-metadata change later the same day.

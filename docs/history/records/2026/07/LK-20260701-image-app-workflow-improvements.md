# Image app workflow improvements

```labkit-change
schema: 1
id: LK-20260701-image-app-workflow-improvements
date: 2026-07-01
type: feat
compatibility: compatible
component: `labkit_launcher` | `1.1.5 -> 1.1.6`
component: `labkit.image` | `1.0.0 -> 1.1.0`
component: `labkit.ui` | `3.2.10 -> 3.3.0`
component: `labkit.ui` | `3.3.0 -> 3.3.1`
component: `labkit_BatchImageCrop_app` | `1.4.0 -> 1.5.0`
component: `labkit_BatchImageCrop_app` | `1.5.0 -> 1.5.1`
component: `labkit_FLIRThermal_app` | `1.0.0 -> 1.1.0`
component: `labkit_FLIRThermal_app` | `1.1.0 -> 1.1.2`
component: `labkit_ImageEnhance_app` | `1.4.0 -> 1.4.1`
component: `labkit_ImageMatch_app` | `1.4.0 -> 1.4.1`
```

## Context

- Large image workflows became more predictable and less likely to spend time on
  unnecessary preview work.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.image` `1.0.0 -> 1.1.0`
- `labkit.ui` `3.2.10 -> 3.3.1`
- Batch Crop `1.4.0 -> 1.5.1`
- FLIR Thermal `1.0.0 -> 1.1.2`
- `labkit_launcher` `1.1.5 -> 1.1.6`

- Added preview-budget helpers.
- Improved image app range and preview controls.
- Improved image measurement workflows.

## User and data impact

- Large image workflows became more predictable and less likely to spend time on
  unnecessary preview work.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commits `15a798ba` and `70bfcfd4`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

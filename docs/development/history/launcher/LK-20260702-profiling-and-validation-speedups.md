# Profiling and validation speedups

```labkit-change
schema: 1
id: LK-20260702-profiling-and-validation-speedups
date: 2026-07-02
type: ci
compatibility: compatible
component: `labkit_launcher` | `1.2.0 -> 1.2.1`
component: `labkit_launcher` | `1.2.1 -> 1.2.2`
component: `labkit.ui` | `3.4.0 -> 3.4.1`
component: `labkit.ui` | `3.4.1 -> 3.4.2`
component: `labkit_BatchImageCrop_app` | `1.6.0 -> 1.6.1`
component: `labkit_ECGPrint_app` | `1.3.0 -> 1.3.1`
```

## Context

- Maintainers get faster diagnosis and faster validation without changing app
  behavior.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit_launcher` `1.2.0 -> 1.2.2`
- `labkit.ui` `3.4.0 -> 3.4.2`
- `labkit_BatchImageCrop_app` `1.6.0 -> 1.6.1`
- `labkit_ECGPrint_app` `1.3.0 -> 1.3.1`

- Added LabKit profiling and build-managed test routing to the launcher.
- Reduced GUI profiling overhead and deferred Batch Crop image reads until
  preview/export.
- Compressed validation runtime with bounded GUI waits.

## User and data impact

- Maintainers get faster diagnosis and faster validation without changing app
  behavior.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commits `c07dfc0a`, `74025fee`, `eadcca82`, `25912c54`, and `fcfc36d8`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

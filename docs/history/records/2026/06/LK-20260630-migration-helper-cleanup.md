# Migration helper cleanup

```labkit-change
schema: 1
id: LK-20260630-migration-helper-cleanup
date: 2026-06-30
type: refactor
compatibility: compatible
component: `labkit.ui` | `3.2.8 -> 3.2.9`
component: `labkit_DICPostprocess_app` | `1.2.3 -> 1.2.4`
component: `labkit_BatchImageCrop_app` | `1.3.7 -> 1.3.8`
component: `labkit_BatchImageCrop_app` | `1.3.8 -> 1.3.9`
component: `labkit_ImageEnhance_app` | `1.3.4 -> 1.3.5`
component: `labkit_RHSPreview_app` | `1.2.2 -> 1.2.3`
component: `labkit_RHSPreview_app` | `1.2.3 -> 1.2.4`
scope: historical project evolution
```

## Context

- Maintainers no longer need to route through temporary migration helpers to
  understand these workflows.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- DIC Post, Batch Crop, and RHS Preview patch bumped.

- Retired migration helper debt.
- Consolidated RHS preview window bounds, Batch Crop scale state, and Image
  Enhance export helpers.

## User and data impact

- Maintainers no longer need to route through temporary migration helpers to
  understand these workflows.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commits `7f73b71b`, `e3349af6`, `733fb951`, `98a2b02c`, and `391540a7`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

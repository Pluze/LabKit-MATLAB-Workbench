# Migration helper cleanup

```labkit-change
id: LK-20260630-migration-helper-cleanup
date: 2026-06-30
sequence: 23
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

Several apps still split one small decision across multiple temporary helper
files created during earlier package migrations. That made simple state and
preview behavior harder to follow without creating a reusable API.

## Decision and rationale

Consolidate related values behind one clearly named operation and delete
pass-through helpers whose only purpose was reducing file length. Preserve the
visible app behavior while making each calculation or state summary traceable
from its caller.

## Changes

- DIC Post, Batch Crop, and RHS Preview patch bumped.

- Retired migration helper debt.
- Consolidated RHS preview window bounds, Batch Crop scale state, and Image
  Enhance export helpers.

## User and data impact

No workflow or result format changed. The cleanup reduced internal indirection
in Image Enhance export, Batch Crop scale summaries, RHS Preview window bounds,
and a small set of DIC/electrochem helpers.

## Compatibility and migration

The consolidated helpers preserved the app-facing state and result structures.
No project or export format changed as the duplicate implementations were
removed.

## Validation

Commits `7f73b71b`, `e3349af6`, `733fb951`, `98a2b02c`, and `391540a7`
added or updated focused tests for each consolidated operation.

## Evidence

- Main commits `7f73b71b`, `e3349af6`, `733fb951`, `98a2b02c`, and `391540a7`.

## Known limitations and follow-up

This was a behavior-preserving cleanup. Later workflow-first packages replaced
some of the package names shown in the historical commits.

# Migration helper cleanup

```labkit-change
id: CHG-20260630-migration-helper-cleanup
date: 2026-06-30
type: refactor
compatibility: compatible
component: labkit.ui | 3.2.8 -> 3.2.9
component: labkit_DICPostprocess_app | 1.2.3 -> 1.2.4
component: labkit_BatchImageCrop_app | 1.3.7 -> 1.3.9
component: labkit_ImageEnhance_app | 1.3.4 -> 1.3.5
component: labkit_RHSPreview_app | 1.2.2 -> 1.2.4
```

## Why

Several apps still split one small decision across multiple temporary helper files created during earlier package migrations. That made simple state and preview behavior harder to follow without creating a reusable API.

### Accepted choice

Consolidate related values behind one clearly named operation and delete pass-through helpers whose only purpose was reducing file length. Preserve the visible app behavior while making each calculation or state summary traceable from its caller.

## What changed

- DIC Post, Batch Crop, and RHS Preview patch bumped.

- Retired migration helper debt.
- Consolidated RHS preview window bounds, Batch Crop scale state, and Image Enhance export helpers.

## Impact

No workflow or result format changed. The cleanup reduced internal indirection in Image Enhance export, Batch Crop scale summaries, RHS Preview window bounds, and a small set of DIC/electrochem helpers.

## Compatibility and limits

The consolidated helpers preserved the app-facing state and result structures. No project or export format changed as the duplicate implementations were removed.

### Remaining limits

This was a behavior-preserving cleanup. Later workflow-first packages replaced some of the package names shown in the historical commits.

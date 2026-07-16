# Shared image facade

```labkit-change
schema: 1
id: LK-20260630-shared-image-facade
date: 2026-06-30
type: feat
compatibility: compatible
introduced: `labkit.image` | `1.0.0`
component: `labkit_BatchImageCrop_app` | `1.3.9 -> 1.4.0`
component: `labkit_CurvatureMeasurement_app` | `1.2.3 -> 1.2.4`
component: `labkit_FocusStack_app` | `1.2.5 -> 1.3.0`
component: `labkit_ImageEnhance_app` | `1.3.5 -> 1.4.0`
component: `labkit_ImageMatch_app` | `1.3.5 -> 1.4.0`
scope: historical project evolution
```

## Context

- Image app behavior became more consistent, and reusable image IO stopped
  living inside individual GUI workflows.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.image` `1.0.0`
- Batch Crop, Curvature, Focus Stack, Image Enhance, and Image Match advanced
  within their image-facade adoption lines.

- Added a GUI-free image facade for file input, display normalization, basic
  processing, and preview support.
- Adopted that facade across image-measurement apps.

## User and data impact

- Image app behavior became more consistent, and reusable image IO stopped
  living inside individual GUI workflows.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commit `7023e87e`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

# Image Apps stop creating invalid placeholder outputs

```labkit-change
id: LK-20260716-image-manifest-output-arrays
date: 2026-07-16
sequence: 80
type: fix
compatibility: compatible
component: `labkit_BatchImageCrop_app` | `1.7.1 -> 1.7.2`
component: `labkit_FLIRThermal_app` | `1.4.1 -> 1.4.2`
component: `labkit_ImageEnhance_app` | `1.6.1 -> 1.6.2`
component: `labkit_ImageMatch_app` | `1.6.1 -> 1.6.2`
scope: Image Measurement
scope: Result manifests
```

## Context

Four image Apps preallocated variable-length result arrays by first asking the
Runtime output factory to create a record with an empty ID. Runtime V2 rejects
empty result IDs, so otherwise valid export workflows could stop before their
standard manifest was written.

## Decision and rationale

Use the canonical empty result array introduced by `labkit.ui` and append only
validated real outputs. This preserves strict IDs without requiring each App
to duplicate the manifest struct shape.

## Changes

- Updated Batch Crop crop outputs.
- Updated FLIR image, colorbar, and temperature-CSV outputs.
- Updated Image Enhance batch outputs.
- Updated Image Match batch outputs.

## User and data impact

The exported images, numeric CSV data, filenames, roles, statuses, and manifest
schemas are unchanged. Exports no longer fail during internal output-array
initialization.

## Compatibility and migration

No saved project or export schema migration is required. Existing result files
remain readable.

## Validation

Each affected App's hidden synthetic GUI export workflow verifies its domain
output plus the standard LabKit manifest. Version and component-history
guardrails cover all four products.

## Evidence

- [Batch Crop](../../../../apps/image-measurement/batch-crop/README.md)
- [FLIR Thermal](../../../../apps/image-measurement/flir-thermal/README.md)
- [Image Enhance](../../../../apps/image-measurement/image-enhance/README.md)
- [Image Match](../../../../apps/image-measurement/image-match/README.md)

## Known limitations and follow-up

The Apps still need their separate single-definition and projectSpec reviews;
this record only fixes the shared manifest construction defect.

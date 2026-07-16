# Tool-panel hosts and image app fixes

```labkit-change
schema: 2
id: LK-20260629-tool-panel-hosts-and-image-app-fixes
date: 2026-06-29
sequence: 18
type: fix
compatibility: compatible
component: `labkit.ui` | `3.2.0 -> 3.2.2`
component: `labkit.ui` | `3.2.2 -> 3.2.3`
component: `labkit_BatchImageCrop_app` | `1.3.2 -> 1.3.3`
component: `labkit_CurvatureMeasurement_app` | `1.2.0 -> 1.2.1`
component: `labkit_ImageEnhance_app` | `1.3.0 -> 1.3.1`
component: `labkit_ImageMatch_app` | `1.3.0 -> 1.3.1`
```

## Context

Reusable interaction tools were being attached to generic empty sections,
while several image apps had separate problems with file-entry identity,
reported output size, and White ROI updates.

## Decision and rationale

Add a semantic `toolPanel` host for composed tools and fix the image-app
behaviors at their actual data owners. Normalize file entries and regenerate
ids deterministically so presentation updates do not change source identity.

## Changes

- `labkit.ui` `3.2.0 -> 3.2.3`
- Batch Crop, Curvature, Image Enhance, and Image Match patch bumped where
  layouts or image-app behavior changed.

- Hardened file-panel entry normalization and deterministic ID regeneration.
- Fixed output-size reporting and White ROI responsiveness.
- Added semantic `toolPanel` hosts.

## User and data impact

White ROI controls responded to the selected image, Batch Crop reported output
dimensions consistently, and reusable tools occupied a stable named layout
area. Existing source and result formats were unchanged.

## Compatibility and migration

Existing file entries and image results remained readable. Deterministic ids
were regenerated in memory, and the new layout host did not alter saved data.

## Validation

The listed commits updated file-panel, tool-host, and focused image-app tests.
Exact historical commands were not recorded.

## Evidence

- Main commits `f2189aef`, `77084fbe`, and `871739cd`.

## Known limitations and follow-up

The first `toolPanel` API was later replaced by the current semantic layout and
managed-interaction model.

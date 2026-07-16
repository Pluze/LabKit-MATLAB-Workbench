# Tool-panel hosts and image app fixes

```labkit-change
schema: 1
id: LK-20260629-tool-panel-hosts-and-image-app-fixes
date: 2026-06-29
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

- Reusable tools gained a real layout host, and image app reports/ROI controls
  became less surprising.

## Decision and rationale

Treat this as one coherent evolution record because the listed versions and
evidence changed together to address the stated user or maintainer need.

## Changes

- `labkit.ui` `3.2.0 -> 3.2.3`
- Batch Crop, Curvature, Image Enhance, and Image Match patch bumped where
  layouts or image-app behavior changed.

- Hardened file-panel entry normalization and deterministic ID regeneration.
- Fixed output-size reporting and White ROI responsiveness.
- Added semantic `toolPanel` hosts.

## User and data impact

- Reusable tools gained a real layout host, and image app reports/ROI controls
  became less surprising.

## Compatibility and migration

No manual migration was recorded for this historical change.

## Validation

Historical test commands were not recorded consistently. The carrying
mainline commits and release tags below are the authoritative evidence;
current guardrails protect the surviving contracts.

## Evidence

- Main commits `f2189aef`, `77084fbe`, and `871739cd`.

## Known limitations and follow-up

This normalized baseline preserves the historical intent; consult the evidence for commit-level implementation details.

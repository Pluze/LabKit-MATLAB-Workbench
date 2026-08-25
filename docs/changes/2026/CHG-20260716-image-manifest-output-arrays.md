# Image Apps stop creating invalid placeholder outputs

```labkit-change
id: CHG-20260716-image-manifest-output-arrays
date: 2026-07-16
type: fix
compatibility: compatible
component: labkit_BatchImageCrop_app | 1.7.1 -> 1.7.2
component: labkit_FLIRThermal_app | 1.4.1 -> 1.4.2
component: labkit_ImageEnhance_app | 1.6.1 -> 1.6.2
component: labkit_ImageMatch_app | 1.6.1 -> 1.6.2
```

## Why

Four image Apps preallocated variable-length result arrays by first asking the Runtime output factory to create a record with an empty ID. Runtime V2 rejects empty result IDs, so otherwise valid export workflows could stop before their standard manifest was written.

### Accepted choice

Use the canonical empty result array introduced by `labkit.ui` and append only validated real outputs. This preserves strict IDs without requiring each App to duplicate the manifest struct shape.

## What changed

- Updated Batch Crop crop outputs.
- Updated FLIR image, colorbar, and temperature-CSV outputs.
- Updated Image Enhance batch outputs.
- Updated Image Match batch outputs.

## Impact

The exported images, numeric CSV data, filenames, roles, statuses, and manifest schemas are unchanged. Exports no longer fail during internal output-array initialization.

## Compatibility and limits

No saved project or export schema migration is required. Existing result files remain readable.

### Remaining limits

The Apps still need their separate single-definition and projectSpec reviews; this record only fixes the shared manifest construction defect.

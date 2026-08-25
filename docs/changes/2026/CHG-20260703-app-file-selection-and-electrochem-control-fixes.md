# App file-selection and electrochem control fixes

```labkit-change
id: CHG-20260703-app-file-selection-and-electrochem-control-fixes
date: 2026-07-03
type: fix
compatibility: compatible
component: labkit_CIC_app | 1.3.1 -> 1.3.3
component: labkit_CSC_app | 1.3.1 -> 1.3.3
component: labkit_VTResistance_app | 1.3.1 -> 1.3.3
component: labkit_BatchImageCrop_app | 1.6.2 -> 1.6.3
component: labkit_FLIRThermal_app | 1.2.1 -> 1.2.2
component: labkit_FocusStack_app | 1.4.1 -> 1.4.2
component: labkit_ImageEnhance_app | 1.5.1 -> 1.5.2
component: labkit_ImageMatch_app | 1.5.1 -> 1.5.2
```

## Why

Adding files to an existing multi-file session could replace or select the wrong entry in several apps. CIC, CSC, and VT Resistance also exposed manual plot controls that no longer matched their intended result-review workflow.

### Accepted choice

Preserve the complete file list when new selections are appended and select a newly added item predictably. Remove obsolete electrochem controls instead of keeping buttons whose effect was ambiguous or redundant.

## What changed

- CIC, CSC, VT Resistance, Batch Crop, FLIR Thermal, Focus Stack, Image Enhance, and Image Match patch bumped for appended file selections.
- CIC, CSC, and VT Resistance patch bumped again for manual plot-control removal.

- Preserved appended file selections.
- Removed electrochem manual plot controls that no longer matched the workflow.

## Impact

Users could add another batch without losing files already loaded, across the listed electrochem and image apps. The electrochem workbenches became simpler; calculations and exported result schemas were unchanged.

## Compatibility and limits

Existing loaded-file and result formats remained valid. Appended selections now preserved the active item, and the removed manual plot controls did not alter the underlying calculation options.

### Remaining limits

The change covered app-level append handling. Later framework work unified the native file-selection behavior across platforms.

# Multi-app launcher packages

```labkit-change
id: CHG-20260709-multi-app-launcher-packages
date: 2026-07-09
type: feat
compatibility: compatible
component: labkit_launcher | 1.2.7 -> 1.3.0
```

## Why

The deployment tool could package one app, but laboratory workflows often used a small related set. Creating one ZIP per app duplicated the shared LabKit runtime, while manually merging ZIP files risked inconsistent entry files and manifests. The launcher's selected row also could not double as a multi-select without making Open and Debug ambiguous.

### Accepted choice

Add a separate Package checkbox to each launcher row. Keep the ordinary row selection for Open and Debug, and let checked rows produce one bundle with one entry file per app and a manifest describing the complete package.

## What changed

- Project deployment tooling, multi-app bundle support.

- Added an independent `Package` checkbox column to the launcher app table so users can choose multiple apps without changing the row selected for Open or Debug.
- `Package Checked` and `Checked P-code` now create one zip containing every checked app, one direct entry file per app, and a multi-app manifest.
- Kept single-app package names, result fields, and manifest schema compatible when only one app is supplied to `packageLabKitApp`.

## Impact

Users could distribute a related group of apps in one source or P-code ZIP without including the rest of the workbench. Opening and debugging still acted on the highlighted app, so preparing a package did not change normal launcher navigation.

## Compatibility and limits

- Existing direct calls that package one app continue to produce the original single-app package contract.

### Remaining limits

Bundles intentionally included selected apps and their LabKit dependencies, not tests, full documentation, or unrelated private workspaces. P-code packages still required a compatible MATLAB runtime.

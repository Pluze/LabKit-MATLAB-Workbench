# Cross-version dialogs and Batch Crop duplication keep portable shapes

```labkit-change
id: LK-20260729-cross-version-dialog-and-duplicate-repair
date: 2026-07-29
sequence: 162
type: fix
compatibility: compatible
component: `labkit.app` | `2.0.1 -> 2.0.2`
component: `labkit_BatchImageCrop_app` | `1.9.0 -> 1.9.1`
scope: Windows MATLAB file-dialog filter compatibility
scope: Batch Crop duplicate task shape alignment
scope: oldest/latest MATLAB CI compatibility matrix
```

## Context

MATLAB R2024b on Windows rejected string-valued cells passed to `uiputfile`
while exporting a diagnostic ZIP. Batch Crop also inserted a duplicate with
vertical concatenation even when the native file-list source binding supplied
a row struct array, so duplicating from a multi-image list could fail with a
dimension mismatch.

## Decision and rationale

The private MATLAB adapter now uses its existing dialog-filter normalizer for
ordinary input and output dialogs. Batch Crop normalizes its four parallel task
collections to columns at the duplicate callback boundary before inserting the
new task. These are the narrow owners of the platform and App shape contracts;
no new public API or saved-project migration is needed.

## Changes

- Converted native input/output dialog filters to character-cell tables before
  calling `uigetfile` or `uiputfile`.
- Made Batch Crop duplicate insertion preserve one column-aligned task, source,
  image-cache, and path-cache row per list entry.
- Added focused regression coverage for the R2024b-compatible filter value and
  a multi-image row-shaped duplicate state.
- Expanded every validation profile from one fixed MATLAB release to the
  effective R2022b Build Tool floor and the latest release available to the
  official setup action. macOS remains a latest-release platform sentinel.
- Grouped the three validation profiles by platform and release so each matrix
  entry installs MATLAB once while each profile retains a fresh batch session.

## User and data impact

Windows users can choose a destination for diagnostic ZIP bundles, projects,
screenshots, plots, and other Runtime output dialogs. Batch Crop can duplicate
an image task from a multi-image list without changing source images or prior
task settings.

## Compatibility and migration

The repair is backward compatible. Public App SDK signatures, Batch Crop
project payload version 3, scientific crop calculations, and exported result
schemas are unchanged.

## Validation

Focused headless specifications cover the Batch Crop duplicate callback and
the native dialog-filter value. CI runs every full profile on Linux, macOS, and
Windows against R2022b and the latest available MATLAB release, while macOS
runs the latest release. Documentation consistency and the final changed-file
gate cover the integrated version and history updates.

## Evidence

The repair branch records focused MATLAB test artifacts and the final
changed-file validation result. The supplied sanitized log identifies the
original `MATLAB:catenate:dimensionMismatch` and
`MATLAB:character:CellsMustContainChars` failures.

## Known limitations and follow-up

Automated tests cannot prove the appearance and interaction quality of the
native Windows save dialog. A manual MATLAB R2024b Windows check remains the
final platform acceptance boundary.

# DIC uses framework-owned optional source slots

```labkit-change
id: LK-20260716-dic-source-slots
date: 2026-07-16
sequence: 93
type: refactor
compatibility: compatible
component: `labkit.ui` | `7.4.0 -> 7.4.1`
component: `labkit_DICPostprocess_app` | `1.4.2 -> 1.4.3`
component: `labkit_DICPreprocess_app` | `1.5.3 -> 1.5.4`
scope: DIC
scope: Runtime source boundary
```

## Context

DIC Preprocess and Postprocess use stable semantic source slots such as
`referenceImage`, `movingImage`, `maskImage`, and `dicMat`. Those slots are
legitimately absent before the user selects a file. Each App therefore carried
an identical `pathForId.m` wrapper that returned empty text for an unset slot
and otherwise inspected the nested portable reference.

The first source accessor required every requested ID to exist. Applying that
rule would have preserved the duplicate wrapper instead of lowering App cost.

## Decision and rationale

Make ID-based source lookup preserve the requested shape and return an empty
string for a semantic slot that has not been added. Continue to reject malformed
records and references. This matches ordinary presenter and session behavior
without hiding corrupt project data.

## Changes

- Refined `sourcePaths(sources,ids)` for optional semantic slots.
- Removed both DIC `pathForId.m` wrappers and their duplicate schema knowledge.
- Migrated DIC loading, summaries, presenters, save defaults, and export paths
  to the Runtime accessor.
- Preserved alignment, crop, mask, anchor, rendering, calculation, and export
  behavior.

## User and data impact

An empty DIC project still presents empty file controls and enables them as the
workflow requires. Selected and relinked files load through the same paths.
Developers no longer implement a source-ID lookup helper for each App.

## Compatibility and migration

The accessor change relaxes one error case and is compatible within UI 7. No
saved project shape changed and no DIC payload migration is required.

## Validation

Runtime unit tests cover mixed present and absent IDs. DIC unit and hidden-GUI
tests cover empty startup, file selection, point matching, ROI and mask edits,
viewport-preserving interaction, project state, and result export.

## Evidence

- [DIC Preprocess](../../../../apps/dic/dic-preprocess/README.md)
- [DIC Postprocess](../../../../apps/dic/dic-postprocess/README.md)
- [Runtime and Lifecycle](../../../../framework/guides/runtime.md)

## Known limitations and follow-up

Other families still contain direct portable-reference reads. They will move
to the same accessor before the repository-wide no-leak contract is enabled.

# Clean Debug startup and reliable Batch Crop ROI interaction

```labkit-change
id: LK-20260725-clean-debug-start-and-roi-repair
date: 2026-07-25
sequence: 160
type: fix
compatibility: compatible
component: `labkit.app` | `1.2.4 -> 1.2.5`
component: `labkit_BatchImageCrop_app` | `1.8.2 -> 1.8.3`
scope: App Framework
scope: Launcher Debug workflow
scope: Batch Crop
```

## Context

Debug launches used an App's synthetic project as its live project and then
ran normal startup actions. That made diagnostic sessions perform user work
automatically and exposed Batch Crop's small-sample numeric-control limit
failure. Batch Crop also registered separate center and ROI editors on one
preview, leaving the ROI dependent on editor focus order.

## Decision and rationale

Keep synthetic packs as validated diagnostic fixtures, but start every Debug
runtime from the schema's clean project and suppress automatic startup actions.
Use one managed Batch Crop ROI interaction: background clicks set its center
and dragging moves it, so no competing editor can take pointer ownership.

## Changes

- Separated synthetic-pack creation from runtime initial-project selection.
- Suppressed `OnStart` for synthetic diagnostic sessions.
- Extended isolated App validation to create, validate, and headlessly run all
  public synthetic sample projects.
- Added native Debug-start and Batch Crop small-image control regressions.
- Unified Batch Crop preview center placement and ROI movement under the ROI.

## User and data impact

Open Debug now opens each App cleanly while preserving anonymous synthetic
inputs and a manifest in its diagnostic folder. Users select any sample files
deliberately. Batch Crop ROI clicks and drags respond consistently. Existing
projects, source data, and exports are unchanged.

## Compatibility and migration

The App SDK public compatibility range and all saved-project schemas remain
unchanged. Existing projects open normally; only synthetic Debug startup no
longer auto-loads data or runs startup actions.

## Validation

- App SDK source contract for clean synthetic runtime startup.
- Native hidden-GUI Debug startup conformance for all public Apps.
- Path-isolated construction, schema validation, and headless use of every
  public App synthetic sample.
- Batch Crop native small-image control creation and ROI geometry regressions.

## Evidence

- [App runtime guide](../../../../framework/guides/runtime.md)
- [LabKit Launcher](../../../../apps/labkit-core/launcher/README.md)
- [Batch Image Crop](../../../../apps/image-measurement/batch-crop/README.md)
- [Testing](../../../../development/maintain-and-release/testing.md)

## Known limitations and follow-up

Native pointer feel and visual ROI affordance remain developer-led manual
checks on representative images; automated hidden-GUI tests prove creation and
semantic dispatch boundaries, not physical input-device behavior.

# Direct manipulation stays visible and Batch Crop restores manifests

```labkit-change
id: LK-20260820-direct-manipulation-and-batch-crop-restore
date: 2026-08-20
sequence: 188
type: refactor
compatibility: breaking
component: `labkit.app` | `2.4.1 -> 4.0.0`
component: `labkit.biosignal` | `2.0.0 -> 3.0.0`
component: `labkit_BatchImageCrop_app` | `1.9.4 -> 1.10.0`
component: `labkit_VideoMarker_app` | `1.7.4 -> 1.8.0`
scope: App SDK busy presentation
scope: Slider and managed plot interactions
scope: App-owned task continuation
scope: Batch Crop manifest restoration
scope: Batch Crop manifest provenance
scope: App-owned state and result boundaries
scope: Live source records and runtime resources
scope: Unconsumed SDK and biosignal APIs
```

## Context

The App SDK treated every callback as a visible busy action after 250 ms and disabled every native object exposing an `Enable` property. Slider changes and managed ROI clicks or drags could therefore disable visual containers while a plot renderer rebuilt its graphics, exposing a transient white window or blank axes. The same runtime exposed generic Project State save/load menus for every App with a schema, even when durable state existed only for transactions and diagnostics rather than a user task-continuation workflow. After that persistence layer was removed, framework assumptions about project/session roots, self-version requirements, portable source flags, resource scopes, common state specifications, and synthetic or journal export formats still encoded the retired design without production consumers. Batch Crop manifests described exported crop results but could not reopen the recorded source collection and operation state, and omitted several project-wide values needed for exact physical-mode restoration.

## Decision and rationale

Keep direct manipulation transactional without presenting it as a long-running action. Long discrete actions retain delayed busy feedback, but freeze only mutable leaf inputs and preserve the committed visual hierarchy. Remove project and result persistence semantics from the framework entirely: diagnostics may capture opaque runtime state, while a real continuation workflow owns explicit controls and its complete format inside the App. Keep only stable UI, serialized transactions, execution queues, lifecycle, diagnostics, dialogs, resources, and source selection in the SDK; App state roots, final result meaning, and continuation archives remain App-owned. Make the Batch Crop CSV a validated restorable final snapshot containing exact physical dimensions, upsample policy, format, and task order. Restore only successfully saved rows from the current format, with no migration, intermediate-state history, or multi-batch merge policy.

## Changes

- Increased the visible busy delay to 500 ms, limited native disabling to semantic leaf inputs, and left tabs, panels, plots, and committed graphics enabled.
- Routed sliders and managed plot interactions through serialized transactions without action-style busy presentation.
- Removed framework project schemas, document identity, dirty tracking, recovery, generic save/load menus, generic result packages, result manifests, and portable source relinking.
- Reduced `Definition` to opaque in-memory state creation and source-list refresh, made additional facade requirements optional, removed the unused App validation callback, and stopped built-in Apps from declaring a self-dependency on `labkit.app`.
- Treated Bind paths as App-owned dotted fields, removed uniform empty state buckets and shallow per-App state-shape specifications, and kept diagnostic state capture solely for logs and debugging.
- Reduced live source records to `id`, `role`, and `path`; moved path reading to the pure `labkit.app.source.paths` function and flattened transient resources to App-owned IDs with replacement, explicit removal, and close cleanup.
- Removed unused file-list and section options, the unconsumed synthetic JSON manifest and retained-journal export duplicate, test-only runtime hooks, and public plotting, integrity, and biosignal comparison helpers without production consumers.
- Added explicit Video Marker **Save MAT** and **Open MAT** controls backed by its App-owned archive; edits and navigation never autosave.
- Converted the remaining in-use Video Marker framework archives to the current App-owned format, then removed framework-project, legacy-project, and older-payload readers.
- Added Batch Crop **Restore manifest**, source relocation beside the selected manifest, dimension verification, successfully saved task reconstruction, and crop/scale/output-setting restoration.
- Extended new manifests with task order, exact physical dimensions, max-upsample percentage, and output format while retaining the existing result columns.

## User and data impact

Dragging sliders and plot interactions no longer flash action busy chrome or blank the surrounding App window. Long buttons still reject repeated input and show their stage after the delay. Analysis Apps no longer expose or implement a generic task archive. Video Marker keeps its explicit Session-panel continuation workflow. Batch Crop users can reopen a manifest and continue working with the recorded sources and task parameters. A missing source, changed pixel dimensions, malformed geometry, or conflicting shared setting leaves the current task unchanged.

## Compatibility and migration

This removes the version-2 project/result authoring API and the remaining state/source/resource assumptions built on it, advancing `labkit.app` to 4.0.0. The unused public group-comparison removal advances `labkit.biosignal` to 3.0.0. Built-in Apps migrate together and declare only additional facades they actually call. No generic live-state or source-record compatibility adapter is provided. Batch Crop manifest restoration deliberately accepts only the current final-snapshot format; older state files and manifests are not migrated. Video Marker accepts only its current App-owned archive after the remaining active framework archives are converted outside the repository.

## Validation

Focused App SDK evidence covers delayed action feedback, leaf-only input freezing, reentrant action rejection, the absence of visible busy state for sliders and managed rectangles, retained diagnostic state destinations, source/resource contracts, and removal of the generic Project State menu. Definition and initial-session conformance cover every built-in App on the opaque state boundary. Batch Crop result and presentation evidence covers current-manifest round trips, saved-row restoration, changed-source rejection, stable columns, and the restore action declaration. Video Marker evidence covers explicit archive round trips, continued rendering, and the absence of implicit MAT writes. Biosignal, test-catalog, architecture, code-analysis, and documentation checks cover the retired consumers and public surface. Native pointer feel and renderer-specific paint timing remain manual GUI boundaries.

## Evidence

- [App Framework](../../../../framework/README.md)
- [Batch Image Crop](../../../../apps/image-measurement/batch-crop/README.md)

## Known limitations and follow-up

Source dimension verification detects replacement images with changed geometry but cannot prove byte identity when dimensions are unchanged. Intermediate adjustments, earlier batches, failed rows, and legacy manifest formats are intentionally outside the restore contract.

# Runtime V2 lifecycle ownership across the app fleet

```labkit-change
id: CHG-20260715-runtime-v2-app-migration
date: 2026-07-15
type: refactor
compatibility: breaking
component: labkit.ui | 5.2.0 -> 6.0.0
component: labkit_DICPostprocess_app | 1.3.6 -> 1.4.0
component: labkit_DICPreprocess_app | 1.4.0 -> 1.5.0
component: labkit_ChronoOverlay_app | 1.3.6 -> 1.4.0
component: labkit_CIC_app | 1.3.8 -> 1.4.0
component: labkit_CSC_app | 1.3.10 -> 1.4.0
component: labkit_EIS_app | 1.3.4 -> 1.4.0
component: labkit_VTResistance_app | 1.3.8 -> 1.4.0
component: labkit_GaitAnalysis_app | 1.0.0 -> 1.1.0
component: labkit_BatchImageCrop_app | 1.6.8 -> 1.7.0
component: labkit_CurvatureMeasurement_app | 1.3.5 -> 1.4.0
component: labkit_FLIRThermal_app | 1.3.0 -> 1.4.0
component: labkit_FocusStack_app | 1.4.9 -> 1.5.0
component: labkit_ImageEnhance_app | 1.5.8 -> 1.6.0
component: labkit_ImageMatch_app | 1.5.8 -> 1.6.0
component: labkit_VideoMarker_app | 1.2.0 -> 1.3.0
component: labkit_FigureStudio_app | 0.1.5 -> 0.2.0
component: labkit_NerveResponseAnalysis_app | 1.3.5 -> 1.4.0
component: labkit_ResponseReviewStats_app | 1.3.5 -> 1.4.0
component: labkit_RHSPreview_app | 1.3.4 -> 1.4.0
component: labkit_ECGPrint_app | 1.3.5 -> 1.4.0
```

## Why

App lifecycle, callback ordering, UI-derived state, project persistence, graphics resources, and result packaging were implemented repeatedly across apps. Migrating only the lifecycle names would have preserved the main author cost: each app would still need to understand raw controls, figure callbacks, and multiple competing state copies.

### Accepted choice

Make Runtime V2 the only write path and give the framework ownership of launch, startup, the FIFO event queue, atomic state commits, deterministic presentation, dialogs, interaction resources, project persistence, and result manifests. Apps retain explicit project/session/presentation/result contracts and all domain calculations, workflow decisions, plots, schemas, and exports.

This deliberately optimizes ownership and learning cost rather than total app line count. Explicit app contracts can add code in a large scientific app, but they replace hidden closure state and callback plumbing with one inspectable model. The remaining 36 public UI functions have distinct reviewed contracts; the earlier 32-function planning target was not forced through vague APIs.

## What changed

- Migrated all twenty public apps to Runtime V2 definitions, standard launch, canonical project/session state, semantic events, pure presentation, and managed resources.
- Standardized current project writes and result manifests while retaining app-owned payload migrations and existing output files.
- Retired Runtime V1 writes and removed the public control-registry mutation, standalone editor/runtime, preview mutation, dialog, title, and dispatch compatibility surfaces.
- Kept supported V1 snapshots and named legacy app projects as read-only import formats; subsequent saves use the current project codec.
- Updated app requirements to `labkit.ui >=6 <7` and made UI 6 the breaking public facade boundary.
- Replaced Video Marker's optional `vision.PointTracker` branch with one deterministic app-owned multiscale patch matcher, retaining confidence, constant-velocity fallback, subpixel coordinates, and forward-cache behavior without Computer Vision Toolbox.
- Added traceable temporary MathWorks-product debt declarations: rapid app work must ship a base-MATLAB fallback plus deterministic and Toolbox-parity tests, and product analysis must continue to see the dependency until replacement.
- Re-audited already migrated apps, removed five dead or presenter-only helper files, and updated helper-quality classification from retired role packages to the current workflow-first lifecycle/state/result/UI boundaries.
- Corrected Runtime V2 interaction event construction so paired-anchor cell payloads remain one scalar semantic event. DIC Preprocess point matching now accepts alternating reference/moving points, enables alignment after two complete pairs, and completes the in-workbench rigid registration flow.
- Hardened the same scalar-envelope invariant for app-managed Runtime V2 resources and `runBusy` callback capture, including legitimate cell-form MATLAB callbacks and cell-valued resource payloads.
- Made project replacement invalidate the prior presentation cache before the fresh session is rendered, so opening an unchanged project still rebuilds app-owned preview graphics and other ephemeral visual resources.
- Corrected shared file-event index decoding for R2025a string results, so CIC and the other multi-file V2 apps can select and remove imported items.
- Stopped presentation commits from rerunning unchanged preview requests, and made DIC point-label updates preserve image handles and zoom viewports.
- Routed anchor-editor wheel input to the shared image zoom implementation without the retired wrapper's same-name recursion.
- Deferred CIC and VT batch DTA decoding until a file becomes visible or the batch is exported, so multi-file selection no longer blocks on every source.
- Let Gait Analysis read current Video Marker project/recovery envelopes and legacy Video/Image Marker autosaves directly as pose-coordinate inputs.
- Added interaction-mode subtitles for curve anchors, point marking, paired anchors, scale references, and fixed point slots; restored axes context menus after renderer resets; and promoted screenshot/project commands to top-level window entries.
- Moved Video Marker's Session controls to the top of the Video page, added an `Open MAT` project shortcut, and made New setup explicitly cancel, save, or discard before clearing the current project.
- Reorganized human documentation into getting-started, app workflow, public API, development, and focused-guide layers. Split app authoring from the user catalog, added the missing contract API reference, and made a project guardrail verify that every public `+labkit` function remains indexed under its owning facade.

## Impact

App entrypoint names, scientific calculations, workflow decisions, plots, and existing export filenames remain stable. Current projects have a consistent save/reopen path, external sources use portable references, and result exports include a standard manifest. Runtime errors and modal interactions now pass through framework services, which also makes hidden validation deterministic.

## Compatibility and limits

The migrated app versions require `labkit.ui >=6 <7`; they must not be copied into a UI 5 checkout. Supported V1 snapshots and documented legacy projects remain importable but are not written again. After import, save a new current project if continued editing or recovery is required.

### Remaining limits

Explicit domain contracts mean that large apps do not necessarily have fewer production lines. Further extraction is justified only by repeated mechanics, not by file-size targets. Pointer feel, drag ergonomics, and scientific visual judgment still require the documented manual app review before merge.

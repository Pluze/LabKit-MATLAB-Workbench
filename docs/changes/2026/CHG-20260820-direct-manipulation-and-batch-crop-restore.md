# Direct manipulation stays visible and Batch Crop restores manifests

```labkit-change
id: CHG-20260820-direct-manipulation-and-batch-crop-restore
date: 2026-08-20
type: refactor
compatibility: breaking
component: labkit.app | 2.4.1 -> 3.0.0
component: labkit.biosignal | 2.0.0 -> 3.0.0
component: labkit_DICPostprocess_app | 1.6.1 -> 1.7.0
component: labkit_DICPreprocess_app | 1.7.3 -> 1.8.0
component: labkit_ChronoOverlay_app | 1.6.2 -> 1.7.0
component: labkit_CIC_app | 1.6.3 -> 1.7.0
component: labkit_CSC_app | 1.6.2 -> 1.7.0
component: labkit_EIS_app | 1.6.3 -> 1.7.0
component: labkit_VTResistance_app | 1.6.3 -> 1.7.0
component: labkit_Mark10Monitor_app | 1.0.2 -> 1.1.0
component: labkit_BatchImageCrop_app | 1.9.4 -> 1.10.0
component: labkit_CurvatureMeasurement_app | 1.6.3 -> 1.7.0
component: labkit_FLIRThermal_app | 1.6.3 -> 1.7.0
component: labkit_FocusStack_app | 1.7.3 -> 1.8.0
component: labkit_ImageEnhance_app | 1.8.3 -> 1.9.0
component: labkit_ImageMatch_app | 1.8.3 -> 1.9.0
component: labkit_VideoMarker_app | 1.7.4 -> 1.8.0
component: labkit_GaitAnalysis_app | 2.2.3 -> 3.0.0
component: labkit_NerveResponseAnalysis_app | 1.6.2 -> 1.7.0
component: labkit_ResponseReviewStats_app | 1.6.2 -> 1.7.0
component: labkit_RHSPreview_app | 1.6.3 -> 1.7.0
component: labkit_TTestWizard_app | 1.3.2 -> 1.4.0
component: labkit_ECGPrint_app | 2.0.0 -> 2.1.0
```

## Why

The App SDK treated every callback as a visible busy action after 250 ms and disabled every native object exposing an `Enable` property. Slider changes and managed ROI clicks or drags could therefore disable visual containers while a plot renderer rebuilt its graphics, exposing a transient white window or blank axes. The same runtime exposed generic Project State save/load menus for every App with a schema, even when durable state existed only for transactions and diagnostics rather than a user task-continuation workflow. After that persistence layer was removed, framework assumptions about project/session roots, self-version requirements, portable source flags, resource scopes, common state specifications, two diagnostic-state export modes, and a framework-wide synthetic-sample protocol still encoded retired designs whose only consumers were developer menus, tests, and documentation. Batch Crop manifests described exported crop results but could not reopen the recorded source collection and operation state, and omitted several project-wide values needed for exact physical-mode restoration.

### Accepted choice

Keep direct manipulation transactional without presenting it as a long-running action. Long discrete actions retain delayed busy feedback, but freeze only mutable leaf inputs and preserve the committed visual hierarchy. Remove project and result persistence semantics from the framework entirely: diagnostics may capture opaque runtime state, while a real continuation workflow owns explicit controls and its complete format inside the App. Keep the durable journal because a MATLAB hang can otherwise erase the only evidence of the callback and stage that triggered it, but maintain one compact state export and only two durable callback boundaries rather than parallel exact/compact formats or a disk reopen after every stage. Treat fixture generation as private automated-test input construction, never as a Definition, Runtime, launcher, or App product capability. Keep only stable UI, serialized transactions, execution queues, lifecycle, diagnostics, dialogs, resources, and source selection in the SDK; App state roots, final result meaning, and continuation archives remain App-owned. Make the Batch Crop CSV a validated restorable final snapshot containing exact physical dimensions, upsample policy, format, and task order. Restore only successfully saved rows from the current format, with no migration, intermediate-state history, or multi-batch merge policy.

## What changed

- Increased the visible busy delay to 500 ms, limited native disabling to semantic leaf inputs, and left tabs, panels, plots, and committed graphics enabled.
- Routed sliders and managed plot interactions through serialized transactions without action-style busy presentation.
- Removed framework project schemas, document identity, dirty tracking, recovery, generic save/load menus, generic result packages, result manifests, and portable source relinking.
- Reduced `Definition` to opaque in-memory state creation and source-list refresh, made additional facade requirements optional, removed the unused App validation callback, and stopped built-in Apps from declaring a self-dependency on `labkit.app`.
- Treated Bind paths as App-owned dotted fields, removed uniform empty state buckets and shallow per-App state-shape specifications, and kept diagnostic state capture solely for logs and debugging.
- Reduced live source records to `id`, `role`, and `path`; moved path reading to the pure `labkit.app.source.paths` function and flattened transient resources to App-owned IDs with replacement, explicit removal, and close cleanup.
- Removed unused layout, interaction, snapshot, deployment-return, and inspection options; moved the native-only plot popout implementation out of the public SDK; and removed test-only runtime hooks and public integrity and biosignal helpers without production consumers.
- Retired `BuildSyntheticSamples`, its Runtime generator, Developer Tools menu, three-value sample model, and all App-owned sample-pack implementations. Automated behavior specs now construct ordinary current inputs locally, share only genuinely multi-owner builders under owner-named fixture packages, and keep test-run state outside the fixture namespace.
- Kept persistent session journals for hard-hang forensics, durably recorded callback entry and native-presentation entry, added read-only export of the newest same-App active journal, and reduced diagnostic state export to the single compact MAT projection.
- Added explicit Video Marker **Save MAT** and **Open MAT** controls backed by its App-owned archive; edits and navigation never autosave.
- Kept Video Marker frame-range controls inside the strictly increasing native limits required by the supported MATLAB floor while continuing to clamp App values to the actual video frame count.
- Converted the remaining in-use Video Marker framework archives to the current App-owned format, then removed framework-project, legacy-project, and older-payload readers.
- Updated Gait Analysis to consume only the current Video Marker archive instead of preserving the retired framework envelope as its input contract.
- Added Batch Crop **Restore manifest**, source relocation beside the selected manifest, dimension verification, successfully saved task reconstruction, and crop/scale/output-setting restoration.
- Extended new manifests with task order, exact physical dimensions, max-upsample percentage, and output format while retaining the existing result columns.

## Impact

Dragging sliders and plot interactions no longer flash action busy chrome or blank the surrounding App window. Long buttons still reject repeated input and show their stage after the delay. Analysis Apps no longer expose or implement a generic task archive. Video Marker keeps its explicit Session-panel continuation workflow. Batch Crop users can reopen a manifest and continue working with the recorded sources and task parameters. A missing source, changed pixel dimensions, malformed geometry, or conflicting shared setting leaves the current task unchanged.

## Compatibility and limits

This removes the version-2 project/result authoring API, the public sample-generation contract, exact diagnostic-state export, and the remaining state/source/resource assumptions built on them, advancing `labkit.app` to 3.0.0. The unused public group-comparison removal advances `labkit.biosignal` to 3.0.0. Built-in Apps migrate together and declare only additional facades they actually call; Apps whose ordinary scientific workflows remain compatible advance by one direct minor step. No generic live-state, source-record, sample-pack, or diagnostic-mode compatibility adapter is provided. Batch Crop manifest restoration deliberately accepts only the current final-snapshot format; older state files and manifests are not migrated. Video Marker accepts only its current App-owned archive after the remaining active framework archives are converted outside the repository, and Gait Analysis 3.0.0 consumes that same format without an intermediate compatibility reader.

### Remaining limits

Source dimension verification detects replacement images with changed geometry but cannot prove byte identity when dimensions are unchanged. Intermediate adjustments, earlier batches, failed rows, and legacy manifest formats are intentionally outside the restore contract.

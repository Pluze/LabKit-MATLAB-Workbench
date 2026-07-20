# App SDK explicit contract replaces the retired UI runtime

```labkit-change
schema: 2
id: LK-20260719-ui-explicit-contract-migration
date: 2026-07-19
sequence: 138
type: refactor
compatibility: breaking
component: `labkit.app` | `new -> 1.0.0`
component: `labkit_DICPostprocess_app` | `1.4.7 -> 1.5.0`
component: `labkit_DICPreprocess_app` | `1.5.8 -> 1.6.0`
component: `labkit_ChronoOverlay_app` | `1.4.7 -> 1.5.0`
component: `labkit_CIC_app` | `1.4.7 -> 1.5.0`
component: `labkit_CSC_app` | `1.4.8 -> 1.5.0`
component: `labkit_EIS_app` | `1.4.7 -> 1.5.0`
component: `labkit_VTResistance_app` | `1.4.7 -> 1.5.0`
component: `labkit_GaitAnalysis_app` | `2.0.8 -> 2.1.0`
component: `labkit_BatchImageCrop_app` | `1.7.7 -> 1.8.0`
component: `labkit_CurvatureMeasurement_app` | `1.4.6 -> 1.5.0`
component: `labkit_FLIRThermal_app` | `1.4.8 -> 1.5.0`
component: `labkit_FocusStack_app` | `1.5.6 -> 1.6.0`
component: `labkit_ImageEnhance_app` | `1.6.7 -> 1.7.0`
component: `labkit_ImageMatch_app` | `1.6.8 -> 1.7.0`
component: `labkit_VideoMarker_app` | `1.5.7 -> 1.6.0`
component: `labkit_FigureStudio_app` | `0.2.9 -> 0.3.0`
component: `labkit_NerveResponseAnalysis_app` | `1.4.8 -> 1.5.0`
component: `labkit_ResponseReviewStats_app` | `1.4.7 -> 1.5.0`
component: `labkit_RHSPreview_app` | `1.4.6 -> 1.5.0`
component: `labkit_TTestWizard_app` | `1.0.1 -> 1.1.0`
component: `labkit_ECGPrint_app` | `1.4.6 -> 1.5.0`
scope: App Framework
scope: DIC
scope: Electrochem
scope: Gait
scope: Image Measurement
scope: LabKit Core
scope: Neurophysiology
scope: Statistics
scope: Wearable
scope: Project persistence
scope: Result provenance
```

## Context

The retired UI runtime removed substantial per-App lifecycle code, but Apps still
registered callback tables, repeated bound values in presenters, authored
standard file add/remove/clear behavior, and depended on nested event/service
structs. A replacement SDK kernel had already established immutable semantic
values, pre-GUI validation, transactional state/presentation commits, project
documents, result manifests, resources, and portable sources. The migration
then had to restore the complete behavior and visual contract of every tracked
App before the retired production facade could be deleted.

## Decision and rationale

Create `labkit.app` as the stable SDK rather than misnaming the expanded
contract `labkit.ui` or adapting it back to Runtime V2 transport structs. Keep
the public root small, partition authoring by capability, and concentrate
complexity in a paved path: direct-callback `layout.*` nodes, strict bindings,
runtime-completed `view.Snapshot` values, standard file lifecycle, fixed
`CreateSession(project,context)`, and private native adapters.

Migrate all 21 tracked Apps through capability waves, treating their previous
controls, tabs, layout proportions, interactions, project behavior, results,
debug samples, and workflow wording as product contracts rather than reducing
the task to launch compatibility.

## Changes

- Added the private native MATLAB adapter with semantic component ownership,
  typed RuntimeKernel callbacks, native dialog results, complete-presentation
  reconciliation, and rollback to the previous native view after a failed
  renderer commit.
- Added `Definition.launch`, fixed renderer `(axes,model)` dispatch, semantic
  labels, runtime-owned file add/remove/clear and selection, and transient
  session rebuild after source collection changes.
- Added strict table view options, typed complete-data edits, and distinct
  `event.TableCellEdit`, `event.TableCellSelection`, and
  `event.ListSelection` values; the private adapter absorbs native MATLAB
  table-value differences.
- Fixed session construction to `CreateSession(project,context)` so Apps resolve
  opaque portable sources without reading their representation.
- Migrated Chrono Overlay to one directly bound export callback, four state
  bindings, one directly bound two-axis renderer, and a two-operation view
  snapshot.
- Partitioned the public SDK into `layout`, `view`, `event`, `project`,
  `result`, and `dialog`; layout nodes, option parsing, stores, adapters, and
  runtime execution remain hidden under `internal`.
- Reduced Chrono's noncomment layout/action/presenter code from 277 lines to
  86 while preserving its DTA alignment, plot options, project schema, CSV
  columns, and result provenance.
- Migrated T-Test Wizard as the typed editable-table, feature-fragment, and
  multi-page workspace proof: table selections and edits have explicit payload
  classes, `+workbench` exposes product assembly, workflow packages own their
  layout/presentation/actions, and the private adapter owns concrete layout.
- Migrated VT Resistance to direct file and analysis-setting bindings, a
  complete summary/table/two-axis snapshot, and an App-owned result-package
  export. Plot renderers and scientific choices now live with their owning
  analysis capabilities instead of a technical UI package.
- Migrated Gait Analysis to capability-owned source adoption, option
  invalidation, deterministic analysis, step selection/navigation, three-axis
  rendering, CSV-set export, and result packaging.
- Migrated DIC Preprocess to two role-bound image sources, paired-anchor
  registration, managed crop and mask editors, two-axis rendering, edit replay,
  and result-package exports owned by its analysis, mask, and result
  capabilities.
- Migrated Batch Image Crop to framework-owned source selection plus
  App-owned duplicate crop tasks, direct crop-center and scale-reference
  interactions, capability snapshots, and result-package export.
- Added `labkit.app.project.sourceRecord` so pure payload migrations can
  convert legacy paths into portable sources without constructing the
  framework-owned reference representation.
- Corrected folder chooser dispatch to its one-path backend contract and
  applied table data before table selection during native reconciliation, so
  a selection may legally target rows introduced by the same snapshot.
- Preserved cell-valued interaction payloads in the transactional event queue
  and kept multi-target interaction bridge specifications scalar, enabling
  paired-anchor gestures across two semantic axes.
- Removed handler objects, callback tables, renderer registries, and their
  forwarding from the App authoring contract. Layout controls and plot areas
  reference concrete functions directly.
- Migrated the remaining electrochemistry, DIC, image-measurement,
  neurophysiology, core, wearable, and high-state workflows, including
  editable tables, workspace pages, file roles, multi-axis plots, managed
  point/rectangle/interval/scale interactions, long-lived video resources,
  project recovery, result packages, and synthetic diagnostic samples.
- Restored shared product presentation: versioned titles and dirty markers,
  startup progress and failure surfaces, guarded close behavior, utility
  menus, adjustable pane dividers, scroll and grow policies, numeric panners,
  adaptive action grids, usage text, plot navigation, pop-out/export tools,
  and viewport-preserving overlays.
- Internalized contract compilation, runtime construction, native platform
  plans, target inventories, and callback-context creation. `Definition` is
  the sole author-created root; `CallbackContext` is a sealed runtime-injected
  port; optional concepts remain grouped under purpose-specific packages.
- Deleted the complete retired `labkit.ui` production facade and the
  migration-only analyzer, prototypes, compatibility tools, and debt-only
  tests after source scans and focused App tests proved that no production
  consumer remained.

## User and data impact

Chrono Overlay retains its input formats, pulse-gap alignment, plot meanings,
parameter defaults, CSV table, and version-2 project payload. T-Test Wizard
retains its source formats, group/test calculations, plot meaning, two CSV
exports, and version-2 project payload. VT Resistance retains its pulse
detection, resistance calculations, plot semantics, CSV schema, and version-1
project payload while recomputing the decoded batch under shared settings.
Gait Analysis retains its Video Marker payload contract, project migrations,
step segmentation, gait metrics, CSV set, and version-3 project payload. File
identities and portable paths remain runtime-owned. DIC Preprocess retains its
rigid registration, common crop, mask editing, image/mask exports, and
version-1 project payload. Batch Image Crop retains duplicate tasks per source,
fixed-pixel and physical crops, rotation/padding, scale calibration, scale-bar
placement, image/CSV exports, and its version-2 payload. Existing payload
migrations remain App-owned.

The other 15 Apps retain their documented source formats, scientific
calculations, units, thresholds, project payload versions, export schemas, and
result meanings. Their product versions advance once from the `main` baseline
to identify the new App SDK source contract and restored complete UI behavior.
No project payload version was increased merely because the UI framework
changed.

## Compatibility and migration

`labkit.app` 1 is a source-breaking replacement contract for App definitions,
presenters, callbacks, events, and interactions. Every tracked App migrated
before the retired `labkit.ui` boundary was deleted; there is no runtime
adapter or dual authoring surface. Public App entrypoint commands remain
stable. Project documents retain their format and App payload versions
independently of the facade transition.

## Validation

Focused headless tests cover strict values, transactional runtime behavior,
project save/restore, authoring defaults, and Chrono calculations/exports.
Hidden GUI tests cover native semantic construction, typed control and table
callbacks, bound
side effects, standard file lifecycle, transient session rebuild, two-axis
rendering, viewport preservation, renderer rollback, Chrono export, and
project restore. VT Resistance focused tests cover resistance calculations,
CSV compatibility, native layout, shared batch recomputation, two-axis
rendering, result packaging, and project restore. Gait focused tests cover
project migration, pose decoding, scientific calculations, CSV compatibility,
typed table navigation, three-axis rendering, folder selection, result
packaging, and project restore.
DIC Preprocess focused tests cover project state, image loading, edit replay,
registration/crop/mask helpers, export manifests, native two-axis layout,
paired-anchor alignment, and managed crop interaction. Framework regression
tests cover cell-valued event payloads and native multi-axis interaction
bridging.
Batch Image Crop focused tests cover crop geometry, padding, physical scaling,
project migration, duplicate tasks, output planning/writes, native semantic
layout, current-center editing, and standard result manifests.
Focused framework and App tests additionally cover all 21 semantic layouts,
typed events, managed interactions, project migration/recovery, result
writing, synthetic sample packs, diagnostics, resource cleanup, window titles,
startup success/failure, close behavior, and native adapter reconciliation.

## Evidence

- [Chrono Overlay](../../../../apps/electrochemistry/chrono-overlay/README.md)
- [VT Resistance](../../../../apps/electrochemistry/vt-resistance/README.md)
- [Gait Analysis](../../../../apps/gait/gait-analysis/README.md)
- [DIC Preprocess](../../../../apps/dic/dic-preprocess/README.md)
- [Batch Image Crop](../../../../apps/image-measurement/batch-crop/README.md)
- [App catalog](../../../../apps/README.md)
- [LabKit App Framework](../../../../framework/README.md)
- [Build a Complete App](../../../../development/build-apps/complete-app.md)

## Known limitations and follow-up

Automated GUI evidence does not replace developer-led validation of native
dialogs, editable-table feel, pointer interaction, long-lived resource use,
representative exports, visual quality, or scientific workflow suitability.
That interactive validation remains a release input for the exact integrated
commit.

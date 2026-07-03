# LabKit MATLAB Workbench Component Changelog

Generated from repository history through 2026-07-02 America/Chicago.

This file records component-level version metadata for LabKit MATLAB Workbench. It is intentionally more detailed than a release-note changelog: it tracks each app, launcher, and reusable facade component that owns a `version.m` or equivalent version metadata entry.

## Scope and reconstruction notes

- App and launcher version metadata was introduced by PR #24 on 2026-06-23. Before that point, component work existed in git history but was not represented by per-component semantic versions.
- Facade versions are stored as `labkit.contract.versionInfo(...)` records. App versions are stored as app-owned `version.m` files. The launcher stores version metadata in `labkit_launcher.m`.
- This changelog distinguishes between:
  - **pre-versioned history**: meaningful component work before explicit component version metadata existed; and
  - **versioned history**: observed semantic-version changes from version metadata files and PR diffs.
- Some intermediate versions between PR #24 and PR #27 were already present at the base of PR #27. Those intermediate values are recorded as observed checkpoints even when this document does not expand every individual sub-commit in that burst.
- The repository release policy uses semantic versioning: patch for bug fixes, minor for user-visible features/workflow changes/meaningful maintenance improvements, and major for breaking changes or intentionally incompatible workflows.

## Version-history anchors

| Date | PR / commit | Area | Version-history role |
|---|---|---|---|
| 2026-05 to 2026-06 | pre-PR component commits | Early LabKit apps and framework | Pre-versioned app extraction, parser extraction, GUI restructuring, and test-framework migration. |
| 2026-06-23 | PR #24 / `d70c260` | all apps + launcher + UI facade | Introduced app/launcher version metadata, versioned titles, lightweight `"version"` requests, launcher catalog version/date display, and version guardrails. |
| 2026-06-25 | `fe8654c` | launcher | Added the launcher version manager and bumped launcher from `1.0.0` to `1.1.0`. |
| 2026-06-29 | PR #26 / `f2189a` | `labkit.ui` | Fixed shared file-panel entry normalization; actual diff bumped `labkit.ui` from `3.2.0` to `3.2.2`. |
| 2026-07-02 | PR #27 / `279befb` | all supported apps + UI facade | Added app-owned debug sample packs and debug artifact sample/output folders; bumped most app versions to the `1.3.x` family and UI to `3.4.0`. |
| 2026-07-02 | PR #28 / `eadcca8` | `labkit.ui` + tests | Compressed validation runtime with GUI idle/bounded waits and scale-bar debounce registration; bumped UI to `3.4.1`. |
| 2026-07-02 | PR #29 / `25912c5` | `labkit.ui` + Batch Image Crop | Reduced debug/profile overhead and deferred Batch Image Crop image reads; bumped UI to `3.4.2` and Batch Image Crop to `1.6.1`. |
| 2026-07-02 CT / 2026-07-03 UTC | PR #30 / `71365de` | launcher + `labkit.ui` | Improved perceived startup by painting windows earlier, deferring launcher discovery, and lazy-loading preview scroll setup; bumped launcher to `1.2.3` and UI to `3.4.4`. |

## Current version inventory

### Core and launcher components

| Component | Current version | Status / family | Metadata location | Current notes |
|---|---:|---|---|---|
| `labkit_launcher` | `1.2.3` | Launcher | `labkit_launcher.m` | Self-contained GUI selector, updater, repair path, version manager, profiler/code-analyzer actions. |
| `labkit.ui` | `3.4.4` | stable facade | `+labkit/+ui/version.m` | UI 3.x app/spec/view/tool/diag contract, visible-window early paint, lazy preview scroll setup, debug artifacts, close guard, crash reports, output prompts, text fitting. |
| `labkit.dta` | `2.0.0` | stable facade | `+labkit/+dta/version.m` | DTA parser, file item, pulse, and curve facade contract. |
| `labkit.rhs` | `1.0.0` | stable facade | `+labkit/+rhs/version.m` | RHS discovery, metadata, indexing, and waveform-window facade contract. |
| `labkit.image` | `1.1.0` | stable facade | `+labkit/+image/version.m` | GUI-free image file input, basic processing, and preview-budget helpers. |
| `labkit.thermal` | `1.0.0` | experimental facade | `+labkit/+thermal/version.m` | GUI-free FLIR radiometric JPEG, raw matrix, temperature conversion, and display rendering facade. |
| `labkit.biosignal` | `1.0.0` | stable facade | `+labkit/+biosignal/version.m` | Biosignal recording, filtering, event, segmentation, and ECG facade contract. |

### App components

| App component | Family | Current version | Updated date | Metadata location |
|---|---|---:|---|---|
| `labkit_CIC_app` | Electrochem | `1.3.0` | 2026-07-01 | `apps/electrochem/cic/+cic/version.m` |
| `labkit_CSC_app` | Electrochem | `1.3.0` | 2026-07-01 | `apps/electrochem/csc/+csc/version.m` |
| `labkit_EIS_app` | Electrochem | `1.3.0` | 2026-07-01 | `apps/electrochem/eis/+eis/version.m` |
| `labkit_VTResistance_app` | Electrochem | `1.3.0` | 2026-07-01 | `apps/electrochem/vt_resistance/+vt_resistance/version.m` |
| `labkit_ChronoOverlay_app` | Electrochem | `1.3.0` | 2026-07-01 | `apps/electrochem/chrono_overlay/+chrono_overlay/version.m` |
| `labkit_DICPreprocess_app` | DIC | `1.3.0` | 2026-07-02 | `apps/dic/dic_preprocess/+dic_preprocess/version.m` |
| `labkit_DICPostprocess_app` | DIC | `1.3.0` | 2026-07-02 | `apps/dic/dic_postprocess/+dic_postprocess/version.m` |
| `labkit_BatchImageCrop_app` | Image Measurement | `1.6.1` | 2026-07-02 | `apps/image_measurement/batch_crop/+batch_crop/version.m` |
| `labkit_CurvatureMeasurement_app` | Image Measurement | `1.3.0` | 2026-07-01 | `apps/image_measurement/curvature/+curvature/version.m` |
| `labkit_FLIRThermal_app` | Image Measurement | `1.2.0` | 2026-07-02 | `apps/image_measurement/flir_thermal/+flir_thermal/version.m` |
| `labkit_FocusStack_app` | Image Measurement | `1.4.0` | 2026-07-01 | `apps/image_measurement/focus_stack/+focus_stack/version.m` |
| `labkit_ImageEnhance_app` | Image Measurement | `1.5.0` | 2026-07-01 | `apps/image_measurement/image_enhance/+image_enhance/version.m` |
| `labkit_ImageMatch_app` | Image Measurement | `1.5.0` | 2026-07-01 | `apps/image_measurement/image_match/+image_match/version.m` |
| `labkit_RHSPreview_app` | Neurophysiology | `1.3.0` | 2026-07-02 | `apps/neurophysiology/rhs_preview/+rhs_preview/version.m` |
| `labkit_NerveResponseAnalysis_app` | Neurophysiology | `1.3.0` | 2026-07-02 | `apps/neurophysiology/nerve_response_analysis/+nerve_response_analysis/version.m` |
| `labkit_ResponseReviewStats_app` | Neurophysiology | `1.3.0` | 2026-07-02 | `apps/neurophysiology/response_review_stats/+response_review_stats/version.m` |
| `labkit_ECGPrint_app` | Wearable | `1.3.1` | 2026-07-02 | `apps/wearable/ecg_print/+ecg_print/version.m` |

## Detailed component histories

## Core and launcher

### `labkit_launcher`

Current version: `1.2.3`.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | existing `labkit_launcher.m` history | Self-contained launcher existed before explicit launcher metadata. It handled app discovery and update/repair workflows but did not yet expose a structured launcher version record. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | Added `launcherVersion()`, `labkit_launcher("version")`, app catalog version/date display, and app version-title support. |
| `1.1.0` | 2026-06-25 | `fe8654c` | Added the launcher version manager and `Versions` button for deliberate upgrade/rollback across releases, tags, and main-branch commits. |
| `1.2.2` | 2026-07-02 | observed at PR #30 base | Launcher had accumulated release/updater/profile/version-manager hardening before PR #30. This is the immediate pre-PR #30 checkpoint. |
| `1.2.3` | 2026-07-02 | PR #30 / `71365de` | Deferred app discovery until after the launcher window is visible, painted visible launcher earlier, and made profiler export avoid opening a browser by default. |

### `labkit.ui`

Current version: `3.4.4`; compatible range: `>=3.0 <4`; status: stable.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | PR #21 and earlier UI migration history | Introduced and migrated the declarative app/spec/view/tool/diag UI architecture, replacing older app runner patterns. |
| `2.2.0` | 2026-06-23 | PR #24 / `d70c260` | Added app version-title support and the `"version"` lightweight request path. |
| `3.2.2` | 2026-06-29 | PR #26 / `f2189a` | Fixed shared file-panel entry normalization for Batch Crop folder-scan refreshes; regenerated empty/duplicate IDs deterministically. Actual diff shows `3.2.0 -> 3.2.2`. |
| `3.4.0` | 2026-07-02 | PR #27 / `279befb` | Added debug artifact sample/output folders to the UI debug context and app-owned debug sample pack flow. Actual diff shows `3.3.1 -> 3.4.0`. |
| `3.4.1` | 2026-07-02 | PR #28 / `eadcca8` | Added GUI idle/bounded stability waits and scale-bar debounce registration while reducing validation runtime. |
| `3.4.2` | 2026-07-02 | PR #29 / `25912c5` | Reduced debug trace text mirroring and profiling overhead; version bump was performed once at branch closeout. |
| `3.4.4` | 2026-07-02 CT / 2026-07-03 UTC | PR #30 / `71365de` | Added visible-window early paint and lazy preview scroll-interaction setup for better perceived startup responsiveness. Actual diff shows `3.4.2 -> 3.4.4`. |

Notes:

- Intermediate values between `2.2.0` and `3.2.0`, and between `3.2.2` and `3.3.1`, occurred in the post-metadata UI migration/hardening burst before PR #27. The PR boundaries above are the durable checkpoints visible from the reconstructed history.
- PR #26 text mentioned `3.2.1`, but the actual file diff records `3.2.0 -> 3.2.2`; this changelog follows the file diff.

### `labkit.dta`

Current version: `2.0.0`; compatible range: `>=2.0 <3`; status: stable.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | EIS/electrochem parser and helper extraction commits | DTA parsing and curve helpers were extracted while EIS and electrochem workflows were migrated away from monolithic app runners. |
| `1.x` lineage | 2026-06-23 | PR #24 metadata baseline | DTA facade participated in the version-guardrail model introduced for app-facing facades. |
| `2.0.0` | by 2026-07-01 | post-PR #24 to PR #27-base history | Stabilized the DTA parser, file item, pulse, and curve facade contract; old session helper surface was removed before the current `2.0.0` checkpoint. |

No later `labkit.dta` version bump was observed in PR #27 through PR #30.

### `labkit.rhs`

Current version: `1.0.0`; compatible range: `>=1.0 <2`; status: stable.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | RHS preview/import work | RHS file discovery, metadata inspection, indexing, and waveform-window read logic existed before formal facade versioning. |
| `1.0.0` | 2026-06-23 onward | PR #24 metadata model / current facade file | First stable RHS facade contract: discovery, metadata, indexing, and waveform-window access. |

No later `labkit.rhs` version bump was observed in PR #27 through PR #30.

### `labkit.image`

Current version: `1.1.0`; compatible range: `>=1.0 <2`; status: stable.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | Focus Stack, Batch Crop, Curvature, Image Enhance, Image Match history | Image apps carried their own local image loading, path, preview, and processing helpers before this shared facade existed. |
| `1.1.0` | by 2026-07-01 | post-PR #24 to PR #27-base history | Added a GUI-free image facade for file input, path normalization, basic processing, preview sizing, and responsive image-app helpers. |

No later `labkit.image` version bump was observed in PR #27 through PR #30.

### `labkit.thermal`

Current version: `1.0.0`; compatible range: `>=1.0 <2`; status: experimental.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before shared thermal facade | FLIR app development | Thermal handling was app-local while FLIR postprocess support was being introduced. |
| `1.0.0` | by 2026-07-01 | post-PR #24 to PR #27-base history | Added an experimental GUI-free thermal image facade for FLIR radiometric JPEG reads, raw sensor matrices, temperature conversion, and display rendering. |

No later `labkit.thermal` version bump was observed in PR #27 through PR #30.

### `labkit.biosignal`

Current version: `1.0.0`; compatible range: `>=1.0 <2`; status: stable.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | ECG Print and biosignal import/processing work | Recording import, filtering, segmentation, and ECG analysis helpers existed before facade versioning. |
| `1.0.0` | 2026-06-23 onward | PR #24 metadata model / current facade file | First stable biosignal facade contract: recording, filtering, event, segmentation, and ECG helpers. |

No later `labkit.biosignal` version bump was observed in PR #27 through PR #30.

## Electrochem apps

Shared pre-versioned history for electrochem apps:

- PR #8 consolidated CIC, VT Resistance, and Chrono Overlay runner helpers through app-owned electrochem workflow dispatch instead of duplicate runner-local implementations.
- PR #14 removed electrochem `+core/dispatch.m` string routers and moved implementations into component-local package functions.
- PR #17 converged EIS and other electrochem runner helpers toward app-owned package/view helpers.
- PR #21 migrated electrochem app GUIs to the UI 2.0 declarative `buildSpec` + package-root `run.m` pattern.

### `labkit_EIS_app`

Current version: `1.3.0`; updated: 2026-07-01.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | EIS parser/helper/app-package commits | EIS DTA parser extraction, overlay export helper extraction, app-owned package migration, DTA facade adoption, and EIS app relocation happened before explicit app versions. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First EIS app version metadata. |
| `1.2.1` | 2026-06-24 | observed at PR #27 base | Post-metadata EIS/electrochem updates before debug sample packs. |
| `1.3.0` | 2026-07-01 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

### `labkit_CIC_app`

Current version: `1.3.0`; updated: 2026-07-01.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | electrochem app migration history | CIC helper consolidation and UI migration happened before explicit app metadata. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First CIC app version metadata. |
| `1.2.1` | 2026-06-24 | observed at PR #27 base | Post-metadata CIC/electrochem updates before debug sample packs. |
| `1.3.0` | 2026-07-01 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

### `labkit_CSC_app`

Current version: `1.3.0`; updated: 2026-07-01.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | electrochem app migration history | CSC helper consolidation and UI migration happened before explicit app metadata. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First CSC app version metadata. |
| `1.2.1` | 2026-06-24 | observed at PR #27 base | Post-metadata CSC/electrochem updates before debug sample packs. |
| `1.3.0` | 2026-07-01 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

### `labkit_VTResistance_app`

Current version: `1.3.0`; updated: 2026-07-01.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | electrochem app migration history | VT Resistance helper consolidation and UI migration happened before explicit app metadata. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First VT Resistance app version metadata. |
| `1.2.1` | 2026-06-24 | observed at PR #27 base | Post-metadata VT/electrochem updates before debug sample packs. |
| `1.3.0` | 2026-07-01 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

### `labkit_ChronoOverlay_app`

Current version: `1.3.0`; updated: 2026-07-01.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | electrochem app migration history | Chrono Overlay helper consolidation and UI migration happened before explicit app metadata. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First Chrono Overlay app version metadata. |
| `1.2.1` | 2026-06-24 | observed at PR #27 base | Post-metadata Chrono Overlay/electrochem updates before debug sample packs. |
| `1.3.0` | 2026-07-01 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

## DIC apps

Shared pre-versioned history for DIC apps:

- PR #6 and subsequent migration work moved LabKit apps toward official build tasks, GUI/unit tests, and app-owned behavior without test backdoors.
- PR #21 migrated DIC apps to the UI 2.0 declarative `buildSpec` + package-root `run.m` pattern.

### `labkit_DICPreprocess_app`

Current version: `1.3.0`; updated: 2026-07-02.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | DIC migration history | DIC Preprocess UI/layout and package-root runner existed before explicit app metadata. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First DIC Preprocess app version metadata. |
| `1.2.2` | 2026-06-30 | observed at PR #27 base | Post-metadata DIC Preprocess updates before debug sample packs. |
| `1.3.0` | 2026-07-02 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

### `labkit_DICPostprocess_app`

Current version: `1.3.0`; updated: 2026-07-02.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | DIC migration history | DIC Postprocess UI/layout, strain summary, and overlay export workflow existed before explicit app metadata. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First DIC Postprocess app version metadata. |
| `1.2.4` | 2026-07-01 | observed at PR #27 base | Post-metadata DIC Postprocess updates before debug sample packs. |
| `1.3.0` | 2026-07-02 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

## Image Measurement apps

Shared pre-versioned history for image apps:

- PR #2 added the microscope Focus Stack app with optional middle-frame registration and Laplacian-pyramid fusion.
- PR #10 added Batch Image Crop with multi-image loading, fixed-pixel crop geometry, per-image rotation/crop-center confirmation, and manifest-backed exports.
- PR #11 migrated image apps into app-owned package namespaces for Batch Crop, Curvature, and Focus Stack.
- PR #20 added separate Image Enhance and Image Match apps and moved tab row resizing toward shared semantic behavior.
- PR #21 migrated image apps to the UI 2.0 declarative `buildSpec` + package-root `run.m` pattern.

### `labkit_BatchImageCrop_app`

Current version: `1.6.1`; updated: 2026-07-02.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | PR #10, PR #11, PR #21 | Batch Image Crop was added, package-migrated, and moved to declarative UI before explicit app metadata. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First Batch Image Crop app version metadata. |
| `1.5.1` | 2026-07-01 | observed at PR #27 base | Post-metadata Batch Crop workflow and image/scale/crop updates before debug sample packs. |
| `1.6.0` | 2026-07-01 | PR #27 / `279befb` | Added app-owned debug sample pack support. |
| `1.6.1` | 2026-07-02 | PR #29 / `25912c5` | Deferred image reads until current preview/export, improving file-selection responsiveness. |

### `labkit_CurvatureMeasurement_app`

Current version: `1.3.0`; updated: 2026-07-01.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | image app package migration history | Curvature Measurement was package-migrated and moved into the shared app/UI structure before explicit app metadata. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First Curvature Measurement app version metadata. |
| `1.2.4` | 2026-07-01 | observed at PR #27 base | Post-metadata curvature workflow updates before debug sample packs. |
| `1.3.0` | 2026-07-01 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

### `labkit_FocusStack_app`

Current version: `1.4.0`; updated: 2026-07-01.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | PR #2, PR #11, PR #21 | Focus Stack was introduced, package-migrated, and moved to the declarative UI pattern before explicit app metadata. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First Focus Stack app version metadata. |
| `1.3.0` | 2026-07-01 | observed at PR #27 base | Post-metadata Focus Stack workflow updates before debug sample packs. |
| `1.4.0` | 2026-07-01 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

### `labkit_ImageEnhance_app`

Current version: `1.5.0`; updated: 2026-07-01.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | PR #20, PR #21 | Image Enhance was added as a separate image app and migrated into the declarative UI/app-owned package pattern. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First Image Enhance app version metadata. |
| `1.4.1` | 2026-07-01 | observed at PR #27 base | Post-metadata image enhancement workflow updates before debug sample packs. |
| `1.5.0` | 2026-07-01 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

### `labkit_ImageMatch_app`

Current version: `1.5.0`; updated: 2026-07-01.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | PR #20, PR #21 | Image Match was added as a separate image app and migrated into the declarative UI/app-owned package pattern. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First Image Match app version metadata. |
| `1.4.1` | 2026-07-01 | observed at PR #27 base | Post-metadata image matching workflow updates before debug sample packs. |
| `1.5.0` | 2026-07-01 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

### `labkit_FLIRThermal_app`

Current version: `1.2.0`; updated: 2026-07-02.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned / not present at PR #24 baseline | before 2026-07-01 | FLIR app introduction history | FLIR Thermal Postprocess was introduced after the initial PR #24 metadata baseline. |
| `1.1.2` | 2026-07-01 | observed at PR #27 base | FLIR Thermal app existed with postprocess workflow and thermal facade integration before debug sample packs. |
| `1.2.0` | 2026-07-02 | PR #27 / `279befb` | Added app-owned debug sample pack support and changed shared-range behavior so initial padding is wider and shared range can expand to selected items before manual narrowing. |

## Neurophysiology apps

Shared pre-versioned history for neurophysiology apps:

- Neurophysiology app workflows were migrated into app-owned packages and the shared UI pattern before formal version metadata.
- RHS-related work also drove the stable `labkit.rhs` facade for file discovery, metadata, indexing, and waveform-window reads.

### `labkit_RHSPreview_app`

Current version: `1.3.0`; updated: 2026-07-02.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | RHS Preview app/facade history | RHS Preview existed before explicit app metadata and later became the representative large-file/RHS workflow. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First RHS Preview app version metadata. |
| `1.2.4` | 2026-07-01 | observed at PR #27 base | Post-metadata RHS Preview workflow updates before debug sample packs. |
| `1.3.0` | 2026-07-02 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

### `labkit_NerveResponseAnalysis_app`

Current version: `1.3.0`; updated: 2026-07-02.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | neurophysiology app migration history | Nerve Response Analysis existed before explicit app metadata. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First Nerve Response Analysis app version metadata. |
| `1.2.4` | 2026-06-30 | observed at PR #27 base | Post-metadata nerve-response workflow updates before debug sample packs. |
| `1.3.0` | 2026-07-02 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

### `labkit_ResponseReviewStats_app`

Current version: `1.3.0`; updated: 2026-07-02.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | neurophysiology app migration history | Response Review Stats existed before explicit app metadata. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First Response Review Stats app version metadata. |
| `1.2.3` | 2026-06-30 | observed at PR #27 base | Post-metadata response-review workflow updates before debug sample packs. |
| `1.3.0` | 2026-07-02 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |

## Wearable apps

### `labkit_ECGPrint_app`

Current version: `1.3.1`; updated: 2026-07-02.

| Version | Date | Source | Change summary |
|---:|---|---|---|
| pre-versioned | before 2026-06-23 | ECG Print and biosignal migration history | ECG Print existed before explicit app metadata, then moved into an app-owned package and shared biosignal workflow. |
| `1.0.0` | 2026-06-23 | PR #24 / `d70c260` | First ECG Print app version metadata. |
| `1.2.2` | 2026-06-30 | observed at PR #27 base | Post-metadata ECG Print workflow updates before debug sample packs. |
| `1.3.0` | 2026-07-02 | PR #27 / `279befb` | Added app-owned debug sample pack support and debug artifact integration. |
| `1.3.1` | 2026-07-02 | post-PR #27 mainline | Current checkpoint after ECG Print debug/sample or workflow-test adjustments. The post-PR #27 compare shows `apps/wearable/ecg_print/+ecg_print/version.m` changed after PR #27; this document records the resulting current value. |

## Maintenance guidance for future updates

When changing a versioned component:

1. Update that component's own version metadata in the same change as the behavior change.
2. Use `X.Y.Z` semantic version format.
3. Treat app versions, launcher versions, and facade contract versions independently.
4. If a versioned component changes behavior but the version does not increase, expect the project version guardrails to fail.
5. Add a short line to this changelog summarizing:
   - previous version,
   - new version,
   - PR/commit anchor,
   - behavior/contract reason for the bump, and
   - affected users or maintainers.

## Quick append template

```markdown
### `<component>`

| Version | Date | Source | Change summary |
|---:|---|---|---|
| `<new version>` | YYYY-MM-DD | PR #NN / `<short sha>` | `<why the version changed>` |
```
